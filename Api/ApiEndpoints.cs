using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Xsports.Models;
using Xsports.Pages;

namespace Xsports;

public static class ApiEndpoints
{
    public static void MapXsportsApi(this WebApplication app)
    {
        app.MapPost("/api/auth/login", LoginAsync)
            .AllowAnonymous();

        var api = app.MapGroup("/api")
            .RequireAuthorization(new AuthorizeAttribute
            {
                AuthenticationSchemes = JwtBearerDefaults.AuthenticationScheme
            });

        api.MapGet("/produtos", async (AppDbContext db) =>
        {
            var produtos = await db.Produtos.AsNoTracking()
                .OrderBy(produto => produto.Nome)
                .Select(produto => new ProdutoDto(
                    produto.Id,
                    produto.Nome,
                    produto.Preco,
                    produto.Estoque,
                    produto.Categoria,
                    produto.ImagemUrl))
                .ToListAsync();

            return Results.Ok(produtos);
        });

        api.MapPost("/produtos", async (ProdutoRequest request, AppDbContext db) =>
        {
            var erro = Validar(request);
            if (erro is not null)
            {
                return Results.ValidationProblem(new Dictionary<string, string[]>
                {
                    [erro.Value.Key] = [erro.Value.Message]
                });
            }

            var produto = new Produto
            {
                Nome = request.Nome.Trim(),
                Preco = request.Preco,
                Estoque = request.Quantidade,
                Categoria = request.Categoria.Trim(),
                ImagemUrl = request.ImagemUrl ?? string.Empty
            };

            db.Produtos.Add(produto);
            await db.SaveChangesAsync();
            return Results.Created($"/api/produtos/{produto.Id}", ProdutoDto.From(produto));
        });

        api.MapPost("/produtos/upload", async (
            [FromForm] ProdutoUploadRequest request,
            AppDbContext db,
            IWebHostEnvironment environment) =>
        {
            var produtoRequest = new ProdutoRequest(
                request.Nome,
                request.Preco,
                request.Quantidade,
                request.Categoria);
            var erro = Validar(produtoRequest);
            if (erro is not null)
            {
                return Results.ValidationProblem(new Dictionary<string, string[]>
                {
                    [erro.Value.Key] = [erro.Value.Message]
                });
            }

            var (imagemUrl, erroImagem) =
                await SalvarImagemAsync(request.Foto, environment);
            if (erroImagem is not null)
            {
                return Results.ValidationProblem(new Dictionary<string, string[]>
                {
                    ["Foto"] = [erroImagem]
                });
            }

            var produto = new Produto
            {
                Nome = request.Nome.Trim(),
                Preco = request.Preco,
                Estoque = request.Quantidade,
                Categoria = request.Categoria.Trim(),
                ImagemUrl = imagemUrl!
            };

            db.Produtos.Add(produto);
            await db.SaveChangesAsync();
            return Results.Created($"/api/produtos/{produto.Id}", ProdutoDto.From(produto));
        })
        .DisableAntiforgery()
        .WithMetadata(new RequestSizeLimitAttribute(6 * 1024 * 1024));

        api.MapPut("/produtos/{id:int}", async (
            int id,
            ProdutoRequest request,
            AppDbContext db) =>
        {
            var erro = Validar(request);
            if (erro is not null)
            {
                return Results.ValidationProblem(new Dictionary<string, string[]>
                {
                    [erro.Value.Key] = [erro.Value.Message]
                });
            }

            var produto = await db.Produtos.FindAsync(id);
            if (produto is null)
            {
                return Results.NotFound();
            }

            produto.Nome = request.Nome.Trim();
            produto.Preco = request.Preco;
            produto.Estoque = request.Quantidade;
            produto.Categoria = request.Categoria.Trim();
            produto.ImagemUrl = request.ImagemUrl ?? produto.ImagemUrl;

            await db.SaveChangesAsync();
            return Results.Ok(ProdutoDto.From(produto));
        });

        api.MapPut("/produtos/{id:int}/upload", async (
            int id,
            [FromForm] ProdutoUploadRequest request,
            AppDbContext db,
            IWebHostEnvironment environment) =>
        {
            var produtoRequest = new ProdutoRequest(
                request.Nome,
                request.Preco,
                request.Quantidade,
                request.Categoria);
            var erro = Validar(produtoRequest);
            if (erro is not null)
            {
                return Results.ValidationProblem(new Dictionary<string, string[]>
                {
                    [erro.Value.Key] = [erro.Value.Message]
                });
            }

            var produto = await db.Produtos.FindAsync(id);
            if (produto is null)
            {
                return Results.NotFound();
            }

            var (imagemUrl, erroImagem) =
                await SalvarImagemAsync(request.Foto, environment);
            if (erroImagem is not null)
            {
                return Results.ValidationProblem(new Dictionary<string, string[]>
                {
                    ["Foto"] = [erroImagem]
                });
            }

            produto.Nome = request.Nome.Trim();
            produto.Preco = request.Preco;
            produto.Estoque = request.Quantidade;
            produto.Categoria = request.Categoria.Trim();
            produto.ImagemUrl = imagemUrl!;

            await db.SaveChangesAsync();
            return Results.Ok(ProdutoDto.From(produto));
        })
        .DisableAntiforgery()
        .WithMetadata(new RequestSizeLimitAttribute(6 * 1024 * 1024));

        api.MapDelete("/produtos/{id:int}", async (int id, AppDbContext db) =>
        {
            var produto = await db.Produtos.FindAsync(id);
            if (produto is null)
            {
                return Results.NotFound();
            }

            db.Produtos.Remove(produto);
            await db.SaveChangesAsync();
            return Results.NoContent();
        });

        api.MapGet("/movimentacoes", async (AppDbContext db) =>
        {
            var movimentacoes = await db.Movimentacoes
                .AsNoTracking()
                .Include(movimentacao => movimentacao.Produto)
                .OrderByDescending(movimentacao => movimentacao.DataMovimentacao)
                .Select(movimentacao => new MovimentacaoDto(
                    movimentacao.Id,
                    movimentacao.ProdutoId,
                    movimentacao.Produto == null
                        ? "Produto Removido"
                        : movimentacao.Produto.Nome,
                    movimentacao.Quantidade,
                    movimentacao.Motivo,
                    movimentacao.Observacao,
                    movimentacao.DataMovimentacao))
                .ToListAsync();

            return Results.Ok(movimentacoes);
        });

        api.MapPost("/movimentacoes", async (
            MovimentacaoRequest request,
            AppDbContext db) =>
        {
            if (request.Quantidade <= 0)
            {
                return Results.ValidationProblem(new Dictionary<string, string[]>
                {
                    [nameof(request.Quantidade)] = ["A quantidade deve ser maior que zero."]
                });
            }

            var produto = await db.Produtos.FindAsync(request.ProdutoId);
            if (produto is null)
            {
                return Results.NotFound(new { message = "Produto não encontrado." });
            }

            if (request.Quantidade > produto.Estoque)
            {
                return Results.ValidationProblem(new Dictionary<string, string[]>
                {
                    [nameof(request.Quantidade)] =
                    [$"Estoque insuficiente. Saldo atual: {produto.Estoque}."]
                });
            }

            produto.Estoque -= request.Quantidade;
            var movimentacao = new Movimentacao
            {
                ProdutoId = produto.Id,
                Quantidade = request.Quantidade,
                Motivo = string.IsNullOrWhiteSpace(request.Motivo)
                    ? "Venda"
                    : request.Motivo.Trim(),
                Observacao = request.Observacao,
                DataMovimentacao = DateTime.Now
            };

            db.Movimentacoes.Add(movimentacao);
            await db.SaveChangesAsync();

            return Results.Ok(new
            {
                movimentacao.Id,
                movimentacao.ProdutoId,
                movimentacao.Quantidade,
                movimentacao.Motivo,
                movimentacao.DataMovimentacao,
                produto = ProdutoDto.From(produto)
            });
        });
    }

    private static async Task<IResult> LoginAsync(
        LoginRequest request,
        AppDbContext db,
        IPasswordHasher<Usuario> passwordHasher,
        JwtTokenService tokenService)
    {
        if (string.IsNullOrWhiteSpace(request.Email) ||
            string.IsNullOrEmpty(request.Senha))
        {
            return Results.Unauthorized();
        }

        var email = request.Email.Trim();
        var usuario = await db.Usuarios.SingleOrDefaultAsync(item => item.Email == email);
        if (usuario is null)
        {
            return Results.Unauthorized();
        }

        var resultado = passwordHasher.VerifyHashedPassword(
            usuario, usuario.SenhaHash, request.Senha);
        if (resultado == PasswordVerificationResult.Failed)
        {
            return Results.Unauthorized();
        }
        if (resultado == PasswordVerificationResult.SuccessRehashNeeded)
        {
            usuario.SenhaHash = passwordHasher.HashPassword(usuario, request.Senha);
            await db.SaveChangesAsync();
        }

        return Results.Ok(tokenService.Create(usuario));
    }

    private static (string Key, string Message)? Validar(ProdutoRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Nome))
        {
            return (nameof(request.Nome), "Informe o nome do produto.");
        }

        if (request.Preco <= 0)
        {
            return (nameof(request.Preco), "O preço deve ser maior que zero.");
        }

        if (request.Quantidade < 0)
        {
            return (nameof(request.Quantidade), "A quantidade não pode ser negativa.");
        }

        if (string.IsNullOrWhiteSpace(request.Categoria))
        {
            return (nameof(request.Categoria), "Informe a categoria do produto.");
        }

        return null;
    }

    private static async Task<(string? Url, string? Error)> SalvarImagemAsync(
        IFormFile? foto,
        IWebHostEnvironment environment)
    {
        const long tamanhoMaximo = 5 * 1024 * 1024;
        if (foto is null || foto.Length == 0)
        {
            return (null, "Selecione uma foto do produto.");
        }

        if (foto.Length > tamanhoMaximo)
        {
            return (null, "A foto deve ter no máximo 5 MB.");
        }

        var extensaoEnviada = Path.GetExtension(foto.FileName).ToLowerInvariant();
        if (extensaoEnviada is not (".jpg" or ".jpeg" or ".png" or ".webp"))
        {
            return (null, "Envie uma imagem JPG, PNG ou WEBP.");
        }

        var cabecalho = new byte[12];
        await using (var stream = foto.OpenReadStream())
        {
            var lidos = await stream.ReadAsync(cabecalho.AsMemory());
            var extensaoReal = DetectarExtensaoImagem(cabecalho, lidos);
            if (extensaoReal is null ||
                ((extensaoEnviada is ".jpg" or ".jpeg") && extensaoReal != ".jpg") ||
                (extensaoEnviada == ".png" && extensaoReal != ".png") ||
                (extensaoEnviada == ".webp" && extensaoReal != ".webp"))
            {
                return (null, "O arquivo enviado não é uma imagem JPG, PNG ou WEBP válida.");
            }
        }

        var extensao = extensaoEnviada is ".jpg" or ".jpeg"
            ? ".jpg"
            : extensaoEnviada;
        var nomeArquivo = $"{Guid.NewGuid():N}{extensao}";
        var pastaUploads = Path.Combine(environment.WebRootPath, "images");
        Directory.CreateDirectory(pastaUploads);

        var caminhoCompleto = Path.Combine(pastaUploads, nomeArquivo);
        await using (var destino = File.Create(caminhoCompleto))
        {
            await foto.CopyToAsync(destino);
        }

        return ($"/images/{nomeArquivo}", null);
    }

    private static string? DetectarExtensaoImagem(byte[] cabecalho, int lidos)
    {
        if (lidos >= 3 && cabecalho[0] == 0xFF &&
            cabecalho[1] == 0xD8 && cabecalho[2] == 0xFF)
        {
            return ".jpg";
        }

        if (lidos >= 8 &&
            cabecalho[0] == 0x89 && cabecalho[1] == 0x50 &&
            cabecalho[2] == 0x4E && cabecalho[3] == 0x47 &&
            cabecalho[4] == 0x0D && cabecalho[5] == 0x0A &&
            cabecalho[6] == 0x1A && cabecalho[7] == 0x0A)
        {
            return ".png";
        }

        if (lidos >= 12 &&
            cabecalho[0] == 'R' && cabecalho[1] == 'I' &&
            cabecalho[2] == 'F' && cabecalho[3] == 'F' &&
            cabecalho[8] == 'W' && cabecalho[9] == 'E' &&
            cabecalho[10] == 'B' && cabecalho[11] == 'P')
        {
            return ".webp";
        }

        return null;
    }
}

public sealed record LoginRequest(string Email, string Senha);

public sealed class ProdutoUploadRequest
{
    public string Nome { get; set; } = string.Empty;
    public decimal Preco { get; set; }
    public int Quantidade { get; set; }
    public string Categoria { get; set; } = string.Empty;
    public IFormFile? Foto { get; set; }
}

public sealed record ProdutoRequest(
    string Nome,
    decimal Preco,
    int Quantidade,
    string Categoria,
    string? ImagemUrl = null);

public sealed record MovimentacaoRequest(
    int ProdutoId,
    int Quantidade,
    string Motivo,
    string? Observacao = null);

public sealed record MovimentacaoDto(
    int Id,
    int ProdutoId,
    string ProdutoNome,
    int Quantidade,
    string Motivo,
    string? Observacao,
    DateTime DataMovimentacao);

public sealed record ProdutoDto(
    int Id,
    string Nome,
    decimal Preco,
    int Quantidade,
    string Categoria,
    string ImagemUrl)
{
    public static ProdutoDto From(Produto produto) => new(
        produto.Id,
        produto.Nome,
        produto.Preco,
        produto.Estoque,
        produto.Categoria,
        produto.ImagemUrl);
}

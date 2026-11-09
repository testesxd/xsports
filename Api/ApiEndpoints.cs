using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
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
}

public sealed record LoginRequest(string Email, string Senha);

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

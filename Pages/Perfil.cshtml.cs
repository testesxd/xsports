using System.Security.Claims;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.EntityFrameworkCore;
using Xsports.Models;

namespace Xsports.Pages;

public class PerfilModel : PageModel
{
    private readonly AppDbContext _context;
    private readonly IPasswordHasher<Usuario> _passwordHasher;

    public PerfilModel(AppDbContext context, IPasswordHasher<Usuario> passwordHasher)
    {
        _context = context;
        _passwordHasher = passwordHasher;
    }

    [BindProperty]
    public string Nome { get; set; } = string.Empty;

    [BindProperty]
    public string SenhaAtual { get; set; } = string.Empty;

    [BindProperty]
    public string NovaSenha { get; set; } = string.Empty;

    [BindProperty]
    public string ConfirmarSenha { get; set; } = string.Empty;

    public string Email { get; private set; } = string.Empty;

    public async Task<IActionResult> OnGetAsync()
    {
        var usuario = await ObterUsuarioAtualAsync();
        if (usuario is null)
        {
            return NotFound();
        }

        Nome = usuario.Nome;
        Email = usuario.Email;
        return Page();
    }

    public async Task<IActionResult> OnPostAsync()
    {
        var usuario = await ObterUsuarioAtualAsync();
        if (usuario is null)
        {
            return NotFound();
        }

        Email = usuario.Email;
        Nome = Nome.Trim();
        if (string.IsNullOrWhiteSpace(Nome) || Nome.Length > 150)
        {
            ModelState.AddModelError(nameof(Nome), "Informe um nome com até 150 caracteres.");
        }

        var alterandoSenha = !string.IsNullOrEmpty(SenhaAtual)
            || !string.IsNullOrEmpty(NovaSenha)
            || !string.IsNullOrEmpty(ConfirmarSenha);
        if (alterandoSenha)
        {
            if (_passwordHasher.VerifyHashedPassword(usuario, usuario.SenhaHash, SenhaAtual)
                == PasswordVerificationResult.Failed)
            {
                ModelState.AddModelError(nameof(SenhaAtual), "A senha atual está inválida.");
            }

            if (string.IsNullOrEmpty(NovaSenha) || NovaSenha != ConfirmarSenha)
            {
                ModelState.AddModelError(nameof(NovaSenha), "As novas senhas não coincidem.");
            }
        }

        if (!ModelState.IsValid)
        {
            return Page();
        }

        usuario.Nome = Nome;
        if (alterandoSenha)
        {
            usuario.SenhaHash = _passwordHasher.HashPassword(usuario, NovaSenha);
        }

        await _context.SaveChangesAsync();

        var claims = new[]
        {
            new Claim(ClaimTypes.NameIdentifier, usuario.Id.ToString()),
            new Claim(ClaimTypes.Name, usuario.Nome),
            new Claim(ClaimTypes.Email, usuario.Email)
        };
        var identity = new ClaimsIdentity(claims, CookieAuthenticationDefaults.AuthenticationScheme);
        await HttpContext.SignInAsync(
            CookieAuthenticationDefaults.AuthenticationScheme,
            new ClaimsPrincipal(identity));

        TempData["MensagemSucesso"] = "Informações atualizadas com sucesso!";
        return RedirectToPage();
    }

    private async Task<Usuario?> ObterUsuarioAtualAsync()
    {
        var idUsuario = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (!int.TryParse(idUsuario, out var id))
        {
            return null;
        }

        return await _context.Usuarios.SingleOrDefaultAsync(usuario => usuario.Id == id);
    }
}

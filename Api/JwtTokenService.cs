using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Microsoft.IdentityModel.Tokens;
using Xsports.Models;

namespace Xsports;

public sealed class JwtTokenService(
    SymmetricSecurityKey signingKey,
    string issuer,
    string audience)
{
    private static readonly TimeSpan TokenLifetime = TimeSpan.FromMinutes(60);

    public AuthToken Create(Usuario usuario)
    {
        var expiresAt = DateTime.UtcNow.Add(TokenLifetime);
        var claims = new[]
        {
            new Claim(JwtRegisteredClaimNames.Sub, usuario.Id.ToString()),
            new Claim(JwtRegisteredClaimNames.Name, usuario.Nome),
            new Claim(JwtRegisteredClaimNames.Email, usuario.Email),
            new Claim(ClaimTypes.NameIdentifier, usuario.Id.ToString()),
            new Claim(ClaimTypes.Name, usuario.Nome),
            new Claim(ClaimTypes.Email, usuario.Email)
        };
        var token = new JwtSecurityToken(
            issuer,
            audience,
            claims,
            expires: expiresAt,
            signingCredentials: new SigningCredentials(
                signingKey, SecurityAlgorithms.HmacSha256));

        return new AuthToken(
            new JwtSecurityTokenHandler().WriteToken(token),
            "Bearer",
            expiresAt,
            usuario.Nome,
            usuario.Email);
    }
}

public sealed record AuthToken(
    string AccessToken,
    string TokenType,
    DateTime ExpiresAt,
    string Nome,
    string Email);

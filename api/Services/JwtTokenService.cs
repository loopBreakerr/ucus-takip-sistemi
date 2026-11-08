using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using Microsoft.IdentityModel.JsonWebTokens;
using Microsoft.IdentityModel.Tokens;
using UcusTakip.Data.Entities;

namespace UcusTakip.Api.Services;

/// <summary>JWT ayarları. Jwt:Key User Secrets'tan gelir; yoksa kimlik doğrulama devre dışı kalır.</summary>
public class JwtSettings
{
    public const int MinKeyBytes = 32;

    public string Issuer { get; init; } = "UcusTakip.Api";
    public string Audience { get; init; } = "UcusTakip";
    public TimeSpan Lifetime { get; init; } = TimeSpan.FromHours(8);

    /// <summary>Anahtar tanımlı değilse bu rastgele bir geçici anahtardır; hiçbir token üretilmez.</summary>
    public SymmetricSecurityKey SigningKey { get; init; } = new(RandomNumberGenerator.GetBytes(MinKeyBytes));

    public bool IsConfigured { get; init; }

    public static JwtSettings FromConfiguration(IConfiguration config, ILogger logger)
    {
        var key = config["Jwt:Key"];
        var issuer = config["Jwt:Issuer"];
        var audience = config["Jwt:Audience"];

        if (string.IsNullOrWhiteSpace(key))
        {
            logger.LogWarning("Jwt:Key tanımlı değil; kimlik doğrulama devre dışı (api/auth/* 503 döner). Arama endpoint'i çalışmaya devam eder.");
            return new JwtSettings();
        }

        var keyBytes = Encoding.UTF8.GetBytes(key);
        if (keyBytes.Length < MinKeyBytes)
        {
            logger.LogWarning("Jwt:Key en az {Min} bayt olmalı; kimlik doğrulama devre dışı.", MinKeyBytes);
            return new JwtSettings();
        }

        return new JwtSettings
        {
            Issuer = string.IsNullOrWhiteSpace(issuer) ? "UcusTakip.Api" : issuer,
            Audience = string.IsNullOrWhiteSpace(audience) ? "UcusTakip" : audience,
            SigningKey = new SymmetricSecurityKey(keyBytes),
            IsConfigured = true
        };
    }
}

public class JwtTokenService(JwtSettings settings)
{
    public (string Token, DateTime ExpiresAt) CreateToken(ApplicationUser user, IEnumerable<string> roles)
    {
        var expiresAt = DateTime.UtcNow.Add(settings.Lifetime);

        var claims = new List<Claim>
        {
            new("sub", user.Id.ToString()),
            new("email", user.Email ?? string.Empty),
            new("jti", Guid.NewGuid().ToString())
        };
        claims.AddRange(roles.Select(r => new Claim("role", r)));

        var descriptor = new SecurityTokenDescriptor
        {
            Subject = new ClaimsIdentity(claims),
            Issuer = settings.Issuer,
            Audience = settings.Audience,
            Expires = expiresAt,
            SigningCredentials = new SigningCredentials(settings.SigningKey, SecurityAlgorithms.HmacSha256)
        };

        return (new JsonWebTokenHandler().CreateToken(descriptor), expiresAt);
    }
}

using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using UcusTakip.Api.Services;
using UcusTakip.Data;
using UcusTakip.Data.Entities;

namespace UcusTakip.Api.Controllers;

public record AuthRequest(string? Email, string? Password);

[ApiController]
[Route("api/auth")]
public class AuthController(
    UserManager<ApplicationUser> userManager,
    RoleManager<IdentityRole<int>> roleManager,
    JwtTokenService tokenService) : ControllerBase
{
    [HttpPost("register")]
    public async Task<IActionResult> Register([FromBody] AuthRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Email) || string.IsNullOrEmpty(request.Password))
            return BadRequest(new { error = "E-posta ve parola zorunludur." });

        var email = request.Email.Trim();
        var user = new ApplicationUser { UserName = email, Email = email };

        var result = await userManager.CreateAsync(user, request.Password);
        if (!result.Succeeded)
            return BadRequest(new { error = string.Join(" ", result.Errors.Select(e => e.Description).Distinct()) });

        // Roller başlangıçta oluşturulur; veritabanı o an yoksa burada tamamla.
        if (!await roleManager.RoleExistsAsync(IdentitySetup.UserRole))
            await roleManager.CreateAsync(new IdentityRole<int>(IdentitySetup.UserRole));

        var roleResult = await userManager.AddToRoleAsync(user, IdentitySetup.UserRole);
        if (!roleResult.Succeeded)
        {
            await userManager.DeleteAsync(user);
            return StatusCode(StatusCodes.Status500InternalServerError, new { error = "Kayıt tamamlanamadı, lütfen tekrar deneyin." });
        }

        return StatusCode(StatusCodes.Status201Created, new { email = user.Email });
    }

    [HttpPost("login")]
    public async Task<IActionResult> Login([FromBody] AuthRequest request)
    {
        const string invalid = "E-posta veya parola hatalı.";

        if (string.IsNullOrWhiteSpace(request.Email) || string.IsNullOrEmpty(request.Password))
            return Unauthorized(new { error = invalid });

        var user = await userManager.FindByEmailAsync(request.Email.Trim());
        if (user is null || !await userManager.CheckPasswordAsync(user, request.Password))
            return Unauthorized(new { error = invalid });

        var roles = await userManager.GetRolesAsync(user);
        var (token, expiresAt) = tokenService.CreateToken(user, roles);

        return Ok(new { token, email = user.Email, roles, expiresAt });
    }

    [HttpGet("me")]
    [Authorize]
    public IActionResult Me()
    {
        var email = User.FindFirst("email")?.Value;
        var roles = User.FindAll("role").Select(c => c.Value).ToArray();
        return Ok(new { email, roles });
    }
}

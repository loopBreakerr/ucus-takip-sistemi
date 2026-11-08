using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using UcusTakip.Data;
using UcusTakip.Data.Entities;
using UcusTakip.Web.Models;

namespace UcusTakip.Web.Controllers;

public class AccountController(
    UserManager<ApplicationUser> userManager,
    SignInManager<ApplicationUser> signInManager,
    RoleManager<IdentityRole<int>> roleManager,
    ILogger<AccountController> logger) : Controller
{
    private const string DbError = "Veritabanına ulaşılamıyor, lütfen daha sonra tekrar deneyin.";

    [HttpGet]
    public IActionResult Register() => User.Identity?.IsAuthenticated == true ? RedirectToAction("Index", "Home") : View();

    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> Register(RegisterViewModel model)
    {
        if (!ModelState.IsValid) return View(model);

        try
        {
            var email = model.Email.Trim();
            var user = new ApplicationUser { UserName = email, Email = email };
            var result = await userManager.CreateAsync(user, model.Password);
            if (!result.Succeeded)
            {
                foreach (var error in result.Errors.DistinctBy(e => e.Description))
                    ModelState.AddModelError(string.Empty, error.Description);
                return View(model);
            }

            // Roller API başlangıcında oluşur; henüz yoksa burada tamamla.
            if (!await roleManager.RoleExistsAsync(IdentitySetup.UserRole))
                await roleManager.CreateAsync(new IdentityRole<int>(IdentitySetup.UserRole));

            var roleResult = await userManager.AddToRoleAsync(user, IdentitySetup.UserRole);
            if (!roleResult.Succeeded)
            {
                await userManager.DeleteAsync(user);
                ModelState.AddModelError(string.Empty, "Kayıt tamamlanamadı, lütfen tekrar deneyin.");
                return View(model);
            }

            await signInManager.SignInAsync(user, isPersistent: false);
            return RedirectToAction("Index", "Home");
        }
        catch (Exception ex) when (ex is not OperationCanceledException)
        {
            logger.LogWarning(ex, "Kayıt sırasında veritabanı hatası.");
            ModelState.AddModelError(string.Empty, DbError);
            return View(model);
        }
    }

    [HttpGet]
    public IActionResult Login(string? returnUrl = null)
    {
        if (User.Identity?.IsAuthenticated == true) return RedirectToAction("Index", "Home");
        ViewData["ReturnUrl"] = returnUrl;
        return View();
    }

    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> Login(LoginViewModel model, string? returnUrl = null)
    {
        ViewData["ReturnUrl"] = returnUrl;
        if (!ModelState.IsValid) return View(model);

        try
        {
            var user = await userManager.FindByEmailAsync(model.Email.Trim());
            if (user is not null)
            {
                var result = await signInManager.PasswordSignInAsync(user, model.Password, model.RememberMe, lockoutOnFailure: true);
                if (result.Succeeded)
                {
                    return !string.IsNullOrEmpty(returnUrl) && Url.IsLocalUrl(returnUrl)
                        ? LocalRedirect(returnUrl)
                        : RedirectToAction("Index", "Home");
                }

                if (result.IsLockedOut)
                {
                    ModelState.AddModelError(string.Empty, "Çok fazla hatalı deneme. Hesap geçici olarak kilitlendi, daha sonra tekrar deneyin.");
                    return View(model);
                }
            }

            ModelState.AddModelError(string.Empty, "E-posta veya parola hatalı.");
            return View(model);
        }
        catch (Exception ex) when (ex is not OperationCanceledException)
        {
            logger.LogWarning(ex, "Giriş sırasında veritabanı hatası.");
            ModelState.AddModelError(string.Empty, DbError);
            return View(model);
        }
    }

    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> Logout()
    {
        await signInManager.SignOutAsync();
        return RedirectToAction("Index", "Home");
    }

    [HttpGet]
    public IActionResult AccessDenied() => View();
}

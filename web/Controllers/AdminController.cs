using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using UcusTakip.Data;
using UcusTakip.Web.Models;

namespace UcusTakip.Web.Controllers;

[Authorize(Roles = "Admin")]
public class AdminController(AppDbContext db, ILogger<AdminController> logger) : Controller
{
    [HttpGet]
    public async Task<IActionResult> Users()
    {
        try
        {
            var users = await db.Users.AsNoTracking().OrderBy(u => u.Id).ToListAsync();
            var roleMap = await (from ur in db.UserRoles
                                 join r in db.Roles on ur.RoleId equals r.Id
                                 select new { ur.UserId, RoleName = r.Name })
                .ToListAsync();

            var rows = users.Select(u => new AdminUserRow
            {
                Id = u.Id,
                Email = u.Email ?? string.Empty,
                Roles = string.Join(", ", roleMap.Where(x => x.UserId == u.Id).Select(x => x.RoleName).Order())
            }).ToList();

            return View(rows);
        }
        catch (Exception ex) when (ex is not OperationCanceledException)
        {
            logger.LogWarning(ex, "Kullanıcı listesi alınamadı.");
            ViewData["Error"] = "Veritabanına ulaşılamıyor, kullanıcı listesi alınamadı.";
            return View(new List<AdminUserRow>());
        }
    }
}

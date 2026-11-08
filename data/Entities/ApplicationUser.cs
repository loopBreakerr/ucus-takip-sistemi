using Microsoft.AspNetCore.Identity;

namespace UcusTakip.Data.Entities;

/// <summary>
/// Uygulama kullanıcısı. DBML'deki Users tablosunun yerini alır;
/// email, password_hash ve role alanlarını Identity karşılar.
/// </summary>
public class ApplicationUser : IdentityUser<int>
{
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public ICollection<UserFlight> UserFlights { get; set; } = new List<UserFlight>();
    public ICollection<PriceAlert> PriceAlerts { get; set; } = new List<PriceAlert>();
    public ICollection<Notification> Notifications { get; set; } = new List<Notification>();
}

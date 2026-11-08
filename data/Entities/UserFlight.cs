namespace UcusTakip.Data.Entities;

/// <summary>Kullanıcının takip ettiği uçuş (birleşik anahtar: UserId + FlightId).</summary>
public class UserFlight
{
    public int UserId { get; set; }
    public ApplicationUser User { get; set; } = null!;

    public int FlightId { get; set; }
    public Flight Flight { get; set; } = null!;

    public DateTime AddedAt { get; set; } = DateTime.UtcNow;
}

namespace UcusTakip.Data.Entities;

public class Notification
{
    public int Id { get; set; }

    public int UserId { get; set; }
    public ApplicationUser User { get; set; } = null!;

    /// <summary>Hangi alarmdan geldi.</summary>
    public int? AlertId { get; set; }
    public PriceAlert? Alert { get; set; }

    public string Message { get; set; } = string.Empty;

    public bool IsRead { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}

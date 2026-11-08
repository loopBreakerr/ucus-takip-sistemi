namespace UcusTakip.Data.Entities;

public class PriceAlert
{
    public int Id { get; set; }

    public int UserId { get; set; }
    public ApplicationUser User { get; set; } = null!;

    public string Origin { get; set; } = string.Empty;

    public string Destination { get; set; } = string.Empty;

    public DateOnly TravelDate { get; set; }

    public decimal TargetPrice { get; set; }

    public string? Currency { get; set; }

    public bool IsActive { get; set; } = true;

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public ICollection<Notification> Notifications { get; set; } = new List<Notification>();
}

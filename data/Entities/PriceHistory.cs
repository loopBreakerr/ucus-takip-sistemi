namespace UcusTakip.Data.Entities;

public class PriceHistory
{
    public int Id { get; set; }

    public string Origin { get; set; } = string.Empty;

    public string Destination { get; set; } = string.Empty;

    public DateOnly TravelDate { get; set; }

    public decimal Price { get; set; }

    public string? Currency { get; set; }

    /// <summary>Simüle fiyat mı?</summary>
    public bool IsSimulated { get; set; }

    public DateTime CheckedAt { get; set; } = DateTime.UtcNow;
}

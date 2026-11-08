namespace UcusTakip.Data.Entities;

public class Flight
{
    public int Id { get; set; }

    /// <summary>Ör. TK 1.</summary>
    public string FlightNumber { get; set; } = string.Empty;

    public DateOnly FlightDate { get; set; }

    public string Origin { get; set; } = string.Empty;

    public string Destination { get; set; } = string.Empty;

    /// <summary>Eşleşme yoksa boş.</summary>
    public int? AircraftId { get; set; }
    public Aircraft? Aircraft { get; set; }

    public ICollection<UserFlight> UserFlights { get; set; } = new List<UserFlight>();
}

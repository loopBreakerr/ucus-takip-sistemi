namespace UcusTakip.Data.Entities;

public class Aircraft
{
    public int Id { get; set; }

    /// <summary>ADSB.lol uçak kimliği.</summary>
    public string? IcaoHex { get; set; }

    /// <summary>Çağrı kodu, ör. THY1.</summary>
    public string? Callsign { get; set; }

    public ICollection<Flight> Flights { get; set; } = new List<Flight>();
}

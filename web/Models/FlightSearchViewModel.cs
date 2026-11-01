namespace UcusTakip.Web.Models;

public class FlightSearchViewModel
{
    public string? From { get; set; }
    public string? To { get; set; }
    public DateOnly? Date { get; set; }

    // Arama yapıldıysa true; sonuç ve hata alanları yalnızca o zaman anlamlıdır.
    public bool Searched { get; set; }
    public FlightApiResponse? Result { get; set; }
    public string? ErrorMessage { get; set; }
    public bool ServiceUnavailable { get; set; }
}

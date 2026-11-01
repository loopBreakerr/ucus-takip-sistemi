namespace UcusTakip.Web.Models;

// API'nin GET api/flights/search cevabı (camelCase JSON, System.Text.Json ile okunur).
public record FlightApiResponse(
    string From,
    string To,
    DateOnly Date,
    string Source,
    List<FlightOfferDto> Flights);

public record FlightOfferDto(
    string FlightNumber,
    string Airline,
    DateTime DepartureTime,
    DateTime ArrivalTime,
    int DurationMinutes,
    decimal Price,
    string Currency,
    bool IsSimulated);

// API'nin 400 cevabı: { "error": "..." }
public record FlightApiError(string? Error);

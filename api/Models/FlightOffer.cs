namespace UcusTakip.Api.Models;

public record FlightOffer(
    string FlightNumber,
    string Airline,
    DateTime DepartureTime,
    DateTime ArrivalTime,
    int DurationMinutes,
    decimal Price,
    string Currency,
    bool IsSimulated);

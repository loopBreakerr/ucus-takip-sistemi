namespace UcusTakip.Api.Models;

public record FlightSearchResponse(
    string From,
    string To,
    DateOnly Date,
    string Source,
    IReadOnlyList<FlightOffer> Flights);

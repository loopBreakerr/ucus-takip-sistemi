using UcusTakip.Api.Models;

namespace UcusTakip.Api.Services;

public interface IFlightPriceProvider
{
    Task<IReadOnlyList<FlightOffer>> SearchAsync(string from, string to, DateOnly date);
}

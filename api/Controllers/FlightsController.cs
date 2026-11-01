using System.Globalization;
using Microsoft.AspNetCore.Mvc;
using UcusTakip.Api.Models;
using UcusTakip.Api.Services;

namespace UcusTakip.Api.Controllers;

[ApiController]
[Route("api/flights")]
public class FlightsController(IFlightPriceProvider priceProvider) : ControllerBase
{
    [HttpGet("search")]
    public async Task<IActionResult> Search(
        [FromQuery] string? from, [FromQuery] string? to, [FromQuery] string? date)
    {
        var origin = NormalizeAirportCode(from);
        var destination = NormalizeAirportCode(to);

        if (origin is null)
            return BadRequest(new { error = "'from' parametresi tam 3 harfli bir havalimanı kodu olmalıdır (örn. IST)." });
        if (destination is null)
            return BadRequest(new { error = "'to' parametresi tam 3 harfli bir havalimanı kodu olmalıdır (örn. FCO)." });
        if (origin == destination)
            return BadRequest(new { error = "Kalkış ve varış havalimanı aynı olamaz." });

        if (!DateOnly.TryParseExact(date, "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, out var flightDate))
            return BadRequest(new { error = "'date' parametresi yyyy-MM-dd biçiminde geçerli bir tarih olmalıdır (örn. 2026-12-15)." });
        if (flightDate < DateOnly.FromDateTime(DateTime.Today))
            return BadRequest(new { error = "Geçmiş bir tarih için uçuş aranamaz." });

        var flights = await priceProvider.SearchAsync(origin, destination, flightDate);

        return Ok(new FlightSearchResponse(origin, destination, flightDate, "simulated", flights));
    }

    private static string? NormalizeAirportCode(string? code)
    {
        var trimmed = code?.Trim();
        return trimmed is { Length: 3 } && trimmed.All(char.IsAsciiLetter)
            ? trimmed.ToUpperInvariant()
            : null;
    }
}

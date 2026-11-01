using System.Net;
using System.Text.Json;
using UcusTakip.Web.Models;

namespace UcusTakip.Web.Services;

public record FlightSearchOutcome(FlightApiResponse? Response, string? Error, bool ServiceUnavailable);

public class FlightApiClient(HttpClient http, ILogger<FlightApiClient> logger)
{
    private const string ServiceDownMessage =
        "Servise ulaşılamadı. Lütfen API'nin çalıştığından emin olup tekrar deneyin.";

    public async Task<FlightSearchOutcome> SearchAsync(
        string from, string to, DateOnly date, CancellationToken cancellationToken = default)
    {
        var url = $"api/flights/search?from={Uri.EscapeDataString(from)}&to={Uri.EscapeDataString(to)}" +
                  $"&date={date:yyyy-MM-dd}";

        try
        {
            using var response = await http.GetAsync(url, cancellationToken);

            if (response.IsSuccessStatusCode)
            {
                var result = await response.Content.ReadFromJsonAsync<FlightApiResponse>(cancellationToken);
                return result is null
                    ? new FlightSearchOutcome(null, "Servisten boş bir cevap alındı.", true)
                    : new FlightSearchOutcome(result, null, false);
            }

            if (response.StatusCode == HttpStatusCode.BadRequest)
            {
                var error = await response.Content.ReadFromJsonAsync<FlightApiError>(cancellationToken);
                return new FlightSearchOutcome(null, error?.Error ?? "Arama bilgileri geçersiz.", false);
            }

            logger.LogWarning("Uçuş API'si beklenmeyen durum kodu döndürdü: {StatusCode}", (int)response.StatusCode);
            return new FlightSearchOutcome(
                null, $"Servis beklenmeyen bir cevap verdi (HTTP {(int)response.StatusCode}).", true);
        }
        catch (Exception ex) when (ex is HttpRequestException or TaskCanceledException or JsonException)
        {
            if (cancellationToken.IsCancellationRequested)
                throw;

            logger.LogWarning(ex, "Uçuş API'sine ulaşılamadı.");
            return new FlightSearchOutcome(null, ServiceDownMessage, true);
        }
    }
}

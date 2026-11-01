using UcusTakip.Api.Models;

namespace UcusTakip.Api.Services;

// Gerçek bir API çağrısı yapmaz; aynı (from, to, date) ve aynı gün için hep aynı sahte veriyi üretir.
public class SimulatedPriceProvider : IFlightPriceProvider
{
    private const int MinDuration = 90;
    private const int MaxDuration = 600;
    private const int EarlyBookingDays = 30;

    private static readonly (string Name, string Code)[] Airlines =
    [
        ("Turkish Airlines", "TK"),
        ("Pegasus", "PC"),
        ("AJet", "VF"),
        ("Lufthansa", "LH"),
        ("SunExpress", "XQ"),
    ];

    // Anahtar: iki havalimanı kodu alfabetik sıralı. Değer: (taban fiyat USD, süre dk).
    private static readonly Dictionary<string, (decimal Price, int Duration)> KnownRoutes = new()
    {
        ["ADB-IST"] = (75, 90),
        ["AMS-IST"] = (250, 230),
        ["AYT-IST"] = (80, 90),
        ["BER-IST"] = (220, 205),
        ["CDG-IST"] = (230, 235),
        ["DXB-IST"] = (330, 270),
        ["ESB-IST"] = (70, 90),
        ["FCO-IST"] = (240, 170),
        ["FRA-IST"] = (240, 200),
        ["IST-JFK"] = (680, 600),
        ["IST-LHR"] = (260, 240),
    };

    public Task<IReadOnlyList<FlightOffer>> SearchAsync(string from, string to, DateOnly date)
    {
        var today = DateOnly.FromDateTime(DateTime.Today);
        var routeKey = string.CompareOrdinal(from, to) <= 0 ? $"{from}-{to}" : $"{to}-{from}";

        var (basePrice, baseDuration) = GetRouteBase(routeKey);
        var rng = new Random(StableHash($"{from}|{to}|{date:yyyy-MM-dd}|{today.DayNumber}"));

        var daysLeft = date.DayNumber - today.DayNumber;
        var urgency = daysLeft < EarlyBookingDays
            ? 1.0 + (EarlyBookingDays - Math.Max(daysLeft, 0)) * 0.015
            : 1.0;

        var count = rng.Next(4, 7);
        var slot = 960 / count; // 06:00 - 22:00 arası eşit dilimler
        var usedNumbers = new HashSet<string>();
        var offers = new List<FlightOffer>(count);

        for (var i = 0; i < count; i++)
        {
            var minuteOfDay = 360 + i * slot + rng.Next(0, slot) / 5 * 5;
            var departure = date.ToDateTime(TimeOnly.MinValue).AddMinutes(minuteOfDay);

            var duration = Math.Clamp(baseDuration + rng.Next(-10, 11), MinDuration, MaxDuration);
            var arrival = departure.AddMinutes(duration);

            var fluctuation = 1.0 + (rng.NextDouble() * 0.30 - 0.15);
            var price = Math.Round(basePrice * (decimal)(fluctuation * urgency), 0);

            var airline = Airlines[rng.Next(Airlines.Length)];
            string flightNumber;
            do
            {
                flightNumber = $"{airline.Code} {rng.Next(1000, 10000)}";
            } while (!usedNumbers.Add(flightNumber));

            offers.Add(new FlightOffer(
                flightNumber, airline.Name, departure, arrival,
                duration, price, "USD", IsSimulated: true));
        }

        return Task.FromResult<IReadOnlyList<FlightOffer>>(offers);
    }

    // Bilinen rotalar sabit tablodan gelir; diğerleri yalnızca rota koduna bağlı sabit bir değer alır.
    private static (decimal Price, int Duration) GetRouteBase(string routeKey)
    {
        if (KnownRoutes.TryGetValue(routeKey, out var known))
            return known;

        var routeRng = new Random(StableHash(routeKey));
        return (routeRng.Next(150, 401), routeRng.Next(MinDuration, MaxDuration + 1));
    }

    // string.GetHashCode() çalıştırmalar arasında değişir; FNV-1a (32 bit) her zaman aynı sonucu verir.
    private static int StableHash(string text)
    {
        var hash = 2166136261u;
        foreach (var ch in text)
        {
            hash ^= ch;
            hash *= 16777619u;
        }
        return unchecked((int)hash);
    }
}

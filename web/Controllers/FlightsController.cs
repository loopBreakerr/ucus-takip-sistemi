using Microsoft.AspNetCore.Mvc;
using UcusTakip.Web.Models;
using UcusTakip.Web.Services;

namespace UcusTakip.Web.Controllers;

public class FlightsController(FlightApiClient apiClient) : Controller
{
    // GET /Flights                          → boş form (tarih varsayılan: yarın)
    // GET /Flights?From=IST&To=FCO&Date=... → form + sonuç
    public async Task<IActionResult> Index(FlightSearchViewModel model, CancellationToken cancellationToken)
    {
        if (!Request.Query.Any())
        {
            model.Date = DateOnly.FromDateTime(DateTime.Today.AddDays(1));
            return View(model);
        }

        model.Searched = true;

        if (model.Date is null)
        {
            model.ErrorMessage = "Lütfen geçerli bir tarih seçin.";
            return View(model);
        }

        var outcome = await apiClient.SearchAsync(
            model.From?.Trim() ?? "", model.To?.Trim() ?? "", model.Date.Value, cancellationToken);

        model.Result = outcome.Response;
        model.ErrorMessage = outcome.Error;
        model.ServiceUnavailable = outcome.ServiceUnavailable;

        if (outcome.Response is not null)
        {
            // API büyük harfe çevirdiği kodları forma da öyle yansıt.
            model.From = outcome.Response.From;
            model.To = outcome.Response.To;
        }

        return View(model);
    }
}

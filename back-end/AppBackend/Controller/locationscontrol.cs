using System.Globalization;
using System.Text.Json;
using Microsoft.AspNetCore.Mvc;

namespace AppBackend.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class LocationsController : ControllerBase
    {
        // Shared across requests so the connection pool is reused.
        private static readonly HttpClient Http = new()
        {
            Timeout = TimeSpan.FromSeconds(10),
        };

        // GET: api/locations/reverse?latitude=14.548783&longitude=121.057449
        // Turns GPS coordinates into a readable address for the report form.
        [HttpGet("reverse")]
        public async Task<IActionResult> Reverse(
            [FromQuery] double latitude,
            [FromQuery] double longitude)
        {
            if (latitude is < -90 or > 90 || longitude is < -180 or > 180)
            {
                return BadRequest(
                    "Latitude must be between -90 and 90 and longitude between -180 and 180.");
            }

            var url =
                "https://nominatim.openstreetmap.org/reverse" +
                "?format=jsonv2&zoom=18&addressdetails=1&accept-language=en" +
                $"&lat={latitude.ToString(CultureInfo.InvariantCulture)}" +
                $"&lon={longitude.ToString(CultureInfo.InvariantCulture)}";

            try
            {
                using var request = new HttpRequestMessage(HttpMethod.Get, url);
                // Nominatim rejects anonymous clients, so identify the app.
                request.Headers.UserAgent.ParseAdd("SnapFix/1.0");
                request.Headers.Accept.ParseAdd("application/json");

                using var response = await Http.SendAsync(request);
                if (!response.IsSuccessStatusCode)
                {
                    return StatusCode(502, new { error = "Location lookup failed." });
                }

                var json = await response.Content.ReadAsStringAsync();
                using var document = JsonDocument.Parse(json);
                var root = document.RootElement;

                var displayName = root.TryGetProperty("display_name", out var name)
                    ? name.GetString()
                    : null;

                return Ok(new
                {
                    name = BuildShortName(root),
                    displayName,
                });
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Geocode error: {ex.Message}");
                return StatusCode(502, new { error = "Location lookup failed." });
            }
        }

        // Prefers the parts a resident recognises: road, barangay/suburb, city.
        private static string? BuildShortName(JsonElement root)
        {
            if (!root.TryGetProperty("address", out var address))
            {
                return null;
            }

            string? Get(string key) =>
                address.TryGetProperty(key, out var value) ? value.GetString() : null;

            var parts = new[]
            {
                Get("road"),
                Get("neighbourhood") ?? Get("suburb") ?? Get("quarter"),
                Get("village") ?? Get("town") ?? Get("city") ?? Get("municipality"),
                Get("state") ?? Get("province"),
            };

            var cleaned = parts
                .Where(part => !string.IsNullOrWhiteSpace(part))
                .Select(part => part!.Trim())
                .Distinct()
                .ToArray();

            return cleaned.Length == 0 ? null : string.Join(", ", cleaned);
        }
    }
}

using Microsoft.AspNetCore.Mvc;
using System.Collections.Generic;
using System.Linq;

[ApiController]
[Route("api/[controller]")]
public class TicketsController : ControllerBase
{
    // GET: api/tickets
    // Handles fetching the list and applying filters from the UI
    [HttpGet]
    public IActionResult GetTickets(
        [FromQuery] string? search, 
        [FromQuery] string? status, 
        [FromQuery] string? priority)
    {
        // 1. Mock database table (matches the image data)
        var tickets = new List<Ticket>
        {
            new Ticket { Id = "SF-1024", Title = "Road Damage", Location = "BGC, Taguig", Priority = "High", Status = "Pending", DateSubmitted = new DateTime(2026, 10, 24), Description = "" },
            new Ticket { Id = "SF-1025", Title = "Broken Streetlight", Location = "Makati City", Priority = "Medium", Status = "In Progress", DateSubmitted = new DateTime(2026, 10, 24), Description = "" },
            new Ticket { Id = "SF-1026", Title = "Garbage Collection", Location = "Pasig City", Priority = "Low", Status = "Pending", DateSubmitted = new DateTime(2026, 10, 25), Description = "" }
        };

        var query = tickets.AsQueryable();

        // 2. Apply filters if they are provided by the front-end
        if (!string.IsNullOrEmpty(status) && status != "All Statuses")
        {
            query = query.Where(t => t.Status == status);
        }

        if (!string.IsNullOrEmpty(priority) && priority != "All Priorities")
        {
            query = query.Where(t => t.Priority == priority);
        }

        if (!string.IsNullOrEmpty(search))
        {
            // Search by Ticket ID or Issue (Title)
            query = query.Where(t => 
                t.Id.Contains(search, StringComparison.OrdinalIgnoreCase) || 
                t.Title.Contains(search, StringComparison.OrdinalIgnoreCase));
        }

        // 3. Return the filtered list to populate the table
        return Ok(query.ToList());
    }
}
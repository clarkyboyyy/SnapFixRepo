
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using AppBackend.Model;
using AppBackend.Data;

namespace AppBackend.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class TicketsController : ControllerBase
    {
        private readonly AppDbContext _context;

        public TicketsController(AppDbContext context)
        {
            _context = context;
        }

        // GET: api/tickets
        [HttpGet]
        public async Task<IActionResult> GetAllTickets()
        {
            var tickets = await _context.Tickets
                .OrderByDescending(ticket => ticket.DateSubmitted)
                .ToListAsync();
            return Ok(tickets);
        }

        // GET: api/tickets/SF-1793252633763
        [HttpGet("{id}")]
        public async Task<IActionResult> GetTicket(string id)
        {
            var ticket = await _context.Tickets.FindAsync(id);
            return ticket == null ? NotFound() : Ok(ticket);
        }

        // POST: api/tickets
        [HttpPost]
        public async Task<IActionResult> CreateTicket([FromBody] Ticket newTicket)
        {
            try
            {
                if (newTicket == null)
                {
                    return BadRequest("Invalid ticket data.");
                }

                newTicket.Status = NormalizeStatus(newTicket.Status);
                newTicket.Progress = newTicket.Status == TicketStatus.Resolved
                    ? 100
                    : Math.Clamp(newTicket.Progress, 0, 100);

                _context.Tickets.Add(newTicket);
                await _context.SaveChangesAsync();

                return Ok(newTicket);
            }
            catch (Exception ex)
            {
                var error = ex.InnerException?.Message ?? ex.Message;
                Console.WriteLine($"DB Error: {error}");

                return StatusCode(500, error);
            }
        }

        // PUT: api/tickets/SF-1793252633763
        // The admin dashboard calls this whenever it saves a review, so the
        // same row the mobile app reads is the one that changes.
        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateTicket(
            string id,
            [FromBody] UpdateTicketRequest request)
        {
            var ticket = await _context.Tickets.FindAsync(id);
            if (ticket == null)
            {
                return NotFound(new { error = $"Ticket {id} was not found." });
            }

            var previousStatus = ticket.Status;
            var previousProgress = ticket.Progress;
            var previousDepartment = ticket.AssignedDepartment;

            var status = NormalizeStatus(request.Status ?? ticket.Status);
            var progress = Math.Clamp(request.Progress ?? ticket.Progress, 0, 100);
            if (status == TicketStatus.Resolved)
            {
                progress = 100;
            }

            ticket.Status = status;
            ticket.Progress = progress;

            if (request.Priority != null)
            {
                ticket.Priority = request.Priority;
            }

            if (request.AssignedDepartment != null)
            {
                ticket.AssignedDepartment = request.AssignedDepartment;
            }

            if (request.AdminNotes != null)
            {
                ticket.AdminNotes = request.AdminNotes;
            }

            var note = request.Note?.Trim();
            var changed =
                previousStatus != ticket.Status ||
                previousProgress != ticket.Progress ||
                previousDepartment != ticket.AssignedDepartment;

            if (changed || !string.IsNullOrEmpty(note))
            {
                _context.TicketUpdates.Add(new TicketUpdate
                {
                    TicketId = id,
                    Status = ticket.Status,
                    Progress = ticket.Progress,
                    Note = string.IsNullOrEmpty(note) ? null : note,
                    CreatedAt = DateTime.UtcNow,
                });
            }

            await _context.SaveChangesAsync();
            return Ok(ticket);
        }

        // GET: api/tickets/SF-1793252633763/updates
        [HttpGet("{id}/updates")]
        public async Task<IActionResult> GetUpdates(string id)
        {
            var updates = await _context.TicketUpdates
                .Where(update => update.TicketId == id)
                .OrderByDescending(update => update.CreatedAt)
                .ToListAsync();

            return Ok(updates);
        }

        private static string NormalizeStatus(string? value)
        {
            return TicketStatus.Normalize(value);
        }
    }
}

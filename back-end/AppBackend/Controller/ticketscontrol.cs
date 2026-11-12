
using Microsoft.AspNetCore.Mvc;
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
        public IActionResult GetAllTickets()
        {
            var tickets = _context.Tickets.ToList();
            return Ok(tickets);
        }

        // POST: api/tickets
        [HttpPost]
        public IActionResult CreateTicket([FromBody] Ticket newTicket)
        {
            try
            {
                if (newTicket == null)
                {
                    return BadRequest("Invalid ticket data.");
                }

                newTicket.Status = string.IsNullOrEmpty(newTicket.Status)
                    ? "Submitted"
                    : newTicket.Status;

                _context.Tickets.Add(newTicket);
                _context.SaveChanges();

                return Ok(newTicket);
            }
            catch (Exception ex)
            {
                var error = ex.InnerException?.Message ?? ex.Message;
                Console.WriteLine($"DB Error: {error}");

                return StatusCode(500, error);
            }
        }
    }
}

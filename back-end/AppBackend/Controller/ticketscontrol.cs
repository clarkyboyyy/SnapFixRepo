using Microsoft.AspNetCore.Mvc;
using System.Linq;
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

        // GET: api/tickets (Used by your Web Admin HTML to view all tickets)
        [HttpGet]
        public IActionResult GetAllTickets()
        {
            var tickets = _context.Tickets.ToList();
            return Ok(tickets);
        }

        // POST: api/tickets (Used by your Flutter app to submit a new ticket)
        [HttpPost]
        public IActionResult CreateTicket([FromBody] Ticket newTicket)
        {
            _context.Tickets.Add(newTicket);
            _context.SaveChanges();
            
            return CreatedAtAction(nameof(GetAllTickets), new { id = newTicket.Id }, newTicket);
        }
    }
}
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using AppBackend.Data;

[Route("api/messages")]
[ApiController]
public class MessagesController : ControllerBase
{
    private readonly AppDbContext _context;

    public MessagesController(AppDbContext context)
    {
        _context = context;
    }

    // GET: api/messages/SF-1793252633763
    [HttpGet("{ticketId}")]
    public async Task<IActionResult> GetMessages(string ticketId)
    {
        var messages = await _context.Messages
            .Where(message => message.TicketId == ticketId)
            .OrderBy(message => message.DateSent)
            .ToListAsync();

        return Ok(messages);
    }

    // POST: api/messages
    [HttpPost]
    public async Task<IActionResult> SendMessage([FromBody] MessageModel newMessage)
    {
        try
        {
            if (newMessage == null ||
                string.IsNullOrWhiteSpace(newMessage.TicketId) ||
                string.IsNullOrWhiteSpace(newMessage.Message))
            {
                return BadRequest(new { error = "Invalid message payload." });
            }

            var senderType = newMessage.SenderType.Trim().ToLowerInvariant();
            newMessage.Id = 0;
            newMessage.SenderType = senderType == "admin" ? "admin" : "citizen";
            newMessage.Message = newMessage.Message.Trim();
            newMessage.DateSent = DateTime.UtcNow;

            _context.Messages.Add(newMessage);
            await _context.SaveChangesAsync();

            return Ok(newMessage);
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error sending message: {ex.Message}");
            return StatusCode(500, new { error = ex.Message });
        }
    }
}

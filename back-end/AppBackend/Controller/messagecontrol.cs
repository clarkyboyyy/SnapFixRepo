using Microsoft.AspNetCore.Mvc;
using Supabase;

[Route("api/messages")]
[ApiController]
public class MessagesController : ControllerBase
{
    private readonly Supabase.Client _supabase;

    public MessagesController(Supabase.Client supabase)
    {
        _supabase = supabase;
    }

    // GET: api/messages/SF-1793252633763
    [HttpGet("{ticketId}")]
    public async Task<IActionResult> GetMessages(string ticketId)
    {
        try
        {
            var response = await _supabase.From<MessageModel>()
                .Filter("ticket_id", Supabase.Postgrest.Constants.Operator.Equals, ticketId)
                .Get();
                
            return Ok(response.Models);
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error fetching messages: {ex.Message}");
            return StatusCode(500, new { error = ex.Message });
        }
    }

    // POST: api/messages
   [HttpPost]
    public async Task<IActionResult> SendMessage([FromBody] MessageModel newMessage)
    {
        try
        {
            if (newMessage == null || string.IsNullOrWhiteSpace(newMessage.TicketId) || string.IsNullOrWhiteSpace(newMessage.Message))
            {
                return BadRequest(new { error = "Invalid message payload." });
            }

            newMessage.DateSent = DateTime.UtcNow;

            // Use ReturnType.Minimal to prevent mapping errors on return
            var response = await _supabase.From<MessageModel>()
                .Insert(newMessage, new Supabase.Postgrest.QueryOptions { Returning = Supabase.Postgrest.QueryOptions.ReturnType.Minimal });

            return Ok(new { success = true });
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error sending message: {ex.Message}");
            return StatusCode(500, new { error = ex.Message });
        }
    }
}
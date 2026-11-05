using Supabase.Postgrest.Attributes;
using Supabase.Postgrest.Models;

[Table("Messages")]
public class MessageModel : BaseModel
{
    [PrimaryKey("id", false)]
    public int Id { get; set; }

    [Column("ticket_id")]
    public string TicketId { get; set; } = string.Empty;

    [Column("sender_type")]
    public string SenderType { get; set; } = string.Empty;

    [Column("message")]
    public string Message { get; set; } = string.Empty;

    [Column("date_sent")]
    public DateTime DateSent { get; set; } = DateTime.UtcNow;
}
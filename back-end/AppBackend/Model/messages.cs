using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

// Row in the existing `Messages` table. It is excluded from migrations
// because Supabase already owns that table.
[Table("Messages")]
public class MessageModel
{
    [Key]
    [Column("id")]
    [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
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

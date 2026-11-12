using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace AppBackend.Model
{
    // One entry in a ticket's tracking history, written whenever the admin
    // changes status, progress, or adds a progress note.
    [Table("ticket_updates")]
    public class TicketUpdate
    {
        [Key]
        [Column("id")]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int Id { get; set; }

        [Column("ticket_id")]
        public required string TicketId { get; set; }

        [Column("status")]
        public string? Status { get; set; }

        [Column("progress")]
        public int Progress { get; set; }

        [Column("note")]
        public string? Note { get; set; }

        [Column("created_at")]
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}

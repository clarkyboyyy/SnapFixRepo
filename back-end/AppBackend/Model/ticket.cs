using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace AppBackend.Model
{
    [Table("tickets")] // Assumes you name the Supabase table "tickets"
    public class Ticket
    {
        [Key] // Marks this as the Primary Key
        [Column("id")]
        public required string Id { get; set; } // e.g., "SF-1024"

        [Column("title")]
        public required string Title { get; set; } // e.g., "Road Damage"

        [Column("location")]
        public required string Location { get; set; } // e.g., "BGC, Taguig"

        [Column("date_submitted")]
        public DateTime DateSubmitted { get; set; }

        [Column("description")]
        public required string Description { get; set; }

        [Column("photo_url")]
        public string? PhotoUrl { get; set; } // Nullable

        // Editable fields
        [Column("status")]
        public required string Status { get; set; } // e.g., "Pending"

        [Column("priority")]
        public required string Priority { get; set; } // e.g., "High"

        [Column("assigned_department")]
        public string? AssignedDepartment { get; set; }

        [Column("admin_notes")]
        public string? AdminNotes { get; set; }
    }
}
public class Ticket
{
    public required string Id { get; set; } // e.g., "SF-1024"
    public required string Title { get; set; } // e.g., "Road Damage"
    public required string Location { get; set; } // e.g., "BGC, Taguig"
    public DateTime DateSubmitted { get; set; }
    public required string Description { get; set; }
    public string? PhotoUrl { get; set; } // Nullable, as UI shows "No photo attached"
    
    // Editable fields
    public required string Status { get; set; } // e.g., "Pending"
    public required string Priority { get; set; } // e.g., "High"
    public string? AssignedDepartment { get; set; }
    public string? AdminNotes { get; set; }
}
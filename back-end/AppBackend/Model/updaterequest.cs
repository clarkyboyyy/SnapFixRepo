public class UpdateTicketRequest
{
    public string? Status { get; set; }
    public string? Priority { get; set; }
    public string? AssignedDepartment { get; set; }
    public string? AdminNotes { get; set; }
    public int? Progress { get; set; }

    // Optional note describing this update; stored in the tracking history.
    public string? Note { get; set; }
}

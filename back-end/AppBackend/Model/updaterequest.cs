public class UpdateTicketRequest
{
    public required string Status { get; set; }
    public required string Priority { get; set; }
    public string? AssignedDepartment { get; set; }
    public string? AdminNotes { get; set; }
}
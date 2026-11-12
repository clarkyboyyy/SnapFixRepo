namespace AppBackend.Model
{
    // The single status vocabulary shared by the web dashboard, the API, and
    // the Flutter app.
    public static class TicketStatus
    {
        public const string Submitted = "Submitted";
        public const string InProgress = "In Progress";
        public const string Resolved = "Resolved";

        public static string Normalize(string? value)
        {
            var status = (value ?? string.Empty)
                .Trim()
                .ToLowerInvariant()
                .Replace("-", " ")
                .Replace("_", " ");

            return status switch
            {
                "ongoing" or "in progress" or "inprogress" or "assigned"
                    or "working" => InProgress,
                "resolved" or "closed" or "completed" or "done" => Resolved,
                _ => Submitted,
            };
        }
    }
}

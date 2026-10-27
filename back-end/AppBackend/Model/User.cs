using System.ComponentModel.DataAnnotations.Schema;

namespace AppBackend.Model
{
    [Table("Users")] // Ensure this matches exactly how your table is named in Supabase
    public class User
    {
        [Column("id")]
        public int Id { get; set; }

        [Column("email")]
        public string Email { get; set; } = string.Empty;

        [Column("password")]
        public string Password { get; set; } = string.Empty;
    }
}
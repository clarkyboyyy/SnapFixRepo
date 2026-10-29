using System.ComponentModel.DataAnnotations.Schema;

namespace AppBackend.Model
{
    [Table("Users")] 
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
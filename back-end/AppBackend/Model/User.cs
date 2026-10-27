using System.ComponentModel.DataAnnotations.Schema;
namespace AppBackend.Model
{
    [Table("Users")]
    public class User
    {
        public int Id { get; set; } // Primary key for the database
        public string Email { get; set; } = string.Empty;
        public string Password { get; set; } = string.Empty;
        // You can add other fields here later, like 'Name' or 'Role'
    }
}
using Microsoft.EntityFrameworkCore;
using AppBackend.Model; // Ensure this matches your namespace for ticket.cs, etc.

namespace AppBackend.Data
{
    public class AppDbContext : DbContext
    {
        public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

        // List your database tables here. 
        // You will need a User/Account model to handle logins.
        public DbSet<Ticket> Tickets { get; set; } 
        
        // If you haven't created a user.cs model yet, create one in your Model folder
        public DbSet<User> Users { get; set; }
    }
}

using Microsoft.EntityFrameworkCore;
using AppBackend.Model;

namespace AppBackend.Data
{
    public class AppDbContext : DbContext
    {
        public AppDbContext(DbContextOptions<AppDbContext> options)
            : base(options)
        {
        }

        // Existing tables
        public DbSet<Ticket> Tickets { get; set; }

        public DbSet<User> Users { get; set; }

        // New Reports table
        public DbSet<Report> Reports { get; set; }
    }
}

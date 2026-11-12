
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

        public DbSet<Ticket> Tickets { get; set; }

        public DbSet<User> Users { get; set; }

        public DbSet<Report> Reports { get; set; }

        public DbSet<TicketUpdate> TicketUpdates { get; set; }

        public DbSet<MessageModel> Messages { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // The conversation table is created and owned by Supabase.
            modelBuilder.Entity<MessageModel>()
                .ToTable("Messages", table => table.ExcludeFromMigrations());
        }
    }
}

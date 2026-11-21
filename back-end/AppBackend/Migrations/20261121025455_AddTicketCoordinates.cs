using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace AppBackend.Migrations
{
    /// <inheritdoc />
    public partial class AddTicketCoordinates : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // IF NOT EXISTS keeps this safe when the columns were already added
            // by hand in the Supabase SQL editor.
            migrationBuilder.Sql(@"
                ALTER TABLE tickets ADD COLUMN IF NOT EXISTS latitude double precision;
                ALTER TABLE tickets ADD COLUMN IF NOT EXISTS longitude double precision;
            ");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(@"
                ALTER TABLE tickets DROP COLUMN IF EXISTS latitude;
                ALTER TABLE tickets DROP COLUMN IF EXISTS longitude;
            ");
        }
    }
}

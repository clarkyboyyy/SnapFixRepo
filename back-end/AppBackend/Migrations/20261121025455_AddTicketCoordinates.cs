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
            migrationBuilder.AddColumn<double>(
                name: "latitude",
                table: "tickets",
                type: "double precision",
                nullable: true);

            migrationBuilder.AddColumn<double>(
                name: "longitude",
                table: "tickets",
                type: "double precision",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "latitude",
                table: "tickets");

            migrationBuilder.DropColumn(
                name: "longitude",
                table: "tickets");
        }
    }
}

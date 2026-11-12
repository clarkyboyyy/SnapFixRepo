using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace AppBackend.Migrations
{
    /// <inheritdoc />
    public partial class AddTicketOwnerAndProfile : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "category",
                table: "tickets",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "user_email",
                table: "tickets",
                type: "text",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "category",
                table: "tickets");

            migrationBuilder.DropColumn(
                name: "user_email",
                table: "tickets");
        }
    }
}
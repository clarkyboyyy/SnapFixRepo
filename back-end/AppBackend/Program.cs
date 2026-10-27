using AppBackend.Data; // Make sure you have this to find AppDbContext
using Microsoft.EntityFrameworkCore; // Make sure you have this to use SQL Server

var builder = WebApplication.CreateBuilder(args);

// 1. ADDED THIS BLOCK: Connects C# to your SQL Server database
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection")));

builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowLiveServer", policy =>
    {
        policy.WithOrigins("http://127.0.0.1:5500", "http://localhost:5141")
              .AllowAnyHeader()
              .AllowAnyMethod();
    });
});

builder.Services.AddControllers();

builder.Services.AddAuthorization();
var app = builder.Build();

app.UseCors("AllowLiveServer"); 

app.UseAuthorization();
app.MapControllers();
app.Run();
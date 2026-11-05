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

var options = new Supabase.SupabaseOptions
{
    AutoConnectRealtime = true
};

var supabase = new Supabase.Client("https://oymklmxvcftvrinjqryx.supabase.co", "sb_publishable_Dq3xrZuH4APjvmU5EjxEow_JXpo16sa", options);
builder.Services.AddSingleton(supabase);

builder.Services.AddControllers();

builder.Services.AddAuthorization();
var app = builder.Build();

app.UseCors("AllowLiveServer"); 

app.UseAuthorization();
app.MapControllers();
app.Run();
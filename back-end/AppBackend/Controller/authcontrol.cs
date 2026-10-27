using Microsoft.AspNetCore.Mvc;
using System.Linq; // Required to query the database
using AppBackend.Models; 
// using AppBackend.Data; // Uncomment this if your AppDbContext is in a Data folder
using AppBackend.Data;
namespace AppBackend.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AuthController : ControllerBase
    {
        // 1. Add your Database Connection
        private readonly AppDbContext _context; 

        public AuthController(AppDbContext context)
        {
            _context = context;
        }

        // POST: api/auth/login
        [HttpPost("login")]
        public IActionResult Login([FromBody] LoginRequest request)
        {
            // Basic validation
            if (string.IsNullOrWhiteSpace(request.email) || string.IsNullOrWhiteSpace(request.password))
            {
                return BadRequest(new { message = "Email and password are required." });
            }

            // 2. REAL DATABASE CHECK
            // We ask the database if a record exists matching the typed email and password.
            // Note: Change "Users" if your database table is named something else (e.g., Accounts, Admins)
            var user = _context.Users.FirstOrDefault(u => 
                u.Email == request.email && 
                u.Password == request.password);

            if (user != null)
            {
                // 3. Successful login response using actual database data
                return Ok(new 
                { 
                    token = "sample-jwt-token-12345",
                    username = user.Email, // Pulls directly from the database record
                    role = "User", 
                    message = "Login successful" 
                });
            }

            // 4. Failed login response
            return Unauthorized(new { message = "Invalid username or password." });
        }
    }
}
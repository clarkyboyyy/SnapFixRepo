using Microsoft.AspNetCore.Mvc;
using System.Linq; // Required to query the database
using AppBackend.Model; 
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

        // ---------------------------------------------------
        // NEW CODE: POST: api/auth/register
        // ---------------------------------------------------
        [HttpPost("register")]
        public IActionResult Register([FromBody] User request)
        {
            // Basic validation
            if (string.IsNullOrWhiteSpace(request.Email) || string.IsNullOrWhiteSpace(request.Password))
            {
                return BadRequest(new { message = "Email and password are required." });
            }

            // 1. Check if the email is already taken
            var existingUser = _context.Users.FirstOrDefault(u => u.Email == request.Email);
            if (existingUser != null)
            {
                return BadRequest(new { message = "An account with this email already exists." });
            }

            // 2. Prepare the new user data
            var newUser = new User
            {
                Email = request.Email,
                Password = request.Password
            };

            // 3. Automatically save it to the Supabase Users table
            _context.Users.Add(newUser);
            _context.SaveChanges(); 

            return Ok(new { message = "Account created successfully!" });
        }
    }
}
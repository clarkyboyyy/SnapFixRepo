using Microsoft.AspNetCore.Mvc;
// If your namespace is different, replace 'AppBackend' with your actual project name
using AppBackend.Models; 

namespace AppBackend.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AuthController : ControllerBase
    {
        // POST: api/auth/login
        [HttpPost("login")]
        public IActionResult Login([FromBody] LoginRequest request)
        {
            // 1. Basic validation
            if (string.IsNullOrWhiteSpace(request.email) || string.IsNullOrWhiteSpace(request.password))
            {
                return BadRequest(new { message = "Email and password are required." });
            }

            // 2. Mock database check
            // In a real application, you would query your database here and compare hashed passwords.
            if (request.email == "admin@gmail.com" && request.password == "password123")
            {
                // 3. Successful login response
                // Normally, you generate and return a secure JWT (JSON Web Token) here.
                return Ok(new 
                { 
                    token = "sample-jwt-token-12345",
                    username = "admin",
                    role = "Administrator",
                    message = "Login successful" 
                });
            }

            // 4. Failed login response
            return Unauthorized(new { message = "Invalid username or password." });
        }
    }
}
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using AppBackend.Model; 
using AppBackend.Data;

namespace AppBackend.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AuthController : ControllerBase
    {
        private readonly AppDbContext _context;
        private readonly ILogger<AuthController> _logger;

        public AuthController(AppDbContext context, ILogger<AuthController> logger)
        {
            _context = context;
            _logger = logger;
        }

        // POST: api/auth/login
        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginRequest request)
        {
            var email = request.email.Trim().ToLowerInvariant();

            try
            {
                var user = await _context.Users
                    .AsNoTracking()
                    .FirstOrDefaultAsync(u =>
                        u.Email.ToLower() == email &&
                        u.Password == request.password);

                if (user == null)
                {
                    return Unauthorized(new { message = "Invalid username or password." });
                }

                return Ok(new
                {
                    token = "sample-jwt-token-12345",
                    id = user.Id,
                    fullName = user.FullName ?? string.Empty,
                    email = user.Email,
                    phone = user.Phone ?? string.Empty,
                    address = user.Address ?? string.Empty,
                    username = user.Email,
                    role = "User",
                    message = "Login successful"
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Login failed for {Email}", email);
                return StatusCode(500, new { message = "The account could not be checked. Try again." });
            }
        }

        // POST: api/auth/register
        [HttpPost("register")]
        public async Task<IActionResult> Register([FromBody] RegisterRequest request)
        {
            var email = request.Email.Trim().ToLowerInvariant();

            try
            {
                var existingUser = await _context.Users
                    .AsNoTracking()
                    .FirstOrDefaultAsync(u => u.Email.ToLower() == email);

                if (existingUser != null)
                {
                    return Conflict(new { message = "An account with this email already exists." });
                }

                var newUser = new User
                {
                    Email = email,
                    Password = request.Password,
                    FullName = request.FullName.Trim(),
                    Phone = ToStoredValue(request.Phone),
                    Address = ToStoredValue(request.Address)
                };

                _context.Users.Add(newUser);
                await _context.SaveChangesAsync();

                return StatusCode(StatusCodes.Status201Created, new
                {
                    message = "Account created successfully!",
                    id = newUser.Id,
                    fullName = newUser.FullName,
                    email = newUser.Email,
                    phone = newUser.Phone ?? string.Empty,
                    address = newUser.Address ?? string.Empty
                });
            }
            catch (DbUpdateException ex)
            {
                _logger.LogError(ex, "Could not save the account for {Email}", email);
                return StatusCode(500, new { message = "The account could not be saved. Try again." });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Registration failed for {Email}", email);
                return StatusCode(500, new { message = "Registration failed. Try again." });
            }
        }

        // GET: api/auth/profile?email=name@example.com
        [HttpGet("profile")]
        public async Task<IActionResult> GetProfile([FromQuery] string? email)
        {
            if (string.IsNullOrWhiteSpace(email))
            {
                return BadRequest(new { message = "Email is required." });
            }

            var cleanEmail = email.Trim().ToLowerInvariant();

            try
            {
                var user = await _context.Users
                    .AsNoTracking()
                    .FirstOrDefaultAsync(u => u.Email.ToLower() == cleanEmail);

                if (user == null)
                {
                    return NotFound(new { message = "No profile is stored for this account." });
                }

                return Ok(new
                {
                    id = user.Id,
                    fullName = user.FullName ?? string.Empty,
                    email = user.Email,
                    phone = user.Phone ?? string.Empty,
                    address = user.Address ?? string.Empty
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Could not load the profile for {Email}", cleanEmail);
                return StatusCode(500, new { message = "The profile could not be loaded. Try again." });
            }
        }

        // PUT: api/auth/profile
        [HttpPut("profile")]
        public async Task<IActionResult> UpdateProfile([FromBody] UpdateProfileRequest request)
        {
            var email = request.Email.Trim().ToLowerInvariant();

            try
            {
                var user = await _context.Users
                    .FirstOrDefaultAsync(u => u.Email.ToLower() == email);

                if (user == null)
                {
                    return NotFound(new { message = "No profile is stored for this account." });
                }

                user.FullName = request.FullName.Trim();
                user.Phone = ToStoredValue(request.Phone);
                user.Address = ToStoredValue(request.Address);
                await _context.SaveChangesAsync();

                return Ok(new
                {
                    message = "Profile updated successfully!",
                    id = user.Id,
                    fullName = user.FullName,
                    email = user.Email,
                    phone = user.Phone ?? string.Empty,
                    address = user.Address ?? string.Empty
                });
            }
            catch (DbUpdateException ex)
            {
                _logger.LogError(ex, "Could not update the profile for {Email}", email);
                return StatusCode(500, new { message = "The profile could not be updated. Try again." });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Profile update failed for {Email}", email);
                return StatusCode(500, new { message = "The profile could not be updated. Try again." });
            }
        }

        private static string? ToStoredValue(string? value) =>
            string.IsNullOrWhiteSpace(value) ? null : value.Trim();
    }
}

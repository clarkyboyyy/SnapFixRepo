using System.ComponentModel.DataAnnotations;

namespace AppBackend.Model;

public class UpdateProfileRequest
{
    [Required(ErrorMessage = "Email is required.")]
    [EmailAddress(ErrorMessage = "Enter a valid email address.")]
    public string Email { get; set; } = string.Empty;

    [Required(ErrorMessage = "Full name is required.")]
    [MinLength(2, ErrorMessage = "Full name is too short.")]
    [MaxLength(120)]
    public string FullName { get; set; } = string.Empty;

    [Phone(ErrorMessage = "Enter a valid phone number.")]
    [MaxLength(30)]
    public string? Phone { get; set; }

    [MaxLength(300)]
    public string? Address { get; set; }
}

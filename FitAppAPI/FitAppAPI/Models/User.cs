using System;
using System.ComponentModel.DataAnnotations;

namespace FitAppAPI.Models
{
    public class User
    {
        [Key]
        public Guid Id { get; set; } = Guid.NewGuid();

        [Required]
        [MaxLength(50)]
        public string Username { get; set; }

        [Required]
        [EmailAddress]
        public string Email { get; set; }

        [Required]
        public string PasswordHash { get; set; }

        public string? AvatarUrl { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public bool IsEmailVerified { get; set; } = false;
    }
}

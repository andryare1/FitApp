using System;
namespace FitAppAPI.Models
{
    public class EmailVerificationCode
    {
        public int Id { get; set; }
        public Guid UserId { get; set; }
        public string Code { get; set; }
        public DateTime ExpirationTime { get; set; }
        public bool IsUsed { get; set; }

        public User User { get; set; }  // если у тебя есть навигационное свойство
    }
}


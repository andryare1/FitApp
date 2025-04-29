using Microsoft.AspNetCore.Mvc;
using FitAppAPI.Models;
using FitAppAPI.Services;
using FitAppAPI.Data;
using System.Security.Cryptography;
using System.Text;
using Microsoft.EntityFrameworkCore;

namespace FitAppAPI.Controllers
{
    [Route("api/auth")]
    [ApiController]
    public class AuthController : ControllerBase
    {
        private readonly JwtService _jwtService;
        private readonly AppDbContext _context;

        public AuthController(JwtService jwtService, AppDbContext context)
        {
            _jwtService = jwtService;
            _context = context;
        }
        [HttpPost("register")]
        public async Task <IActionResult> Register([FromBody] UserRegisterDto model)
        {
            if (string.IsNullOrWhiteSpace(model.Username) || string.IsNullOrWhiteSpace(model.Email) || string.IsNullOrWhiteSpace(model.Password))
            {
                return BadRequest(new { message = "Все поля обязательны для заполнения." });
            }

            if (await _context.Users.AnyAsync(u => u.Username == model.Username))
            {
                return BadRequest(new { message = "Пользователь с таким именем уже существует." });
            }

            if (await _context.Users.AnyAsync(u => u.Email == model.Email))
            {
                return BadRequest(new { message = "Пользователь с таким Email уже существует." });
            }

            var user = new User
            {
                Username = model.Username,
                Email = model.Email,
                PasswordHash = HashPassword(model.Password)
            };

            await _context.Users.AddAsync(user);
            await _context.SaveChangesAsync();

            return Ok(new
            {
                message = "Регистрация успешна!",
                userId = user.Id,
                email = user.Email
            });
        }


        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] UserLoginDto model)
        {
            var user = await _context.Users.SingleOrDefaultAsync(u => u.Username == model.Username);
            if (user == null || !VerifyPassword(model.Password, user.PasswordHash))
            {
                return Unauthorized(new { message = "Неверный логин или пароль." });
            }

            if (!user.IsEmailVerified)
            {
                return Unauthorized(new { message = "Email не подтвержден" });
            }

            // Преобразуем userId из Guid в строку
            var token = _jwtService.GenerateToken(user.Username, user.Id.ToString());
            return Ok(new { Token = token });
        }

        private static string HashPassword(string password)
        {
            using (SHA256 sha256 = SHA256.Create())
            {
                byte[] bytes = sha256.ComputeHash(Encoding.UTF8.GetBytes(password));
                return Convert.ToBase64String(bytes);
            }
        }

        private static bool VerifyPassword(string inputPassword, string storedHash)
        {
            string inputHash = HashPassword(inputPassword);
            return inputHash == storedHash;
        }
    }
}

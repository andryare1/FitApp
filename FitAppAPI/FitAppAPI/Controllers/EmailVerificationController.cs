using System;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;
using FitAppAPI.Data;
using FitAppAPI.Models;
using Microsoft.AspNetCore.Authorization;
using System.Security.Claims;
using FitAppAPI.Services;
using Microsoft.AspNetCore.Identity.UI.Services;


namespace FitAppAPI.Controllers
{
    [ApiController]
    [Route("api/email-verification")]
    public class EmailVerificationController : ControllerBase
    {
        private readonly AppDbContext _context;
        private readonly IEmailSender _emailSender;

        public EmailVerificationController(AppDbContext context, IEmailSender emailSender)
        {
            _context = context;
            _emailSender = emailSender;
        }

        [HttpPost("send-code")]
        public async Task<IActionResult> SendCode([FromBody] SendVerificationCodeDto dto)
        {
            var user = await _context.Users.FirstOrDefaultAsync(u => u.Id == dto.UserId && u.Email == dto.Email);
            if (user == null) return NotFound("Пользователь не найден");

            // Генерация кода
            var code = new Random().Next(100000, 999999).ToString();

            var verification = new EmailVerificationCode
            {
                UserId = dto.UserId,
                Code = code,
                ExpirationTime = DateTime.UtcNow.AddMinutes(5),
                IsUsed = false
            };

            _context.EmailVerificationCodes.Add(verification);
            await _context.SaveChangesAsync();

            // Отправка письма
            var htmlContent = GetHtmlTemplate(code);
            await _emailSender.SendEmailAsync(dto.Email, "Код подтверждения", htmlContent);

            return Ok("Код отправлен");
        }

        [HttpPost("verify")]
        public async Task<IActionResult> VerifyCode([FromBody] VerifyEmailCodeDto dto)
        {
            var verification = await _context.EmailVerificationCodes
                .Where(v => v.UserId == dto.UserId && v.Code == dto.Code && !v.IsUsed)
                .OrderByDescending(v => v.ExpirationTime)
                .FirstOrDefaultAsync();

            if (verification == null || verification.ExpirationTime < DateTime.UtcNow)
            {
                return BadRequest("Неверный или просроченный код");
            }

            verification.IsUsed = true;

            var user = await _context.Users.FirstOrDefaultAsync(u => u.Id == dto.UserId);
            if (user != null)
            {
                user.IsEmailVerified = true;
            }

            await _context.SaveChangesAsync();
            return Ok("Email подтверждён");
        }

        private string GetHtmlTemplate(string code)
        {
            var templatePath = Path.Combine(Directory.GetCurrentDirectory(), "EmailTemplates", "VerificationCodeTemplate.html");
            var template = System.IO.File.ReadAllText(templatePath);
            return template.Replace("{{CODE}}", code);
        }
    }
}


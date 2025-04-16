using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using FitAppAPI.Data;
using FitAppAPI.Models;
using Microsoft.AspNetCore.Authorization;
using System.Security.Claims;
using FitAppAPI.Services;

namespace FitAppAPI.Controllers
{
    [Route("api/avatar")]
    [ApiController]
    [Authorize]
    public class AvatarController : ControllerBase
    {
        private readonly AppDbContext _context;
        private readonly JwtService _jwtService; // Добавлен сервис JWT для работы с токенами
        private readonly string _avatarFolderPath = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "avatars");

        public AvatarController(AppDbContext context, JwtService jwtService)
        {
            _context = context;
            _jwtService = jwtService;
        }

        [HttpPost("upload")]
        [Authorize]
        public async Task<IActionResult> UploadAvatar(IFormFile avatar)
        {
            if (avatar == null || avatar.Length == 0)
            {
                return BadRequest(new { message = "Файл не был выбран." });
            }
            // Извлечение токена из заголовков запроса
            var token = Request.Headers["Authorization"].ToString().Replace("Bearer ", "");
            if (string.IsNullOrEmpty(token))
            {
                return Unauthorized(new { message = "Токен не предоставлен." });
            }
            // Декодирование токена и извлечение userId
            var principal = _jwtService.GetPrincipalFromToken(token);
            var userId = principal?.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (userId == null)
            {
                return Unauthorized(new { message = "Не удалось извлечь ID пользователя из токена." });
            }
            // Получение текущего пользователя
            var user = await _context.Users.FirstOrDefaultAsync(u => u.Id.ToString() == userId);
            if (user == null)
            {
                return Unauthorized(new { message = "Пользователь не найден." });
            }
            // Удаление предыдущей аватарки, если она существует
            if (!string.IsNullOrEmpty(user.AvatarUrl))
            {
                // Извлекаем имя файла (без папки)
                var oldFileName = Path.GetFileName(user.AvatarUrl);

                if (!string.IsNullOrEmpty(oldFileName))
                {
                    var oldAvatarPath = Path.Combine(_avatarFolderPath, oldFileName);

                    if (System.IO.File.Exists(oldAvatarPath))
                    {
                        try
                        {
                            System.IO.File.Delete(oldAvatarPath);
                        }
                        catch (Exception ex)
                        {
                            return StatusCode(500, new { message = $"Не удалось удалить старую аватарку: {ex.Message}" });
                        }
                    }
                }
            }
            // Создание папки для аватарок, если её нет
            if (!Directory.Exists(_avatarFolderPath))
            {
                Directory.CreateDirectory(_avatarFolderPath);
            }
            // Генерация нового имени файла
            var newFileName = Guid.NewGuid().ToString() + Path.GetExtension(avatar.FileName);
            var newFilePath = Path.Combine(_avatarFolderPath, newFileName);

            try
            {
                // Сохранение нового файла
                using (var stream = new FileStream(newFilePath, FileMode.Create))
                {
                    await avatar.CopyToAsync(stream);
                }
                // Обновление пути к аватарке в базе данных
                user.AvatarUrl = "/avatars/" + newFileName;
                _context.Users.Update(user);
                await _context.SaveChangesAsync();

                return Ok(new { message = "Аватарка успешно загружена.", AvatarUrl = user.AvatarUrl });
            }
            catch
            {
                return StatusCode(500, new { message = "Ошибка при загрузке аватарки." });
            }
        }


        [HttpGet("{userId}")]
        public IActionResult GetAvatar(Guid userId)
        {
            var user = _context.Users.FirstOrDefault(u => u.Id == userId);
            if (user == null || string.IsNullOrEmpty(user.AvatarUrl))
            {
                return NotFound(new { message = "Аватарка не найдена." });
            }

            var avatarPath = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", user.AvatarUrl.TrimStart('/'));
            if (!System.IO.File.Exists(avatarPath))
            {
                return NotFound(new { message = "Аватарка не найдена на сервере." });
            }

            var fileBytes = System.IO.File.ReadAllBytes(avatarPath);
            return File(fileBytes, "image/jpeg");  // Простой способ вернуть файл
        }



        [HttpDelete("delete")]
        [Authorize]
        public async Task<IActionResult> DeleteAvatar()
        {
            var token = Request.Headers["Authorization"].ToString().Replace("Bearer ", "");
            if (string.IsNullOrEmpty(token))
            {
                return Unauthorized(new { message = "Токен не предоставлен." });
            }

            var principal = _jwtService.GetPrincipalFromToken(token);
            var userId = principal?.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (userId == null)
            {
                return Unauthorized(new { message = "Не удалось извлечь ID пользователя из токена." });
            }

            var user = await _context.Users.FirstOrDefaultAsync(u => u.Id.ToString() == userId);
            if (user == null)
            {
                return Unauthorized(new { message = "Пользователь не найден." });
            }

            if (!string.IsNullOrEmpty(user.AvatarUrl))
            {
                var fileName = Path.GetFileName(user.AvatarUrl);
                var avatarPath = Path.Combine(_avatarFolderPath, fileName);

                if (System.IO.File.Exists(avatarPath))
                {
                    try
                    {
                        System.IO.File.Delete(avatarPath);
                    }
                    catch (Exception ex)
                    {
                        return StatusCode(500, new { message = $"Ошибка при удалении файла: {ex.Message}" });
                    }
                }

                user.AvatarUrl = null;
                _context.Users.Update(user);
                await _context.SaveChangesAsync();
            }

            return Ok(new { message = "Аватарка удалена." });
        }
    }
}

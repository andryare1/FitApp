using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System;
using System.Linq;
using System.Security.Claims;
using System.Threading.Tasks;
using System.Collections.Generic;
using FitAppAPI.Data;
using FitAppAPI.Models;

namespace FitAppAPI.Controllers
{
    [Route("api/trainings")]
    [ApiController]
    [Authorize]
    public class TrainingController : ControllerBase
    {
        private readonly AppDbContext _context;

        public TrainingController(AppDbContext context)
        {
            _context = context;
        }

        private Guid GetUserId()
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            return Guid.TryParse(userIdClaim, out var userId) ? userId : Guid.Empty;
        }

        [HttpPost]
public async Task<IActionResult> CreateTraining([FromBody] Training training)
{
    var userId = GetUserId();
    if (userId == Guid.Empty) return Unauthorized();

    // Устанавливаем ID пользователя для тренировки
    training.UserId = userId;

    // Сохраняем тренировку
    _context.Trainings.Add(training);
    await _context.SaveChangesAsync();

    // Добавляем упражнения
    if (training.TrainingExercises != null && training.TrainingExercises.Any())
    {
        foreach (var te in training.TrainingExercises)
        {
            te.TrainingId = training.Id;  // Привязываем упражнения к тренировке
            _context.TrainingExercises.Add(te);
        }
        await _context.SaveChangesAsync();
    }

    return Ok(new { message = "Тренировка создана", training });
}

        [HttpGet]
        public async Task<IActionResult> GetUserTrainings()
        {
            var userId = GetUserId();
            if (userId == Guid.Empty) return Unauthorized();

            var trainings = await _context.Trainings
                .Where(t => t.UserId == userId)
                .Include(t => t.TrainingExercises)
                .ThenInclude(te => te.Exercise)
                .ToListAsync();

            return Ok(trainings);
        }

        [HttpGet("{id}")]
        public async Task<IActionResult> GetTraining(int id)
        {
            var userId = GetUserId();
            if (userId == Guid.Empty) return Unauthorized();

            var training = await _context.Trainings
                .Where(t => t.Id == id && t.UserId == userId)
                .Include(t => t.TrainingExercises)
                .ThenInclude(te => te.Exercise)
                .FirstOrDefaultAsync();

            if (training == null) return NotFound(new { message = "Тренировка не найдена" });

            return Ok(training);
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateTraining(Guid id, [FromBody] Training updatedTraining)
        {
            var userId = GetUserId();
            if (userId == Guid.Empty) return Unauthorized();

            var training = await _context.Trainings.FindAsync(id);
            if (training == null || training.UserId != userId) return NotFound(new { message = "Тренировка не найдена" });

            training.Name = updatedTraining.Name;
            await _context.SaveChangesAsync();

            return Ok(new { message = "Тренировка обновлена", training });
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteTraining(Guid id)
        {
            var userId = GetUserId();
            if (userId == Guid.Empty) return Unauthorized();

            var training = await _context.Trainings.FindAsync(id);
            if (training == null || training.UserId != userId) return NotFound(new { message = "Тренировка не найдена" });

            _context.Trainings.Remove(training);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Тренировка удалена" });
        }
    }
}

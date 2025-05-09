using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using FitAppAPI.Data;
using System.Security.Claims;
using System;
using System.Linq;
using System.Threading.Tasks;
using System.Collections.Generic;

namespace FitAppAPI.Controllers
{
    [Authorize]
    [ApiController]
    [Route("api/[controller]")]
    public class StatisticsController : ControllerBase
    {
        private readonly AppDbContext _context;

        public StatisticsController(AppDbContext context)
        {
            _context = context;
        }

        private Guid GetUserId() => Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value);

        [HttpGet("user")]
        public async Task<IActionResult> GetUserStatistics()
        {
            var userId = GetUserId();
            var trainings = await _context.Trainings
                .Where(t => t.UserId == userId)
                .Include(t => t.TrainingExercises)
                    .ThenInclude(te => te.Exercise)
                .ToListAsync();

            var totalTrainings = trainings.Count;
            var totalExercises = trainings.Sum(t => t.TrainingExercises.Count);

            // Получаем среднюю длительность тренировок из TrainingProgress
            var trainingDurations = await _context.TrainingProgress
                .Where(tp => tp.UserId == userId && tp.EndTime.HasValue)
                .GroupBy(tp => tp.TrainingId)
                .Select(g => new
                {
                    Duration = g.Max(tp => tp.EndTime.Value) - g.Min(tp => tp.StartTime.Value)
                })
                .ToListAsync();

            // Подсчет пропущенных упражнений
            var skippedExercises = await _context.TrainingProgress
                .Where(tp => tp.UserId == userId && tp.WasSkipped)
                .CountAsync();

            // Подсчет успешно выполненных упражнений
            var completedExercises = await _context.TrainingProgress
                .Where(tp => tp.UserId == userId && !tp.WasSkipped)
                .CountAsync();

            // Подсчет дней с тренировками
            var trainingDays = trainings
                .Select(t => t.CreatedAt.Date)
                .Distinct()
                .Count();

            // Подсчет среднего количества подходов на тренировку
            var averageSetsPerTraining = trainings
                .SelectMany(t => t.TrainingExercises)
                .Select(te => te.Sets)
                .DefaultIfEmpty(0)
                .Average();

            var muscleGroupCounts = trainings
                .SelectMany(t => t.TrainingExercises)
                .GroupBy(te => te.Exercise.MuscleGroup)
                .Select(g => new { MuscleGroup = g.Key, Count = g.Count() })
                .OrderByDescending(x => x.Count)
                .ToList();

            var favoriteMuscleGroup = muscleGroupCounts.FirstOrDefault()?.MuscleGroup.ToString() ?? "Нет данных";

            return Ok(new
            {
                totalTrainings,
                totalExercises,
                favoriteMuscleGroup,
                skippedExercises,
                completedExercises,
                trainingDays,
                averageSetsPerTraining = Math.Round(averageSetsPerTraining, 1),
                completionRate = totalExercises > 0
                    ? Math.Round((double)completedExercises / (completedExercises + skippedExercises) * 100, 1)
                    : 0
            });
        }

        [HttpGet("muscle-groups")]
        public async Task<IActionResult> GetMuscleGroupStats()
        {
            var userId = GetUserId();

            var muscleGroupStats = await _context.Trainings
                .Where(t => t.UserId == userId)
                .SelectMany(t => t.TrainingExercises)
                .GroupBy(te => te.Exercise.MuscleGroup)
                .Select(g => new
                {
                    muscleGroup = g.Key.ToString(),
                    count = g.Count()
                })
                .OrderByDescending(x => x.count)
                .ToListAsync();

            return Ok(new { stats = muscleGroupStats });
        }
    }
}
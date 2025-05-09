using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using FitAppAPI.Data;
using FitAppAPI.Models;
using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;

[ApiController]
[Route("api/session")]
[Authorize]
public class SessionController : ControllerBase
{
    private readonly AppDbContext _context;

    public SessionController(AppDbContext context)
    {
        _context = context;
    }

    private Guid GetUserId() => Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value);

    [HttpPost("start-session")]
    public async Task<IActionResult> StartTrainingSession([FromBody] StartTrainingSessionDto dto)
    {
        var userId = GetUserId();

        var session = new TrainingSession
        {
            TrainingId = dto.TrainingId,
            UserId = userId,
            StartedAt = DateTime.UtcNow
        };

        _context.TrainingSessions.Add(session);
        await _context.SaveChangesAsync();

        return Ok(new { sessionId = session.Id });
    }



    [HttpPut("{sessionId}/complete")]
    public async Task<IActionResult> CompleteTrainingSession(int sessionId)
    {
        var userId = GetUserId();

        var session = await _context.TrainingSessions
            .Include(s => s.Progresses)
            .Include(s => s.Training)
                .ThenInclude(t => t.TrainingExercises)
            .FirstOrDefaultAsync(s => s.Id == sessionId && s.UserId == userId);

        if (session == null) return NotFound();

        // 1. Создаем недостающие записи прогресса
        foreach (var exercise in session.Training.TrainingExercises)
        {
            var progress = session.Progresses.FirstOrDefault(p => p.ExerciseId == exercise.ExerciseId);
            if (progress == null)
            {
                progress = new TrainingProgress
                {
                    TrainingId = session.TrainingId,
                    ExerciseId = exercise.ExerciseId,
                    UserId = userId,
                    TrainingSessionId = sessionId,
                    SetsPlanned = exercise.Sets,
                    SetsCompleted = 0,
                    SetsSkipped = exercise.Sets,
                    WasSkipped = true, // Все автоматически созданные - пропущенные
                    ExerciseCompletionPercentage = 0,
                    StartTime = DateTime.UtcNow.AddMinutes(-5),
                    EndTime = DateTime.UtcNow,
                    CreatedAt = DateTime.UtcNow
                };
                _context.TrainingProgress.Add(progress);
            }
            else if (progress.SetsCompleted == 0 && !progress.WasSkipped)
            {
                // Корректируем некорректные записи
                progress.WasSkipped = true;
                progress.SetsSkipped = progress.SetsPlanned;
            }
        }

        // 2. Пересчитываем проценты для всех упражнений
        foreach (var progress in session.Progresses)
        {
            progress.ExerciseCompletionPercentage = progress.SetsPlanned > 0
                ? (decimal)progress.SetsCompleted / progress.SetsPlanned * 100
                : 0;
        }

        // 3. Считаем общий процент
        session.Training.CompletionPercentage = session.Progresses.Any()
            ? Math.Round(session.Progresses.Average(p => p.ExerciseCompletionPercentage), 2)
            : 0;

        session.CompletedAt = DateTime.UtcNow;
        await _context.SaveChangesAsync();

        return Ok(new
        {
            completionPercentage = session.Training.CompletionPercentage,
            details = session.Progresses.Select(p => new {
                p.ExerciseId,
                p.SetsCompleted,
                p.WasSkipped,
                p.ExerciseCompletionPercentage
            })
        });
    }

    [HttpDelete("{sessionId}")]
    public async Task<IActionResult> DeleteTrainingSession(int sessionId)
    {
        var session = await _context.TrainingSessions
            .FirstOrDefaultAsync(s => s.Id == sessionId && s.UserId == GetUserId());

        if (session == null) return NotFound();

        _context.TrainingSessions.Remove(session);
        await _context.SaveChangesAsync();
        return NoContent();
    }
}


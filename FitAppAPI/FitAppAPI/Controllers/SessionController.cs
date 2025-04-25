using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using FitAppAPI.Data;
using FitAppAPI.Models;
using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;

[ApiController]
[Route("api/session")]
//[Authorize]
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

        // Находим сессию тренировки по ID
        var session = await _context.TrainingSessions
            .Include(s => s.Progresses) // Включаем прогресс сессии
            .Include(s => s.Training) // Включаем саму тренировку
            .FirstOrDefaultAsync(s => s.Id == sessionId && s.UserId == userId);

        if (session == null)
            return NotFound("Session not found.");

        // Если нет прогресса в сессии
        if (session.Progresses == null || !session.Progresses.Any())
            return BadRequest("No progress found for this session.");

        // Вычисляем процент выполнения для текущей сессии
        var sessionCompletion = session.Progresses.Average(p => p.ExerciseCompletionPercentage);

        // Обновляем процент выполнения тренировки в таблице Trainings
        session.Training.CompletionPercentage = Math.Round(sessionCompletion, 2);

        // Сохраняем изменения в базе данных
        await _context.SaveChangesAsync();

        return Ok(new
        {
            message = "Session completed",
            completionPercentage = session.Training.CompletionPercentage
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


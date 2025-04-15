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


    [ApiController]
    [Route("api/trainings")]
    [Authorize]
    public class TrainingsController : ControllerBase
    {
        private readonly AppDbContext _context;

       // public TrainingsController(AppDbContext context)
       // {
       //     _context = context;
       // }

        private Guid GetUserId() => Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value);


        private readonly ILogger<TrainingsController> _logger;

        public TrainingsController(AppDbContext context, ILogger<TrainingsController> logger)
        {
            _context = context;
            _logger = logger;
        }

        [HttpGet]
        public async Task<ActionResult<IEnumerable<TrainingDto>>> GetTrainings()
        {
            var userId = GetUserId();

            var trainings = await _context.Trainings
                .Where(t => t.UserId == userId)
                .OrderByDescending(t => t.CreatedAt)
                .Select(t => new TrainingDto
                {
                    Id = t.Id,
                    Name = t.Name,
                    CreatedAt = t.CreatedAt,
                    CompletionPercentage = t.CompletionPercentage, 
                    Exercises = t.TrainingExercises
                        .OrderBy(te => te.OrderIndex)
                        .Select(te => new TrainingExerciseDto
                        {
                            Id = te.Id,
                            ExerciseId = te.ExerciseId,
                            ExerciseName = te.Exercise.Name,
                            Sets = te.Sets,
                            ImageUrl = $"{Request.Scheme}://{Request.Host}{te.Exercise.ImageUrl}",
                            Reps = te.Reps,
                            Weight = te.Weight,
                            OrderIndex = te.OrderIndex,
                        })
                        .ToList()
                })
                .ToListAsync();

            return Ok(trainings);
        }


        [HttpGet("{trainingId}/with-exercises")]
        public async Task<ActionResult<TrainingDto>> GetTrainingWithExercises(int trainingId)
        {
            var userId = GetUserId();
            var training = await _context.Trainings
                .Include(t => t.TrainingExercises)
                    .ThenInclude(te => te.Exercise)
                .FirstOrDefaultAsync(t => t.Id == trainingId && t.UserId == userId);

            if (training == null) return NotFound();

            return new TrainingDto
            {
                Id = training.Id,
                Name = training.Name,
                CreatedAt = training.CreatedAt,
                Exercises = training.TrainingExercises
                    .OrderBy(te => te.OrderIndex)
                    .Select(te => new TrainingExerciseDto
                    {
                        Id = te.Id,
                        ExerciseId = te.ExerciseId,
                        ExerciseName = te.Exercise.Name,
                        ImageUrl = $"{Request.Scheme}://{Request.Host}{te.Exercise.ImageUrl}",
                        Sets = te.Sets,
                        Reps = te.Reps,
                        Weight = te.Weight,
                        OrderIndex = te.OrderIndex
                    })
                    .ToList()
            };
        }


        [HttpPut("{trainingId}/full")]
        public async Task<ActionResult<TrainingDto>> UpdateFullTraining(
    int trainingId,
    [FromBody] UpdateTrainingDto dto)
        {
            var training = await _context.Trainings
                .Include(t => t.TrainingExercises)
                .FirstOrDefaultAsync(t => t.Id == trainingId && t.UserId == GetUserId());

            if (training == null) return NotFound();

            // Обновляем название
            training.Name = dto.Name;

            // Удаляем старые упражнения
            _context.TrainingExercises.RemoveRange(training.TrainingExercises);

            // Добавляем новые упражнения
            training.TrainingExercises = dto.Exercises.Select((e, i) => new TrainingExercise
            {
                ExerciseId = e.ExerciseId,
                Sets = e.Sets,
                Reps = e.Reps,
                Weight = e.Weight,
                OrderIndex = i,
            }).ToList();

            await _context.SaveChangesAsync();

            return await GetTrainingWithExercises(trainingId);
        }

        [HttpPost("create-full")]
        public async Task<ActionResult<TrainingDto>> CreateTrainingWithExercises(
      [FromBody] CreateTrainingDto dto)
        {
            // Проверяем существование упражнений
            var exerciseIds = dto.Exercises.Select(e => e.ExerciseId).Distinct().ToList();
            var existingExercises = await _context.Exercises
                .Where(e => exerciseIds.Contains(e.Id))
                .ToListAsync();

            if (existingExercises.Count != exerciseIds.Count)
            {
                var missingIds = exerciseIds.Except(existingExercises.Select(e => e.Id));
                return BadRequest($"Exercises not found: {string.Join(", ", missingIds)}");
            }

            var training = new Training
            {
                Name = dto.Name,
                UserId = GetUserId(),
                CreatedAt = DateTime.UtcNow,
                TrainingExercises = dto.Exercises.Select(e => new TrainingExercise
                {
                    ExerciseId = e.ExerciseId,
                    Sets = e.Sets,
                    Reps = e.Reps,
                    Weight = e.Weight,
                    OrderIndex = e.OrderIndex,
                }).ToList()
            };

            _context.Trainings.Add(training);
            await _context.SaveChangesAsync();

            // Явно загружаем упражнения для ответа
            var result = await _context.Trainings
                .Include(t => t.TrainingExercises)
                    .ThenInclude(te => te.Exercise) // Добавляем загрузку Exercise
                .FirstOrDefaultAsync(t => t.Id == training.Id);

            return Ok(new TrainingDto
            {
                Id = result.Id,
                Name = result.Name,
                CreatedAt = result.CreatedAt,
                Exercises = result.TrainingExercises
                    .OrderBy(te => te.OrderIndex)
                    .Select(te => new TrainingExerciseDto
                    {
                        Id = te.Id,
                        ExerciseId = te.ExerciseId,
                        ExerciseName = te.Exercise?.Name ?? string.Empty, // Защита от null
                        Sets = te.Sets,
                        ImageUrl = $"{Request.Scheme}://{Request.Host}{te.Exercise.ImageUrl}", // ?????? проверить
                        Reps = te.Reps,
                        Weight = te.Weight,
                        OrderIndex = te.OrderIndex
                    })
            });
        }

        [HttpPatch("{trainingId}")]
        public async Task<ActionResult<TrainingDto>> PartialUpdateTraining(
    int trainingId,
    [FromBody] PartialUpdateTrainingDto dto)
        {
            var training = await _context.Trainings
                .Include(t => t.TrainingExercises)
                .FirstOrDefaultAsync(t => t.Id == trainingId && t.UserId == GetUserId());

            if (training == null) return NotFound();

            // Обновляем только те поля, которые пришли
            if (dto.Name != null) training.Name = dto.Name;

            if (dto.Exercises != null)
            {
                _context.TrainingExercises.RemoveRange(training.TrainingExercises);
                training.TrainingExercises = dto.Exercises.Select((e, i) => new TrainingExercise
                {
                    ExerciseId = e.ExerciseId,
                    Sets = e.Sets,
                    Reps = e.Reps,
                    Weight = e.Weight,
                    OrderIndex = i,
                }).ToList();
            }

            await _context.SaveChangesAsync();
            return await GetTrainingWithExercises(trainingId);
        }



        [HttpPut("{trainingId}/exercises")]
        public async Task<IActionResult> UpdateTrainingExercises(
    int trainingId,
    [FromBody] UpdateTrainingExercisesDto dto)
        {
            var training = await _context.Trainings
                .Include(t => t.TrainingExercises)
                .FirstOrDefaultAsync(t => t.Id == trainingId && t.UserId == GetUserId());

            if (training == null) return NotFound();

            _context.TrainingExercises.RemoveRange(training.TrainingExercises);
            training.TrainingExercises = dto.Exercises.Select((e, i) => new TrainingExercise
            {
                ExerciseId = e.ExerciseId,
                Sets = e.Sets,
                Reps = e.Reps,
                Weight = e.Weight,
                OrderIndex = i,
            }).ToList();

            await _context.SaveChangesAsync();
            return NoContent();
        }

        [HttpDelete("{trainingId}")]
        public async Task<IActionResult> DeleteTraining(int trainingId)
        {
            var training = await _context.Trainings
                .FirstOrDefaultAsync(t => t.Id == trainingId && t.UserId == GetUserId());

            if (training == null) return NotFound();

            _context.Trainings.Remove(training);
            await _context.SaveChangesAsync();
            return NoContent();
        }



        [HttpPost("progress")]
        public async Task<IActionResult> StartExercise([FromBody] StartExerciseDto dto)
        {
            _logger.LogInformation("StartExercise method called. TrainingId: {TrainingId}, ExerciseId: {ExerciseId}, TrainingSessionId: {TrainingSessionId}",
                dto.TrainingId, dto.ExerciseId, dto.TrainingSessionId);

            var userId = GetUserId();
            _logger.LogInformation("UserId retrieved: {UserId}", userId);

            try
            {
                var progress = new TrainingProgress
                {
                    Id = 0, // Используем GUID, как в твоей БД
                    TrainingId = dto.TrainingId,
                    UserId = userId,
                    ExerciseId = dto.ExerciseId,
                    SetsPlanned = dto.SetsPlanned,
                    SetsCompleted = 0,
                    SetsSkipped = 0,
                    ExerciseCompletionPercentage = 0, // Начальный процент тренировки
                    WasSkipped = false,
                    StartTime = DateTime.UtcNow,
                    CreatedAt = DateTime.UtcNow,
                    TrainingSessionId = dto.TrainingSessionId
                };

                _logger.LogInformation("TrainingProgress entity created: {Progress}", progress);

                _context.TrainingProgress.Add(progress);
                await _context.SaveChangesAsync();

                _logger.LogInformation("TrainingProgress saved to database. Progress Id: {ProgressId}", progress.Id);

                return Ok(new { id = progress.Id });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "An error occurred while saving the TrainingProgress for TrainingId: {TrainingId}, ExerciseId: {ExerciseId}",
                    dto.TrainingId, dto.ExerciseId);
                return StatusCode(500, "Internal server error");
            }
        }

        // Обновление прогресса по завершению упражнения
        [HttpPut("progress/{id}")]
        public async Task<IActionResult> CompleteExercise(int id, [FromBody] CompleteExerciseDto dto)
        {
            var userId = GetUserId();

            var progress = await _context.TrainingProgress
                .FirstOrDefaultAsync(p => p.Id == id && p.UserId == userId);

            if (progress == null)
                return NotFound();

            // Получаем информацию о запланированных подходах из таблицы TrainingExercise
            var trainingExercise = await _context.TrainingExercises
                .FirstOrDefaultAsync(te => te.TrainingId == progress.TrainingId && te.ExerciseId == progress.ExerciseId);

            if (trainingExercise == null)
                return NotFound();

            // Получаем запланированное количество подходов из таблицы TrainingExercise
            progress.SetsPlanned = trainingExercise.Sets;

            progress.SetsCompleted = dto.SetsCompleted;
            progress.SetsSkipped = progress.SetsPlanned - progress.SetsCompleted;
            progress.EndTime = DateTime.UtcNow;
            progress.WasSkipped = dto.WasSkipped;

            progress.ExerciseCompletionPercentage = trainingExercise.Sets > 0
                ? ((decimal)progress.SetsCompleted / trainingExercise.Sets) * 100
                : 0;

            await _context.SaveChangesAsync();

            return Ok();
        }
     

        [HttpGet("{trainingId}/progress")]
        public async Task<ActionResult<TrainingProgressResponseDto>> GetProgressByTraining(int trainingId)
        {
            var userId = GetUserId();

            var training = await _context.Trainings
                .FirstOrDefaultAsync(t => t.Id == trainingId && t.UserId == userId);

            if (training == null)
                return NotFound("Тренировка не найдена");

            var progressList = await _context.TrainingProgress
                .Where(p => p.TrainingId == trainingId && p.UserId == userId)
                .Select(p => new TrainingProgressDto
                {
                    Id = p.Id,
                    ExerciseId = p.ExerciseId,
                    SetsPlanned = p.SetsPlanned,
                    SetsCompleted = p.SetsCompleted,
                    SetsSkipped = p.SetsSkipped,
                    ExerciseCompletionPercentage = p.ExerciseCompletionPercentage,
                    WasSkipped = p.WasSkipped,
                    StartTime = p.StartTime,
                    EndTime = p.EndTime
                })
                .ToListAsync();

            var response = new TrainingProgressResponseDto
            {
                TrainingCompletionPercentage = training.CompletionPercentage,
                ProgressList = progressList
            };

            return Ok(response);
        }


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
    }
}
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

            public TrainingsController(AppDbContext context)
            {
                _context = context;
            }

            private Guid GetUserId() => Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value);

            [HttpGet]
        [HttpGet]
        public async Task<ActionResult<IEnumerable<TrainingDto>>> GetTrainings()
        {
            var userId = GetUserId();
            return await _context.Trainings
                .Where(t => t.UserId == userId)
                .OrderByDescending(t => t.CreatedAt)
                .Select(t => new TrainingDto
                {
                    Id = t.Id,
                    Name = t.Name,
                    CreatedAt = t.CreatedAt,
                    Exercises = t.TrainingExercises
                        .OrderBy(te => te.OrderIndex)
                        .Select(te => new TrainingExerciseDto
                        {
                            Id = te.Id,
                            ExerciseId = te.ExerciseId,
                            ExerciseName = te.Exercise.Name,
                            Sets = te.Sets,
                            Reps = te.Reps,
                            Weight = te.Weight,
                            OrderIndex = te.OrderIndex
                        })
                        .ToList()
                })
                .ToListAsync();
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
                    Comment = e.Comment
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
                        Reps = te.Reps,
                        Weight = te.Weight,
                        OrderIndex = te.OrderIndex
                    })
            });
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
                    Comment = e.Comment
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
        }
    }

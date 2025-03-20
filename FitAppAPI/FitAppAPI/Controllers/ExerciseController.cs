using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using FitAppAPI.Data;
using FitAppAPI.Models;

[Route("api/exercises")]
[ApiController]
public class ExerciseController : ControllerBase
{
    private readonly AppDbContext _context;

    public ExerciseController(AppDbContext context)
    {
        _context = context;
    }

    // 1. Поиск упражнений по названию
    [HttpGet("search")]
    public async Task<ActionResult<IEnumerable<Exercise>>> SearchExercises([FromQuery] string query)
    {
        if (string.IsNullOrWhiteSpace(query))
        {
            return BadRequest("Запрос не должен быть пустым");
        }

        var results = await _context.Exercises
            .Where(e => e.Name.Contains(query))
            .ToListAsync();

        if (results.Count == 0)
            return NotFound("Упражнения не найдены");

        return Ok(results);
    }

    // 2. Получение упражнений по группе мышц
    [HttpGet("group/{muscleGroup}")]
    public async Task<ActionResult<IEnumerable<object>>> GetExercisesByGroup(string muscleGroup)
    {
        // Преобразование строки в соответствующий enum
        if (!Enum.TryParse(muscleGroup, true, out MuscleGroup muscleGroupEnum))
        {
            return BadRequest("Некорректное значение группы мышц");
        }

        var results = await _context.Exercises
            .Where(e => e.MuscleGroup == muscleGroupEnum)
            .Select(e => new
            {
                e.Id,
                e.Name,
                e.MuscleGroup,
                ImageUrl = Url.Content($"~/wwwroot/{e.ImageUrl}")
            })
            .ToListAsync();

        if (results.Count == 0)
            return NotFound("Нет упражнений для этой группы мышц");

        return Ok(results);
    }

}

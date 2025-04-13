using System.ComponentModel.DataAnnotations;

public class TrainingDto
{
    public int Id { get; set; }
    public string Name { get; set; }
    public DateTime CreatedAt { get; set; }
    public IEnumerable<TrainingExerciseDto> Exercises { get; set; }
}

public class TrainingExerciseDto
{
    public int Id { get; set; }
    public int ExerciseId { get; set; }
    public string ExerciseName { get; set; }
    public string ImageUrl { get; set; } 
    public int Sets { get; set; }
    public int Reps { get; set; }
    public decimal Weight { get; set; }
    public int OrderIndex { get; set; }
}

public class CreateTrainingDto
{
    [Required]
    [StringLength(100)]
    public string Name { get; set; }

    [Required]
    [MinLength(1)]
    public List<CreateTrainingExerciseDto> Exercises { get; set; }
}

public class CreateTrainingExerciseDto
{
    [Required]
    public int ExerciseId { get; set; }

    [Range(1, 20)]
    public int Sets { get; set; } = 3;

    [Range(1, 50)]
    public int Reps { get; set; } = 10;

    [Range(0, 500)]
    public decimal Weight { get; set; }

    public int OrderIndex { get; set; }  // Добавляем OrderIndex

}

public class UpdateTrainingExercisesDto
{
    [Required]
    [MinLength(1)]
    public List<UpdateTrainingExerciseDto> Exercises { get; set; }
}

public class UpdateTrainingExerciseDto : CreateTrainingExerciseDto
{
    public int Id { get; set; }
}

public class UpdateExerciseDto
{
    public int ExerciseId { get; set; }
    public int Sets { get; set; }
    public int Reps { get; set; }
    public decimal Weight { get; set; }
}

public class UpdateTrainingDto
{
    public string Name { get; set; }
    public List<UpdateExerciseDto> Exercises { get; set; }
}

public class PartialUpdateTrainingDto
{
    public string Name { get; set; }
    public List<UpdateExerciseDto> Exercises { get; set; }
}


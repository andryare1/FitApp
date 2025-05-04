using System.ComponentModel.DataAnnotations;

public class TrainingDto
{
    public int Id { get; set; }
    public string Name { get; set; }
    public DateTime CreatedAt { get; set; }
    public IEnumerable<TrainingExerciseDto> Exercises { get; set; }
    public decimal CompletionPercentage { get; set; }
}

public class TrainingExerciseDto
{
    public int Id { get; set; }
    public int ExerciseId { get; set; }
    public string ExerciseName { get; set; }
    public string ImageUrl { get; set; }
    public string VideoUrl { get; set; }
    public int Sets { get; set; }
    public int Reps { get; set; }
    public decimal Weight { get; set; }
    public int OrderIndex { get; set; }
    public decimal CompletionPercentage { get; set; }
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
    public decimal TrainingCompletionPercentage { get; set; }  // Процент выполнения всей тренировки
}

public class StartExerciseDto
{
    public int TrainingId { get; set; }  // Ссылка на тренировку (int)
    public int ExerciseId { get; set; }  // Ссылка на упражнение (int)
    public int SetsPlanned { get; set; }  // Количество запланированных подходов
    public int TrainingSessionId { get; set; }
}

public class CompleteExerciseDto
{
    public int SetsCompleted { get; set; }
    public bool WasSkipped { get; set; }

    public decimal ExerciseCompletionPercentage { get; set; }  // % выполнения конкретного упражнения

    public decimal TrainingCompletionPercentage { get; set; }  // % выполнения всей тренировки
}

public class TrainingProgressDto
{
    public int Id { get; set; }
    public int ExerciseId { get; set; }
    public int SetsPlanned { get; set; }
    public int SetsSkipped { get; set; }  
    public int SetsCompleted { get; set; }
    public bool WasSkipped { get; set; }
    public DateTime? StartTime { get; set; }
    public DateTime? EndTime { get; set; }

    public decimal ExerciseCompletionPercentage { get; set; }  // процент выполнения именно этого упражнения
}

public class TrainingProgressResponseDto
{
    public decimal TrainingCompletionPercentage { get; set; }
    public List<TrainingProgressDto> ProgressList { get; set; }
}

public class StartTrainingSessionDto
{
    public int TrainingId { get; set; }
}

public class SendVerificationCodeDto
{
    public Guid UserId { get; set; }
    public string Email { get; set; }
}

public class VerifyEmailCodeDto
{
    public Guid UserId { get; set; }
    public string Code { get; set; }
}
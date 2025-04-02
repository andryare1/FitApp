using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace FitAppAPI.Models {
    public class TrainingExercise
    {
        [Key]
        [Column("id")]
        public int Id { get; set; }

        [Required]
        [Column("training_id")]
        public int TrainingId { get; set; }

        [ForeignKey("TrainingId")]
        public Training Training { get; set; }

        [Required]
        [Column("exercise_id")]
        public int ExerciseId { get; set; }

        [ForeignKey("ExerciseId")]
        public Exercise Exercise { get; set; }

        [Required]
        [Column("sets")]
        public int Sets { get; set; } // Подходы

        [Required]
        [Column("reps")]
        public int Reps { get; set; } // Повторения

        [Column("weight")]
        public float Weight { get; set; } // Вес

        [Column("comment")]
        public string? Comment { get; set; } // Комментарий

        [Column("order_index")]
        public int OrderIndex { get; set; } // Порядковый номер
    }
}

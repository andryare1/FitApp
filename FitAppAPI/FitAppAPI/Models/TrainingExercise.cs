using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace FitAppAPI.Models {
    public class TrainingExercise
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public int TrainingId { get; set; }

        public Training Training { get; set; }

        [Required]
        public int ExerciseId { get; set; }

        public Exercise Exercise { get; set; }

        [Required]
        public int Sets { get; set; } // Подходы

        [Required]
        public int Reps { get; set; } // Повторения

        public decimal Weight { get; set; } // Вес

        public int OrderIndex { get; set; } // Порядковый номер
    }
}

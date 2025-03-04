using System.ComponentModel.DataAnnotations;

namespace FitAppAPI.Models
{
    public enum MuscleGroup
    {
        Chest,
        Back,
        Shoulders,
        Arms,
        Legs,
        Abs
    }

    public class Exercise
    {
        [Key]
        public int Id { get; set; } // Поле id типа int

        [Required]
        [MaxLength(100)]
        public string Name { get; set; } // Название упражнения

        [Required]
        [MaxLength(500)]
        public string Description { get; set; } // Описание упражнения

        [Required]
        public MuscleGroup MuscleGroup { get; set; } // Группа мышц (через enum)

        [Required]
        public string ImageUrl { get; set; } // URL изображения
    }
}

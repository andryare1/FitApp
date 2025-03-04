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
        public int Id { get; set; }

        [Required]
        [MaxLength(100)]
        public string Name { get; set; }

        [Required]
        [MaxLength(500)]
        public string Description { get; set; }

        [Required]
        public MuscleGroup MuscleGroup { get; set; }

        [Required]
        public string ImageUrl { get; set; }

    }
}

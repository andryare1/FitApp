
using System.ComponentModel.DataAnnotations;

namespace FitAppAPI.Models
{
    public class Training
    {
        [Key]
        public int Id { get; set; } 

        [Required]
        public string Name { get; set; }

        [Required]
        public Guid UserId { get; set; } // ID владельца
        
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public List<TrainingExercise> TrainingExercises { get; set; } = new();
    }

}

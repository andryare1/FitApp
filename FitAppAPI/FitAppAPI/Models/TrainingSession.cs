using System;
namespace FitAppAPI.Models
{
    public class TrainingSession
    {
        public int Id { get; set; }

        public int TrainingId { get; set; }

        public Training Training { get; set; }

        public Guid UserId { get; set; }

        public DateTime StartedAt { get; set; } = DateTime.UtcNow;

        public ICollection<TrainingProgress> Progresses { get; set; }
    }
}


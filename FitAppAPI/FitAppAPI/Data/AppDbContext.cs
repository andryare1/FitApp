using Microsoft.EntityFrameworkCore;
using FitAppAPI.Models;

namespace FitAppAPI.Data
{
    public class AppDbContext : DbContext
    {
        public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

        public DbSet<User> Users { get; set; }
        public DbSet<Exercise> Exercises { get; set; }
        public DbSet<Training> Trainings { get; set; }
        public DbSet<TrainingExercise> TrainingExercises { get; set; }
        public DbSet<TrainingProgress> TrainingProgress { get; set; }
        public DbSet<TrainingSession> TrainingSessions { get; set; } // ⬅ добавляем новую таблицу
      
    }
}
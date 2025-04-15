using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace FitAppAPI.Models
{
    public class TrainingProgress
    {
        [Key]
        public int Id { get; set; }  // Уникальный идентификатор для прогресса

        [Required]
        public int TrainingId { get; set; }  // Ссылка на тренировку (int)

        [Required]
        public Guid UserId { get; set; }  // Ссылка на пользователя (Guid)

        [Required]
        public int ExerciseId { get; set; }  // Ссылка на упражнение (int)

        [Required]
        public int SetsPlanned { get; set; }  // Сколько подходов запланировано

        public int SetsCompleted { get; set; }  // Сколько подходов выполнено

        public int SetsSkipped { get; set; }  // Количество пропущенных подходов (если нужно учитывать)

        [Required]
        public bool WasSkipped { get; set; }  // Было ли упражнение пропущено

        public DateTime? StartTime { get; set; }  // Когда начало выполнения упражнения

        public DateTime? EndTime { get; set; }  // Когда завершилось выполнение упражнения

        [Required]
        public DateTime CreatedAt { get; set; }  // Когда запись была создана

        public int TrainingSessionId { get; set; }
        public TrainingSession TrainingSession { get; set; }

        // Новый параметр для процента выполнения упражнения


        // Новый параметр для процента выполнения всей тренировки
        public decimal ExerciseCompletionPercentage { get; set; }

        // Навигационные свойства для связи с другими таблицами
        [ForeignKey("TrainingId")]
        public virtual Training Training { get; set; }

        [ForeignKey("UserId")]
        public virtual User User { get; set; }

        [ForeignKey("ExerciseId")]
        public virtual Exercise Exercise { get; set; }
    }
}
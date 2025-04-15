using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace FitAppAPI.Migrations
{
    /// <inheritdoc />
    public partial class UpdateTrainingProgressColumns : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_TrainingExercises_Exercises_exercise_id",
                table: "TrainingExercises");

            migrationBuilder.DropForeignKey(
                name: "FK_TrainingExercises_Trainings_training_id",
                table: "TrainingExercises");

            migrationBuilder.DropColumn(
                name: "comment",
                table: "TrainingExercises");

            migrationBuilder.RenameColumn(
                name: "weight",
                table: "TrainingExercises",
                newName: "Weight");

            migrationBuilder.RenameColumn(
                name: "sets",
                table: "TrainingExercises",
                newName: "Sets");

            migrationBuilder.RenameColumn(
                name: "reps",
                table: "TrainingExercises",
                newName: "Reps");

            migrationBuilder.RenameColumn(
                name: "id",
                table: "TrainingExercises",
                newName: "Id");

            migrationBuilder.RenameColumn(
                name: "training_id",
                table: "TrainingExercises",
                newName: "TrainingId");

            migrationBuilder.RenameColumn(
                name: "order_index",
                table: "TrainingExercises",
                newName: "OrderIndex");

            migrationBuilder.RenameColumn(
                name: "exercise_id",
                table: "TrainingExercises",
                newName: "ExerciseId");

            migrationBuilder.RenameIndex(
                name: "IX_TrainingExercises_training_id",
                table: "TrainingExercises",
                newName: "IX_TrainingExercises_TrainingId");

            migrationBuilder.RenameIndex(
                name: "IX_TrainingExercises_exercise_id",
                table: "TrainingExercises",
                newName: "IX_TrainingExercises_ExerciseId");

            migrationBuilder.AddColumn<decimal>(
                name: "CompletionPercentage",
                table: "Trainings",
                type: "decimal(18,2)",
                nullable: false,
                defaultValue: 0m);

            migrationBuilder.AddColumn<bool>(
                name: "IsDraft",
                table: "Trainings",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AlterColumn<decimal>(
                name: "Weight",
                table: "TrainingExercises",
                type: "decimal(18,2)",
                nullable: false,
                oldClrType: typeof(float),
                oldType: "real");

            migrationBuilder.CreateTable(
                name: "TrainingProgress",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    TrainingId = table.Column<int>(type: "int", nullable: false),
                    UserId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    ExerciseId = table.Column<int>(type: "int", nullable: false),
                    SetsPlanned = table.Column<int>(type: "int", nullable: false),
                    SetsCompleted = table.Column<int>(type: "int", nullable: false),
                    SetsSkipped = table.Column<int>(type: "int", nullable: false),
                    WasSkipped = table.Column<bool>(type: "bit", nullable: false),
                    StartTime = table.Column<DateTime>(type: "datetime2", nullable: true),
                    EndTime = table.Column<DateTime>(type: "datetime2", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    CompletionPercentage = table.Column<decimal>(type: "decimal(18,2)", nullable: false),
                    TrainingCompletionPercentage = table.Column<decimal>(type: "decimal(18,2)", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_TrainingProgress", x => x.Id);
                    table.ForeignKey(
                        name: "FK_TrainingProgress_Exercises_ExerciseId",
                        column: x => x.ExerciseId,
                        principalTable: "Exercises",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_TrainingProgress_Trainings_TrainingId",
                        column: x => x.TrainingId,
                        principalTable: "Trainings",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_TrainingProgress_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_TrainingProgress_ExerciseId",
                table: "TrainingProgress",
                column: "ExerciseId");

            migrationBuilder.CreateIndex(
                name: "IX_TrainingProgress_TrainingId",
                table: "TrainingProgress",
                column: "TrainingId");

            migrationBuilder.CreateIndex(
                name: "IX_TrainingProgress_UserId",
                table: "TrainingProgress",
                column: "UserId");

            migrationBuilder.AddForeignKey(
                name: "FK_TrainingExercises_Exercises_ExerciseId",
                table: "TrainingExercises",
                column: "ExerciseId",
                principalTable: "Exercises",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_TrainingExercises_Trainings_TrainingId",
                table: "TrainingExercises",
                column: "TrainingId",
                principalTable: "Trainings",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_TrainingExercises_Exercises_ExerciseId",
                table: "TrainingExercises");

            migrationBuilder.DropForeignKey(
                name: "FK_TrainingExercises_Trainings_TrainingId",
                table: "TrainingExercises");

            migrationBuilder.DropTable(
                name: "TrainingProgress");

            migrationBuilder.DropColumn(
                name: "CompletionPercentage",
                table: "Trainings");

            migrationBuilder.DropColumn(
                name: "IsDraft",
                table: "Trainings");

            migrationBuilder.RenameColumn(
                name: "Weight",
                table: "TrainingExercises",
                newName: "weight");

            migrationBuilder.RenameColumn(
                name: "Sets",
                table: "TrainingExercises",
                newName: "sets");

            migrationBuilder.RenameColumn(
                name: "Reps",
                table: "TrainingExercises",
                newName: "reps");

            migrationBuilder.RenameColumn(
                name: "Id",
                table: "TrainingExercises",
                newName: "id");

            migrationBuilder.RenameColumn(
                name: "TrainingId",
                table: "TrainingExercises",
                newName: "training_id");

            migrationBuilder.RenameColumn(
                name: "OrderIndex",
                table: "TrainingExercises",
                newName: "order_index");

            migrationBuilder.RenameColumn(
                name: "ExerciseId",
                table: "TrainingExercises",
                newName: "exercise_id");

            migrationBuilder.RenameIndex(
                name: "IX_TrainingExercises_TrainingId",
                table: "TrainingExercises",
                newName: "IX_TrainingExercises_training_id");

            migrationBuilder.RenameIndex(
                name: "IX_TrainingExercises_ExerciseId",
                table: "TrainingExercises",
                newName: "IX_TrainingExercises_exercise_id");

            migrationBuilder.AlterColumn<float>(
                name: "weight",
                table: "TrainingExercises",
                type: "real",
                nullable: false,
                oldClrType: typeof(decimal),
                oldType: "decimal(18,2)");

            migrationBuilder.AddColumn<string>(
                name: "comment",
                table: "TrainingExercises",
                type: "nvarchar(max)",
                nullable: true);

            migrationBuilder.AddForeignKey(
                name: "FK_TrainingExercises_Exercises_exercise_id",
                table: "TrainingExercises",
                column: "exercise_id",
                principalTable: "Exercises",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_TrainingExercises_Trainings_training_id",
                table: "TrainingExercises",
                column: "training_id",
                principalTable: "Trainings",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }
    }
}

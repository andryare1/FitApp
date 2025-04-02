using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace FitAppAPI.Migrations
{
    /// <inheritdoc />
    public partial class UpdateTrainingIdToGuid : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "Trainings",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Name = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    UserId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Trainings", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "TrainingExercises",
                columns: table => new
                {
                    id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    training_id = table.Column<int>(type: "int", nullable: false),
                    exercise_id = table.Column<int>(type: "int", nullable: false),
                    sets = table.Column<int>(type: "int", nullable: false),
                    reps = table.Column<int>(type: "int", nullable: false),
                    weight = table.Column<float>(type: "real", nullable: false),
                    comment = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    order_index = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_TrainingExercises", x => x.id);
                    table.ForeignKey(
                        name: "FK_TrainingExercises_Exercises_exercise_id",
                        column: x => x.exercise_id,
                        principalTable: "Exercises",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_TrainingExercises_Trainings_training_id",
                        column: x => x.training_id,
                        principalTable: "Trainings",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_TrainingExercises_exercise_id",
                table: "TrainingExercises",
                column: "exercise_id");

            migrationBuilder.CreateIndex(
                name: "IX_TrainingExercises_training_id",
                table: "TrainingExercises",
                column: "training_id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "TrainingExercises");

            migrationBuilder.DropTable(
                name: "Trainings");
        }
    }
}

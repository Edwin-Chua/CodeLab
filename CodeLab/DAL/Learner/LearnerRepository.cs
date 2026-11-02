using System.Data;
using System.Data.SqlClient;
using CodeLab.Models;
namespace CodeLab.DAL
{
    public class LearnerRepository
    {
        public void RecordDailyActivity(int learnerId, System.DateTime today)
        {
            const string sql = @"
SET XACT_ABORT ON;
BEGIN TRANSACTION;
IF EXISTS(SELECT 1 FROM dbo.Users WHERE Id=@id AND Role=N'Learner' AND Status=N'Active')
BEGIN
    IF NOT EXISTS(SELECT 1 FROM dbo.LearnerStats WITH (UPDLOCK,HOLDLOCK) WHERE LearnerId=@id)
        INSERT dbo.LearnerStats(LearnerId,StreakDays,LastActiveDate) VALUES(@id,1,@today);
    ELSE
        UPDATE dbo.LearnerStats
        SET StreakDays=CASE WHEN StreakDays<=0 THEN 1
                           WHEN LastActiveDate=@today THEN StreakDays
                           WHEN LastActiveDate=DATEADD(day,-1,@today) THEN StreakDays+1
                           ELSE 1 END,
            LastActiveDate=@today
        WHERE LearnerId=@id AND LastActiveDate<=@today;
END;
COMMIT TRANSACTION;";
            using(var connection=DatabaseHelper.GetConnection())
            using(var command=new SqlCommand(sql,connection))
            {
                command.Parameters.Add("@id",SqlDbType.Int).Value=learnerId;
                command.Parameters.Add("@today",SqlDbType.Date).Value=today.Date;
                connection.Open();command.ExecuteNonQuery();
            }
        }
        public LearnerDashboardData GetDashboard(int learnerId)
        {
            var data = new LearnerDashboardData { Level = 1, LevelTitle = "Novice Coder", Milestone = 500, Courses = new DataTable() };
            using (var connection = DatabaseHelper.GetConnection())
            {
                connection.Open();
                // Same filter as the course list below, so a locked course leaves the numbers and the list together
                using (var command = new SqlCommand(@"SELECT COUNT(*), COALESCE(SUM(CASE WHEN e.IsCompleted=1 THEN 1 ELSE 0 END),0) FROM dbo.CourseEnrollments e INNER JOIN dbo.Courses c ON c.Id=e.CourseId WHERE e.LearnerId=@id AND c.Status=N'Published'", connection))
                {
                    command.Parameters.Add("@id", SqlDbType.Int).Value = learnerId;
                    using (var reader = command.ExecuteReader()) if (reader.Read()) { data.Enrolled = reader.GetInt32(0); data.Completed = reader.GetInt32(1); }
                }
                using (var command = new SqlCommand("SELECT AchievementPoints, CurrentLevel, LevelTitle, NextMilestonePoints, StreakDays FROM dbo.LearnerStats WHERE LearnerId=@id", connection))
                {
                    command.Parameters.Add("@id", SqlDbType.Int).Value = learnerId;
                    using (var reader = command.ExecuteReader()) if (reader.Read())
                    {
                        data.Points = reader.GetInt32(0); data.Level = reader.GetInt32(1);
                        data.LevelTitle = reader.GetString(2); data.Milestone = reader.GetInt32(3); data.Streak = reader.GetInt32(4);
                    }
                }
                using (var command = new SqlCommand(@"SELECT c.Id,c.Title,c.Category,c.Difficulty,e.ProgressPercent,e.IsCompleted,nextLesson.Id AS LessonId,nextLesson.Title AS LessonTitle,nextLesson.Content AS LessonContent,nextLesson.DurationMinutes,c.ThumbnailUrl AS ThumbnailUrl,(SELECT FullName FROM dbo.Users WHERE Id=c.InstructorId) AS Instructor FROM dbo.CourseEnrollments e INNER JOIN dbo.Courses c ON c.Id=e.CourseId OUTER APPLY (SELECT TOP 1 l.Id,l.Title,l.Content,l.DurationMinutes,l.ThumbnailUrl FROM dbo.Lessons l WHERE l.CourseId=c.Id AND NOT EXISTS(SELECT 1 FROM dbo.LessonCompletions lc WHERE lc.LessonId=l.Id AND lc.LearnerId=e.LearnerId) ORDER BY l.OrderIndex,l.Id) nextLesson WHERE e.LearnerId=@id AND c.Status=N'Published' ORDER BY COALESCE((SELECT MAX(lc.CompletedAt) FROM dbo.LessonCompletions lc INNER JOIN dbo.Lessons l ON l.Id=lc.LessonId WHERE lc.LearnerId=e.LearnerId AND l.CourseId=c.Id),e.EnrolledAt) DESC,c.Id DESC", connection))
                {
                    command.Parameters.Add("@id", SqlDbType.Int).Value = learnerId;
                    using (var adapter = new SqlDataAdapter(command)) adapter.Fill(data.Courses);
                }
            }
            return data;
        }
    }
}

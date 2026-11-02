using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using CodeLab.Helpers;
using CodeLab.Models;

namespace CodeLab.DAL
{
    public class CourseRepository
    {
        /// <summary>
        /// Returns the course with this id, or null if there is none.
        /// </summary>
        public Course GetById(int courseId)
        {
            string query = @"SELECT Id, Title, Description, Category, Difficulty, InstructorId, Status,
                                    ThumbnailUrl, RejectionReason, LockReason, CreatedAt, UpdatedAt
                             FROM Courses
                             WHERE Id = @Id";

            using (SqlConnection connection = DatabaseHelper.GetConnection())
            {
                using (SqlCommand command = new SqlCommand(query, connection))
                {
                    command.Parameters.Add("@Id", SqlDbType.Int).Value = courseId;

                    connection.Open();
                    using (SqlDataReader reader = command.ExecuteReader())
                    {
                        if (!reader.Read())
                        {
                            return null;
                        }

                        return new Course
                        {
                            Id = Convert.ToInt32(reader["Id"]),
                            Title = reader["Title"].ToString(),
                            Description = reader["Description"].ToString(),
                            Category = reader["Category"].ToString(),
                            Difficulty = reader["Difficulty"].ToString(),
                            InstructorId = Convert.ToInt32(reader["InstructorId"]),
                            Status = reader["Status"].ToString(),
                            ThumbnailUrl = reader["ThumbnailUrl"] as string,
                            RejectionReason = reader["RejectionReason"] as string,
                            LockReason = reader["LockReason"] as string,
                            CreatedAt = Convert.ToDateTime(reader["CreatedAt"]),
                            UpdatedAt = Convert.ToDateTime(reader["UpdatedAt"])
                        };
                    }
                }
            }
        }

        /// <summary>
        /// Returns every Published course, newest first, with its lesson count.
        /// Only the columns guests may see are read.
        /// </summary>
        public List<Course> GetPublished()
        {
            List<Course> courses = new List<Course>();
            string query = @"SELECT c.Id, c.Title, c.Description, c.Category, c.Difficulty, c.ThumbnailUrl, c.CreatedAt,
                                    (SELECT COUNT(*) FROM Lessons l WHERE l.CourseId = c.Id) AS LessonCount
                             FROM Courses c
                             WHERE c.Status = @Published
                             ORDER BY c.CreatedAt DESC, c.Id DESC";

            using (SqlConnection connection = DatabaseHelper.GetConnection())
            {
                using (SqlCommand command = new SqlCommand(query, connection))
                {
                    command.Parameters.Add("@Published", SqlDbType.NVarChar, 20).Value = CourseStatuses.Published;

                    connection.Open();
                    using (SqlDataReader reader = command.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            courses.Add(new Course
                            {
                                Id = Convert.ToInt32(reader["Id"]),
                                Title = reader["Title"].ToString(),
                                Description = reader["Description"].ToString(),
                                Category = reader["Category"].ToString(),
                                Difficulty = reader["Difficulty"].ToString(),
                                Status = CourseStatuses.Published,
                                ThumbnailUrl = reader["ThumbnailUrl"] as string,
                                CreatedAt = Convert.ToDateTime(reader["CreatedAt"]),
                                LessonCount = Convert.ToInt32(reader["LessonCount"])
                            });
                        }
                    }
                }
            }

            return courses;
        }

        /// <summary>
        /// Saves a new course as a Draft and returns its id, or 0 if it could not be saved.
        /// </summary>
        public int Insert(Course course)
        {
            string query = @"INSERT INTO Courses (Title, Description, Category, Difficulty, InstructorId, Status, ThumbnailUrl)
                             OUTPUT INSERTED.Id
                             VALUES (@Title, @Description, @Category, @Difficulty, @InstructorId, @Status, @ThumbnailUrl)";

            try
            {
                using (SqlConnection connection = DatabaseHelper.GetConnection())
                {
                    using (SqlCommand command = new SqlCommand(query, connection))
                    {
                        AddCourseParameters(command, course);
                        command.Parameters.Add("@InstructorId", SqlDbType.Int).Value = course.InstructorId;
                        command.Parameters.Add("@Status", SqlDbType.NVarChar, 20).Value = CourseStatuses.Draft;

                        connection.Open();
                        return Convert.ToInt32(command.ExecuteScalar());
                    }
                }
            }
            catch (SqlException sqlException)
            {
                LogHelper.LogError("CourseRepository.Insert failure", sqlException);
                return 0;
            }
        }

        /// <summary>
        /// Updates the details of a Draft course that belongs to the given tutor. Returns false
        /// if nothing was saved (wrong owner, or the course is no longer a Draft).
        /// </summary>
        public bool UpdateDraft(Course course)
        {
            string query = @"UPDATE Courses
                                SET Title = @Title, Description = @Description, Category = @Category,
                                    Difficulty = @Difficulty, ThumbnailUrl = @ThumbnailUrl, UpdatedAt = SYSUTCDATETIME()
                              WHERE Id = @Id AND InstructorId = @InstructorId AND Status = @Draft";

            try
            {
                using (SqlConnection connection = DatabaseHelper.GetConnection())
                {
                    using (SqlCommand command = new SqlCommand(query, connection))
                    {
                        AddCourseParameters(command, course);
                        command.Parameters.Add("@Id", SqlDbType.Int).Value = course.Id;
                        command.Parameters.Add("@InstructorId", SqlDbType.Int).Value = course.InstructorId;
                        command.Parameters.Add("@Draft", SqlDbType.NVarChar, 20).Value = CourseStatuses.Draft;

                        connection.Open();
                        return command.ExecuteNonQuery() > 0;
                    }
                }
            }
            catch (SqlException sqlException)
            {
                LogHelper.LogError("CourseRepository.UpdateDraft failure", sqlException);
                return false;
            }
        }

        /// <summary>
        /// Moves a tutor's Draft course to Pending Review and clears any feedback from an earlier
        /// rejection. Only works while the course has at least one lesson. Returns false if nothing changed.
        /// </summary>
        public bool SubmitForReview(int courseId, int tutorId)
        {
            string query = @"UPDATE Courses
                                SET Status = @PendingReview, RejectionReason = NULL, UpdatedAt = SYSUTCDATETIME()
                              WHERE Id = @Id AND InstructorId = @InstructorId
                                AND Status = @Draft
                                AND EXISTS (SELECT 1 FROM Lessons WHERE CourseId = @Id)";

            try
            {
                using (SqlConnection connection = DatabaseHelper.GetConnection())
                {
                    using (SqlCommand command = new SqlCommand(query, connection))
                    {
                        command.Parameters.Add("@Id", SqlDbType.Int).Value = courseId;
                        command.Parameters.Add("@InstructorId", SqlDbType.Int).Value = tutorId;
                        command.Parameters.Add("@PendingReview", SqlDbType.NVarChar, 20).Value = CourseStatuses.PendingReview;
                        command.Parameters.Add("@Draft", SqlDbType.NVarChar, 20).Value = CourseStatuses.Draft;

                        connection.Open();
                        return command.ExecuteNonQuery() > 0;
                    }
                }
            }
            catch (SqlException sqlException)
            {
                LogHelper.LogError("CourseRepository.SubmitForReview failure", sqlException);
                return false;
            }
        }

        private static void AddCourseParameters(SqlCommand command, Course course)
        {
            command.Parameters.Add("@Title", SqlDbType.NVarChar, 200).Value = course.Title;
            command.Parameters.Add("@Description", SqlDbType.NVarChar, -1).Value = course.Description;
            command.Parameters.Add("@Category", SqlDbType.NVarChar, 80).Value = course.Category;
            command.Parameters.Add("@Difficulty", SqlDbType.NVarChar, 20).Value = course.Difficulty;
            command.Parameters.Add("@ThumbnailUrl", SqlDbType.NVarChar, 500).Value = (object)course.ThumbnailUrl ?? DBNull.Value;
        }

        /// <summary>
        /// Returns the courses one tutor owns, most recently updated first,
        /// with how many lessons and enrolled students each one has.
        /// </summary>
        public List<TutorCourseSummary> GetCourseSummariesByTutor(int tutorId)
        {
            List<TutorCourseSummary> courses = new List<TutorCourseSummary>();
            string query = @"SELECT c.Id, c.Title, c.Category, c.Difficulty, c.Status, c.UpdatedAt, c.ThumbnailUrl,
                                    CASE WHEN c.RejectionReason IS NULL THEN 0 ELSE 1 END AS HasFeedback,
                                    c.LockReason,
                                    (SELECT COUNT(*) FROM Lessons l WHERE l.CourseId = c.Id) AS LessonCount,
                                    (SELECT COUNT(*) FROM CourseEnrollments e WHERE e.CourseId = c.Id) AS StudentCount
                             FROM Courses c
                             WHERE c.InstructorId = @TutorId
                             ORDER BY c.UpdatedAt DESC, c.Id DESC";

            using (SqlConnection connection = DatabaseHelper.GetConnection())
            {
                using (SqlCommand command = new SqlCommand(query, connection))
                {
                    command.Parameters.Add("@TutorId", SqlDbType.Int).Value = tutorId;

                    connection.Open();
                    using (SqlDataReader reader = command.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            courses.Add(new TutorCourseSummary
                            {
                                Id = Convert.ToInt32(reader["Id"]),
                                Title = reader["Title"].ToString(),
                                Category = reader["Category"].ToString(),
                                Difficulty = reader["Difficulty"].ToString(),
                                Status = reader["Status"].ToString(),
                                LessonCount = Convert.ToInt32(reader["LessonCount"]),
                                StudentCount = Convert.ToInt32(reader["StudentCount"]),
                                UpdatedAt = Convert.ToDateTime(reader["UpdatedAt"]),
                                HasFeedback = Convert.ToInt32(reader["HasFeedback"]) == 1,
                                LockReason = reader["LockReason"] as string,
                                ThumbnailUrl = reader["ThumbnailUrl"] as string
                            });
                        }
                    }
                }
            }

            return courses;
        }
    }
}

using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using CodeLab.Helpers;
using CodeLab.Models;

namespace CodeLab.DAL
{
    public class UserAdminRepository
    {
        // HasActivity covers every table that points at Users without ON DELETE CASCADE. TutorProfiles and
        // LearnerStats cascade, so they are left out. A table added with such a link must be added here too.
        private const string SelectUsers =
            @"SELECT u.Id, u.FullName, u.Username, u.Email, u.Role, u.Status, u.AvatarUrl, u.JoinedDate, u.LastLogin,
                     (SELECT COUNT(*) FROM Courses c WHERE c.InstructorId = u.Id) AS CourseCount,
                     CASE WHEN EXISTS (SELECT 1 FROM Courses WHERE InstructorId = u.Id)
                            OR EXISTS (SELECT 1 FROM CourseEnrollments WHERE LearnerId = u.Id)
                            OR EXISTS (SELECT 1 FROM LessonCompletions WHERE LearnerId = u.Id)
                            OR EXISTS (SELECT 1 FROM Quizzes WHERE CreatedByUserId = u.Id)
                            OR EXISTS (SELECT 1 FROM QuizAttempts WHERE LearnerId = u.Id)
                            OR EXISTS (SELECT 1 FROM CodeSubmissions WHERE LearnerId = u.Id)
                            OR EXISTS (SELECT 1 FROM DiscussionPosts WHERE AuthorId = u.Id)
                            OR EXISTS (SELECT 1 FROM DiscussionReplies WHERE AuthorId = u.Id)
                            OR EXISTS (SELECT 1 FROM LearnerBadges WHERE LearnerId = u.Id)
                            OR EXISTS (SELECT 1 FROM AuditLogs WHERE UserId = u.Id)
                          THEN 1 ELSE 0 END AS HasActivity
              FROM Users u";

        /// <summary>
        /// Returns every account, newest first. A search text, when given, must appear in the full
        /// name, username or email.
        /// </summary>
        public List<AdminUserRow> GetUsers(string search)
        {
            // CHARINDEX rather than LIKE, so a typed % or _ is treated as plain text
            string query = SelectUsers + @"
                            WHERE @Search IS NULL
                               OR CHARINDEX(@Search, u.FullName) > 0
                               OR CHARINDEX(@Search, u.Username) > 0
                               OR CHARINDEX(@Search, u.Email) > 0
                            ORDER BY u.JoinedDate DESC, u.Id DESC";

            List<AdminUserRow> users = new List<AdminUserRow>();

            using (SqlConnection connection = DatabaseHelper.GetConnection())
            {
                using (SqlCommand command = new SqlCommand(query, connection))
                {
                    command.Parameters.Add("@Search", SqlDbType.NVarChar, 200).Value = (object)search ?? DBNull.Value;

                    connection.Open();
                    using (SqlDataReader reader = command.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            users.Add(ReadUser(reader));
                        }
                    }
                }
            }

            return users;
        }

        /// <summary>
        /// Returns one account, or null if there is none with this id.
        /// </summary>
        public AdminUserRow GetById(int userId)
        {
            string query = SelectUsers + " WHERE u.Id = @Id";

            using (SqlConnection connection = DatabaseHelper.GetConnection())
            {
                using (SqlCommand command = new SqlCommand(query, connection))
                {
                    command.Parameters.Add("@Id", SqlDbType.Int).Value = userId;

                    connection.Open();
                    using (SqlDataReader reader = command.ExecuteReader())
                    {
                        return reader.Read() ? ReadUser(reader) : null;
                    }
                }
            }
        }

        /// <summary>
        /// True if an account other than this one already uses the email address (case is ignored).
        /// </summary>
        public bool IsEmailTakenByOther(int userId, string email)
        {
            string query = @"SELECT COUNT(*) FROM Users WHERE Email = @Email AND Id <> @Id";

            using (SqlConnection connection = DatabaseHelper.GetConnection())
            {
                using (SqlCommand command = new SqlCommand(query, connection))
                {
                    command.Parameters.Add("@Email", SqlDbType.NVarChar, 255).Value = email;
                    command.Parameters.Add("@Id", SqlDbType.Int).Value = userId;

                    connection.Open();
                    return Convert.ToInt32(command.ExecuteScalar()) > 0;
                }
            }
        }

        /// <summary>
        /// Saves an account's full name, email and role. Returns false if it could not be saved.
        /// </summary>
        public bool UpdateDetails(int userId, string fullName, string email, string role)
        {
            string query = @"UPDATE Users SET FullName = @FullName, Email = @Email, Role = @Role WHERE Id = @Id";

            try
            {
                using (SqlConnection connection = DatabaseHelper.GetConnection())
                {
                    using (SqlCommand command = new SqlCommand(query, connection))
                    {
                        command.Parameters.Add("@FullName", SqlDbType.NVarChar, 120).Value = fullName;
                        command.Parameters.Add("@Email", SqlDbType.NVarChar, 255).Value = email;
                        command.Parameters.Add("@Role", SqlDbType.NVarChar, 20).Value = role;
                        command.Parameters.Add("@Id", SqlDbType.Int).Value = userId;

                        connection.Open();
                        return command.ExecuteNonQuery() > 0;
                    }
                }
            }
            catch (SqlException sqlException)
            {
                LogHelper.LogError("UserAdminRepository.UpdateDetails failure", sqlException);
                return false;
            }
        }

        /// <summary>
        /// Suspends an Active account. Returns false if it was not Active or could not be saved.
        /// </summary>
        public bool Suspend(int userId)
        {
            return ChangeStatus(userId, UserStatuses.Active, UserStatuses.Suspended, "UserAdminRepository.Suspend failure");
        }

        /// <summary>
        /// Reactivates a Suspended account. Returns false if it was not Suspended or could not be saved.
        /// </summary>
        public bool Reactivate(int userId)
        {
            return ChangeStatus(userId, UserStatuses.Suspended, UserStatuses.Active, "UserAdminRepository.Reactivate failure");
        }

        /// <summary>
        /// Deletes an account. Its TutorProfiles and LearnerStats rows cascade. Returns false if nothing
        /// was deleted, which includes an account that gained activity since it was checked.
        /// </summary>
        public bool Delete(int userId)
        {
            string query = @"DELETE FROM Users WHERE Id = @Id";

            try
            {
                using (SqlConnection connection = DatabaseHelper.GetConnection())
                {
                    using (SqlCommand command = new SqlCommand(query, connection))
                    {
                        command.Parameters.Add("@Id", SqlDbType.Int).Value = userId;

                        connection.Open();
                        return command.ExecuteNonQuery() > 0;
                    }
                }
            }
            catch (SqlException sqlException)
            {
                LogHelper.LogError("UserAdminRepository.Delete failure", sqlException);
                return false;
            }
        }

        private static bool ChangeStatus(int userId, string fromStatus, string toStatus, string errorContext)
        {
            string query = @"UPDATE Users SET Status = @ToStatus WHERE Id = @Id AND Status = @FromStatus";

            try
            {
                using (SqlConnection connection = DatabaseHelper.GetConnection())
                {
                    using (SqlCommand command = new SqlCommand(query, connection))
                    {
                        command.Parameters.Add("@ToStatus", SqlDbType.NVarChar, 20).Value = toStatus;
                        command.Parameters.Add("@FromStatus", SqlDbType.NVarChar, 20).Value = fromStatus;
                        command.Parameters.Add("@Id", SqlDbType.Int).Value = userId;

                        connection.Open();
                        return command.ExecuteNonQuery() > 0;
                    }
                }
            }
            catch (SqlException sqlException)
            {
                LogHelper.LogError(errorContext, sqlException);
                return false;
            }
        }

        private static AdminUserRow ReadUser(SqlDataReader reader)
        {
            return new AdminUserRow
            {
                Id = Convert.ToInt32(reader["Id"]),
                FullName = reader["FullName"].ToString(),
                Username = reader["Username"].ToString(),
                Email = reader["Email"].ToString(),
                Role = reader["Role"].ToString(),
                Status = reader["Status"].ToString(),
                AvatarUrl = reader["AvatarUrl"] == DBNull.Value ? null : reader["AvatarUrl"].ToString(),
                JoinedDate = Convert.ToDateTime(reader["JoinedDate"]),
                LastLogin = reader["LastLogin"] == DBNull.Value ? (DateTime?)null : Convert.ToDateTime(reader["LastLogin"]),
                CourseCount = Convert.ToInt32(reader["CourseCount"]),
                HasActivity = Convert.ToInt32(reader["HasActivity"]) == 1
            };
        }
    }
}

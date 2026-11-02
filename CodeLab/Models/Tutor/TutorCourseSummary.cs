using System;

namespace CodeLab.Models
{
    /// <summary>
    /// One row of the tutor's course list, with lesson and student counts.
    /// </summary>
    public class TutorCourseSummary
    {
        public int Id { get; set; }
        public string Title { get; set; }
        public string Category { get; set; }
        public string Difficulty { get; set; }
        public string Status { get; set; }
        public int LessonCount { get; set; }
        public int StudentCount { get; set; }
        public DateTime UpdatedAt { get; set; }

        // True when an admin sent the course back to Draft with feedback (Courses.RejectionReason)
        public bool HasFeedback { get; set; }

        // The admin's reason when the course is Locked (Courses.LockReason); null otherwise
        public string LockReason { get; set; }

        // App-relative path of the cover image, or null to show a placeholder
        public string ThumbnailUrl { get; set; }
    }
}

using System;

namespace CodeLab.Models
{
    /// <summary>
    /// One course as an admin sees it: the course, its tutor, and its lesson and student counts.
    /// </summary>
    public class AdminCourseRow
    {
        public int Id { get; set; }
        public string Title { get; set; }
        public string Description { get; set; }
        public string Category { get; set; }
        public string Difficulty { get; set; }
        public string Status { get; set; }

        // App-relative path of the cover image, e.g. "~/Uploads/Covers/c2-....png"; null if none
        public string ThumbnailUrl { get; set; }

        public string LockReason { get; set; }
        public string RejectionReason { get; set; }

        // UTC. Submitting a course sets it, so for a Pending Review course this is when it joined the queue
        public DateTime UpdatedAt { get; set; }

        public string TutorName { get; set; }
        public string TutorEmail { get; set; }
        public int LessonCount { get; set; }
        public int StudentCount { get; set; }

        // What an admin may do in this status. A course can be deleted in any status.
        public bool CanApproveOrReject
        {
            get { return Status == CourseStatuses.PendingReview; }
        }

        public bool CanLock
        {
            get { return Status == CourseStatuses.Published; }
        }

        public bool CanUnlock
        {
            get { return Status == CourseStatuses.Locked; }
        }

        // True if there is a quick status-change action (Approve, Lock, or Unlock)
        public bool HasMiddleAction
        {
            get { return CanApproveOrReject || CanLock || CanUnlock; }
        }

        // Actionable "Review" for pending moderation; read-only "View" otherwise
        public string PrimaryActionText
        {
            get { return CanApproveOrReject ? "Review" : "View"; }
        }

        /// <summary>
        /// The admin's feedback that applies to the current status: why it is Locked, or why a Draft was sent back.
        /// </summary>
        public string ModerationNote
        {
            get
            {
                if (Status == CourseStatuses.Locked)
                {
                    return LockReason;
                }

                return Status == CourseStatuses.Draft ? RejectionReason : null;
            }
        }
    }
}

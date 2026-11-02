using System;
using System.Web;
using CodeLab.Models;

namespace CodeLab.Helpers
{
    /// <summary>
    /// Small formatting helpers for showing data on pages.
    /// </summary>
    public static class DisplayHelper
    {
        /// <summary>
        /// A UTC time as "Just now", "5 min ago", "3 days ago", or "12 Oct 2026" when older than a week.
        /// </summary>
        public static string TimeAgo(DateTime utc)
        {
            DateTime time = DateTime.SpecifyKind(utc, DateTimeKind.Utc);
            TimeSpan age = DateTime.UtcNow - time;
            if (age.TotalMinutes < 1) return "Just now";
            if (age.TotalHours < 1) return (int)age.TotalMinutes + " min ago";
            if (age.TotalDays < 1) return (int)age.TotalHours + (age.TotalHours < 2 ? " hour ago" : " hours ago");
            if (age.TotalDays < 7) return (int)age.TotalDays + (age.TotalDays < 2 ? " day ago" : " days ago");
            return time.ToLocalTime().ToString("d MMM yyyy");
        }

        /// <summary>
        /// Up to two initials for an avatar, e.g. "Helena Zhang" gives "HZ".
        /// </summary>
        public static string Initials(string name)
        {
            string[] words = (name ?? string.Empty).Split(new[] { ' ' }, StringSplitOptions.RemoveEmptyEntries);
            if (words.Length == 0)
            {
                return "?";
            }

            string first = words[0].Substring(0, 1);
            return words.Length == 1
                ? first.ToUpperInvariant()
                : (first + words[words.Length - 1].Substring(0, 1)).ToUpperInvariant();
        }

        /// <summary>
        /// Renders an admin avatar element: a circular image if AvatarUrl is present, or initials in a circle otherwise.
        /// </summary>
        public static string AvatarHtml(string name, string avatarUrl, string extraCssClass = null)
        {
            string initials = Initials(name);
            string css = string.IsNullOrWhiteSpace(extraCssClass) ? "cl-admin-avatar" : "cl-admin-avatar " + extraCssClass;

            if (string.IsNullOrWhiteSpace(avatarUrl))
            {
                return "<span class=\"" + css + "\" aria-hidden=\"true\">" + HttpUtility.HtmlEncode(initials) + "</span>";
            }

            string browserUrl = avatarUrl.StartsWith("~/", StringComparison.Ordinal)
                ? VirtualPathUtility.ToAbsolute(avatarUrl)
                : avatarUrl;

            return "<span class=\"" + css + "\"><img src=\"" + HttpUtility.HtmlAttributeEncode(browserUrl)
                + "\" alt=\"\" referrerpolicy=\"no-referrer\" onerror=\"this.style.display='none';this.parentElement.textContent='"
                + HttpUtility.JavaScriptStringEncode(initials) + "';\" /></span>";
        }

        /// <summary>
        /// The first part of a long text, cut at a word and ending in "...".
        /// </summary>
        public static string Excerpt(string text, int maxLength)
        {
            if (string.IsNullOrEmpty(text) || text.Length <= maxLength)
            {
                return text;
            }

            int cut = text.LastIndexOf(' ', maxLength);
            return text.Substring(0, cut > 0 ? cut : maxLength).TrimEnd() + "...";
        }

        /// <summary>
        /// The Admin.css badge colour for a course status.
        /// </summary>
        public static string CourseBadgeCss(string status)
        {
            switch (status)
            {
                case CourseStatuses.Published: return "cl-admin-badge-approved";
                case CourseStatuses.PendingReview: return "cl-admin-badge-pending";
                case CourseStatuses.Locked: return "cl-admin-badge-rejected";
                default: return "cl-admin-badge-neutral";
            }
        }

        /// <summary>
        /// The Admin.css badge colour for a user's role.
        /// </summary>
        public static string RoleBadgeCss(string role)
        {
            switch (role)
            {
                case UserRoles.Admin: return "cl-admin-badge-accent";
                case UserRoles.Tutor: return "cl-admin-badge-info";
                default: return "cl-admin-badge-neutral";
            }
        }

        /// <summary>
        /// The Admin.css badge colour for an account status.
        /// </summary>
        public static string UserStatusBadgeCss(string status)
        {
            switch (status)
            {
                case UserStatuses.Active: return "cl-admin-badge-approved";
                case UserStatuses.Suspended: return "cl-admin-badge-rejected";
                default: return "cl-admin-badge-pending";
            }
        }

        /// <summary>
        /// The Admin.css badge colour for an audit log category.
        /// </summary>
        public static string AuditCategoryBadgeCss(string category)
        {
            switch (category)
            {
                case AuditCategories.Security: return "cl-admin-badge-rejected";
                case AuditCategories.Administrative: return "cl-admin-badge-info";
                case AuditCategories.Deletion: return "cl-admin-badge-pending";
                default: return "cl-admin-badge-neutral";
            }
        }

        /// <summary>
        /// When a user last logged in, as TimeAgo text, or "Never".
        /// </summary>
        public static string LastLogin(DateTime? utc)
        {
            return utc.HasValue ? TimeAgo(utc.Value) : "Never";
        }

        /// <summary>
        /// The OnClientClick script that asks an admin to confirm deleting a course.
        /// </summary>
        public static string CourseDeleteConfirm(int studentCount)
        {
            string students = studentCount == 0
                ? "No students are enrolled."
                : studentCount + (studentCount == 1 ? " enrolled student loses access." : " enrolled students lose access.");

            return "return confirm('Delete this course permanently, with its lessons, quiz, challenge and discussions? "
                + students + "');";
        }
    }
}

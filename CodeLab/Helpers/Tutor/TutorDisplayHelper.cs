using System;
using System.Collections.Generic;
using System.Web;
using CodeLab.Models;

namespace CodeLab.Helpers
{
    /// <summary>
    /// Small display pieces shared by the Tutor pages: avatars, badges, breadcrumbs, dates and names.
    /// Every value from the database is HTML-encoded here.
    /// </summary>
    public static class TutorDisplayHelper
    {
        // ---------- People ----------

        // A user's photo, or their initials when there is no photo
        public static string AvatarHtml(string name, string avatarUrl)
        {
            return string.IsNullOrEmpty(avatarUrl)
                ? "<span class=\"cl-avatar cl-avatar-sm\" aria-hidden=\"true\">" + HttpUtility.HtmlEncode(Initials(name)) + "</span>"
                : "<img class=\"cl-avatar cl-avatar-sm\" src=\"" + HttpUtility.HtmlAttributeEncode(ToBrowserUrl(avatarUrl)) + "\" alt=\"\" />";
        }

        // Learner's photo (or initials), name and username
        public static string LearnerHtml(string name, string username, string avatarUrl)
        {
            string usernameHtml = string.IsNullOrEmpty(username)
                ? string.Empty
                : "<small>@" + HttpUtility.HtmlEncode(username) + "</small>";

            return "<span class=\"cl-learner cl-learner-2line\">" + AvatarHtml(name, avatarUrl)
                + "<span><strong>" + HttpUtility.HtmlEncode(name) + "</strong>" + usernameHtml + "</span></span>";
        }

        // First letters of the first and last name, e.g. "Grace Lee" -> "GL"
        public static string Initials(string name, string fallback = "?")
        {
            string[] words = (name ?? string.Empty).Split(new[] { ' ' }, StringSplitOptions.RemoveEmptyEntries);
            if (words.Length == 0) return fallback;
            string initials = words[0].Substring(0, 1);
            if (words.Length > 1) initials += words[words.Length - 1].Substring(0, 1);
            return initials.ToUpperInvariant();
        }

        // ---------- Badges ----------

        // Course status colours: green = live, amber = waiting, red = blocked, grey = draft
        public static string CourseStatusCss(string status)
        {
            switch (status)
            {
                case CourseStatuses.Published: return "cl-badge-success";
                case CourseStatuses.PendingReview: return "cl-badge-warning";
                case CourseStatuses.Locked: return "cl-badge-danger";
                default: return "cl-badge-neutral";
            }
        }

        public static string PassBadge(bool passed)
        {
            return passed
                ? "<span class=\"cl-badge cl-status cl-badge-success\">Passed</span>"
                : "<span class=\"cl-badge cl-status cl-badge-danger\">Failed</span>";
        }

        // Code submission status: Passed (green), Failed (amber), Error (red)
        public static string SubmissionStatusHtml(string status)
        {
            switch (status)
            {
                case "Passed": return "<span class=\"cl-badge cl-status cl-badge-success\">Passed</span>";
                case "Failed": return "<span class=\"cl-badge cl-status cl-badge-warning\">Failed</span>";
                default: return "<span class=\"cl-badge cl-status cl-badge-danger\">" + HttpUtility.HtmlEncode(status) + "</span>";
            }
        }

        // ---------- Results pages ----------

        // "5 out of 10": learners who completed, out of learners enrolled in the course
        public static string OutOfHtml(int completed, int enrolled)
        {
            if (enrolled == 0)
            {
                return "<span class=\"text-muted\">No learners enrolled</span>";
            }

            return "<span class=\"cl-completed\">" + completed + " out of " + enrolled + "</span>";
        }

        // Note under a stat card, e.g. "Out of 10 enrolled learners"
        public static string OutOfEnrolled(int enrolled)
        {
            return enrolled == 0 ? "No learners enrolled yet"
                : "Out of " + enrolled + (enrolled == 1 ? " enrolled learner" : " enrolled learners");
        }

        // <option> tags for a course filter: each course once, A to Z (the value is the course title)
        public static string CourseOptionsHtml(IEnumerable<string> courseTitles)
        {
            SortedSet<string> titles = new SortedSet<string>(StringComparer.OrdinalIgnoreCase);
            foreach (string title in courseTitles)
            {
                if (!string.IsNullOrWhiteSpace(title)) titles.Add(title);
            }

            System.Text.StringBuilder html = new System.Text.StringBuilder();
            foreach (string title in titles)
            {
                html.Append("<option value=\"").Append(HttpUtility.HtmlAttributeEncode(title)).Append("\">")
                    .Append(HttpUtility.HtmlEncode(title)).Append("</option>");
            }

            return html.ToString();
        }

        // One breadcrumb link followed by the ">" separator
        public static string Crumb(string text, string url)
        {
            return "<a href=\"" + HttpUtility.HtmlAttributeEncode(url) + "\">" + HttpUtility.HtmlEncode(text) + "</a>"
                + "<i data-lucide=\"chevron-right\" class=\"cl-icon\" aria-hidden=\"true\"></i>";
        }

        // ---------- Text ----------

        // Display name of a code language key, e.g. "typescript" -> "TypeScript"
        public static string LanguageName(string key)
        {
            KeyValuePair<string, string> language = LessonOptions.CodeLanguages.Find(l => l.Key == key);
            return language.Key != null ? language.Value : key;
        }

        // 1st, 2nd, 3rd, 4th ... 11th, 12th, 13th ... 21st
        public static string Ordinal(int number)
        {
            int lastTwo = number % 100;
            string suffix = lastTwo >= 11 && lastTwo <= 13 ? "th"
                : number % 10 == 1 ? "st"
                : number % 10 == 2 ? "nd"
                : number % 10 == 3 ? "rd"
                : "th";
            return number + suffix;
        }

        // ---------- Dates (stored in UTC, shown in local time) ----------

        // e.g. "5 min ago", "3 days ago", "12 Oct 2026"
        public static string TimeAgo(DateTime utc)
        {
            TimeSpan age = DateTime.UtcNow - DateTime.SpecifyKind(utc, DateTimeKind.Utc);
            if (age.TotalMinutes < 1) return "Just now";
            if (age.TotalHours < 1) return (int)age.TotalMinutes + " min ago";
            if (age.TotalDays < 1) return (int)age.TotalHours + (age.TotalHours < 2 ? " hour ago" : " hours ago");
            if (age.TotalDays < 7) return (int)age.TotalDays + (age.TotalDays < 2 ? " day ago" : " days ago");
            return LocalDate(utc);
        }

        // e.g. "12 Oct 2026, 3:45 PM"
        public static string LocalDateTime(DateTime utc)
        {
            return ToLocal(utc).ToString("d MMM yyyy, h:mm tt");
        }

        // e.g. "12 Oct 2026"
        public static string LocalDate(DateTime utc)
        {
            return ToLocal(utc).ToString("d MMM yyyy");
        }

        // e.g. "3:45 PM"
        public static string LocalTime(DateTime utc)
        {
            return ToLocal(utc).ToString("h:mm tt");
        }

        private static DateTime ToLocal(DateTime utc)
        {
            return DateTime.SpecifyKind(utc, DateTimeKind.Utc).ToLocalTime();
        }

        private static string ToBrowserUrl(string url)
        {
            return url.StartsWith("~/", StringComparison.Ordinal) ? VirtualPathUtility.ToAbsolute(url) : url;
        }
    }
}

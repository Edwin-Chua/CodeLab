using System;
using System.Collections.Generic;
using System.Web;
using System.Web.UI;
using CodeLab.BLL;
using CodeLab.Helpers;
using CodeLab.Models;

namespace CodeLab.Modules.Tutor
{
    public partial class Dashboard : Page
    {
        private const string CourseEditorPage = "CourseEditor";
        private const string LessonEditorPage = "LessonEditor";

        // Background colours for courses without a cover image, picked by course id
        private static readonly string[] CoverTones = { "cl-cover-tone-1", "cl-cover-tone-2", "cl-cover-tone-3", "cl-cover-tone-4" };

        protected void Page_Load(object sender, EventArgs e)
        {
            if (IsPostBack)
            {
                return;
            }

            litGreeting.Text = GetGreeting();
            litTutorName.Text = Master.TutorName;
            SetUpCreateCourseButton();
            BindDashboard();
        }

        private void SetUpCreateCourseButton()
        {
            hlCreateCourse.NavigateUrl = "~/Modules/Tutor/" + CourseEditorPage;

            if (!CanManageCourses())
            {
                hlCreateCourse.Enabled = false;
                hlCreateCourse.CssClass += " disabled";
                hlCreateCourse.Attributes["aria-disabled"] = "true";
            }
        }

        private void BindDashboard()
        {
            OperationResult<TutorDashboard> result = new TutorManager().GetDashboard();

            if (!result.Success)
            {
                lblMessage.Text = HttpUtility.HtmlEncode(result.Message);
                lblMessage.Visible = true;
                phNoCourses.Visible = true;
                litSummary.Text = "Your dashboard could not be loaded.";
                return;
            }

            TutorDashboard dashboard = result.Data;
            List<TutorCourseSummary> courses = dashboard.Courses;

            // Headline numbers
            litCourseCount.Text = dashboard.CourseCount.ToString();
            litPublishedNote.Text = dashboard.PublishedCount + " published";
            litStudentCount.Text = dashboard.StudentCount.ToString();
            litCompletedCount.Text = dashboard.CompletedCount.ToString();
            litCompletedNote.Text = dashboard.EnrollmentCount == 0
                ? "No enrolments yet"
                : dashboard.CompletedCount + " out of " + dashboard.EnrollmentCount + " completed";
            litForumPostCount.Text = dashboard.ForumPostCount.ToString();

            // Counts per status, for the filter chips, the pipeline and the banner
            int drafts = courses.FindAll(c => c.Status == CourseStatuses.Draft).Count;
            int pending = courses.FindAll(c => c.Status == CourseStatuses.PendingReview).Count;
            int published = courses.FindAll(c => c.Status == CourseStatuses.Published).Count;
            int locked = courses.FindAll(c => c.Status == CourseStatuses.Locked).Count;

            litCountAll.Text = courses.Count.ToString();
            litCountDraft.Text = drafts.ToString();
            litCountPending.Text = pending.ToString();
            litCountPublished.Text = published.ToString();
            litSummary.Text = BuildSummary(courses.Count, drafts, pending, published);

            // Course cards
            bool hasCourses = courses.Count > 0;
            rptCourses.Visible = hasCourses;
            phNoCourses.Visible = !hasCourses;
            rptCourses.DataSource = courses;
            rptCourses.DataBind();

            // Pipeline
            litPipelineTotal.Text = courses.Count == 1 ? "1 course" : courses.Count + " courses";
            rptPipeline.DataSource = new List<PipelineRow>
            {
                new PipelineRow("Draft", drafts, courses.Count, "cl-tone-neutral"),
                new PipelineRow("In review", pending, courses.Count, "cl-tone-amber"),
                new PipelineRow("Published", published, courses.Count, "cl-tone-green"),
                new PipelineRow("Locked", locked, courses.Count, "cl-tone-red")
            };
            rptPipeline.DataBind();

            // Things the tutor should act on
            List<AttentionItem> attention = BuildAttentionList(courses);
            rptAttention.DataSource = attention;
            rptAttention.DataBind();
            rptAttention.Visible = attention.Count > 0;
            phAllClear.Visible = attention.Count == 0;
        }

        // Drafts with admin feedback first, then drafts without lessons, then courses waiting for review
        private List<AttentionItem> BuildAttentionList(List<TutorCourseSummary> courses)
        {
            List<AttentionItem> items = new List<AttentionItem>();
            bool canManage = CanManageCourses();

            foreach (TutorCourseSummary course in courses)
            {
                if (course.Status == CourseStatuses.Draft && course.HasFeedback)
                {
                    items.Add(new AttentionItem(course.Title, "An admin asked for changes", "message-square-warning",
                        "cl-tone-red", CourseUrl(course.Id)));
                }
                else if (course.Status == CourseStatuses.Locked)
                {
                    // Same red as admin feedback; the course page shows the full reason
                    string text = string.IsNullOrWhiteSpace(course.LockReason)
                        ? "An admin locked this course"
                        : "Locked by an admin: " + Shorten(course.LockReason.Trim(), 80);
                    items.Add(new AttentionItem(course.Title, text, "lock", "cl-tone-red", CourseUrl(course.Id)));
                }
            }

            foreach (TutorCourseSummary course in courses)
            {
                if (course.Status == CourseStatuses.Draft && course.LessonCount == 0 && !course.HasFeedback)
                {
                    string url = canManage && Master.IsPageAvailable(LessonEditorPage)
                        ? Master.GetPageUrl(LessonEditorPage) + "?courseId=" + course.Id
                        : CourseUrl(course.Id);
                    items.Add(new AttentionItem(course.Title, "Add a lesson so it can be submitted", "notebook-pen",
                        "cl-tone-amber", url));
                }
            }

            foreach (TutorCourseSummary course in courses)
            {
                if (course.Status == CourseStatuses.PendingReview)
                {
                    items.Add(new AttentionItem(course.Title, "Waiting for an admin to review", "hourglass",
                        "cl-tone-blue", CourseUrl(course.Id)));
                }
            }

            return items.Count > 6 ? items.GetRange(0, 6) : items;
        }

        // Cuts long text to max characters, ending in "…"
        private static string Shorten(string text, int max)
        {
            return text.Length <= max ? text : text.Substring(0, max - 1).TrimEnd() + "…";
        }

        private static string BuildSummary(int total, int drafts, int pending, int published)
        {
            if (total == 0)
            {
                return "Create your first course to start teaching on CodeLab.";
            }

            List<string> parts = new List<string>();
            if (published > 0) parts.Add(published + " published");
            if (pending > 0) parts.Add(pending + " in review");
            if (drafts > 0) parts.Add(drafts + (drafts == 1 ? " draft" : " drafts"));

            return "You have " + (total == 1 ? "1 course" : total + " courses") + ": " + string.Join(", ", parts) + ".";
        }

        private static string GetGreeting()
        {
            int hour = DateTime.Now.Hour;
            if (hour < 12) return "Good morning";
            if (hour < 18) return "Good afternoon";
            return "Good evening";
        }

        private bool CanManageCourses()
        {
            return Master.IsApproved && Master.IsPageAvailable(CourseEditorPage);
        }

        protected string CourseUrl(int courseId)
        {
            return Master.GetPageUrl(CourseEditorPage) + "?id=" + courseId;
        }

        // The cover image, or the course's first letter on a coloured background
        protected string CoverHtml(TutorCourseSummary course)
        {
            if (!string.IsNullOrEmpty(course.ThumbnailUrl))
            {
                return "<img src=\"" + HttpUtility.HtmlAttributeEncode(ResolveUrl(course.ThumbnailUrl)) + "\" alt=\"\" loading=\"lazy\" />";
            }

            string letter = string.IsNullOrWhiteSpace(course.Title) ? "C" : course.Title.Trim().Substring(0, 1).ToUpperInvariant();
            return "<span class=\"cl-course-card-letter\">" + HttpUtility.HtmlEncode(letter) + "</span>";
        }

        protected string CoverToneCss(TutorCourseSummary course)
        {
            return string.IsNullOrEmpty(course.ThumbnailUrl) ? CoverTones[course.Id % CoverTones.Length] : string.Empty;
        }

        protected string DifficultyCss(string difficulty)
        {
            switch (difficulty)
            {
                case "Beginner": return "cl-badge-success";
                case "Intermediate": return "cl-badge-info";
                case "Advanced": return "cl-badge-danger";
                default: return "cl-badge-neutral";
            }
        }

        protected string ManageLink(int courseId)
        {
            if (!CanManageCourses())
            {
                return string.Empty;
            }

            return "<a class=\"cl-link-arrow\" href=\"" + HttpUtility.HtmlAttributeEncode(CourseUrl(courseId)) + "\">Manage &rarr;</a>";
        }

        // One bar in the "Course pipeline" card (public so the Repeater can read it)
        public class PipelineRow
        {
            public PipelineRow(string label, int count, int total, string tone)
            {
                Label = label;
                Count = count;
                Tone = tone;
                Percent = total == 0 ? 0 : (int)Math.Round(count * 100.0 / total);
            }

            public string Label { get; private set; }
            public int Count { get; private set; }
            public int Percent { get; private set; }
            public string Tone { get; private set; }
        }

        // One row in the "Needs your attention" card
        public class AttentionItem
        {
            public AttentionItem(string title, string text, string icon, string tone, string url)
            {
                Title = title;
                Text = text;
                Icon = icon;
                Tone = tone;
                Url = url;
            }

            public string Title { get; private set; }
            public string Text { get; private set; }
            public string Icon { get; private set; }
            public string Tone { get; private set; }
            public string Url { get; private set; }
        }
    }
}

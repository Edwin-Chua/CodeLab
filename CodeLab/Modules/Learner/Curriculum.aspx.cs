using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Globalization;
using System.Text.RegularExpressions;
using System.Web;
using System.Web.Script.Serialization;
using System.Web.UI;
using System.Web.UI.WebControls;
using CodeLab.BLL;
using CodeLab.Models;
using CodeLab.DAL;
using CodeLab.Helpers;

namespace CodeLab.Modules.Learner
{
    public partial class Curriculum : Page
    {
        private readonly LearnerCourseManager manager =
            new LearnerCourseManager();

        private readonly List<LessonRow> lessons =
            new List<LessonRow>();

        private bool ready;
        private bool redirecting;
        private bool enrolled;
        private bool quizMode;
        private bool quizPassed;

        protected string courseTitle;
        private string courseCoverUrl;

        private LessonRow selectedLesson;
        private QuizRow quiz;
        private QuizSession activeQuiz;
        private DataRow result;
        protected QuizAttemptReview AttemptReview { get; private set; }

        protected int CourseId
        {
            get { return ReadInt(Request.QueryString["id"]); }
        }

        private int LearnerId
        {
            get { return SessionHelper.GetCurrentUserID(); }
        }

        private string LastLessonKey
        {
            get
            {
                return "CodeLab.LastLesson." + LearnerId + "." + CourseId;
            }
        }

        private string QuizSessionKey
        {
            get
            {
                return "CodeLab.FinalQuiz." + LearnerId + "." + CourseId;
            }
        }

        private bool AllLessonsCompleted
        {
            get
            {
                return lessons.Count > 0 &&
                    lessons.TrueForAll(item => item.IsCompleted);
            }
        }

        private bool CanAttemptQuiz
        {
            get
            {
                return enrolled &&
                    AllLessonsCompleted &&
                    quiz != null &&
                    quiz.QuestionCount > 0;
            }
        }

        public sealed class LessonRow
        {
            public int Id { get; set; }
            public string Title { get; set; }
            public string Content { get; set; }
            public string CodeSnippet { get; set; }
            public string ThumbnailUrl { get; set; }
            public string VideoUrl { get; set; }
            public string AttachmentUrl { get; set; }
            public string AttachmentName { get; set; }
            public int DurationMinutes { get; set; }
            public bool IsCompleted { get; set; }
        }

        private sealed class QuizRow
        {
            public int Id { get; set; }
            public string Title { get; set; }
            public string Instructions { get; set; }
            public int PassMark { get; set; }
            public int QuestionCount { get; set; }
        }

        [Serializable]
        public sealed class QuestionRow
        {
            public int Id { get; set; }
            public string QuestionText { get; set; }
            public List<string> Options { get; set; }
            public int CorrectOptionIndex { get; set; }
            public string Explanation { get; set; }
        }

        [Serializable]
        private sealed class QuizSession
        {
            public string Token { get; set; }
            public int QuizId { get; set; }
            public int PassMark { get; set; }
            public int SubmittedAttemptId { get; set; }
            public List<QuestionRow> Questions { get; set; }
        }

        // ProgressPercent measures lesson completion.
        // IsCompleted also requires a passed final quiz.
        //
        // Local SQL variables have distinct names so they do not
        // conflict with the @done or @passed command parameters.
        private const string UpdateProgressSql = @"
DECLARE @progressTotal int =
(
    SELECT COUNT(*)
    FROM dbo.Lessons
    WHERE CourseId = @course
);

DECLARE @progressFinished int =
(
    SELECT COUNT(*)
    FROM dbo.LessonCompletions lc
    JOIN dbo.Lessons l ON l.Id = lc.LessonId
    WHERE l.CourseId = @course
      AND lc.LearnerId = @learner
);

DECLARE @progressQuizCount int =
(
    SELECT COUNT(*)
    FROM dbo.Quizzes
    WHERE CourseId = @course
);

DECLARE @courseQuizPassed bit = 0;

IF @progressQuizCount = 1 AND EXISTS
(
    SELECT 1
    FROM dbo.QuizAttempts qa
    JOIN dbo.Quizzes q ON q.Id = qa.QuizId
    WHERE q.CourseId = @course
      AND qa.LearnerId = @learner
      AND qa.Passed = 1
      AND EXISTS
      (
          SELECT 1
          FROM dbo.QuizQuestions qq
          WHERE qq.QuizId = q.Id
      )
)
    SET @courseQuizPassed = 1;

DECLARE @courseDone bit =
    CASE WHEN @progressTotal > 0
          AND @progressFinished = @progressTotal
          AND @courseQuizPassed = 1
         THEN 1 ELSE 0 END;

UPDATE dbo.CourseEnrollments
SET ProgressPercent =
        CASE WHEN @progressTotal = 0 THEN 0
             ELSE CAST(
                 100.0 * @progressFinished / @progressTotal
                 AS decimal(5,2))
        END,
    IsCompleted = @courseDone,
    CompletedAt =
        CASE WHEN @courseDone = 1
             THEN COALESCE(CompletedAt, SYSUTCDATETIME())
             ELSE NULL
        END
WHERE LearnerId = @learner
  AND CourseId = @course;";

        protected override void OnInit(EventArgs e)
        {
            ViewStateUserKey = Session.SessionID;
            base.OnInit(e);

            if (!SessionHelper.IsLoggedIn() ||
                !SessionHelper.IsUserInRole("Learner"))
            {
                Redirect(ResolveUrl("~/Modules/Public/Login"));
                return;
            }

            // Create dynamic question controls before posted answers load.
            try
            {
                LoadCourseData();
                SelectLesson();
                RestoreQuizView();

                if (redirecting)
                {
                    return;
                }

BindLessonLists();

if (activeQuiz != null &&
    activeQuiz.SubmittedAttemptId == 0)
                {
                    // Answer keys stay in server-side Session.
                    rptQuizQuestions.EnableViewState = false;
                    rptQuizQuestions.DataSource = activeQuiz.Questions;
                    rptQuizQuestions.DataBind();
                }

                ready = true;
                RenderPage();
            }
            catch (SqlException ex)
            {
                Fail(
                    ex,
                    "Could not load the course. Check the database connection and setup.");
            }
            catch (InvalidOperationException ex)
            {
                Fail(ex, ex.Message);
            }
        }

        protected override void OnPreRender(EventArgs e)
        {
            if (ready && !redirecting)
            {
                RenderPage();

                try
                {
                    BindAttemptHistory();
                }
                catch (SqlException ex)
                {
                    System.Diagnostics.Trace.TraceError(
                        "Could not load quiz attempt history: {0}", ex);

                    pnlAttemptHistory.Visible = false;

                    ShowError(
                        "Could not load your quiz attempt history. Please reload the page.");
                }
            }

            if(!redirecting && ready && enrolled && AllLessonsCompleted && quizPassed && Session["CourseCongratulations."+LearnerId+"."+CourseId] is bool) {
                Session.Remove("CourseCongratulations."+LearnerId+"."+CourseId);
                ScriptManager.RegisterStartupScript(this,GetType(),"courseCongratulations","var d=document.getElementById('curriculumCompletedDialog');if(d&&!d.open)d.showModal();",true);
            }
            base.OnPreRender(e);
        }

        private void LoadCourseData()
        {
            if (CourseId <= 0)
            {
                throw new InvalidOperationException(
                    "Invalid course identifier.");
            }

            DataTable courses = Query(@"
SELECT c.Title, c.ThumbnailUrl,
       CAST(CASE WHEN EXISTS
       (
           SELECT 1
           FROM dbo.CourseEnrollments e
           WHERE e.CourseId = c.Id
             AND e.LearnerId = @learner
       ) THEN 1 ELSE 0 END AS bit) AS IsEnrolled
FROM dbo.Courses c
WHERE c.Id = @course
  AND c.Status = N'Published';");

            if (courses.Rows.Count != 1)
            {
                throw new InvalidOperationException(
                    "Course not found or no longer available.");
            }

            DataRow course = courses.Rows[0];

            courseTitle = Text(course, "Title");
            courseCoverUrl = Text(course, "ThumbnailUrl");
            enrolled = Convert.ToBoolean(course["IsEnrolled"]);

            DataTable lessonData = Query(@"
SELECT l.Id, l.Title, l.DurationMinutes,
       CASE WHEN @enrolled = 1
            THEN l.Content ELSE N'' END AS Content,
       CASE WHEN @enrolled = 1
            THEN l.CodeSnippet ELSE N'' END AS CodeSnippet,
       CASE WHEN @enrolled = 1
            THEN l.ThumbnailUrl ELSE N'' END AS ThumbnailUrl,
       CASE WHEN @enrolled = 1
            THEN l.VideoUrl ELSE N'' END AS VideoUrl,
       CASE WHEN @enrolled = 1
            THEN l.AttachmentUrl ELSE N'' END AS AttachmentUrl,
       CASE WHEN @enrolled = 1
            THEN l.AttachmentName ELSE N'' END AS AttachmentName,
       CAST(CASE WHEN @enrolled = 1 AND EXISTS
       (
           SELECT 1
           FROM dbo.LessonCompletions lc
           WHERE lc.LessonId = l.Id
             AND lc.LearnerId = @learner
       ) THEN 1 ELSE 0 END AS bit) AS IsCompleted
FROM dbo.Lessons l
WHERE l.CourseId = @course
ORDER BY l.OrderIndex, l.Id;",
                new SqlParameter("@enrolled", SqlDbType.Bit)
                {
                    Value = enrolled
                });

            foreach (DataRow row in lessonData.Rows)
            {
                lessons.Add(new LessonRow
                {
                    Id = Convert.ToInt32(row["Id"]),
                    Title = Text(row, "Title"),
                    Content = Text(row, "Content"),
                    CodeSnippet = Text(row, "CodeSnippet"),
                    ThumbnailUrl = Text(row, "ThumbnailUrl"),
                    VideoUrl = Text(row, "VideoUrl"),
                    AttachmentUrl = Text(row, "AttachmentUrl"),
                    AttachmentName = Text(row, "AttachmentName"),
                    DurationMinutes =
                        Convert.ToInt32(row["DurationMinutes"]),
                    IsCompleted = Convert.ToBoolean(row["IsCompleted"])
                });
            }

            DataTable quizData = Query(@"
SELECT q.Id, q.Title, q.Instructions, q.PassMark,
       (
           SELECT COUNT(*)
           FROM dbo.QuizQuestions qq
           WHERE qq.QuizId = q.Id
       ) AS QuestionCount,
       CAST(CASE WHEN EXISTS
       (
           SELECT 1
           FROM dbo.QuizAttempts qa
           WHERE qa.QuizId = q.Id
             AND qa.LearnerId = @learner
             AND qa.Passed = 1
       ) THEN 1 ELSE 0 END AS bit) AS HasPassed
FROM dbo.Quizzes q
WHERE q.CourseId = @course
ORDER BY q.Id;");

            if (quizData.Rows.Count > 1)
            {
                throw new InvalidOperationException(
                    "This course has more than one quiz. Keep one final quiz linked to the course.");
            }

            if (quizData.Rows.Count == 1)
            {
                DataRow row = quizData.Rows[0];

                quiz = new QuizRow
                {
                    Id = Convert.ToInt32(row["Id"]),
                    Title = Text(row, "Title"),
                    Instructions = Text(row, "Instructions"),
                    PassMark = Convert.ToInt32(row["PassMark"]),
                    QuestionCount =
                        Convert.ToInt32(row["QuestionCount"])
                };

                quizPassed = enrolled &&
                    Convert.ToBoolean(row["HasPassed"]);
            }
        }

        private void SelectLesson()
        {
            if (!enrolled)
            {
                return;
            }

            int lessonId = ReadInt(Request.QueryString["lesson"]);

            selectedLesson =
                lessons.Find(item => item.Id == lessonId);

            if (selectedLesson == null)
            {
                lessonId = ReadInt(
                    Convert.ToString(Session[LastLessonKey]));

                selectedLesson =
                    lessons.Find(item => item.Id == lessonId);
            }

            if (selectedLesson == null)
            {
                selectedLesson =
                    lessons.Find(item => !item.IsCompleted);
            }

            if (selectedLesson == null && lessons.Count > 0)
            {
                selectedLesson = lessons[0];
            }

            if (selectedLesson != null)
            {
                Session[LastLessonKey] = selectedLesson.Id;
            }
        }

        private void BindLessonLists()
        {
            rptPreviewLessons.DataSource = enrolled ? null : lessons;
            rptPreviewLessons.DataBind();

            rptSidebarLessons.DataSource = enrolled ? lessons : null;
            rptSidebarLessons.DataBind();
        }

        private void BindAttemptHistory()
        {
            bool canViewHistory = enrolled && quiz != null;

            pnlAttemptHistory.Visible = canViewHistory;

            if (!canViewHistory)
            {
                return;
            }

            DataTable attempts = Query(@"
SELECT
    ROW_NUMBER() OVER (
        ORDER BY qa.AttemptedAt ASC, qa.Id ASC
    ) AS AttemptNumber,
    qa.Id,
    qa.AttemptedAt,
    qa.ScorePercent,
    qa.Passed
FROM dbo.QuizAttempts qa
INNER JOIN dbo.Quizzes q ON q.Id = qa.QuizId
WHERE qa.LearnerId = @learner
  AND qa.QuizId = @quiz
  AND q.CourseId = @course
ORDER BY qa.AttemptedAt DESC, qa.Id DESC;",
                IntParameter("@quiz", quiz.Id));

            attempts.Columns.Add(
                "AttemptedAtDisplay",
                typeof(string));

            foreach (DataRow row in attempts.Rows)
            {
                DateTime attemptedAtUtc = DateTime.SpecifyKind(
                    Convert.ToDateTime(row["AttemptedAt"]),
                    DateTimeKind.Utc);

                row["AttemptedAtDisplay"] = attemptedAtUtc
                    .AddHours(8)
                    .ToString(
                        "dd MMM yyyy, hh:mm tt",
                        CultureInfo.InvariantCulture);
            }

            bool hasAttempts = attempts.Rows.Count > 0;

            pnlNoAttempts.Visible = !hasAttempts;
            rptAttemptHistory.Visible = hasAttempts;

            rptAttemptHistory.DataSource = attempts;
            rptAttemptHistory.DataBind();
        }

        private void RestoreQuizView()
        {
            if (!enrolled || quiz == null)
            {
                return;
            }

            int resultId = ReadInt(Request.QueryString["result"]);

            if (resultId > 0)
            {
                DataTable attempts = Query(@"
SELECT ScorePercent, Passed, CorrectCount, TotalQuestions
FROM dbo.QuizAttempts
WHERE Id = @attempt
  AND QuizId = @quiz
  AND LearnerId = @learner;",
                    IntParameter("@attempt", resultId),
                    IntParameter("@quiz", quiz.Id));

                if (attempts.Rows.Count == 1)
                {
                    result = attempts.Rows[0];
                    AttemptReview = manager.GetAttemptReview(LearnerId, CourseId, resultId);
                    quizMode = true;
                }
                else
                {
                    ShowError("That quiz result is not available.");
                }

                return;
            }

            if (Request.QueryString["view"] != "quiz")
            {
                return;
            }

            if (!CanAttemptQuiz)
            {
                ShowError(
                    "Complete all lessons before attempting the final quiz.");
                return;
            }

            QuizSession saved =
                Session[QuizSessionKey] as QuizSession;

            if (saved == null ||
                saved.QuizId != quiz.Id ||
                saved.Token != Request.QueryString["attempt"])
            {
                ShowError(
                    "This quiz session has expired or was replaced. Select Attempt Quiz to start again.");
                return;
            }

            if (saved.SubmittedAttemptId > 0)
            {
                RedirectToResult(saved.SubmittedAttemptId);
                return;
            }

            activeQuiz = saved;
            quizMode = true;
        }

        private void RenderPage()
        {
            pnlCurriculum.Visible = true;
            pnlPreview.Visible = !enrolled;
            pnlWorkspace.Visible = enrolled;

            pnlNoLessonsPreview.Visible =
                !enrolled && lessons.Count == 0;

            // Preview title and enrolled sidebar title.
            litCourse.Text = courseTitle;
            litSidebarCourse.Text = courseTitle;

            // Course cover uses Courses.ThumbnailUrl.
            string coverUrl = SafeResourceUrl(courseCoverUrl);

            pnlCourseCover.Visible =
                enrolled && coverUrl.Length > 0;

            imgCourseCover.ImageUrl = coverUrl;
            imgCourseCover.AlternateText = courseTitle + " cover";

            btnEnroll.Visible = !enrolled;
            btnUnenroll.Visible = enrolled;

            pnlPreviewQuiz.Visible = !enrolled && quiz != null;
            pnlSidebarQuiz.Visible = enrolled && quiz != null;

            if (quiz != null)
            {
                string details =
                    quiz.QuestionCount + " questions • Pass mark: " +
                    quiz.PassMark + "%";

                litPreviewQuizDetails.Text = details;
                litSidebarQuizDetails.Text = details;

                litQuizTitle.Text = "Final Quiz";
                litQuizDetails.Text = details;
                litQuizInstructions.Text = quiz.Instructions;
            }

            int completed =
                lessons.FindAll(item => item.IsCompleted).Count;

            int percent = lessons.Count == 0
                ? 0
                : (int)Math.Round(
                    100.0 * completed / lessons.Count,
                    MidpointRounding.AwayFromZero);

            litProgressDetail.Text =
                completed + " of " + lessons.Count +
                " lessons completed";

            litProgressPercent.Text =
                percent.ToString(CultureInfo.InvariantCulture);

            litProgressFill.Text =
                "<div class=\"cc-progress-fill\" style=\"width:" +
                percent.ToString(CultureInfo.InvariantCulture) +
                "%\"></div>";

            bool courseCompleted =
                enrolled &&
                AllLessonsCompleted &&
                quiz != null &&
                quiz.QuestionCount > 0 &&
                quizPassed;

            lblCourseStatus.Text = courseCompleted
                ? "Course completed"
                : "Course in progress";

            btnOpenQuiz.Enabled = CanAttemptQuiz;
            btnOpenQuiz.Text =
                quizPassed ? "Retake Quiz" : "Attempt Quiz";

            lblQuizAvailability.Text =
                quiz == null
                    ? string.Empty
                    : quiz.QuestionCount == 0
                        ? "Quiz questions are not available yet."
                        : !AllLessonsCompleted
                            ? "Complete all lessons to unlock."
                            : quizPassed
                                ? "Final quiz passed."
                                : "Ready to attempt.";

            pnlLesson.Visible =
                enrolled && !quizMode && selectedLesson != null;

            pnlNoLesson.Visible =
                enrolled && !quizMode && selectedLesson == null;

            pnlQuiz.Visible = enrolled && quizMode;

            pnlQuizQuestions.Visible =
                quizMode && activeQuiz != null;

            pnlQuizResult.Visible =
                quizMode && result != null;

            btnRetryQuiz.Visible =
                result != null && CanAttemptQuiz;

            if (pnlLesson.Visible)
            {
                RenderLesson();
            }

            if (result != null)
            {
                bool passed = Convert.ToBoolean(result["Passed"]);

                litQuizResultTitle.Text =
                    passed ? "Quiz passed" : "Keep practising";

                litQuizScore.Text =
                    result["CorrectCount"] + " of " +
                    result["TotalQuestions"] + " correct • " +
                    result["ScorePercent"] + "%";

                litQuizResultMessage.Text = passed
                    ? (AllLessonsCompleted
                        ? "You have completed the lessons and passed the final quiz."
                        : "You passed this quiz. Complete all lessons to finish the course.")
                    : "Review the lessons and try again.";

                btnRetryQuiz.Text =
                    passed ? "Retake Quiz" : "Try Again";
            }
        }

        private void RenderLesson()
        {
            int index = lessons.IndexOf(selectedLesson);

            litLessonNumber.Text = "Lesson " + (index + 1);
            litLessonTitle.Text = selectedLesson.Title;

            litLessonDuration.Text =
                selectedLesson.DurationMinutes.ToString();

            litLessonContent.Text =
                string.IsNullOrWhiteSpace(selectedLesson.Content)
                    ? "No text content has been added yet."
                    : MarkdownHelper.ToHtml(selectedLesson.Content);

            lblLessonStatus.Text =
                selectedLesson.IsCompleted
                    ? "Completed"
                    : "Not completed";

            btnToggleComplete.Text =
                selectedLesson.IsCompleted
                    ? "Mark Incomplete"
                    : "Mark Completed";

            litLessonPosition.Text =
                "Lesson " + (index + 1) + " of " + lessons.Count;

            btnPreviousLesson.Enabled = index > 0;

            bool isLastLesson = index == lessons.Count - 1;

            btnNextLesson.Text = isLastLesson
                ? "Attempt Quiz"
                : "Next Lesson →";

            btnNextLesson.Enabled = isLastLesson
                ? CanAttemptQuiz
                : true;

            pnlCode.Visible =
                !string.IsNullOrWhiteSpace(
                    selectedLesson.CodeSnippet);

            litCodeSnippet.Text = selectedLesson.CodeSnippet;

            string imageUrl =
                SafeResourceUrl(selectedLesson.ThumbnailUrl);

            pnlLessonImage.Visible = imageUrl.Length > 0;
            imgLesson.ImageUrl = imageUrl;

            imgLesson.AlternateText =
                selectedLesson.Title + " illustration";

            string attachmentUrl =
                SafeResourceUrl(selectedLesson.AttachmentUrl);

            pnlAttachment.Visible = attachmentUrl.Length > 0;
            lnkAttachment.NavigateUrl = attachmentUrl;

            litAttachmentName.Text =
                string.IsNullOrWhiteSpace(
                    selectedLesson.AttachmentName)
                    ? "Open lesson attachment"
                    : selectedLesson.AttachmentName;

            ConfigureVideo(selectedLesson.VideoUrl);
        }

        private void ConfigureVideo(string value)
        {
            pnlVideo.Visible = false;
            litVideoEmbed.Text = string.Empty;

            string videoId;

            if (!TryGetYouTubeVideoId(value, out videoId))
            {
                return;
            }

            string title = HttpUtility.HtmlAttributeEncode(
                "Lesson video: " + selectedLesson.Title);

            // Only a validated YouTube ID is used in this HTML.
            litVideoEmbed.Text =
                "<iframe src=\"https://www.youtube-nocookie.com/embed/" +
                videoId + "\"" +
                " title=\"" + title + "\"" +
                " style=\"position:absolute;inset:0;width:100%;height:100%;border:0;\"" +
                " loading=\"lazy\"" +
                " referrerpolicy=\"strict-origin-when-cross-origin\"" +
                " allow=\"accelerometer; clipboard-write; encrypted-media;" +
                " gyroscope; picture-in-picture; web-share\"" +
                " allowfullscreen></iframe>";

            pnlVideo.Visible = true;
        }

        protected void rptSidebarLessons_ItemDataBound(
            object sender, RepeaterItemEventArgs e)
        {
            if (e.Item.ItemType != ListItemType.Item &&
                e.Item.ItemType != ListItemType.AlternatingItem)
            {
                return;
            }

            LessonRow lesson = (LessonRow)e.Item.DataItem;

            LinkButton button =
                (LinkButton)e.Item.FindControl("btnSelectLesson");

            // Explicitly preserve completion styling for the timeline.
            button.CssClass = lesson.IsCompleted
                ? "cc-sidebar-lesson is-completed"
                : "cc-sidebar-lesson";

            if (!quizMode &&
                selectedLesson != null &&
                lesson.Id == selectedLesson.Id)
            {
                button.CssClass += " is-active";
                button.Attributes["aria-current"] = "step";
            }
            else
            {
                button.Attributes.Remove("aria-current");
            }
        }

        protected void rptSidebarLessons_ItemCommand(
            object source, RepeaterCommandEventArgs e)
        {
            if (!ready ||
                !enrolled ||
                e.CommandName != "SelectLesson")
            {
                return;
            }

            int id = ReadInt(
                Convert.ToString(e.CommandArgument));

            if (lessons.Exists(item => item.Id == id))
            {
                RedirectToLesson(id);
            }
        }

        protected void btnPreviousLesson_Click(
            object sender, EventArgs e)
        {
            NavigateLesson(-1);
        }

        protected void btnNextLesson_Click(object sender, EventArgs e)
        {
            if (!ready || !enrolled || selectedLesson == null)
            {
                return;
            }

            int index = lessons.IndexOf(selectedLesson);

            if (index == lessons.Count - 1)
            {
                StartQuiz();
                return;
            }

            NavigateLesson(1);
        }

        private void NavigateLesson(int direction)
        {
            if (!ready || !enrolled || selectedLesson == null)
            {
                return;
            }

            int index =
                lessons.IndexOf(selectedLesson) + direction;

            if (index >= 0 && index < lessons.Count)
            {
                RedirectToLesson(lessons[index].Id);
            }
        }

        protected void btnBackToLessons_Click(
            object sender, EventArgs e)
        {
            if (!ready || !enrolled)
            {
                return;
            }

            if (selectedLesson != null)
            {
                RedirectToLesson(selectedLesson.Id);
            }
            else
            {
                Redirect(CourseUrl());
            }
        }

        protected void btnToggleComplete_Click(
            object sender, EventArgs e)
        {
            if (!ready ||
                !enrolled ||
                selectedLesson == null ||
                quizMode)
            {
                return;
            }

            try
            {
                using (SqlConnection connection =
                    DatabaseHelper.GetConnection())
                {
                    connection.Open();

                    using (SqlTransaction transaction =
                        connection.BeginTransaction(
                            IsolationLevel.Serializable))
                    {
                        using (SqlCommand command = Command(
                            connection, @"
IF NOT EXISTS
(
    SELECT 1
    FROM dbo.CourseEnrollments e
    JOIN dbo.Courses c ON c.Id = e.CourseId
    WHERE e.CourseId = @course
      AND e.LearnerId = @learner
      AND c.Status = N'Published'
)
OR NOT EXISTS
(
    SELECT 1
    FROM dbo.Lessons
    WHERE Id = @lesson
      AND CourseId = @course
)
    THROW 51010, 'Course or enrolment is no longer valid.', 1;

IF @done = 1
BEGIN
    IF NOT EXISTS
    (
        SELECT 1
        FROM dbo.LessonCompletions
        WHERE LearnerId = @learner
          AND LessonId = @lesson
    )
        INSERT dbo.LessonCompletions (LearnerId, LessonId)
        VALUES (@learner, @lesson);
END
ELSE
BEGIN
    DELETE FROM dbo.LessonCompletions
    WHERE LearnerId = @learner
      AND LessonId = @lesson;
END;
" + UpdateProgressSql, transaction))
                        {
                            command.Parameters.Add(
                                IntParameter(
                                    "@lesson",
                                    selectedLesson.Id));

                            command.Parameters.Add(
                                "@done",
                                SqlDbType.Bit).Value =
                                    !selectedLesson.IsCompleted;

                            command.ExecuteNonQuery();
                        }

                        transaction.Commit();
                    }
                }

                // Changing lesson completion invalidates an unfinished quiz.
                Session.Remove(QuizSessionKey);

                bool wasCourseCompleted=AllLessonsCompleted && quizPassed;
                int currentLessonId = selectedLesson.Id;

                // Reload saved completion and progress without redirecting.
                lessons.Clear();
                quiz = null;
                quizPassed = false;
                activeQuiz = null;
                result = null;
                quizMode = false;

                LoadCourseData();

                selectedLesson = lessons.Find(
                    item => item.Id == currentLessonId);

                if (selectedLesson == null)
                {
                    SelectLesson();
                }
                else
                {
                    Session[LastLessonKey] = selectedLesson.Id;
                }

                lblError.Text = string.Empty;
                lblError.Visible = false;

                if(!wasCourseCompleted && AllLessonsCompleted && quizPassed) Session["CourseCongratulations."+LearnerId+"."+CourseId]=true;
                // The UpdatePanels send only the changing sections to the browser.
                BindLessonLists();
                RenderPage();
            }
            catch (SqlException ex)
            {
                Log(ex);

                ShowError(
                    "Could not save lesson completion. Refresh and try again.");
            }
        }

        protected void btnEnroll_Click(
            object sender, EventArgs e)
        {
            if (!ready || enrolled)
            {
                return;
            }

            try
            {
                manager.Enroll(LearnerId, CourseId);
                Redirect(CourseUrl());
            }
            catch (SqlException ex)
            {
                Log(ex);
                ShowError("Could not enrol. Please try again.");
            }
        }

        protected void btnUnenroll_Click(
            object sender, EventArgs e)
        {
            if (!ready || !enrolled)
            {
                return;
            }

            try
            {
                manager.Unenroll(LearnerId, CourseId);

                Session.Remove(LastLessonKey);
                Session.Remove(QuizSessionKey);

                Redirect(CourseUrl());
            }
            catch (SqlException ex)
            {
                Log(ex);
                ShowError("Could not unenrol. Please try again.");
            }
        }

        protected void btnOpenQuiz_Click(
            object sender, EventArgs e)
        {
            StartQuiz();
        }

        protected void btnRetryQuiz_Click(
            object sender, EventArgs e)
        {
            StartQuiz();
        }

        private void StartQuiz()
        {
            if (!ready || !CanAttemptQuiz)
            {
                ShowError(
                    "Complete all lessons before starting the final quiz.");
                return;
            }

            try
            {
                DataTable questionData = Query(@"
SELECT Id, QuestionText, OptionsJson, CorrectOptionIndex, Explanation
FROM dbo.QuizQuestions
WHERE QuizId = @quiz
ORDER BY OrderIndex, Id;",
                    IntParameter("@quiz", quiz.Id));

                JavaScriptSerializer serializer =
                    new JavaScriptSerializer();

                List<QuestionRow> questions =
                    new List<QuestionRow>();

                foreach (DataRow row in questionData.Rows)
                {
                    List<string> options =
                        serializer.Deserialize<List<string>>(
                            Text(row, "OptionsJson"));

                    int answer =
                        Convert.ToInt32(row["CorrectOptionIndex"]);

                    if (options == null ||
                        options.Count < 2 ||
                        options.Exists(option => option == null) ||
                        answer < 0 ||
                        answer >= options.Count)
                    {
                        throw new InvalidOperationException(
                            "A quiz question has invalid answer options.");
                    }

                    questions.Add(new QuestionRow
                    {
                        Id = Convert.ToInt32(row["Id"]),
                        QuestionText = Text(row, "QuestionText"),
                        Options = options,
                        CorrectOptionIndex = answer,
                        Explanation = Text(row, "Explanation")
                    });
                }

                if (questions.Count == 0)
                {
                    ShowError(
                        "This quiz does not have any questions yet.");
                    return;
                }

                QuizSession state = new QuizSession
                {
                    Token = Guid.NewGuid().ToString("N"),
                    QuizId = quiz.Id,
                    PassMark = quiz.PassMark,
                    Questions = questions
                };

                Session[QuizSessionKey] = state;

                Redirect(
                    CourseUrl() +
                    "&view=quiz&attempt=" + state.Token);
            }
            catch (SqlException ex)
            {
                Log(ex);
                ShowError(
                    "Could not start the quiz. Please try again.");
            }
            catch (ArgumentException ex)
            {
                Log(ex);
                ShowError(
                    "The quiz options are not configured correctly.");
            }
            catch (InvalidOperationException ex)
            {
                Log(ex);
                ShowError(
                    "The quiz questions are not configured correctly.");
            }
        }

        protected void rptQuizQuestions_ItemDataBound(
            object sender, RepeaterItemEventArgs e)
        {
            if (e.Item.ItemType != ListItemType.Item &&
                e.Item.ItemType != ListItemType.AlternatingItem)
            {
                return;
            }

            QuestionRow question =
                (QuestionRow)e.Item.DataItem;

            RadioButtonList answers =
                (RadioButtonList)e.Item.FindControl("rblAnswers");

            for (int index = 0;
                 index < question.Options.Count;
                 index++)
            {
                answers.Items.Add(new ListItem(
                    HttpUtility.HtmlEncode(
                        question.Options[index]),
                    index.ToString(
                        CultureInfo.InvariantCulture)));
            }
        }

        protected void btnSubmitQuiz_Click(
            object sender, EventArgs e)
        {
            if (!ready ||
                !CanAttemptQuiz ||
                activeQuiz == null)
            {
                ShowError(
                    "The quiz is not available. Complete all lessons and start again.");
                return;
            }

            if (activeQuiz.SubmittedAttemptId > 0)
            {
                RedirectToResult(
                    activeQuiz.SubmittedAttemptId);
                return;
            }

            int correct = 0;
            var review = new QuizAttemptReview { PassMark = activeQuiz.PassMark };

            for (int index = 0;
                 index < activeQuiz.Questions.Count;
                 index++)
            {
                RadioButtonList answers =
                    (RadioButtonList)rptQuizQuestions
                        .Items[index]
                        .FindControl("rblAnswers");

                int selected;

                if (!int.TryParse(
                        answers.SelectedValue, out selected) ||
                    selected < 0 ||
                    selected >=
                        activeQuiz.Questions[index].Options.Count)
                {
                    lblQuizError.Text =
                        "Please answer every question before submitting.";

                    lblQuizError.Visible = true;
                    return;
                }

                var question = activeQuiz.Questions[index];
                review.Answers.Add(new QuizAnswerReview
                {
                    QuestionText = question.QuestionText,
                    Options = new List<string>(question.Options),
                    SelectedOptionIndex = selected,
                    CorrectOptionIndex = question.CorrectOptionIndex,
                    Explanation = question.Explanation ?? string.Empty
                });
                if (selected ==
                    activeQuiz.Questions[index].CorrectOptionIndex)
                {
                    correct++;
                }
            }

            int total = activeQuiz.Questions.Count;

            decimal percentage = 100m * correct / total;
            bool passed = percentage >= activeQuiz.PassMark;

            // The database stores whole-number percentages.
            int storedScore = (int)Math.Floor(percentage);

            try
            {
                int attemptId;

                using (SqlConnection connection =
                    DatabaseHelper.GetConnection())
                {
                    connection.Open();

                    using (SqlTransaction transaction =
                        connection.BeginTransaction(
                            IsolationLevel.Serializable))
                    {
                        using (SqlCommand command = Command(
                            connection, @"
IF NOT EXISTS
(
    SELECT 1
    FROM dbo.CourseEnrollments e
    JOIN dbo.Courses c ON c.Id = e.CourseId
    WHERE e.CourseId = @course
      AND e.LearnerId = @learner
      AND c.Status = N'Published'
)
OR NOT EXISTS
(
    SELECT 1
    FROM dbo.Quizzes
    WHERE Id = @quiz
      AND CourseId = @course
)
OR
(
    SELECT COUNT(*)
    FROM dbo.Quizzes
    WHERE CourseId = @course
) <> 1
OR NOT EXISTS
(
    SELECT 1
    FROM dbo.Lessons
    WHERE CourseId = @course
)
OR EXISTS
(
    SELECT 1
    FROM dbo.Lessons l
    WHERE l.CourseId = @course
      AND NOT EXISTS
      (
          SELECT 1
          FROM dbo.LessonCompletions lc
          WHERE lc.LessonId = l.Id
            AND lc.LearnerId = @learner
      )
)
    THROW 51011, 'Quiz prerequisites are no longer satisfied.', 1;

INSERT dbo.QuizAttempts
(
    LearnerId,
    QuizId,
    ScorePercent,
    Passed,
    TotalQuestions,
    CorrectCount
)
VALUES
(
    @learner,
    @quiz,
    @score,
    @passed,
    @totalQuestions,
    @correct
);

DECLARE @newAttempt int = CAST(SCOPE_IDENTITY() AS int);
" + UpdateProgressSql + @"
SELECT @newAttempt;", transaction))
                        {
                            command.Parameters.Add(
                                IntParameter(
                                    "@quiz",
                                    activeQuiz.QuizId));

                            command.Parameters.Add(
                                IntParameter(
                                    "@score",
                                    storedScore));

                            command.Parameters.Add(
                                IntParameter(
                                    "@totalQuestions",
                                    total));

                            command.Parameters.Add(
                                IntParameter(
                                    "@correct",
                                    correct));

                            command.Parameters.Add(
                                "@passed",
                                SqlDbType.Bit).Value = passed;

                            attemptId = Convert.ToInt32(
                                command.ExecuteScalar());
                        }

                        manager.SaveAttemptReview(transaction, LearnerId, CourseId, attemptId, review);

                        transaction.Commit();
                    }
                }

                // Normal refresh/back-button resubmissions reuse
                // this result instead of inserting another attempt.
                if(passed && !quizPassed) Session["CourseCongratulations."+LearnerId+"."+CourseId]=true;
                activeQuiz.SubmittedAttemptId = attemptId;
                Session[QuizSessionKey] = activeQuiz;

                RedirectToResult(attemptId);
            }
            catch (SqlException ex)
            {
                Log(ex);

                lblQuizError.Text =
                    "Could not save the result. Check that you are still enrolled and all lessons are completed.";

                lblQuizError.Visible = true;
            }
        }

        private DataTable Query(
            string sql,
            params SqlParameter[] parameters)
        {
            using (SqlConnection connection =
                DatabaseHelper.GetConnection())
            using (SqlCommand command =
                Command(connection, sql, null))
            {
                command.Parameters.AddRange(parameters);

                using (SqlDataAdapter adapter =
                    new SqlDataAdapter(command))
                {
                    DataTable table = new DataTable();
                    adapter.Fill(table);
                    return table;
                }
            }
        }

        private SqlCommand Command(
            SqlConnection connection,
            string sql,
            SqlTransaction transaction)
        {
            SqlCommand command =
                new SqlCommand(sql, connection, transaction);

            command.Parameters.Add(
                IntParameter("@course", CourseId));

            command.Parameters.Add(
                IntParameter("@learner", LearnerId));

            return command;
        }

        private static SqlParameter IntParameter(
            string name, int value)
        {
            return new SqlParameter(name, SqlDbType.Int)
            {
                Value = value
            };
        }

        private static string Text(
            DataRow row, string column)
        {
            return row.IsNull(column)
                ? string.Empty
                : Convert.ToString(row[column]);
        }

        private static int ReadInt(string value)
        {
            int number;

            return int.TryParse(value, out number)
                ? number
                : 0;
        }

        private string CourseUrl()
        {
            return ResolveUrl(
                "~/Modules/Learner/Curriculum.aspx") +
                "?id=" +
                CourseId.ToString(
                    CultureInfo.InvariantCulture);
        }

        private void RedirectToLesson(int id)
        {
            Session[LastLessonKey] = id;

            Redirect(
                CourseUrl() +
                "&lesson=" +
                id.ToString(CultureInfo.InvariantCulture));
        }

        private void RedirectToResult(int id)
        {
            Redirect(
                CourseUrl() +
                "&result=" +
                id.ToString(CultureInfo.InvariantCulture));
        }

        private void Redirect(string url)
        {
            redirecting = true;

            Response.Redirect(url, false);
            Context.ApplicationInstance.CompleteRequest();
        }

        private string SafeResourceUrl(string value)
        {
            if (string.IsNullOrWhiteSpace(value))
            {
                return string.Empty;
            }

            value = value.Trim();

            if (value.StartsWith(
                "~/", StringComparison.Ordinal))
            {
                if (value.Contains("\\") ||
                    value.Contains("..") ||
                    value.Contains("\r") ||
                    value.Contains("\n"))
                {
                    return string.Empty;
                }

                return ResolveUrl(value);
            }

            Uri uri;

            if (Uri.TryCreate(
                    value, UriKind.Absolute, out uri) &&
                (uri.Scheme == Uri.UriSchemeHttps ||
                 uri.Scheme == Uri.UriSchemeHttp) &&
                string.IsNullOrEmpty(uri.UserInfo))
            {
                return uri.AbsoluteUri;
            }

            return string.Empty;
        }

        private static bool TryGetYouTubeVideoId(
            string value, out string videoId)
        {
            videoId = string.Empty;

            if (string.IsNullOrWhiteSpace(value))
            {
                return false;
            }

            Uri uri;

            if (!Uri.TryCreate(
                    value.Trim(), UriKind.Absolute, out uri) ||
                (uri.Scheme != Uri.UriSchemeHttps &&
                 uri.Scheme != Uri.UriSchemeHttp) ||
                !string.IsNullOrEmpty(uri.UserInfo))
            {
                return false;
            }

            string host = uri.Host.ToLowerInvariant();

            string[] parts = uri.AbsolutePath.Split(
                new[] { '/' },
                StringSplitOptions.RemoveEmptyEntries);

            string candidate = null;

            if (host == "youtu.be" ||
                host == "www.youtu.be")
            {
                if (parts.Length == 1)
                {
                    candidate = parts[0];
                }
            }
            else if (
                host == "youtube.com" ||
                host == "www.youtube.com" ||
                host == "m.youtube.com" ||
                host == "music.youtube.com")
            {
                if (parts.Length == 1 &&
                    parts[0].Equals(
                        "watch",
                        StringComparison.OrdinalIgnoreCase))
                {
                    candidate =
                        HttpUtility.ParseQueryString(
                            uri.Query)["v"];
                }
                else if (parts.Length == 2 &&
                    (
                        parts[0].Equals(
                            "embed",
                            StringComparison.OrdinalIgnoreCase) ||
                        parts[0].Equals(
                            "shorts",
                            StringComparison.OrdinalIgnoreCase) ||
                        parts[0].Equals(
                            "live",
                            StringComparison.OrdinalIgnoreCase)
                    ))
                {
                    candidate = parts[1];
                }
            }
            else if (
                host == "youtube-nocookie.com" ||
                host == "www.youtube-nocookie.com")
            {
                if (parts.Length == 2 &&
                    parts[0].Equals(
                        "embed",
                        StringComparison.OrdinalIgnoreCase))
                {
                    candidate = parts[1];
                }
            }

            if (string.IsNullOrEmpty(candidate) ||
                !Regex.IsMatch(
                    candidate,
                    @"\A[A-Za-z0-9_-]{11}\z"))
            {
                return false;
            }

            videoId = candidate;
            return true;
        }

        private void ShowError(string message)
        {
            lblError.Text = HttpUtility.HtmlEncode(message);
            lblError.Visible = true;
        }

        private void Fail(
            Exception exception, string message)
        {
            ready = false;
            pnlCurriculum.Visible = false;

            Log(exception);
            ShowError(message);
        }

        private static void Log(Exception exception)
        {
            System.Diagnostics.Trace.TraceError(
                "Curriculum error: {0}", exception);
        }
    }
}
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using CodeLab.BLL;
using CodeLab.Helpers;
using CodeLab.Models;

namespace CodeLab.Modules.Tutor
{
    /// <summary>
    /// Read-only learner results for the tutor's quizzes, in three views picked by the link:
    /// QuizResults (all quizzes), QuizResults?quizId=1 (every attempt), QuizResults?attemptId=5 (one attempt's answers).
    /// </summary>
    public partial class QuizResults : Page
    {
        private readonly LearnerResultsManager _manager = new LearnerResultsManager();

        protected int QuizId { get; private set; }
        protected int AttemptId { get; private set; }
        protected int AttemptScore { get; private set; }

        protected void Page_Load(object sender, EventArgs e)
        {
            // This page explains the locked state itself
            Master.HideApprovalNotice = true;
            litHeading.Text = "Quiz Results";

            if (!Master.IsApproved)
            {
                litCrumbs.Text = "<span>Quiz Results</span>";
                litSubheading.Text = "Learner results unlock once your tutor application is approved.";
                phLocked.Visible = true;
                return;
            }

            int attemptId = QueryId("attemptId");
            int quizId = QueryId("quizId");

            if (attemptId > 0)
            {
                ShowAttempt(attemptId);
            }
            else if (quizId > 0)
            {
                ShowQuiz(quizId);
            }
            else
            {
                ShowOverview();
            }
        }

        // ---------- 1. All quizzes ----------

        private void ShowOverview()
        {
            litCrumbs.Text = "<span>Quiz Results</span>";
            litSubheading.Text = "How learners are doing in the quizzes of your published courses.";

            OperationResult<List<QuizResultSummary>> result = _manager.GetQuizzes();
            if (!result.Success)
            {
                ShowError(result.Message);
                return;
            }

            rptQuizzes.DataSource = result.Data;
            rptQuizzes.DataBind();
            rptQuizzes.Visible = result.Data.Count > 0;
            litCourseOptions.Text = TutorDisplayHelper.CourseOptionsHtml(result.Data.Select(q => q.CourseTitle));
            phCourseFilter.Visible = result.Data.Count > 0;
            phNoQuizzes.Visible = result.Data.Count == 0;
            phOverview.Visible = true;
        }

        // ---------- 2. One quiz ----------

        private void ShowQuiz(int quizId)
        {
            OperationResult<QuizResultSummary> quiz = _manager.GetQuiz(quizId);
            if (!quiz.Success)
            {
                ShowError(quiz.Message);
                ShowOverview();
                return;
            }

            OperationResult<List<QuizAttemptRow>> attempts = _manager.GetQuizAttempts(quizId);
            if (!attempts.Success)
            {
                ShowError(attempts.Message);
                return;
            }

            QuizResultSummary q = quiz.Data;
            QuizId = q.QuizId;
            litHeading.Text = q.QuizTitle;
            litSubheading.Text = q.CourseTitle + " · " + Plural(q.QuestionCount, "question") + " · pass mark " + q.PassMark + "%";
            litCrumbs.Text = TutorDisplayHelper.Crumb("Quiz Results", QuizUrl(0)) + "<span>" + HttpUtility.HtmlEncode(q.QuizTitle) + "</span>";

            litLearners.Text = q.EnrolledCount.ToString("N0");
            litLearnersNote.Text = q.LearnerCount == 0
                ? "No one has taken the quiz yet"
                : q.LearnerCount + (q.LearnerCount == 1 ? " has" : " have") + " taken the quiz";

            litCompleted.Text = q.PassedLearnerCount.ToString("N0");
            litCompletedNote.Text = TutorDisplayHelper.OutOfEnrolled(q.EnrolledCount);

            // Enrolled learners with no attempt yet (never below 0)
            litNotTaken.Text = Math.Max(0, q.EnrolledCount - q.LearnerCount).ToString("N0");
            litNotTakenNote.Text = TutorDisplayHelper.OutOfEnrolled(q.EnrolledCount);

            litAverage.Text = ScoreText(q.AverageScore);
            litAverageNote.Text = "Pass mark " + q.PassMark + "%";

            rptAttempts.DataSource = attempts.Data;
            rptAttempts.DataBind();
            rptAttempts.Visible = attempts.Data.Count > 0;
            phAttemptFilters.Visible = attempts.Data.Count > 0;
            phNoAttempts.Visible = attempts.Data.Count == 0;
            phQuiz.Visible = true;
        }

        // ---------- 3. One attempt ----------

        private void ShowAttempt(int attemptId)
        {
            OperationResult<QuizAttemptDetail> result = _manager.GetQuizAttempt(attemptId);
            if (!result.Success)
            {
                ShowError(result.Message);
                ShowOverview();
                return;
            }

            QuizAttemptDetail attempt = result.Data;
            AttemptId = attempt.AttemptId;
            QuizId = attempt.QuizId;
            AttemptScore = Math.Max(0, Math.Min(100, attempt.ScorePercent));

            litHeading.Text = attempt.LearnerName + "'s attempt";
            litSubheading.Text = attempt.QuizTitle + " · " + attempt.CourseTitle;
            litCrumbs.Text = TutorDisplayHelper.Crumb("Quiz Results", QuizUrl(0))
                + TutorDisplayHelper.Crumb(attempt.QuizTitle, QuizUrl(attempt.QuizId))
                + "<span>" + HttpUtility.HtmlEncode(attempt.LearnerName) + "</span>";

            litAttemptLearner.Text = TutorDisplayHelper.LearnerHtml(attempt.LearnerName, attempt.LearnerUsername, attempt.LearnerAvatarUrl);
            litAttemptNumber.Text = TutorDisplayHelper.Ordinal(attempt.AttemptNumber) + " attempt";
            litAttemptDate.Text = TutorDisplayHelper.LocalDateTime(attempt.AttemptedAt);
            litAttemptScore.Text = attempt.ScorePercent + "%";
            litAttemptBadge.Text = TutorDisplayHelper.PassBadge(attempt.Passed);

            int passMark = attempt.AnswerReview != null && attempt.AnswerReview.PassMark.HasValue
                ? attempt.AnswerReview.PassMark.Value
                : attempt.PassMark;
            litAttemptCorrect.Text = attempt.CorrectCount + " of " + attempt.TotalQuestions + " correct · pass mark " + passMark + "%";

            if (attempt.AnswerReview != null && attempt.AnswerReview.Answers.Count > 0)
            {
                List<QuizAnswerItem> answers = attempt.AnswerReview.Answers;
                int correct = answers.Count(a => a.IsCorrect);
                litCountAll.Text = answers.Count.ToString();
                litCountCorrect.Text = correct.ToString();
                litCountWrong.Text = (answers.Count - correct).ToString();

                rptAnswers.DataSource = answers;
                rptAnswers.DataBind();
                phReview.Visible = true;
            }
            else
            {
                phNoReview.Visible = true;
            }

            // The learner's other attempts at the same quiz
            OperationResult<List<QuizAttemptRow>> all = _manager.GetQuizAttempts(attempt.QuizId);
            rptLearnerAttempts.DataSource = all.Success
                ? all.Data.Where(a => a.LearnerId == attempt.LearnerId).ToList()
                : new List<QuizAttemptRow>();
            rptLearnerAttempts.DataBind();

            phAttempt.Visible = true;
        }

        // ---------- Used by the markup ----------

        protected string QuizUrl(int quizId)
        {
            return Master.GetPageUrl("QuizResults") + (quizId > 0 ? "?quizId=" + quizId : string.Empty);
        }

        protected string AttemptUrl(int attemptId)
        {
            return Master.GetPageUrl("QuizResults") + "?attemptId=" + attemptId;
        }

        protected static string CompletedHtml(QuizResultSummary row)
        {
            return TutorDisplayHelper.OutOfHtml(row.PassedLearnerCount, row.EnrolledCount);
        }

        protected static string ScoreText(double? score)
        {
            return score.HasValue ? Math.Round(score.Value) + "%" : "–";
        }

        protected static string AnswerBadge(QuizAnswerItem answer)
        {
            if (answer.IsCorrect)
            {
                return "<span class=\"cl-review-badge is-correct\"><i data-lucide=\"circle-check\" class=\"cl-icon\" aria-hidden=\"true\"></i>Correct</span>";
            }

            return answer.IsAnswered
                ? "<span class=\"cl-review-badge is-wrong\"><i data-lucide=\"circle-x\" class=\"cl-icon\" aria-hidden=\"true\"></i>Wrong</span>"
                : "<span class=\"cl-review-badge is-wrong\"><i data-lucide=\"circle-minus\" class=\"cl-icon\" aria-hidden=\"true\"></i>Not answered</span>";
        }

        /// <summary>
        /// The options of one question: the correct answer in green, and the learner's pick in red when it was wrong.
        /// </summary>
        protected static object OptionsFor(QuizAnswerItem answer)
        {
            List<string> options = answer.Options ?? new List<string>();
            return options.Select((text, index) =>
            {
                bool isCorrect = index == answer.CorrectOptionIndex;
                bool isPicked = answer.SelectedOptionIndex.HasValue && index == answer.SelectedOptionIndex.Value;

                string css = isCorrect ? "is-answer" : (isPicked ? "is-picked-wrong" : string.Empty);
                string tags = isCorrect
                    ? "<span class=\"cl-review-tag is-answer\"><i data-lucide=\"check\" class=\"cl-icon\" aria-hidden=\"true\"></i>Correct answer</span>"
                    : string.Empty;

                return new
                {
                    Letter = index < 26 ? ((char)('A' + index)).ToString() : (index + 1).ToString(),
                    Text = text ?? string.Empty,
                    Css = css,
                    Tags = tags
                };
            }).ToList();
        }

        protected static string ExplanationHtml(string explanation)
        {
            if (string.IsNullOrWhiteSpace(explanation))
            {
                return string.Empty;
            }

            return "<div class=\"cl-review-explain\"><i data-lucide=\"lightbulb\" class=\"cl-icon\" aria-hidden=\"true\"></i><p>"
                + HttpUtility.HtmlEncode(explanation) + "</p></div>";
        }

        // ---------- Helpers ----------

        private int QueryId(string name)
        {
            int id;
            return int.TryParse(Request.QueryString[name], out id) && id > 0 ? id : 0;
        }

        private static string Plural(int count, string word)
        {
            return count + " " + word + (count == 1 ? string.Empty : "s");
        }

        private void ShowError(string message)
        {
            lblMessage.Text = HttpUtility.HtmlEncode(message);
            lblMessage.Visible = true;
        }
    }
}

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
    /// Read-only learner results for the tutor's coding challenges, in three views picked by the link:
    /// ChallengeResults (all challenges), ?challengeId=1 (every submission), ?submissionId=5 (one submission's code).
    /// </summary>
    public partial class ChallengeResults : Page
    {
        private readonly LearnerResultsManager _manager = new LearnerResultsManager();

        protected int ChallengeId { get; private set; }
        protected int SubmissionId { get; private set; }

        // highlight.js class for the submitted code, e.g. "language-python"
        protected string CodeCss { get; private set; }

        protected void Page_Load(object sender, EventArgs e)
        {
            // This page explains the locked state itself
            Master.HideApprovalNotice = true;
            litHeading.Text = "Coding Results";

            if (!Master.IsApproved)
            {
                litCrumbs.Text = "<span>Coding Results</span>";
                litSubheading.Text = "Learner results unlock once your tutor application is approved.";
                phLocked.Visible = true;
                return;
            }

            int submissionId = QueryId("submissionId");
            int challengeId = QueryId("challengeId");

            if (submissionId > 0)
            {
                ShowSubmission(submissionId);
            }
            else if (challengeId > 0)
            {
                ShowChallenge(challengeId);
            }
            else
            {
                ShowOverview();
            }
        }

        // ---------- 1. All challenges ----------

        private void ShowOverview()
        {
            litCrumbs.Text = "<span>Coding Results</span>";
            litSubheading.Text = "How learners are doing in the coding challenges of your published courses.";

            OperationResult<List<ChallengeResultSummary>> result = _manager.GetChallenges();
            if (!result.Success)
            {
                ShowError(result.Message);
                return;
            }

            rptChallenges.DataSource = result.Data;
            rptChallenges.DataBind();
            rptChallenges.Visible = result.Data.Count > 0;
            litCourseOptions.Text = TutorDisplayHelper.CourseOptionsHtml(result.Data.Select(c => c.CourseTitle));
            phCourseFilter.Visible = result.Data.Count > 0;
            phNoChallenges.Visible = result.Data.Count == 0;
            phOverview.Visible = true;
        }

        // ---------- 2. One challenge ----------

        private void ShowChallenge(int challengeId)
        {
            OperationResult<ChallengeResultSummary> challenge = _manager.GetChallenge(challengeId);
            if (!challenge.Success)
            {
                ShowError(challenge.Message);
                ShowOverview();
                return;
            }

            OperationResult<List<ChallengeSubmissionRow>> submissions = _manager.GetSubmissions(challengeId);
            if (!submissions.Success)
            {
                ShowError(submissions.Message);
                return;
            }

            ChallengeResultSummary c = challenge.Data;
            List<ChallengeSubmissionRow> rows = submissions.Data;
            ChallengeId = c.ChallengeId;

            litHeading.Text = c.Title;
            litSubheading.Text = c.CourseTitle + " · " + TutorDisplayHelper.LanguageName(c.Language) + " · " + c.Difficulty;
            litCrumbs.Text = TutorDisplayHelper.Crumb("Coding Results", ChallengeUrl(0)) + "<span>" + HttpUtility.HtmlEncode(c.Title) + "</span>";

            litLearners.Text = c.EnrolledCount.ToString("N0");
            litLearnersNote.Text = c.LearnerCount == 0
                ? "No one has submitted code yet"
                : c.LearnerCount + (c.LearnerCount == 1 ? " has" : " have") + " submitted code";

            litSolved.Text = c.SolverCount.ToString("N0");
            litSolvedNote.Text = TutorDisplayHelper.OutOfEnrolled(c.EnrolledCount);

            // Enrolled learners with no submission yet (never below 0)
            litNotTried.Text = Math.Max(0, c.EnrolledCount - c.LearnerCount).ToString("N0");
            litNotTriedNote.Text = TutorDisplayHelper.OutOfEnrolled(c.EnrolledCount);

            int passed = rows.Count(r => r.Status == "Passed");
            int failed = rows.Count(r => r.Status == "Failed");
            int errors = rows.Count - passed - failed;
            litSubmissions.Text = rows.Count.ToString("N0");
            litSubmissionsNote.Text = rows.Count == 0
                ? "No submissions yet"
                : passed + " passed · " + failed + " failed · " + errors + (errors == 1 ? " error" : " errors");

            rptSubmissions.DataSource = rows;
            rptSubmissions.DataBind();
            rptSubmissions.Visible = rows.Count > 0;
            phSubmissionFilters.Visible = rows.Count > 0;
            phNoSubmissions.Visible = rows.Count == 0;
            phChallenge.Visible = true;
        }

        // ---------- 3. One submission ----------

        private void ShowSubmission(int submissionId)
        {
            OperationResult<ChallengeSubmissionDetail> result = _manager.GetSubmission(submissionId);
            if (!result.Success)
            {
                ShowError(result.Message);
                ShowOverview();
                return;
            }

            ChallengeSubmissionDetail s = result.Data;
            SubmissionId = s.SubmissionId;
            ChallengeId = s.ChallengeId;

            litHeading.Text = s.LearnerName + "'s submission";
            litSubheading.Text = s.ChallengeTitle + " · " + s.CourseTitle;
            litCrumbs.Text = TutorDisplayHelper.Crumb("Coding Results", ChallengeUrl(0))
                + TutorDisplayHelper.Crumb(s.ChallengeTitle, ChallengeUrl(s.ChallengeId))
                + "<span>" + HttpUtility.HtmlEncode(s.LearnerName) + "</span>";

            litSubmissionLearner.Text = TutorDisplayHelper.LearnerHtml(s.LearnerName, s.LearnerUsername, s.LearnerAvatarUrl);
            litSubmissionNumber.Text = TutorDisplayHelper.Ordinal(s.AttemptNumber) + " submission";
            litSubmissionDate.Text = TutorDisplayHelper.LocalDateTime(s.SubmittedAt);
            litSubmissionBadge.Text = TutorDisplayHelper.SubmissionStatusHtml(s.Status);
            litSubmissionNote.Text = StatusNote(s.Status);

            litLanguage.Text = TutorDisplayHelper.LanguageName(s.Language);
            CodeCss = "language-" + (s.Language ?? "plaintext");
            litCode.Text = string.IsNullOrEmpty(s.SubmittedCode) ? "(no code)" : s.SubmittedCode;

            bool hasOutput = !string.IsNullOrEmpty(s.OutputResult);
            bool hasExpected = !string.IsNullOrEmpty(s.ExpectedOutput);
            litOutput.Text = hasOutput ? s.OutputResult : "(no output)";
            litExpected.Text = hasExpected ? s.ExpectedOutput : "(the challenge has no expected output)";
            if (hasOutput && hasExpected)
            {
                litOutputMatch.Text = SameOutput(s.OutputResult, s.ExpectedOutput)
                    ? "<span class=\"cl-review-badge is-correct\"><i data-lucide=\"circle-check\" class=\"cl-icon\" aria-hidden=\"true\"></i>Matches</span>"
                    : "<span class=\"cl-review-badge is-wrong\"><i data-lucide=\"circle-x\" class=\"cl-icon\" aria-hidden=\"true\"></i>Different</span>";
            }

            // The learner's other submissions to the same challenge
            OperationResult<List<ChallengeSubmissionRow>> all = _manager.GetSubmissions(s.ChallengeId);
            rptLearnerSubmissions.DataSource = all.Success
                ? all.Data.Where(r => r.LearnerId == s.LearnerId).ToList()
                : new List<ChallengeSubmissionRow>();
            rptLearnerSubmissions.DataBind();

            phSubmission.Visible = true;
        }

        // ---------- Used by the markup ----------

        protected string ChallengeUrl(int challengeId)
        {
            return Master.GetPageUrl("ChallengeResults") + (challengeId > 0 ? "?challengeId=" + challengeId : string.Empty);
        }

        protected string SubmissionUrl(int submissionId)
        {
            return Master.GetPageUrl("ChallengeResults") + "?submissionId=" + submissionId;
        }

        protected static string SolvedHtml(ChallengeResultSummary row)
        {
            return TutorDisplayHelper.OutOfHtml(row.SolverCount, row.EnrolledCount);
        }

        // ---------- Helpers ----------

        private static string StatusNote(string status)
        {
            switch (status)
            {
                case "Passed": return "The output matched the expected output.";
                case "Failed": return "The code ran, but the output did not match.";
                default: return "The code did not run successfully.";
            }
        }

        // Compares outputs ignoring line-ending style and trailing spaces
        private static bool SameOutput(string actual, string expected)
        {
            return Normalise(actual) == Normalise(expected);
        }

        private static string Normalise(string text)
        {
            string[] lines = text.Replace("\r\n", "\n").Split('\n');
            return string.Join("\n", lines.Select(l => l.TrimEnd())).Trim();
        }

        private int QueryId(string name)
        {
            int id;
            return int.TryParse(Request.QueryString[name], out id) && id > 0 ? id : 0;
        }

        private void ShowError(string message)
        {
            lblMessage.Text = HttpUtility.HtmlEncode(message);
            lblMessage.Visible = true;
        }
    }
}

using System;
using System.Data.SqlClient;
using System.Globalization;
using System.Threading.Tasks;
using System.Web;
using System.Web.UI;
using CodeLab.BLL;
using CodeLab.Helpers;
using System.Web.UI.WebControls;
using CodeLab.Models;
using CodeLab.Services;
using System.Web.Script.Serialization;

namespace CodeLab.Modules.Learner
{
    public partial class Challenge : Page
    {
        protected string AiFeedback { get; private set; }
        protected bool IsMarkup { get { return currentChallenge != null && LearnerChallengeDetailManager.IsMarkupChallenge(currentChallenge.Language); } }
        protected bool PreviewReady { get; private set; }
        protected string PreviewDocument
        {
            get
            {
                // The CSP comes before any student markup. The iframe also has an empty sandbox.
                return "<!doctype html><meta charset=\"utf-8\"><meta http-equiv=\"Content-Security-Policy\" content=\"default-src 'none'; style-src 'unsafe-inline'; img-src data:; font-src 'none'; form-action 'none'; base-uri 'none'\">"
                    + (txtCode.Text ?? "");
            }
        }
        private readonly LearnerChallengeDetailManager manager =
            new LearnerChallengeDetailManager();

        private readonly JDoodleExecutionService executionService =
            new JDoodleExecutionService();

        // Request-scoped values loaded after authentication and access checks.
        private LearnerChallengeDetail currentChallenge;
        private bool canAccessChallenge;

        protected void Page_Load(object sender, EventArgs e)
        {
            canAccessChallenge = false;
            currentChallenge = null;

            pnlError.Visible = false;
            litError.Text = string.Empty;
            pnlChallenge.Visible = false;

            btnRun.Enabled = false;
            btnSubmit.Enabled = false;

            if (!SessionHelper.IsLoggedIn() ||
                !SessionHelper.IsUserInRole("Learner") ||
                SessionHelper.GetCurrentUserID() <= 0)
            {
                Response.Redirect(
                    ResolveUrl("~/Modules/Public/Login"),
                    false);

                Context.ApplicationInstance.CompleteRequest();
                return;
            }

            int challengeId;

            if (!int.TryParse(Request.QueryString["id"], out challengeId) ||
                challengeId <= 0)
            {
                ShowError("The challenge link is invalid.");
                return;
            }

            int learnerId = SessionHelper.GetCurrentUserID();

            try
            {
                currentChallenge = manager.GetChallenge(
                    learnerId,
                    challengeId);
            }
            catch (SqlException ex)
            {
                System.Diagnostics.Trace.TraceError(
                    "Challenge details could not load: {0}", ex);

                ShowError(
                    "The challenge is temporarily unavailable. " +
                    "Please try again.");
                return;
            }

            if (currentChallenge == null)
            {
                ShowError(
                    "This challenge is unavailable. You must have completed " +
                    "its published course to access it.");
                return;
            }

            canAccessChallenge = true;
            pnlChallenge.Visible = true;

            BindChallenge(currentChallenge);
            BindSubmissions(learnerId, challengeId);
        }

        private void BindChallenge(LearnerChallengeDetail challenge)
        {
            Page.Title = challenge.Title + " | CodeLab";

            litBreadcrumbCourse.Text = challenge.CourseTitle;
            litBreadcrumbTitle.Text = challenge.Title;

            litTitle.Text = challenge.Title;
            litCourseTitle.Text = challenge.CourseTitle;
            litDescription.Text = challenge.Description;
            litExpectedOutput.Text = challenge.ExpectedOutput;

            litLanguage.Text = challenge.Language;
            litFileName.Text = GetFileName(challenge.Language);

            litPointsReward.Text = challenge.PointsReward.ToString(
                CultureInfo.InvariantCulture);

            litProgressStatus.Text = challenge.ProgressStatus;

            litAttemptCount.Text = challenge.AttemptCount.ToString(
                CultureInfo.InvariantCulture);

            litSubmissionCount.Text = challenge.AttemptCount.ToString(
                CultureInfo.InvariantCulture);

            lblDifficulty.Text = HttpUtility.HtmlEncode(
                challenge.Difficulty ?? string.Empty);

            lblDifficulty.CssClass = GetDifficultyCssClass(
                challenge.Difficulty);

            bool supported = IsSupportedLanguage(challenge.Language);
            btnRun.Text = IsMarkup ? "Preview" : "Run Code";

            if (!IsPostBack)
            {
                txtCode.Text = challenge.StarterCode ?? string.Empty;

                lblExecutionStatus.Text = "Not run";

                litOutput.Text = supported
                    ? (IsMarkup ? "Click Preview to view your HTML/CSS. Submit for AI source review." : "Click Run Code to execute your program. SQL challenges use SQLite.")
                    : "This challenge language is not supported by the execution sandbox.";
            }

            // Always use the database value as the reset source.
            hdnStarterCode.Value = challenge.StarterCode ?? string.Empty;

            btnRun.Enabled = supported;

            btnRun.ToolTip = supported
                ? (IsMarkup ? "Preview HTML/CSS without saving or awarding XP." : "Run your code without saving a submission.")
                : "This challenge language is not supported by the execution sandbox.";

            btnSubmit.Enabled = supported;

            btnSubmit.ToolTip = supported
                ? (IsMarkup ? "Review your HTML/CSS requirements with Gemini and save your submission." : "Run your code, check the output, and save your submission.")
                : "This challenge language is not supported by the execution sandbox.";
        }

        protected void btnRun_Click(object sender, EventArgs e)
        {
            if (!canAccessChallenge || currentChallenge == null)
            {
                return;
            }

            if (!IsSupportedLanguage(currentChallenge.Language))
            {
                lblExecutionStatus.Text = "Unavailable";
                litOutput.Text =
                    "This challenge language is not supported by the execution sandbox.";
                return;
            }

            // Use the language from the database, never a browser value.
            string language = currentChallenge.Language;
            string code = txtCode.Text ?? string.Empty;

            if (IsMarkup)
            {
                if (string.IsNullOrWhiteSpace(code) || code.Length > 20000)
                {
                    litOutput.Text = "Enter HTML/CSS between 1 and 20,000 characters to preview.";
                    return;
                }
                PreviewReady = true;
                lblExecutionStatus.Text = "Preview ready";
                litOutput.Text = "Preview only. Scripts and external assets are disabled. Submit for AI review; previewing does not award XP.";
                return;
            }
            RegisterAsyncTask(new PageAsyncTask(
                () => RunCodeAsync(language, code)));
        }

        private async Task RunCodeAsync(string language, string code)
        {
            CodeExecutionResult result =
                await executionService.ExecuteAsync(language, code);

            if (!result.RequestSucceeded)
            {
                lblExecutionStatus.Text = "Unable to run";
                litOutput.Text = result.ErrorMessage;
                return;
            }

            // An API response is not proof of a correct solution.
            // JDoodle may return program errors in its output.
            lblExecutionStatus.Text = "Response received";

            litOutput.Text = string.IsNullOrEmpty(result.Output)
                ? "(No output)"
                : result.Output;

            // Run does not insert a CodeSubmissions record,
            // change challenge completion, or award XP.
        }

        private void BindSubmissions(int learnerId, int challengeId)
        {
            try
            {
                var submissions = manager.GetSubmissions(
                    learnerId,
                    challengeId);

                rptSubmissions.DataSource = submissions;
                rptSubmissions.DataBind();

                litSubmissionCount.Text = submissions.Count.ToString(
                    CultureInfo.InvariantCulture);

                pnlNoSubmissions.Visible = submissions.Count == 0;
            }
            catch (SqlException ex)
            {
                System.Diagnostics.Trace.TraceError(
                    "Challenge submissions could not load: {0}", ex);

                rptSubmissions.DataSource = null;
                rptSubmissions.DataBind();

                pnlNoSubmissions.Visible = false;
                litSubmissionCount.Text = "—";

                ShowError(
                    "Your submission history is temporarily unavailable. " +
                    "Please refresh the page to try again.");
            }
        }

        private static bool IsSupportedLanguage(string language)
        {
            return LearnerChallengeDetailManager.IsMarkupChallenge(language) || JDoodleExecutionService.IsSupportedLanguage(language);
        }
        private static string GetDifficultyCssClass(string difficulty)
        {
            switch ((difficulty ?? string.Empty).Trim().ToLowerInvariant())
            {
                case "beginner":
                    return "ch-difficulty is-beginner";

                case "intermediate":
                    return "ch-difficulty is-intermediate";

                case "advanced":
                    return "ch-difficulty is-advanced";

                default:
                    return "ch-difficulty";
            }
        }

        private static string GetFileName(string language)
        {
            switch ((language ?? string.Empty).Trim().ToLowerInvariant())
            {
                case "python":
                case "python3":
                    return "solution.py";

                case "javascript":
                    return "solution.js";

                case "typescript":
                    return "solution.ts";

                case "java":
                    return "Main.java";

                case "c":
                    return "solution.c";

                case "c++":
                case "cpp":
                    return "solution.cpp";

                case "c#":
                case "csharp":
                    return "Program.cs";

                case "html": return "index.html";
                case "perl": return "solution.pl";
                case "php": return "solution.php";
                case "bash": case "shell": return "solution.sh";
                case "sql": case "sqlite": return "solution.sql";
                default:
                    return "solution.txt";
            }
        }

        private void ShowError(string message)
        {
            litError.Text = message;
            pnlError.Visible = true;
        }

        protected void btnSubmit_Click(object sender, EventArgs e)
        {
            if (!canAccessChallenge || currentChallenge == null)
            {
                return;
            }

            if (!IsSupportedLanguage(currentChallenge.Language))
            {
                lblExecutionStatus.Text = "Unavailable";
                litOutput.Text =
                    "This challenge language is not supported by the execution sandbox.";
                return;
            }

            int learnerId = SessionHelper.GetCurrentUserID();
            int challengeId = currentChallenge.Id;
            string code = txtCode.Text ?? string.Empty;

            RegisterAsyncTask(new PageAsyncTask(
                () => SubmitCodeAsync(learnerId, challengeId, code)));
        }

        private void ShowSubmissionPopup(
            string resultType,
            string title,
            string message)
                {
                    var serializer = new JavaScriptSerializer();

                    // Escape HTML-sensitive characters before embedding JSON in a script.
                    string payload = serializer.Serialize(new
                    {
                        type = resultType,
                        title = title,
                        message = message
                    })
                    .Replace("<", "\\u003c")
                    .Replace(">", "\\u003e")
                    .Replace("&", "\\u0026")
                    .Replace("\u2028", "\\u2028")
                    .Replace("\u2029", "\\u2029");

                    string script = @"
        (function () {
            function openResult() {
                var data = " + payload + @";
                var dialog = document.getElementById('chResultDialog');

                if (!dialog) return;

                dialog.setAttribute('data-result', data.type);

                document.getElementById('chResultBadge').textContent =
                    data.type === 'passed' ? 'Passed' :
                    data.type === 'failed' ? 'Try again' : 'Unable to submit';

                document.getElementById('chResultTitle').textContent = data.title;
                document.getElementById('chResultMessage').textContent = data.message;

                if (!dialog.open) {
                    dialog.showModal();
                }
            }

            if (document.readyState === 'loading') {
                document.addEventListener('DOMContentLoaded', openResult);
            } else {
                openResult();
            }
        })();";

            ScriptManager.RegisterStartupScript(
                this,
                GetType(),
                "ChallengeSubmissionPopup",
                script,
                true);
        }

        private async Task SubmitCodeAsync(
            int learnerId,
            int challengeId,
            string code)
        {
            PreviewReady = IsMarkup && !string.IsNullOrWhiteSpace(code) && code.Length <= 20000;
            ChallengeSubmissionResult result =
                await manager.SubmitAsync(learnerId, challengeId, code);

            if (!result.Saved)
            {
                string errorMessage = string.IsNullOrWhiteSpace(result.ErrorMessage)
                    ? "The submission could not be confirmed. Check your history before trying again."
                    : result.ErrorMessage;

                lblExecutionStatus.Text = "Submission not confirmed";
                litOutput.Text = errorMessage;

                if (!string.IsNullOrEmpty(result.Output))
                {
                    litOutput.Text +=
                        Environment.NewLine +
                        Environment.NewLine +
                        "Execution output:" +
                        Environment.NewLine +
                        result.Output;
                }

                ShowSubmissionPopup(
                    "error",
                    "Submission not confirmed",
                    errorMessage);

                return;
            }

            AiFeedback = result.AiFeedback;
            bool passed = result.Status == "Passed";

            string message;

            if (passed)
            {
                lblExecutionStatus.Text = "Passed";

                message = result.PointsAwarded > 0
                    ? "Your submission passed! You earned " +
                      result.PointsAwarded.ToString(
                          CultureInfo.InvariantCulture) +
                      " XP."
                    : "Your submission passed! No additional XP was awarded.";
            }
            else
            {
                lblExecutionStatus.Text = result.Status;

                message =
                    result.Status == "Pending review" ? (IsMarkup ? "AI review is pending. No XP was awarded. Submit again to retry the review." : "Your output matched, but AI approval is pending. No XP was awarded. Submit again to retry the review.") : (IsMarkup ? "Your HTML/CSS did not meet the review requirements. Read the feedback and try again." : "Your submission did not pass the output check or AI review. Read the feedback below and try again.");
            }

            litOutput.Text =
                message +
                Environment.NewLine +
                Environment.NewLine +
                "Your output:" +
                Environment.NewLine +
                (string.IsNullOrEmpty(result.Output)
                    ? "(No output)"
                    : result.Output);

            // A saved attempt gets a result popup, not a saving-error popup.
            ShowSubmissionPopup(
                passed ? "passed" : "failed",
                passed ? "Challenge completed!" : result.Status == "Pending review" ? "Review pending" : "Keep practising",
                message);

            try
            {
                var updatedChallenge = manager.GetChallenge(
                    learnerId,
                    challengeId);

                if (updatedChallenge == null)
                {
                    canAccessChallenge = false;
                    btnRun.Enabled = false;
                    btnSubmit.Enabled = false;

                    ShowError(
                        "Your submission was saved, but this challenge " +
                        "is no longer available to your account.");

                    return;
                }

                currentChallenge = updatedChallenge;

                BindChallenge(updatedChallenge);
                BindSubmissions(learnerId, challengeId);
            }
            catch (SqlException ex)
            {
                System.Diagnostics.Trace.TraceError(
                    "Submission saved, but challenge details could not refresh: {0}",
                    ex);

                ShowError(
                    "Your submission was saved, but the displayed progress " +
                    "could not refresh. Reload the page to see the latest progress.");
            }
        }

    }
}

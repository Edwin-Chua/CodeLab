using System;
using System.Web;
using System.Web.UI;
using CodeLab.BLL;
using CodeLab.Helpers;
using CodeLab.Models;

namespace CodeLab.Modules.Admin
{
    public partial class TutorApplication : Page
    {
        // The applicant's user id from ?userId=, or 0 if it is missing or not a number
        private int ApplicantId
        {
            get
            {
                int userId;
                return int.TryParse(Request.QueryString["userId"], out userId) ? userId : 0;
            }
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                LoadApplication();
            }
        }

        protected void btnApprove_Click(object sender, EventArgs e)
        {
            ShowResult(new TutorApprovalManager().Approve(ApplicantId));
            LoadApplication();
        }

        protected void btnReject_Click(object sender, EventArgs e)
        {
            if (!Page.IsValid)
            {
                return;
            }

            OperationResult result = new TutorApprovalManager().Reject(ApplicantId, txtReason.Text);
            ShowResult(result);
            if (result.Success)
            {
                txtReason.Text = string.Empty;
            }

            LoadApplication();
        }

        private void LoadApplication()
        {
            OperationResult<TutorProfile> result = new TutorApprovalManager().GetApplication(ApplicantId);
            if (!result.Success)
            {
                ShowResult(result);
                phApplication.Visible = false;
                return;
            }

            TutorProfile application = result.Data;
            Title = application.FullName + " - Tutor Application";

            litAvatar.Text = DisplayHelper.AvatarHtml(application.FullName, application.AvatarUrl, "cl-admin-avatar-lg");
            litName.Text = application.FullName;
            litSpecialty.Text = application.Specialty;
            litUsername.Text = application.Username;
            litEmail.Text = application.Email;
            litApplied.Text = application.AppliedAt.HasValue
                ? application.AppliedAt.Value.ToLocalTime().ToString("d MMM yyyy, HH:mm") + " (" + DisplayHelper.TimeAgo(application.AppliedAt.Value) + ")"
                : string.Empty;
            litBio.Text = application.Bio;
            litQualifications.Text = application.Qualifications;
            litPitch.Text = string.IsNullOrWhiteSpace(application.CurriculumPitch) ? "Not provided." : application.CurriculumPitch;

            // HyperLink.Text is written as raw HTML, so encode it; only http(s) links become clickable
            hlPortfolio.Text = HttpUtility.HtmlEncode(application.PortfolioUrl);
            if (TutorManager.IsWebUrl(application.PortfolioUrl))
            {
                hlPortfolio.NavigateUrl = application.PortfolioUrl;
                hlPortfolio.Attributes["rel"] = "noopener noreferrer";
            }

            ShowStatus(application);
        }

        private void ShowStatus(TutorProfile application)
        {
            bool isPending = application.Status == TutorStatuses.Pending;
            phDecision.Visible = isPending;
            phDecided.Visible = !isPending;

            lblStatus.Text = HttpUtility.HtmlEncode(application.Status);
            switch (application.Status)
            {
                case TutorStatuses.Approved:
                    lblStatus.CssClass = "cl-admin-badge cl-admin-badge-approved";
                    litDecision.Text = application.ApprovedDate.HasValue
                        ? "Approved on " + application.ApprovedDate.Value.ToLocalTime().ToString("d MMM yyyy") + ". This tutor can create courses."
                        : "Approved. This tutor can create courses.";
                    break;
                case TutorStatuses.Rejected:
                    lblStatus.CssClass = "cl-admin-badge cl-admin-badge-rejected";
                    litDecision.Text = "Rejected. The applicant can update their details and resubmit.";
                    phReason.Visible = !string.IsNullOrWhiteSpace(application.RejectionReason);
                    litReason.Text = application.RejectionReason;
                    break;
                default:
                    lblStatus.CssClass = "cl-admin-badge cl-admin-badge-pending";
                    break;
            }
        }

        private void ShowResult(OperationResult result)
        {
            lblMessage.Text = HttpUtility.HtmlEncode(result.Message);
            lblMessage.CssClass = result.Success ? "alert alert-success d-block" : "alert alert-danger d-block";
            lblMessage.Visible = true;
        }
    }
}

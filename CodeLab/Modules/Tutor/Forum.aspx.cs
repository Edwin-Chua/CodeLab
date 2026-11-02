using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using CodeLab.BLL;
using CodeLab.Helpers;
using CodeLab.Models;

namespace CodeLab.Modules.Tutor
{
    public partial class Forum : Page
    {
        private const string ForumUrl = "~/Modules/Tutor/Forum";

        // True for Learners and Tutors; Admins can read but not post
        protected bool CanPost { get; private set; }

        // The "Start a discussion" form stays open after a failed post so the text is not lost
        protected bool ComposeOpen { get; private set; }

        // Edit box to open again after a failed save, e.g. "edit-post-12"
        protected string ReopenFormId { get; private set; } = string.Empty;

        // The course tutor of the post whose replies are being shown (for the "Instructor" badge)
        protected int CurrentInstructorId { get; private set; }

        private int CourseFilter
        {
            get
            {
                int id;
                return int.TryParse(Request.QueryString["courseId"], out id) && (id > 0 || id == -1 || id == -2) ? id : 0;
            }
        }

        protected string SearchText
        {
            get { return (Request.QueryString["q"] ?? string.Empty).Trim(); }
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            CanPost = DiscussionManager.CanParticipate();
            phCompose.Visible = CanPost;

            if (IsPostBack)
            {
                return;
            }

            switch (Request.QueryString["done"])
            {
                case "posted": ShowSuccess("Your discussion has been posted."); break;
                case "replied": ShowSuccess("Your reply has been posted."); break;
                case "edited": ShowSuccess("Your changes have been saved."); break;
                case "deleted": ShowSuccess("Your post has been deleted."); break;
                case "reply-deleted": ShowSuccess("Your reply has been deleted."); break;
            }

            BindCourses();
            BindPosts();
        }

        protected void btnPost_Click(object sender, EventArgs e)
        {
            Page.Validate("Post");
            if (!Page.IsValid)
            {
                ComposeOpen = true;
                return;
            }

            int courseId;
            int.TryParse(ddlCourse.SelectedValue, out courseId);

            OperationResult<int> result = new DiscussionManager().CreatePost(courseId, txtTitle.Text, txtContent.Text);
            if (!result.Success)
            {
                ComposeOpen = true;
                ShowError(result.Message);
                return;
            }

            // Show every course so the new post is visible, and jump to it
            Response.Redirect(ResolveUrl(ForumUrl) + "?done=posted#post-" + result.Data);
        }

        protected void rptPosts_ItemCommand(object source, RepeaterCommandEventArgs e)
        {
            int postId;
            if (!int.TryParse(e.CommandArgument as string, out postId))
            {
                return;
            }

            DiscussionManager manager = new DiscussionManager();
            switch (e.CommandName)
            {
                case "savePost":
                {
                    TextBox title = (TextBox)e.Item.FindControl("txtEditTitle");
                    TextBox content = (TextBox)e.Item.FindControl("txtEditContent");
                    OperationResult result = manager.UpdatePost(postId, title.Text, content.Text);
                    if (!result.Success)
                    {
                        ShowItemError(e.Item, result.Message, "edit-post-" + postId);
                        return;
                    }

                    RedirectBack("edited", "post-" + postId);
                    return;
                }

                case "deletePost":
                {
                    OperationResult result = manager.DeletePost(postId);
                    if (!result.Success)
                    {
                        ShowItemError(e.Item, result.Message, null);
                        return;
                    }

                    RedirectBack("deleted", null);
                    return;
                }

                case "reply":
                {
                    TextBox reply = (TextBox)e.Item.FindControl("txtReply");
                    OperationResult<int> result = manager.CreateReply(postId, reply.Text);
                    if (!result.Success)
                    {
                        ShowItemError(e.Item, result.Message, null);
                        return;
                    }

                    RedirectBack("replied", "reply-" + result.Data);
                    return;
                }
            }
        }

        protected void rptReplies_ItemCommand(object source, RepeaterCommandEventArgs e)
        {
            int replyId;
            if (!int.TryParse(e.CommandArgument as string, out replyId))
            {
                return;
            }

            // The post this reply belongs to, for showing an error in the right place
            RepeaterItem postItem = (RepeaterItem)((Control)source).NamingContainer;
            DiscussionManager manager = new DiscussionManager();

            if (e.CommandName == "saveReply")
            {
                TextBox content = (TextBox)e.Item.FindControl("txtEditReply");
                OperationResult result = manager.UpdateReply(replyId, content.Text);
                if (!result.Success)
                {
                    ShowItemError(postItem, result.Message, "edit-reply-" + replyId);
                    return;
                }

                RedirectBack("edited", "reply-" + replyId);
            }
            else if (e.CommandName == "deleteReply")
            {
                OperationResult result = manager.DeleteReply(replyId);
                if (!result.Success)
                {
                    ShowItemError(postItem, result.Message, null);
                    return;
                }

                RedirectBack("reply-deleted", "post-" + ((HiddenPostId(postItem))));
            }
        }

        protected void rptPosts_ItemDataBound(object sender, RepeaterItemEventArgs e)
        {
            DiscussionPost post = e.Item.DataItem as DiscussionPost;
            if (post == null)
            {
                return;
            }

            // Replies are bound here so the "Instructor" badge knows this post's course tutor
            CurrentInstructorId = post.CourseInstructorId;
            Repeater replies = (Repeater)e.Item.FindControl("rptReplies");
            replies.DataSource = post.Replies;
            replies.DataBind();
        }

        private void BindCourses()
        {
            OperationResult<List<Course>> courses = new DiscussionManager().GetCourses();
            List<Course> list = courses.Success ? courses.Data.OrderBy(c => c.Title).ToList() : new List<Course>();

            // Filter: all courses, or one
            StringBuilder options = new StringBuilder();
            options.Append("<option value=\"\"").Append(CourseFilter == 0 ? " selected" : "").Append(">All discussions</option>");
            options.Append("<option value=\"-1\"").Append(CourseFilter == -1 ? " selected" : "").Append(">General Discussion</option>");
            options.Append("<option value=\"-2\"").Append(CourseFilter == -2 ? " selected" : "").Append(">All course discussions</option>");
            foreach (Course course in list)
            {
                options.Append("<option value=\"").Append(course.Id).Append('"')
                    .Append(course.Id == CourseFilter ? " selected" : string.Empty).Append('>')
                    .Append(HttpUtility.HtmlEncode(course.Title)).Append("</option>");
            }

            litCourseOptions.Text = options.ToString();

            // New post: the published courses, starting with the one being filtered
            ddlCourse.Items.Clear();
            ddlCourse.Items.Add(new ListItem("General Discussion", "-1"));
            foreach (Course course in list)
            {
                ListItem item = new ListItem(course.Title, course.Id.ToString());
                item.Selected = course.Id == CourseFilter;
                ddlCourse.Items.Add(item);
            }
        }

        private void BindPosts()
        {
            OperationResult<List<DiscussionPost>> result = new DiscussionManager().GetPosts(CourseFilter, SearchText);
            if (!result.Success)
            {
                ShowError(result.Message);
                ShowEmpty("Discussions unavailable", "Please try again in a moment.");
                return;
            }

            List<DiscussionPost> posts = result.Data;
            litCount.Text = posts.Count == 1 ? "1 discussion" : posts.Count + " discussions";
            rptPosts.DataSource = posts;
            rptPosts.DataBind();

            if (posts.Count == 0)
            {
                if (CourseFilter != 0 || SearchText.Length > 0)
                {
                    ShowEmpty("No discussions match", "Try another course or search, or start a new discussion.");
                }
                else
                {
                    ShowEmpty("No discussions yet", CanPost ? "Start the first discussion with the button above." : "Discussions will appear here.");
                }
            }
        }

        private void ShowEmpty(string title, string text)
        {
            litEmptyTitle.Text = title;
            litEmptyText.Text = text;
            phEmpty.Visible = true;
        }

        // Shows an error inside the post card and, if given, opens the edit box again
        private void ShowItemError(RepeaterItem postItem, string message, string reopenFormId)
        {
            Label label = (Label)postItem.FindControl("lblPostError");
            label.Text = HttpUtility.HtmlEncode(message);
            label.Visible = true;
            ReopenFormId = reopenFormId ?? string.Empty;
        }

        // The post id of a post card, read from its reply button
        private static string HiddenPostId(RepeaterItem postItem)
        {
            LinkButton reply = postItem.FindControl("btnReply") as LinkButton;
            return reply != null ? reply.CommandArgument : string.Empty;
        }

        // Back to the same filter after a change, so a refresh cannot repeat it, then jump to the item
        private void RedirectBack(string done, string anchor)
        {
            List<string> query = new List<string>();
            if (CourseFilter != 0) query.Add("courseId=" + CourseFilter);
            if (SearchText.Length > 0) query.Add("q=" + HttpUtility.UrlEncode(SearchText));
            query.Add("done=" + done);
            Response.Redirect(ResolveUrl(ForumUrl) + "?" + string.Join("&", query) + (anchor == null ? string.Empty : "#" + anchor));
        }

        protected bool IsMine(int authorId)
        {
            return authorId == SessionHelper.GetCurrentUserID();
        }

        protected string CourseFilterUrl(int? courseId)
        {
            return ResolveUrl(ForumUrl) + "?courseId=" + (courseId ?? -1).ToString(System.Globalization.CultureInfo.InvariantCulture);
        }

        // "Tutor" or "Admin" by role (a course's own tutor is shown as "Tutor" too); plus "You" on your own posts
        protected string BadgesHtml(int authorId, string role)
        {
            StringBuilder html = new StringBuilder();
            if (role == UserRoles.Tutor)
            {
                html.Append("<span class=\"cl-role-badge is-tutor\">Tutor</span>");
            }
            else if (role == UserRoles.Admin)
            {
                html.Append("<span class=\"cl-role-badge is-admin\">Admin</span>");
            }

            if (IsMine(authorId))
            {
                html.Append("<span class=\"cl-role-badge is-you\">You</span>");
            }

            return html.ToString();
        }

        // Replies by tutors stand out a little, like in the prototype
        protected string ReplyCss(int authorId, string role)
        {
            return role == UserRoles.Tutor || authorId == CurrentInstructorId ? " is-tutor" : string.Empty;
        }

        protected static string ReplyCountText(int count)
        {
            return count == 0 ? "No replies yet" : (count == 1 ? "1 reply" : count + " replies");
        }

        // The signed-in user's photo next to the reply box
        protected string MyAvatarHtml
        {
            get
            {
                return Master.AvatarSrc != null
                    ? "<img class=\"cl-avatar cl-avatar-sm\" src=\"" + HttpUtility.HtmlAttributeEncode(Master.AvatarSrc) + "\" alt=\"\" />"
                    : "<span class=\"cl-avatar cl-avatar-sm\" aria-hidden=\"true\">" + HttpUtility.HtmlEncode(Master.Initials) + "</span>";
            }
        }

        private void ShowSuccess(string message)
        {
            lblSuccess.Text = HttpUtility.HtmlEncode(message);
            lblSuccess.Visible = true;
        }

        private void ShowError(string message)
        {
            lblSuccess.Visible = false;
            lblMessage.Text = HttpUtility.HtmlEncode(message);
            lblMessage.Visible = true;
        }
    }
}

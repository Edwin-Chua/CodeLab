<%@ Page Title="Discussion Forum" Language="C#" MasterPageFile="~/Modules/Tutor/Tutor.Master" AutoEventWireup="true" CodeBehind="Forum.aspx.cs" Inherits="CodeLab.Modules.Tutor.Forum" %>
<%@ MasterType VirtualPath="~/Modules/Tutor/Tutor.Master" %>
<%@ Import Namespace="CodeLab.Models" %>
<%@ Import Namespace="CodeLab.Helpers" %>

<asp:Content ID="ForumContent" ContentPlaceHolderID="TutorContent" runat="server">

    <%-- ===== Header ===== --%>
    <div class="cl-builder-header">
        <div class="cl-builder-heading">
            <nav class="cl-crumbs" aria-label="Breadcrumb">
                <a href="<%: Master.GetPageUrl("Dashboard") %>">Dashboard</a>
                <i data-lucide="chevron-right" class="cl-icon" aria-hidden="true"></i>
                <span>Discussion forum</span>
            </nav>
            <h1>Discussion forum</h1>
            <p>Ask questions, share tips and help learners in General or a published course.</p>
        </div>
        <% if (CanPost) { %>
            <button type="button" class="btn btn-primary cl-forum-new" data-compose-open>
                <i data-lucide="message-square-plus" class="cl-icon me-1" aria-hidden="true"></i>New discussion
            </button>
        <% } %>
    </div>

    <asp:Label ID="lblSuccess" runat="server" CssClass="cl-alert cl-alert-success" Visible="false" />
    <asp:Label ID="lblMessage" runat="server" CssClass="cl-alert cl-alert-danger" Visible="false" />

    <div class="cl-forum">
        <div class="cl-forum-main">

            <%-- ===== Start a new discussion (opened by the "New discussion" button) ===== --%>
            <asp:PlaceHolder ID="phCompose" runat="server" Visible="false">
                <section class="cl-card cl-forum-compose" id="compose" <%= ComposeOpen ? "" : "hidden" %>>
                    <div class="cl-builder-card-head">
                        <span class="cl-builder-icon cl-tone-pink"><i data-lucide="message-square-plus" class="cl-icon" aria-hidden="true"></i></span>
                        <div><h2>Start a discussion</h2><p>General discussions are shared. Course discussions are available to learners enrolled in that course and tutors.</p></div>
                    </div>

                    <asp:ValidationSummary ID="vsPost" runat="server" ValidationGroup="Post" CssClass="cl-alert cl-alert-danger"
                        HeaderText="Please fix the following:" DisplayMode="BulletList" />

                    <%-- ValidateRequestMode="Disabled" lets people type code such as List<int>; posts are always shown encoded --%>
                    <div class="cl-field">
                        <asp:Label ID="lblCourse" runat="server" AssociatedControlID="ddlCourse" CssClass="form-label" Text="Discussion area" />
                        <asp:DropDownList ID="ddlCourse" runat="server" CssClass="form-select" />
                        <asp:RequiredFieldValidator ID="rfvCourse" runat="server" ControlToValidate="ddlCourse" InitialValue=""
                            ErrorMessage="Choose General Discussion or a published course." CssClass="cl-field-error" Display="Dynamic" ValidationGroup="Post" />
                    </div>
                    <div class="cl-field">
                        <asp:Label ID="lblTitle" runat="server" AssociatedControlID="txtTitle" CssClass="form-label" Text="Title" />
                        <asp:TextBox ID="txtTitle" runat="server" ValidateRequestMode="Disabled" CssClass="form-control" MaxLength="250"
                            placeholder="e.g. Why does my loop print one number too many?" />
                        <asp:RequiredFieldValidator ID="rfvTitle" runat="server" ControlToValidate="txtTitle"
                            ErrorMessage="The title is required." CssClass="cl-field-error" Display="Dynamic" ValidationGroup="Post" />
                    </div>
                    <div class="cl-field">
                        <asp:Label ID="lblContent" runat="server" AssociatedControlID="txtContent" CssClass="form-label" Text="Message" />
                        <asp:TextBox ID="txtContent" runat="server" ValidateRequestMode="Disabled" CssClass="form-control" TextMode="MultiLine" Rows="5"
                            MaxLength="5000" placeholder="Explain your question or idea. Paste code if it helps." />
                        <asp:RequiredFieldValidator ID="rfvContent" runat="server" ControlToValidate="txtContent"
                            ErrorMessage="The message is required." CssClass="cl-field-error" Display="Dynamic" ValidationGroup="Post" />
                    </div>

                    <div class="cl-card-actions">
                        <button type="button" class="btn cl-btn-outline" data-compose-close>Cancel</button>
                        <asp:Button ID="btnPost" runat="server" Text="Post discussion" CssClass="btn btn-primary" ValidationGroup="Post" OnClick="btnPost_Click" />
                    </div>
                </section>
            </asp:PlaceHolder>

            <%-- ===== Filter and search ===== --%>
            <div class="cl-card cl-forum-toolbar">
                <div class="cl-forum-filter">
                    <label for="forumCourse" class="visually-hidden">Discussion area</label>
                    <select id="forumCourse" class="form-select">
                        <asp:Literal ID="litCourseOptions" runat="server" Mode="PassThrough" />
                    </select>
                </div>
                <div class="cl-forum-search">
                    <i data-lucide="search" class="cl-icon" aria-hidden="true"></i>
                    <label for="forumSearch" class="visually-hidden">Search discussions</label>
                    <input type="search" id="forumSearch" class="form-control" maxlength="100" placeholder="Search titles, messages or names"
                        value="<%: SearchText %>" />
                </div>
                <span class="cl-forum-count"><asp:Literal ID="litCount" runat="server" Mode="Encode" /></span>
            </div>

            <%-- ===== Discussions ===== --%>
            <asp:Repeater ID="rptPosts" runat="server" OnItemDataBound="rptPosts_ItemDataBound" OnItemCommand="rptPosts_ItemCommand">
                <ItemTemplate>
                    <article class="cl-card cl-post<%# IsMine((int)Eval("AuthorId")) ? " is-mine" : "" %>" id="post-<%# Eval("Id") %>">
                        <header class="cl-post-head">
                            <%# TutorDisplayHelper.AvatarHtml((string)Eval("AuthorName"), (string)Eval("AuthorAvatarUrl")) %>
                            <div class="cl-post-meta">
                                <div class="cl-post-author">
                                    <strong><asp:PlaceHolder runat="server" Visible='<%# Convert.ToString(Eval("AuthorRole")) == "Tutor" %>'><%#: Eval("AuthorName") %></asp:PlaceHolder><asp:PlaceHolder runat="server" Visible='<%# Convert.ToString(Eval("AuthorRole")) != "Tutor" %>'><%#: Eval("AuthorName") %></asp:PlaceHolder><asp:PlaceHolder runat="server" Visible='<%# !string.IsNullOrEmpty(Eval("AuthorBadgeName") as string) %>'><span class='cl-earned-badge tier-<%#: Eval("AuthorBadgeTier") %>' title="Featured earned badge">&#9733; <%#: Eval("AuthorBadgeName") %></span></asp:PlaceHolder></strong>
                                    <%# BadgesHtml((int)Eval("AuthorId"), (string)Eval("AuthorRole")) %>
                                </div>
                                <div class="cl-post-sub">
                                    <a class="cl-post-course" href="<%#: CourseFilterUrl((int?)Eval("CourseId")) %>">
                                        <i data-lucide="book-open" class="cl-icon" aria-hidden="true"></i><%#: Eval("CourseTitle") %>
                                    </a>
                                    <span>·</span>
                                    <time title="<%#: TutorDisplayHelper.LocalDateTime((DateTime)Eval("CreatedAt")) %>"><%#: TutorDisplayHelper.TimeAgo((DateTime)Eval("CreatedAt")) %></time>
                                </div>
                            </div>
                            <asp:PlaceHolder ID="phPostActions" runat="server" Visible='<%# IsMine((int)Eval("AuthorId")) %>'>
                                <div class="cl-post-actions">
                                    <button type="button" class="cl-icon-action" data-toggle-edit="edit-post-<%# Eval("Id") %>" title="Edit post">
                                        <i data-lucide="pencil" class="cl-icon" aria-hidden="true"></i><span class="visually-hidden">Edit post</span>
                                    </button>
                                    <asp:LinkButton ID="btnDeletePost" runat="server" CssClass="cl-icon-action is-danger" CommandName="deletePost"
                                        CommandArgument='<%# Eval("Id") %>' CausesValidation="false" ToolTip="Delete post"
                                        OnClientClick="return confirm('Delete this discussion and all of its replies? This cannot be undone.');">
                                        <i data-lucide="trash-2" class="cl-icon" aria-hidden="true"></i><span class="visually-hidden">Delete post</span>
                                    </asp:LinkButton>
                                </div>
                            </asp:PlaceHolder>
                        </header>

                        <div class="cl-post-view" data-view-of="edit-post-<%# Eval("Id") %>">
                            <h2 class="cl-post-title"><%#: Eval("Title") %></h2>
                            <div class="cl-post-body"><%#: Eval("Content") %></div>
                        </div>

                        <asp:PlaceHolder ID="phEditPost" runat="server" Visible='<%# IsMine((int)Eval("AuthorId")) %>'>
                            <div class="cl-post-edit" id="edit-post-<%# Eval("Id") %>" hidden>
                                <asp:TextBox ID="txtEditTitle" runat="server" ValidateRequestMode="Disabled" CssClass="form-control" MaxLength="250" aria-label="Title"
                                    Text='<%# Eval("Title") %>' />
                                <asp:TextBox ID="txtEditContent" runat="server" ValidateRequestMode="Disabled" CssClass="form-control" TextMode="MultiLine" Rows="5"
                                    MaxLength="5000" aria-label="Message" Text='<%# Eval("Content") %>' />
                                <div class="cl-post-edit-actions">
                                    <button type="button" class="btn btn-sm cl-btn-outline" data-toggle-edit="edit-post-<%# Eval("Id") %>">Cancel</button>
                                    <asp:LinkButton ID="btnSavePost" runat="server" CssClass="btn btn-sm btn-primary" CommandName="savePost"
                                        CommandArgument='<%# Eval("Id") %>' CausesValidation="false" Text="Save changes" />
                                </div>
                            </div>
                        </asp:PlaceHolder>

                        <asp:Label ID="lblPostError" runat="server" CssClass="cl-alert cl-alert-danger cl-post-error" Visible="false" />

                        <%-- ===== Replies (flat: replies cannot be replied to) ===== --%>
                        <div class="cl-replies">
                            <div class="cl-replies-head">
                                <i data-lucide="messages-square" class="cl-icon" aria-hidden="true"></i>
                                <%# ReplyCountText(((DiscussionPost)Container.DataItem).Replies.Count) %>
                            </div>

                            <asp:Repeater ID="rptReplies" runat="server" OnItemCommand="rptReplies_ItemCommand">
                                <ItemTemplate>
                                    <div class="cl-reply<%# ReplyCss((int)Eval("AuthorId"), (string)Eval("AuthorRole")) %>" id="reply-<%# Eval("Id") %>">
                                        <%# TutorDisplayHelper.AvatarHtml((string)Eval("AuthorName"), (string)Eval("AuthorAvatarUrl")) %>
                                        <div class="cl-reply-main">
                                            <div class="cl-reply-head">
                                                <strong><asp:PlaceHolder runat="server" Visible='<%# Convert.ToString(Eval("AuthorRole")) == "Tutor" %>'><%#: Eval("AuthorName") %></asp:PlaceHolder><asp:PlaceHolder runat="server" Visible='<%# Convert.ToString(Eval("AuthorRole")) != "Tutor" %>'><%#: Eval("AuthorName") %></asp:PlaceHolder><asp:PlaceHolder runat="server" Visible='<%# !string.IsNullOrEmpty(Eval("AuthorBadgeName") as string) %>'><span class='cl-earned-badge tier-<%#: Eval("AuthorBadgeTier") %>' title="Featured earned badge">&#9733; <%#: Eval("AuthorBadgeName") %></span></asp:PlaceHolder></strong>
                                                <%# BadgesHtml((int)Eval("AuthorId"), (string)Eval("AuthorRole")) %>
                                                <time title="<%#: TutorDisplayHelper.LocalDateTime((DateTime)Eval("CreatedAt")) %>"><%#: TutorDisplayHelper.TimeAgo((DateTime)Eval("CreatedAt")) %></time>
                                                <asp:PlaceHolder ID="phReplyActions" runat="server" Visible='<%# IsMine((int)Eval("AuthorId")) %>'>
                                                    <span class="cl-reply-actions">
                                                        <button type="button" class="cl-icon-action" data-toggle-edit="edit-reply-<%# Eval("Id") %>" title="Edit reply">
                                                            <i data-lucide="pencil" class="cl-icon" aria-hidden="true"></i><span class="visually-hidden">Edit reply</span>
                                                        </button>
                                                        <asp:LinkButton ID="btnDeleteReply" runat="server" CssClass="cl-icon-action is-danger" CommandName="deleteReply"
                                                            CommandArgument='<%# Eval("Id") %>' CausesValidation="false" ToolTip="Delete reply"
                                                            OnClientClick="return confirm('Delete this reply? This cannot be undone.');">
                                                            <i data-lucide="trash-2" class="cl-icon" aria-hidden="true"></i><span class="visually-hidden">Delete reply</span>
                                                        </asp:LinkButton>
                                                    </span>
                                                </asp:PlaceHolder>
                                            </div>
                                            <div class="cl-reply-body" data-view-of="edit-reply-<%# Eval("Id") %>"><%#: Eval("Content") %></div>
                                            <asp:PlaceHolder ID="phEditReply" runat="server" Visible='<%# IsMine((int)Eval("AuthorId")) %>'>
                                                <div class="cl-post-edit" id="edit-reply-<%# Eval("Id") %>" hidden>
                                                    <asp:TextBox ID="txtEditReply" runat="server" ValidateRequestMode="Disabled" CssClass="form-control" TextMode="MultiLine" Rows="3"
                                                        MaxLength="3000" aria-label="Reply" Text='<%# Eval("Content") %>' />
                                                    <div class="cl-post-edit-actions">
                                                        <button type="button" class="btn btn-sm cl-btn-outline" data-toggle-edit="edit-reply-<%# Eval("Id") %>">Cancel</button>
                                                        <asp:LinkButton ID="btnSaveReply" runat="server" CssClass="btn btn-sm btn-primary" CommandName="saveReply"
                                                            CommandArgument='<%# Eval("Id") %>' CausesValidation="false" Text="Save reply" />
                                                    </div>
                                                </div>
                                            </asp:PlaceHolder>
                                        </div>
                                    </div>
                                </ItemTemplate>
                            </asp:Repeater>

                            <asp:PlaceHolder ID="phReplyForm" runat="server" Visible="<%# CanPost %>">
                                <div class="cl-reply-form">
                                    <%# MyAvatarHtml %>
                                    <asp:TextBox ID="txtReply" runat="server" ValidateRequestMode="Disabled" CssClass="form-control" TextMode="MultiLine" Rows="1"
                                        MaxLength="3000" placeholder="Write a reply…" aria-label="Write a reply" />
                                    <asp:LinkButton ID="btnReply" runat="server" CssClass="btn btn-primary btn-sm" CommandName="reply"
                                        CommandArgument='<%# Eval("Id") %>' CausesValidation="false">
                                        <i data-lucide="send" class="cl-icon" aria-hidden="true"></i><span>Reply</span>
                                    </asp:LinkButton>
                                </div>
                            </asp:PlaceHolder>
                        </div>
                    </article>
                </ItemTemplate>
            </asp:Repeater>

            <%-- ===== Nothing to show ===== --%>
            <asp:PlaceHolder ID="phEmpty" runat="server" Visible="false">
                <section class="cl-card cl-state-card">
                    <svg class="cl-state-art" viewBox="0 0 200 140" aria-hidden="true">
                        <defs><linearGradient id="forumGrad" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#C9527D" /><stop offset="1" stop-color="#FFA2A4" /></linearGradient></defs>
                        <circle cx="100" cy="70" r="62" fill="url(#forumGrad)" opacity=".12" />
                        <rect x="48" y="38" width="80" height="52" rx="14" fill="url(#forumGrad)" />
                        <path d="M64 90l-8 16 22-16z" fill="#C9527D" />
                        <rect x="88" y="62" width="70" height="44" rx="12" fill="#ffffff" stroke="#FFA2A4" stroke-width="3" />
                        <circle cx="108" cy="84" r="4" fill="#C9527D" /><circle cx="123" cy="84" r="4" fill="#C9527D" /><circle cx="138" cy="84" r="4" fill="#C9527D" />
                    </svg>
                    <h2><asp:Literal ID="litEmptyTitle" runat="server" Mode="Encode" /></h2>
                    <p><asp:Literal ID="litEmptyText" runat="server" Mode="Encode" /></p>
                </section>
            </asp:PlaceHolder>
        </div>

        <%-- ===== Side column ===== --%>
        <aside class="cl-forum-aside">
            <section class="cl-card cl-builder-card">
                <div class="cl-builder-card-head">
                    <span class="cl-builder-icon cl-tone-blue"><i data-lucide="info" class="cl-icon" aria-hidden="true"></i></span>
                    <div><h2>Forum guidelines</h2><p>Keep it helpful and friendly.</p></div>
                </div>
                <ul class="cl-checklist">
                    <li>Choose General for community topics, or the course your question is about.</li>
                    <li>Give your discussion a clear title and include any error message or code.</li>
                    <li>Reply to help others. Your replies show a <strong>Tutor</strong> badge.</li>
                    <li>You can edit or delete only your own posts and replies.</li>
                </ul>
            </section>
        </aside>
    </div>

    <script>
        document.addEventListener('DOMContentLoaded', function () {
            // Course filter and search: reload the page with the chosen filter
            var course = document.getElementById('forumCourse');
            var search = document.getElementById('forumSearch');
            var baseUrl = '<%= ResolveUrl("~/Modules/Tutor/Forum") %>';

            function applyFilter() {
                var query = [];
                if (course.value) { query.push('courseId=' + encodeURIComponent(course.value)); }
                if (search.value.trim()) { query.push('q=' + encodeURIComponent(search.value.trim())); }
                window.location.href = baseUrl + (query.length ? '?' + query.join('&') : '');
            }

            course.addEventListener('change', applyFilter);
            search.addEventListener('keydown', function (e) {
                if (e.key === 'Enter') {
                    e.preventDefault();
                    applyFilter();
                }
            });
            search.addEventListener('search', function () {
                if (!search.value) { applyFilter(); }
            });

            // "New discussion" opens the form; Cancel closes it
            var compose = document.getElementById('compose');
            document.querySelectorAll('[data-compose-open]').forEach(function (button) {
                button.addEventListener('click', function () {
                    if (!compose) { return; }
                    compose.hidden = false;
                    compose.scrollIntoView({ behavior: 'smooth', block: 'start' });
                    var title = compose.querySelector('input[type="text"]');
                    if (title) { title.focus({ preventScroll: true }); }
                });
            });
            document.querySelectorAll('[data-compose-close]').forEach(function (button) {
                button.addEventListener('click', function () { compose.hidden = true; });
            });

            // Edit buttons show the edit box in place of the text, and back again
            document.querySelectorAll('[data-toggle-edit]').forEach(function (button) {
                button.addEventListener('click', function () {
                    var id = button.getAttribute('data-toggle-edit');
                    var form = document.getElementById(id);
                    var view = document.querySelector('[data-view-of="' + id + '"]');
                    if (!form) { return; }
                    form.hidden = !form.hidden;
                    if (view) { view.hidden = !form.hidden; }
                    if (!form.hidden) {
                        var box = form.querySelector('textarea, input');
                        if (box) { box.focus(); }
                    }
                });
            });

            // Reply boxes grow as you type
            document.querySelectorAll('.cl-reply-form textarea').forEach(function (box) {
                box.addEventListener('input', function () {
                    box.style.height = 'auto';
                    box.style.height = Math.min(box.scrollHeight, 240) + 'px';
                });
            });

            // After a failed save, reopen the box that needs fixing
            var reopen = '<%= ReopenFormId %>';
            if (reopen) {
                var form = document.getElementById(reopen);
                var view = document.querySelector('[data-view-of="' + reopen + '"]');
                if (form) {
                    form.hidden = false;
                    if (view) { view.hidden = true; }
                    form.scrollIntoView({ block: 'center' });
                }
            }
        });
    </script>

</asp:Content>

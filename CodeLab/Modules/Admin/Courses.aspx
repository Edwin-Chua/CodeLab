<%@ Page Title="Course Moderation" Language="C#" MasterPageFile="~/Modules/Admin/Admin.Master" AutoEventWireup="true" CodeBehind="Courses.aspx.cs" Inherits="CodeLab.Modules.Admin.Courses" %>
<%@ Import Namespace="CodeLab.Helpers" %>

<asp:Content ID="CoursesContent" ContentPlaceHolderID="AdminContent" runat="server">

    <section class="cl-card cl-admin-panel">
        <div class="cl-admin-panel-head">
            <div>
                <h2>Courses</h2>
                <p>Review what tutors submit, publish it or send it back with feedback, and lock anything that breaks the rules.</p>
            </div>
            <nav class="cl-admin-filters" aria-label="Filter by status">
                <asp:HyperLink ID="hlFilterAll" runat="server" />
                <asp:HyperLink ID="hlFilterPending" runat="server" />
                <asp:HyperLink ID="hlFilterPublished" runat="server" />
                <asp:HyperLink ID="hlFilterLocked" runat="server" />
                <asp:HyperLink ID="hlFilterDraft" runat="server" />
            </nav>
        </div>

        <%-- ValidateRequestMode="Disabled" lets the admin search for text such as C<T>. That is safe
             because the search text is only shown encoded and sent to SQL as a parameter. --%>
        <asp:Panel ID="pnlSearch" runat="server" CssClass="cl-admin-search" DefaultButton="btnSearch">
            <asp:TextBox ID="txtSearch" runat="server" CssClass="form-control" MaxLength="100" ValidateRequestMode="Disabled"
                placeholder="Search by title, tutor or email" aria-label="Search courses" />
            <asp:Button ID="btnSearch" runat="server" Text="Search" CssClass="btn cl-btn-outline" CausesValidation="false" OnClick="btnSearch_Click" />
            <asp:HyperLink ID="hlClearSearch" runat="server" CssClass="btn btn-link" Text="Clear" Visible="false" />
        </asp:Panel>

        <asp:Label ID="lblMessage" runat="server" Visible="false" />

        <asp:Repeater ID="rptCourses" runat="server" OnItemCommand="rptCourses_ItemCommand">
            <HeaderTemplate>
                <div class="table-responsive">
                    <table class="table cl-admin-table">
                        <thead>
                            <tr>
                                <th scope="col">Course</th>
                                <th scope="col">Tutor</th>
                                <th scope="col">Category</th>
                                <th scope="col">Status</th>
                                <th scope="col" class="text-end">Students</th>
                                <th scope="col" class="text-end">Actions</th>
                            </tr>
                        </thead>
                        <tbody>
            </HeaderTemplate>
            <ItemTemplate>
                <tr>
                    <td>
                        <strong class="d-block"><%#: Eval("Title") %></strong>
                        <span class="cl-admin-meta"><%#: Eval("Difficulty") %>, <%#: LessonText((int)Eval("LessonCount")) %></span>
                    </td>
                    <td>
                        <span class="d-block"><%#: Eval("TutorName") %></span>
                        <span class="cl-admin-meta"><%#: Eval("TutorEmail") %></span>
                    </td>
                    <td><%#: Eval("Category") %></td>
                    <td>
                        <span class="cl-admin-badge <%# DisplayHelper.CourseBadgeCss((string)Eval("Status")) %>"><%#: Eval("Status") %></span>
                        <asp:PlaceHolder runat="server" Visible='<%# !string.IsNullOrEmpty((string)Eval("ModerationNote")) %>'>
                            <span class="cl-admin-note">Reason: <%#: DisplayHelper.Excerpt((string)Eval("ModerationNote"), 90) %></span>
                        </asp:PlaceHolder>
                    </td>
                    <td class="text-end"><%# Eval("StudentCount") %></td>
                    <td>
                        <div class="cl-admin-row-actions">
                            <asp:HyperLink runat="server" CssClass='<%# (bool)Eval("CanApproveOrReject") ? "btn btn-primary btn-sm cl-admin-action-primary" : "btn cl-btn-outline btn-sm cl-admin-action-primary" %>'
                                NavigateUrl='<%# "~/Modules/Admin/CourseReview?id=" + Eval("Id") %>'>
                                <i data-lucide="eye" class="cl-icon" aria-hidden="true"></i> <%#: Eval("PrimaryActionText") %>
                            </asp:HyperLink>
                            <asp:LinkButton runat="server" CssClass="btn btn-success btn-sm" CausesValidation="false" ToolTip="Approve and publish" aria-label="Approve and publish"
                                CommandName="Approve" CommandArgument='<%# Eval("Id") %>' Visible='<%# (bool)Eval("CanApproveOrReject") %>'
                                OnClientClick="return confirm('Publish this course? Learners can enrol straight away.');">
                                <i data-lucide="check" class="cl-icon" aria-hidden="true"></i>
                            </asp:LinkButton>
                            <asp:HyperLink runat="server" CssClass="btn btn-outline-warning btn-sm" ToolTip="Lock (a reason is required)" aria-label="Lock"
                                NavigateUrl='<%# "~/Modules/Admin/CourseReview?id=" + Eval("Id") + "#decision" %>' Visible='<%# (bool)Eval("CanLock") %>'>
                                <i data-lucide="lock" class="cl-icon" aria-hidden="true"></i>
                            </asp:HyperLink>
                            <asp:LinkButton runat="server" CssClass="btn btn-outline-success btn-sm" CausesValidation="false" ToolTip="Unlock and publish again" aria-label="Unlock"
                                CommandName="Unlock" CommandArgument='<%# Eval("Id") %>' Visible='<%# (bool)Eval("CanUnlock") %>'
                                OnClientClick="return confirm('Unlock this course? It will be published again.');">
                                <i data-lucide="lock-open" class="cl-icon" aria-hidden="true"></i>
                            </asp:LinkButton>
                            <asp:PlaceHolder runat="server" Visible='<%# !(bool)Eval("HasMiddleAction") %>'>
                                <span class="cl-admin-action-spacer" aria-hidden="true"></span>
                            </asp:PlaceHolder>
                            <asp:LinkButton runat="server" CssClass="btn btn-outline-danger btn-sm" CausesValidation="false" ToolTip="Delete permanently" aria-label="Delete"
                                CommandName="Delete" CommandArgument='<%# Eval("Id") %>'
                                OnClientClick='<%# DisplayHelper.CourseDeleteConfirm((int)Eval("StudentCount")) %>'>
                                <i data-lucide="trash-2" class="cl-icon" aria-hidden="true"></i>
                            </asp:LinkButton>
                        </div>
                    </td>
                </tr>
            </ItemTemplate>
            <FooterTemplate>
                        </tbody>
                    </table>
                </div>
            </FooterTemplate>
        </asp:Repeater>

        <asp:PlaceHolder ID="phEmpty" runat="server" Visible="false">
            <div class="cl-admin-empty">
                <i data-lucide="inbox" class="cl-icon" aria-hidden="true"></i>
                <p><asp:Literal ID="litEmpty" runat="server" Mode="Encode" /></p>
            </div>
        </asp:PlaceHolder>
    </section>

</asp:Content>

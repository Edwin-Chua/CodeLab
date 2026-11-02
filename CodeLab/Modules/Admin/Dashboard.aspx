<%@ Page Title="Admin Dashboard" Language="C#" MasterPageFile="~/Modules/Admin/Admin.Master" AutoEventWireup="true" CodeBehind="Dashboard.aspx.cs" Inherits="CodeLab.Modules.Admin.Dashboard" %>
<%@ Import Namespace="CodeLab.Helpers" %>

<asp:Content ID="DashboardContent" ContentPlaceHolderID="AdminContent" runat="server">

    <asp:Label ID="lblMessage" runat="server" CssClass="alert alert-danger d-block" Visible="false" />

    <div class="row g-4">
        <%-- ===== Work waiting for review comes first, in the wider column ===== --%>
        <div class="col-lg-7 d-flex flex-column gap-4">
            <section class="cl-card cl-admin-panel">
                <div class="cl-admin-panel-head">
                    <span class="cl-admin-panel-icon cl-admin-tone-amber"><i data-lucide="graduation-cap" class="cl-icon" aria-hidden="true"></i></span>
                    <div>
                        <h2>Pending tutor applications</h2>
                        <p><asp:Literal ID="litPendingSummary" runat="server" Mode="Encode" /></p>
                    </div>
                    <a runat="server" href="~/Modules/Admin/TutorApplications" class="cl-admin-panel-link">Review all</a>
                </div>

                <asp:Repeater ID="rptPendingTutors" runat="server">
                    <HeaderTemplate><ul class="cl-admin-list"></HeaderTemplate>
                    <ItemTemplate>
                        <li class="cl-admin-list-item">
                            <%# DisplayHelper.AvatarHtml((string)Eval("FullName"), (string)Eval("AvatarUrl")) %>
                            <div class="cl-admin-list-text">
                                <strong><%#: Eval("FullName") %></strong>
                                <span><%#: Eval("Specialty") %>, applied <%#: DisplayHelper.TimeAgo((DateTime)Eval("AppliedAt")) %></span>
                            </div>
                            <asp:HyperLink runat="server" CssClass="btn btn-primary btn-sm" Text="Review"
                                NavigateUrl='<%# "~/Modules/Admin/TutorApplication?userId=" + Eval("UserId") %>' />
                        </li>
                    </ItemTemplate>
                    <FooterTemplate></ul></FooterTemplate>
                </asp:Repeater>

                <asp:PlaceHolder ID="phNoPending" runat="server" Visible="false">
                    <div class="cl-admin-empty">
                        <i data-lucide="circle-check" class="cl-icon" aria-hidden="true"></i>
                        <p>No applications are waiting. New ones will appear here.</p>
                    </div>
                </asp:PlaceHolder>
            </section>

            <%-- flex-grow-1 lets this column reach the bottom of Recent users when it is the shorter one --%>
            <section class="cl-card cl-admin-panel flex-grow-1">
                <div class="cl-admin-panel-head">
                    <span class="cl-admin-panel-icon cl-admin-tone-accent"><i data-lucide="book-open" class="cl-icon" aria-hidden="true"></i></span>
                    <div>
                        <h2>Course moderation</h2>
                        <p><asp:Literal ID="litCourseSummary" runat="server" Mode="Encode" /></p>
                    </div>
                    <a runat="server" href="~/Modules/Admin/Courses" class="cl-admin-panel-link">All courses</a>
                </div>

                <asp:Repeater ID="rptCourses" runat="server">
                    <HeaderTemplate><ul class="cl-admin-list"></HeaderTemplate>
                    <ItemTemplate>
                        <li class="cl-admin-list-item">
                            <div class="cl-admin-list-text">
                                <strong><%#: Eval("Title") %></strong>
                                <span><%#: Eval("TutorName") %>, <%#: Eval("Category") %></span>
                            </div>
                            <span class="cl-admin-badge <%# DisplayHelper.CourseBadgeCss((string)Eval("Status")) %>"><%#: Eval("Status") %></span>
                            <asp:HyperLink runat="server" CssClass="btn btn-primary btn-sm" Text="Review"
                                NavigateUrl='<%# "~/Modules/Admin/CourseReview?id=" + Eval("Id") %>' />
                        </li>
                    </ItemTemplate>
                    <FooterTemplate></ul></FooterTemplate>
                </asp:Repeater>

                <asp:PlaceHolder ID="phNoCourses" runat="server" Visible="false">
                    <div class="cl-admin-empty">
                        <i data-lucide="circle-check" class="cl-icon" aria-hidden="true"></i>
                        <p>No courses are waiting or locked. New submissions will appear here.</p>
                    </div>
                </asp:PlaceHolder>
            </section>
        </div>

        <%-- ===== Recent users ===== --%>
        <div class="col-lg-5">
            <section class="cl-card cl-admin-panel h-100">
                <div class="cl-admin-panel-head">
                    <span class="cl-admin-panel-icon cl-admin-tone-accent"><i data-lucide="users" class="cl-icon" aria-hidden="true"></i></span>
                    <div>
                        <h2>Recent users</h2>
                        <p><asp:Literal ID="litUserSummary" runat="server" Mode="Encode" /></p>
                    </div>
                    <a runat="server" href="~/Modules/Admin/Users" class="cl-admin-panel-link">Manage all users</a>
                </div>

                <asp:Repeater ID="rptUsers" runat="server">
                    <HeaderTemplate><ul class="cl-admin-list"></HeaderTemplate>
                    <ItemTemplate>
                        <li class="cl-admin-list-item">
                            <%# DisplayHelper.AvatarHtml((string)Eval("FullName"), (string)Eval("AvatarUrl")) %>
                            <div class="cl-admin-list-text">
                                <strong><%#: Eval("FullName") %></strong>
                                <span><%#: Eval("Email") %></span>
                            </div>
                            <span class="cl-admin-badge <%# DisplayHelper.RoleBadgeCss((string)Eval("Role")) %>"><%#: Eval("Role") %></span>
                            <asp:HyperLink runat="server" CssClass="btn cl-btn-outline btn-sm" Text="Edit"
                                NavigateUrl='<%# "~/Modules/Admin/UserEdit?id=" + Eval("Id") %>' />
                        </li>
                    </ItemTemplate>
                    <FooterTemplate></ul></FooterTemplate>
                </asp:Repeater>
            </section>
        </div>
    </div>

</asp:Content>

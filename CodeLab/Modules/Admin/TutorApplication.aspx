<%@ Page Title="Tutor Application" Language="C#" MasterPageFile="~/Modules/Admin/Admin.Master" AutoEventWireup="true" CodeBehind="TutorApplication.aspx.cs" Inherits="CodeLab.Modules.Admin.TutorApplication" %>

<asp:Content ID="ApplicationContent" ContentPlaceHolderID="AdminContent" runat="server">

    <a runat="server" href="~/Modules/Admin/TutorApplications" class="cl-admin-back">
        <i data-lucide="arrow-left" class="cl-icon" aria-hidden="true"></i>All applications
    </a>

    <asp:Label ID="lblMessage" runat="server" Visible="false" />

    <asp:PlaceHolder ID="phApplication" runat="server">
        <div class="row g-4">
            <%-- ===== The application ===== --%>
            <div class="col-lg-8">
                <section class="cl-card cl-admin-panel">
                    <div class="cl-admin-applicant">
                        <asp:Literal ID="litAvatar" runat="server" />
                        <div>
                            <h2><asp:Literal ID="litName" runat="server" Mode="Encode" /></h2>
                            <span class="cl-admin-meta"><asp:Literal ID="litSpecialty" runat="server" Mode="Encode" /></span>
                        </div>
                        <asp:Label ID="lblStatus" runat="server" />
                    </div>

                    <dl class="cl-admin-facts">
                        <dt>Username</dt>
                        <dd><asp:Literal ID="litUsername" runat="server" Mode="Encode" /></dd>
                        <dt>Email</dt>
                        <dd><asp:Literal ID="litEmail" runat="server" Mode="Encode" /></dd>
                        <dt>Applied</dt>
                        <dd><asp:Literal ID="litApplied" runat="server" Mode="Encode" /></dd>
                        <dt>Portfolio</dt>
                        <dd><asp:HyperLink ID="hlPortfolio" runat="server" Target="_blank" /></dd>
                    </dl>

                    <div class="cl-admin-section">
                        <h3>About</h3>
                        <p class="cl-admin-prose"><asp:Literal ID="litBio" runat="server" Mode="Encode" /></p>
                    </div>
                    <div class="cl-admin-section">
                        <h3>Qualifications</h3>
                        <p class="cl-admin-prose"><asp:Literal ID="litQualifications" runat="server" Mode="Encode" /></p>
                    </div>
                    <div class="cl-admin-section">
                        <h3>Sample curriculum pitch</h3>
                        <p class="cl-admin-prose"><asp:Literal ID="litPitch" runat="server" Mode="Encode" /></p>
                    </div>
                </section>
            </div>

            <%-- ===== Decision ===== --%>
            <div class="col-lg-4">
                <section id="decision" class="cl-card cl-admin-panel cl-admin-decision">
                    <h2 class="cl-admin-panel-title">Decision</h2>

                    <asp:PlaceHolder ID="phDecision" runat="server">
                        <p class="cl-admin-meta">Approving unlocks course authoring for this tutor straight away.</p>
                        <asp:Button ID="btnApprove" runat="server" Text="Approve tutor" CssClass="btn btn-success w-100"
                            CausesValidation="false" OnClick="btnApprove_Click"
                            OnClientClick="return confirm('Approve this tutor? They can start creating courses straight away.');" />

                        <hr />

                        <asp:Label ID="lblReason" runat="server" AssociatedControlID="txtReason" CssClass="form-label" Text="Reason for rejecting" />
                        <%-- ValidateRequestMode="Disabled" lets the admin type characters such as < in the reason.
                             That is safe because the reason is only ever shown as encoded text. --%>
                        <asp:TextBox ID="txtReason" runat="server" TextMode="MultiLine" Rows="4" CssClass="form-control"
                            ValidateRequestMode="Disabled" placeholder="Tell the applicant what to improve. They will see this." />
                        <asp:RequiredFieldValidator ID="rfvReason" runat="server" ControlToValidate="txtReason" ValidationGroup="Reject"
                            ErrorMessage="Please give a reason. The applicant will see it." CssClass="text-danger small" Display="Dynamic" />
                        <asp:RegularExpressionValidator ID="revReason" runat="server" ControlToValidate="txtReason" ValidationGroup="Reject"
                            ValidationExpression="^[\s\S]{10,500}$" ErrorMessage="The reason must be 10 to 500 characters."
                            CssClass="text-danger small" Display="Dynamic" />
                        <asp:Button ID="btnReject" runat="server" Text="Reject application" CssClass="btn btn-outline-danger w-100 mt-2"
                            ValidationGroup="Reject" OnClick="btnReject_Click" />
                    </asp:PlaceHolder>

                    <asp:PlaceHolder ID="phDecided" runat="server" Visible="false">
                        <p class="mb-0"><asp:Literal ID="litDecision" runat="server" Mode="Encode" /></p>
                        <asp:PlaceHolder ID="phReason" runat="server" Visible="false">
                            <p class="cl-admin-reason"><strong>Reason given:</strong> <asp:Literal ID="litReason" runat="server" Mode="Encode" /></p>
                        </asp:PlaceHolder>
                    </asp:PlaceHolder>
                </section>
            </div>
        </div>
    </asp:PlaceHolder>

</asp:Content>

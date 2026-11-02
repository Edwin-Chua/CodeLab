<%@ Page Title="Coding Results" Language="C#" MasterPageFile="~/Modules/Tutor/Tutor.Master" AutoEventWireup="true" CodeBehind="ChallengeResults.aspx.cs" Inherits="CodeLab.Modules.Tutor.ChallengeResults" %>
<%@ MasterType VirtualPath="~/Modules/Tutor/Tutor.Master" %>
<%@ Import Namespace="CodeLab.Models" %>
<%@ Import Namespace="CodeLab.Helpers" %>

<asp:Content ID="ChallengeResultsContent" ContentPlaceHolderID="TutorContent" runat="server">

    <%-- ===== Header ===== --%>
    <div class="cl-builder-header">
        <div class="cl-builder-heading">
            <nav class="cl-crumbs" aria-label="Breadcrumb">
                <a href="<%: Master.GetPageUrl("Dashboard") %>">Dashboard</a>
                <i data-lucide="chevron-right" class="cl-icon" aria-hidden="true"></i>
                <asp:Literal ID="litCrumbs" runat="server" Mode="PassThrough" />
            </nav>
            <h1><asp:Literal ID="litHeading" runat="server" Mode="Encode" /></h1>
            <p><asp:Literal ID="litSubheading" runat="server" Mode="Encode" /></p>
        </div>
    </div>

    <asp:Label ID="lblMessage" runat="server" CssClass="cl-alert cl-alert-danger" Visible="false" />

    <%-- ===== Not approved yet ===== --%>
    <asp:PlaceHolder ID="phLocked" runat="server" Visible="false">
        <section class="cl-card cl-state-card">
            <svg class="cl-state-art" viewBox="0 0 200 140" aria-hidden="true">
                <defs><linearGradient id="lockGrad" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#C9527D" /><stop offset="1" stop-color="#FFA2A4" /></linearGradient></defs>
                <circle cx="100" cy="70" r="62" fill="url(#lockGrad)" opacity=".12" />
                <rect x="66" y="62" width="68" height="52" rx="12" fill="url(#lockGrad)" />
                <path d="M80 62V48a20 20 0 0 1 40 0v14" fill="none" stroke="url(#lockGrad)" stroke-width="9" stroke-linecap="round" />
                <circle cx="100" cy="84" r="7" fill="#fff" /><rect x="97" y="86" width="6" height="14" rx="3" fill="#fff" />
            </svg>
            <h2>Coding Results are locked</h2>
            <p>You can see learner results once an administrator approves your tutor application.</p>
            <a class="btn btn-primary" href="<%: Master.GetPageUrl("Profile") %>">View my application</a>
        </section>
    </asp:PlaceHolder>

    <%-- ===== 1. All challenges ===== --%>
    <asp:PlaceHolder ID="phOverview" runat="server" Visible="false">
        <section class="cl-card cl-table-card" data-results-table>
            <div class="cl-table-card-header cl-results-toolbar">
                <div>
                    <h2>Coding challenges in your published courses</h2>
                    <p>A learner counts as solved once one of their submissions passes. Open a challenge to see every submission.</p>
                </div>
                <asp:PlaceHolder ID="phCourseFilter" runat="server" Visible="false">
                    <div class="cl-results-filters">
                        <select class="form-select" aria-label="Course" data-filter-course>
                            <option value="">All courses</option>
                            <asp:Literal ID="litCourseOptions" runat="server" Mode="PassThrough" />
                        </select>
                    </div>
                </asp:PlaceHolder>
            </div>
            <asp:Repeater ID="rptChallenges" runat="server">
                <HeaderTemplate>
                    <div class="table-responsive">
                    <table class="table cl-table cl-results-table">
                        <thead><tr><th>Challenge</th><th>Language</th><th>Learners</th><th>Solved</th><th>Submissions</th><th><span class="visually-hidden">Open</span></th></tr></thead>
                        <tbody>
                </HeaderTemplate>
                <ItemTemplate>
                    <tr data-course="<%#: Eval("CourseTitle") %>">
                        <td class="cl-table-title"><a class="cl-row-link" href="<%#: ChallengeUrl((int)Eval("ChallengeId")) %>"><%#: Eval("Title") %></a><small class="cl-table-sub"><%#: Eval("CourseTitle") %></small></td>
                        <td><span class="cl-code-chip"><%#: TutorDisplayHelper.LanguageName((string)Eval("Language")) %></span></td>
                        <td><%# Eval("LearnerCount") %></td>
                        <td><%# SolvedHtml((ChallengeResultSummary)Container.DataItem) %></td>
                        <td><%# Eval("SubmissionCount") %></td>
                        <td class="text-end"><a class="btn btn-sm btn-outline-primary" href="<%#: ChallengeUrl((int)Eval("ChallengeId")) %>">View results</a></td>
                    </tr>
                </ItemTemplate>
                <FooterTemplate></tbody></table></div></FooterTemplate>
            </asp:Repeater>
            <div class="cl-empty cl-empty-sm" data-filter-empty hidden><p>No coding challenges in this course.</p></div>
            <asp:PlaceHolder ID="phNoChallenges" runat="server" Visible="false">
                <div class="cl-empty">
                    <span class="cl-builder-icon cl-tone-pink"><i data-lucide="code" class="cl-icon" aria-hidden="true"></i></span>
                    <h3>No published coding challenges yet</h3>
                    <p>Results appear here once a course with a coding challenge is published and learners try it.</p>
                </div>
            </asp:PlaceHolder>
        </section>
    </asp:PlaceHolder>

    <%-- ===== 2. One challenge: every submission ===== --%>
    <asp:PlaceHolder ID="phChallenge" runat="server" Visible="false">
        <div class="cl-stat-grid cl-results-stats">
            <div class="cl-stat-card">
                <span class="cl-stat-icon cl-tone-blue"><i data-lucide="users" class="cl-icon" aria-hidden="true"></i></span>
                <div>
                    <div class="cl-stat-card-value"><asp:Literal ID="litLearners" runat="server" Mode="Encode" /></div>
                    <div class="cl-stat-card-label">Enrolled learners</div>
                    <div class="cl-stat-card-note"><asp:Literal ID="litLearnersNote" runat="server" Mode="Encode" /></div>
                </div>
            </div>
            <div class="cl-stat-card">
                <span class="cl-stat-icon cl-tone-green"><i data-lucide="circle-check-big" class="cl-icon" aria-hidden="true"></i></span>
                <div>
                    <div class="cl-stat-card-value"><asp:Literal ID="litSolved" runat="server" Mode="Encode" /></div>
                    <div class="cl-stat-card-label">Solved</div>
                    <div class="cl-stat-card-note"><asp:Literal ID="litSolvedNote" runat="server" Mode="Encode" /></div>
                </div>
            </div>
            <div class="cl-stat-card">
                <span class="cl-stat-icon cl-tone-pink"><i data-lucide="user-x" class="cl-icon" aria-hidden="true"></i></span>
                <div>
                    <div class="cl-stat-card-value"><asp:Literal ID="litNotTried" runat="server" Mode="Encode" /></div>
                    <div class="cl-stat-card-label">Not tried yet</div>
                    <div class="cl-stat-card-note"><asp:Literal ID="litNotTriedNote" runat="server" Mode="Encode" /></div>
                </div>
            </div>
            <div class="cl-stat-card">
                <span class="cl-stat-icon cl-tone-amber"><i data-lucide="square-terminal" class="cl-icon" aria-hidden="true"></i></span>
                <div>
                    <div class="cl-stat-card-value"><asp:Literal ID="litSubmissions" runat="server" Mode="Encode" /></div>
                    <div class="cl-stat-card-label">Submissions</div>
                    <div class="cl-stat-card-note"><asp:Literal ID="litSubmissionsNote" runat="server" Mode="Encode" /></div>
                </div>
            </div>
        </div>

        <section class="cl-card cl-table-card" data-results-table>
            <div class="cl-table-card-header cl-results-toolbar">
                <div>
                    <h2>Submissions</h2>
                    <p>Newest first. Open a submission to see the learner's code and output.</p>
                </div>
                <asp:PlaceHolder ID="phSubmissionFilters" runat="server">
                    <div class="cl-results-filters">
                        <label class="cl-results-search">
                            <i data-lucide="search" class="cl-icon" aria-hidden="true"></i>
                            <input type="search" class="form-control" placeholder="Search learner" aria-label="Search learner" data-filter-search />
                        </label>
                        <select class="form-select" aria-label="Result" data-filter-result>
                            <option value="">All results</option>
                            <option value="passed">Passed</option>
                            <option value="failed">Failed</option>
                            <option value="error">Error</option>
                        </select>
                    </div>
                </asp:PlaceHolder>
            </div>
            <asp:Repeater ID="rptSubmissions" runat="server">
                <HeaderTemplate>
                    <div class="table-responsive">
                    <table class="table cl-table cl-results-table">
                        <thead><tr><th>Learner</th><th>Attempt</th><th>Result</th><th>When</th><th><span class="visually-hidden">Open</span></th></tr></thead>
                        <tbody>
                </HeaderTemplate>
                <ItemTemplate>
                    <tr data-name="<%#: (Eval("LearnerName") + " " + Eval("LearnerUsername")).ToLowerInvariant() %>"
                        data-result="<%#: ((string)Eval("Status")).ToLowerInvariant() %>">
                        <td><%# TutorDisplayHelper.LearnerHtml((string)Eval("LearnerName"), (string)Eval("LearnerUsername"), (string)Eval("LearnerAvatarUrl")) %></td>
                        <td><span class="cl-attempt-chip"><%#: TutorDisplayHelper.Ordinal((int)Eval("AttemptNumber")) %></span></td>
                        <td><%# TutorDisplayHelper.SubmissionStatusHtml((string)Eval("Status")) %></td>
                        <td class="text-muted" title="<%#: TutorDisplayHelper.LocalDateTime((DateTime)Eval("SubmittedAt")) %>"><%#: TutorDisplayHelper.TimeAgo((DateTime)Eval("SubmittedAt")) %></td>
                        <td class="text-end"><a class="btn btn-sm btn-outline-primary" href="<%#: SubmissionUrl((int)Eval("SubmissionId")) %>">View code</a></td>
                    </tr>
                </ItemTemplate>
                <FooterTemplate></tbody></table></div></FooterTemplate>
            </asp:Repeater>
            <div class="cl-empty cl-empty-sm" data-filter-empty hidden><p>No submissions match these filters.</p></div>
            <asp:PlaceHolder ID="phNoSubmissions" runat="server" Visible="false">
                <div class="cl-empty">
                    <span class="cl-builder-icon cl-tone-amber"><i data-lucide="hourglass" class="cl-icon" aria-hidden="true"></i></span>
                    <h3>No submissions yet</h3>
                    <p>Submissions show up here as soon as learners run their code for this challenge.</p>
                </div>
            </asp:PlaceHolder>
        </section>
    </asp:PlaceHolder>

    <%-- ===== 3. One submission: code and output ===== --%>
    <asp:PlaceHolder ID="phSubmission" runat="server" Visible="false">
        <div class="cl-results-layout">
            <div class="cl-results-main">
                <section class="cl-card cl-attempt-summary">
                    <div class="cl-attempt-who">
                        <asp:Literal ID="litSubmissionLearner" runat="server" Mode="PassThrough" />
                        <div class="cl-attempt-meta">
                            <span><i data-lucide="repeat" class="cl-icon" aria-hidden="true"></i><asp:Literal ID="litSubmissionNumber" runat="server" Mode="Encode" /></span>
                            <span><i data-lucide="calendar" class="cl-icon" aria-hidden="true"></i><asp:Literal ID="litSubmissionDate" runat="server" Mode="Encode" /></span>
                        </div>
                    </div>
                    <div class="cl-attempt-score">
                        <div>
                            <asp:Literal ID="litSubmissionBadge" runat="server" Mode="PassThrough" />
                            <p><asp:Literal ID="litSubmissionNote" runat="server" Mode="Encode" /></p>
                        </div>
                    </div>
                </section>

                <section class="cl-card cl-results-code">
                    <div class="cl-chart-head">
                        <div><h2>Submitted code</h2><p>Exactly as the learner submitted it.</p></div>
                    </div>
                    <div class="cl-ide">
                        <div class="cl-ide-bar">
                            <span class="cl-ide-dots" aria-hidden="true"><i></i><i></i><i></i></span>
                            <span class="cl-ide-label"><asp:Literal ID="litLanguage" runat="server" Mode="Encode" /></span>
                        </div>
                        <pre class="cl-ide-code"><code class="<%: CodeCss %>"><asp:Literal ID="litCode" runat="server" Mode="Encode" /></code></pre>
                    </div>
                </section>

                <div class="cl-output-compare">
                    <section class="cl-card cl-results-code">
                        <div class="cl-chart-head">
                            <div><h2>Learner's output</h2><p>What the code printed.</p></div>
                            <asp:Literal ID="litOutputMatch" runat="server" Mode="PassThrough" />
                        </div>
                        <pre class="cl-output-box"><asp:Literal ID="litOutput" runat="server" Mode="Encode" /></pre>
                    </section>
                    <section class="cl-card cl-results-code">
                        <div class="cl-chart-head">
                            <div><h2>Expected output</h2><p>From the challenge.</p></div>
                        </div>
                        <pre class="cl-output-box is-expected"><asp:Literal ID="litExpected" runat="server" Mode="Encode" /></pre>
                    </section>
                </div>
            </div>

            <aside class="cl-card cl-results-aside">
                <div class="cl-chart-head">
                    <div><h2>All submissions by this learner</h2><p>To this challenge, newest first.</p></div>
                </div>
                <asp:Repeater ID="rptLearnerSubmissions" runat="server">
                    <HeaderTemplate><ul class="cl-attempt-list"></HeaderTemplate>
                    <ItemTemplate>
                        <li>
                            <a class="<%# (int)Eval("SubmissionId") == SubmissionId ? "is-current" : string.Empty %>" href="<%#: SubmissionUrl((int)Eval("SubmissionId")) %>"
                                <%# (int)Eval("SubmissionId") == SubmissionId ? "aria-current=\"page\"" : string.Empty %>>
                                <span class="cl-attempt-chip"><%#: TutorDisplayHelper.Ordinal((int)Eval("AttemptNumber")) %></span>
                                <span class="cl-attempt-list-text">
                                    <strong><%#: TutorDisplayHelper.LocalDate((DateTime)Eval("SubmittedAt")) %></strong>
                                    <small><%#: TutorDisplayHelper.LocalTime((DateTime)Eval("SubmittedAt")) %></small>
                                </span>
                                <%# TutorDisplayHelper.SubmissionStatusHtml((string)Eval("Status")) %>
                            </a>
                        </li>
                    </ItemTemplate>
                    <FooterTemplate></ul></FooterTemplate>
                </asp:Repeater>
                <a class="btn btn-outline-primary w-100 mt-3" href="<%: ChallengeUrl(ChallengeId) %>">
                    <i data-lucide="arrow-left" class="cl-icon" aria-hidden="true"></i> All submissions to this challenge
                </a>
            </aside>
        </div>
    </asp:PlaceHolder>

    <%-- Syntax colours for the submitted code --%>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/styles/atom-one-dark.min.css" />
    <script src="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/highlight.min.js"></script>
    <script src="<%: ResolveUrl("~/Scripts/tutor-results.js") %>"></script>

</asp:Content>

<%@ Page Title="Quiz Results" Language="C#" MasterPageFile="~/Modules/Tutor/Tutor.Master" AutoEventWireup="true" CodeBehind="QuizResults.aspx.cs" Inherits="CodeLab.Modules.Tutor.QuizResults" %>
<%@ MasterType VirtualPath="~/Modules/Tutor/Tutor.Master" %>
<%@ Import Namespace="CodeLab.Models" %>
<%@ Import Namespace="CodeLab.Helpers" %>

<%-- Do not auto-format this file: a formatter that wraps or re-spaces the data-binding expressions breaks the page. --%>
<asp:Content ID="QuizResultsContent" ContentPlaceHolderID="TutorContent" runat="server">

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
            <h2>Quiz Results are locked</h2>
            <p>You can see learner results once an administrator approves your tutor application.</p>
            <a class="btn btn-primary" href="<%: Master.GetPageUrl("Profile") %>">View my application</a>
        </section>
    </asp:PlaceHolder>

    <%-- ===== 1. All quizzes ===== --%>
    <asp:PlaceHolder ID="phOverview" runat="server" Visible="false">
        <section class="cl-card cl-table-card" data-results-table>
            <div class="cl-table-card-header cl-results-toolbar">
                <div>
                    <h2>Quizzes in your published courses</h2>
                    <p>A learner counts as completed once one of their attempts reaches the pass mark. Open a quiz to see every attempt.</p>
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
            <asp:Repeater ID="rptQuizzes" runat="server">
                <HeaderTemplate>
                    <div class="table-responsive">
                    <table class="table cl-table cl-results-table">
                        <thead><tr><th>Quiz</th><th>Questions</th><th>Learners</th><th>Completed</th><th>Attempts</th><th>Avg score</th><th><span class="visually-hidden">Open</span></th></tr></thead>
                        <tbody>
                </HeaderTemplate>
                <ItemTemplate>
                    <tr data-course="<%#: Eval("CourseTitle") %>">
                        <td class="cl-table-title"><a class="cl-row-link" href="<%#: QuizUrl((int)Eval("QuizId")) %>"><%#: Eval("QuizTitle") %></a><small class="cl-table-sub"><%#: Eval("CourseTitle") %></small></td>
                        <td><%# Eval("QuestionCount") %></td>
                        <td><%# Eval("LearnerCount") %></td>
                        <td><%# CompletedHtml((QuizResultSummary)Container.DataItem) %></td>
                        <td><%# Eval("AttemptCount") %></td>
                        <td><%#: ScoreText((double?)Eval("AverageScore")) %></td>
                        <td class="text-end"><a class="btn btn-sm btn-outline-primary" href="<%#: QuizUrl((int)Eval("QuizId")) %>">View results</a></td>
                    </tr>
                </ItemTemplate>
                <FooterTemplate></tbody></table></div></FooterTemplate>
            </asp:Repeater>
            <div class="cl-empty cl-empty-sm" data-filter-empty hidden><p>No quizzes in this course.</p></div>
            <asp:PlaceHolder ID="phNoQuizzes" runat="server" Visible="false">
                <div class="cl-empty">
                    <span class="cl-builder-icon cl-tone-pink"><i data-lucide="list-checks" class="cl-icon" aria-hidden="true"></i></span>
                    <h3>No published quizzes yet</h3>
                    <p>Results appear here once a course with a quiz is published and learners take it.</p>
                </div>
            </asp:PlaceHolder>
        </section>
    </asp:PlaceHolder>

    <%-- ===== 2. One quiz: every attempt ===== --%>
    <asp:PlaceHolder ID="phQuiz" runat="server" Visible="false">
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
                    <div class="cl-stat-card-value"><asp:Literal ID="litCompleted" runat="server" Mode="Encode" /></div>
                    <div class="cl-stat-card-label">Completed</div>
                    <div class="cl-stat-card-note"><asp:Literal ID="litCompletedNote" runat="server" Mode="Encode" /></div>
                </div>
            </div>
            <div class="cl-stat-card">
                <span class="cl-stat-icon cl-tone-pink"><i data-lucide="user-x" class="cl-icon" aria-hidden="true"></i></span>
                <div>
                    <div class="cl-stat-card-value"><asp:Literal ID="litNotTaken" runat="server" Mode="Encode" /></div>
                    <div class="cl-stat-card-label">Not taken yet</div>
                    <div class="cl-stat-card-note"><asp:Literal ID="litNotTakenNote" runat="server" Mode="Encode" /></div>
                </div>
            </div>
            <div class="cl-stat-card">
                <span class="cl-stat-icon cl-tone-amber"><i data-lucide="trending-up" class="cl-icon" aria-hidden="true"></i></span>
                <div>
                    <div class="cl-stat-card-value"><asp:Literal ID="litAverage" runat="server" Mode="Encode" /></div>
                    <div class="cl-stat-card-label">Average score</div>
                    <div class="cl-stat-card-note"><asp:Literal ID="litAverageNote" runat="server" Mode="Encode" /></div>
                </div>
            </div>
        </div>

        <section class="cl-card cl-table-card" data-results-table>
            <div class="cl-table-card-header cl-results-toolbar">
                <div>
                    <h2>Attempts</h2>
                    <p>Newest first. Open an attempt to see which answers were right or wrong.</p>
                </div>
                <asp:PlaceHolder ID="phAttemptFilters" runat="server">
                    <div class="cl-results-filters">
                        <label class="cl-results-search">
                            <i data-lucide="search" class="cl-icon" aria-hidden="true"></i>
                            <input type="search" class="form-control" placeholder="Search learner" aria-label="Search learner" data-filter-search />
                        </label>
                        <select class="form-select" aria-label="Result" data-filter-result>
                            <option value="">All results</option>
                            <option value="passed">Passed</option>
                            <option value="failed">Failed</option>
                        </select>
                    </div>
                </asp:PlaceHolder>
            </div>
            <asp:Repeater ID="rptAttempts" runat="server">
                <HeaderTemplate>
                    <div class="table-responsive">
                    <table class="table cl-table cl-results-table">
                        <thead><tr><th>Learner</th><th>Attempt</th><th>Score</th><th>Correct</th><th>Result</th><th>When</th><th><span class="visually-hidden">Open</span></th></tr></thead>
                        <tbody>
                </HeaderTemplate>
                <ItemTemplate>
                    <tr data-name="<%#: (Eval("LearnerName") + " " + Eval("LearnerUsername")).ToLowerInvariant() %>" data-result="<%# (bool)Eval("Passed") ? "passed" : "failed" %>">
                        <td><%# TutorDisplayHelper.LearnerHtml((string)Eval("LearnerName"), (string)Eval("LearnerUsername"), (string)Eval("LearnerAvatarUrl")) %></td>
                        <td><span class="cl-attempt-chip"><%#: TutorDisplayHelper.Ordinal((int)Eval("AttemptNumber")) %></span></td>
                        <td><strong><%# Eval("ScorePercent") %>%</strong></td>
                        <td><%# Eval("CorrectCount") %> / <%# Eval("TotalQuestions") %></td>
                        <td><%# TutorDisplayHelper.PassBadge((bool)Eval("Passed")) %></td>
                        <td class="text-muted" title="<%#: TutorDisplayHelper.LocalDateTime((DateTime)Eval("AttemptedAt")) %>"><%#: TutorDisplayHelper.TimeAgo((DateTime)Eval("AttemptedAt")) %></td>
                        <td class="text-end"><a class="btn btn-sm btn-outline-primary" href="<%#: AttemptUrl((int)Eval("AttemptId")) %>">Review</a></td>
                    </tr>
                </ItemTemplate>
                <FooterTemplate></tbody></table></div></FooterTemplate>
            </asp:Repeater>
            <div class="cl-empty cl-empty-sm" data-filter-empty hidden><p>No attempts match these filters.</p></div>
            <asp:PlaceHolder ID="phNoAttempts" runat="server" Visible="false">
                <div class="cl-empty">
                    <span class="cl-builder-icon cl-tone-amber"><i data-lucide="hourglass" class="cl-icon" aria-hidden="true"></i></span>
                    <h3>No attempts yet</h3>
                    <p>Attempts show up here as soon as learners take this quiz.</p>
                </div>
            </asp:PlaceHolder>
        </section>
    </asp:PlaceHolder>

    <%-- ===== 3. One attempt: question by question ===== --%>
    <asp:PlaceHolder ID="phAttempt" runat="server" Visible="false">
        <div class="cl-results-layout">
            <div class="cl-results-main">
                <section class="cl-card cl-attempt-summary">
                    <div class="cl-attempt-who">
                        <asp:Literal ID="litAttemptLearner" runat="server" Mode="PassThrough" />
                        <div class="cl-attempt-meta">
                            <span><i data-lucide="repeat" class="cl-icon" aria-hidden="true"></i><asp:Literal ID="litAttemptNumber" runat="server" Mode="Encode" /></span>
                            <span><i data-lucide="calendar" class="cl-icon" aria-hidden="true"></i><asp:Literal ID="litAttemptDate" runat="server" Mode="Encode" /></span>
                        </div>
                    </div>
                    <div class="cl-attempt-score">
                        <div class="cl-score-ring" style="--score: <%: AttemptScore %>">
                            <span><asp:Literal ID="litAttemptScore" runat="server" Mode="Encode" /></span>
                        </div>
                        <div>
                            <asp:Literal ID="litAttemptBadge" runat="server" Mode="PassThrough" />
                            <p><asp:Literal ID="litAttemptCorrect" runat="server" Mode="Encode" /></p>
                        </div>
                    </div>
                </section>

                <asp:PlaceHolder ID="phReview" runat="server" Visible="false">
                    <div class="cl-review-toolbar">
                        <h2>Answers</h2>
                        <div class="cl-review-filter" role="group" aria-label="Show questions">
                            <button type="button" class="is-active" data-review-filter="all">All <span><asp:Literal ID="litCountAll" runat="server" Mode="Encode" /></span></button>
                            <button type="button" data-review-filter="wrong">Wrong <span><asp:Literal ID="litCountWrong" runat="server" Mode="Encode" /></span></button>
                            <button type="button" data-review-filter="correct">Correct <span><asp:Literal ID="litCountCorrect" runat="server" Mode="Encode" /></span></button>
                        </div>
                    </div>

                    <asp:Repeater ID="rptAnswers" runat="server">
                        <HeaderTemplate><ol class="cl-review-list"></HeaderTemplate>
                        <ItemTemplate>
                            <li class="cl-card cl-review-item <%# ((QuizAnswerItem)Container.DataItem).IsCorrect ? "is-correct" : "is-wrong" %>" data-review="<%# ((QuizAnswerItem)Container.DataItem).IsCorrect ? "correct" : "wrong" %>">
                                <div class="cl-review-head">
                                    <span class="cl-review-number">Q<%# Container.ItemIndex + 1 %></span>
                                    <p class="cl-review-question"><%#: Eval("QuestionText") %></p>
                                    <%# AnswerBadge((QuizAnswerItem)Container.DataItem) %>
                                </div>
                                <asp:Repeater ID="rptOptions" runat="server" DataSource='<%# OptionsFor((QuizAnswerItem)Container.DataItem) %>'>
                                    <HeaderTemplate><ul class="cl-review-options"></HeaderTemplate>
                                    <ItemTemplate>
                                        <li class="<%# Eval("Css") %>">
                                            <span class="cl-review-letter"><%#: Eval("Letter") %></span>
                                            <span class="cl-review-text"><%#: Eval("Text") %></span>
                                            <%# Eval("Tags") %>
                                        </li>
                                    </ItemTemplate>
                                    <FooterTemplate></ul></FooterTemplate>
                                </asp:Repeater>
                                <%# ExplanationHtml((string)Eval("Explanation")) %>
                            </li>
                        </ItemTemplate>
                        <FooterTemplate></ol></FooterTemplate>
                    </asp:Repeater>
                    <div class="cl-empty cl-card cl-empty-sm" data-review-empty hidden><p>No questions in this group.</p></div>
                </asp:PlaceHolder>

                <asp:PlaceHolder ID="phNoReview" runat="server" Visible="false">
                    <div class="cl-feedback cl-feedback-info" role="status">
                        <span class="cl-builder-icon cl-tone-amber"><i data-lucide="file-question" class="cl-icon" aria-hidden="true"></i></span>
                        <div>
                            <strong>No answer details saved for this attempt</strong>
                            <p>Only the score was recorded, so the question-by-question review is not available.</p>
                        </div>
                    </div>
                </asp:PlaceHolder>
            </div>

            <aside class="cl-card cl-results-aside">
                <div class="cl-chart-head">
                    <div><h2>All attempts by this learner</h2><p>At this quiz, newest first.</p></div>
                </div>
                <asp:Repeater ID="rptLearnerAttempts" runat="server">
                    <HeaderTemplate><ul class="cl-attempt-list"></HeaderTemplate>
                    <ItemTemplate>
                        <li>
                            <a class="<%# (int)Eval("AttemptId") == AttemptId ? "is-current" : string.Empty %>" href="<%#: AttemptUrl((int)Eval("AttemptId")) %>" <%# (int)Eval("AttemptId") == AttemptId ? "aria-current=\"page\"" : string.Empty %>>
                                <span class="cl-attempt-chip"><%#: TutorDisplayHelper.Ordinal((int)Eval("AttemptNumber")) %></span>
                                <span class="cl-attempt-list-text">
                                    <strong><%# Eval("ScorePercent") %>%</strong>
                                    <small><%#: TutorDisplayHelper.LocalDate((DateTime)Eval("AttemptedAt")) %></small>
                                </span>
                                <%# TutorDisplayHelper.PassBadge((bool)Eval("Passed")) %>
                            </a>
                        </li>
                    </ItemTemplate>
                    <FooterTemplate></ul></FooterTemplate>
                </asp:Repeater>
                <a class="btn btn-outline-primary w-100 mt-3" href="<%: QuizUrl(QuizId) %>">
                    <i data-lucide="arrow-left" class="cl-icon" aria-hidden="true"></i> All attempts at this quiz
                </a>
            </aside>
        </div>
    </asp:PlaceHolder>

    <script src="<%: ResolveUrl("~/Scripts/tutor-results.js") %>"></script>

</asp:Content>

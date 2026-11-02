<%@ Page Title="Course Curriculum"
    Language="C#"
    MasterPageFile="~/Site.Master"
    AutoEventWireup="true"
    CodeBehind="Curriculum.aspx.cs"
    Inherits="CodeLab.Modules.Learner.Curriculum" %>

<asp:Content ID="CurriculumHead"
    ContentPlaceHolderID="HeadContent"
    runat="server">

<link rel="stylesheet"
    href="<%= ResolveUrl("~/Content/LearnerCurriculum.css") %>?v=3" />


</asp:Content>

<asp:Content ID="CurriculumMain"
    ContentPlaceHolderID="MainContent"
    runat="server">

    <div class="cc-wrap">


        <a class="cc-back"
            href="<%= ResolveUrl("~/Modules/Learner/Courses.aspx") %>">
            &larr; Courses &amp; Curriculum
        </a>

        <asp:UpdatePanel ID="upCurriculumError"
            runat="server"
            UpdateMode="Always"
            ChildrenAsTriggers="true">

            <ContentTemplate>

                <asp:Label ID="lblError"
                    runat="server"
                    Visible="false"
                    CssClass="cc-error"
                    role="alert" />

            </ContentTemplate>

        </asp:UpdatePanel>

        <asp:Panel ID="pnlCurriculum"
            runat="server"
            Visible="false">

            <%-- Course preview before enrolment --%>

            <asp:Panel ID="pnlPreview" runat="server">

                <header class="cc-hero">

                    <span class="cc-eyebrow">COURSE PREVIEW</span>

                    <h1>
                        <asp:Literal ID="litCourse"
                            runat="server"
                            Mode="Encode" />
                    </h1>

                    <div class="cc-hero-actions">

                        <asp:Button ID="btnEnroll"
                            runat="server"
                            Text="Enrol in Course"
                            CssClass="cc-primary"
                            CausesValidation="false"
                            OnClick="btnEnroll_Click" />

                    </div>

                </header>

                <p class="cc-notice">
                    Enrol to access the learning materials,
                    save your progress and take the final quiz.
                </p>

                <section class="cc-module">

                    <div class="cc-module-heading">
                        <div>
                            <small>COURSE CONTENT</small>
                            <h2>Lessons</h2>
                        </div>
                    </div>

                    <div class="cc-module-body">

                        <asp:Repeater ID="rptPreviewLessons"
                            runat="server">

                            <ItemTemplate>

                                <div class="cc-item cc-lesson">

                                    <span class="cc-item-icon"
                                        aria-hidden="true">
                                        &#128214;
                                    </span>

                                    <div class="cc-lesson-main">

                                        <strong>
                                            <%# Container.ItemIndex + 1 %>.
                                            <%#: Eval("Title") %>
                                        </strong>

                                        <small>
                                            <%#: Eval("DurationMinutes") %> min
                                        </small>

                                    </div>

                                    <span class="cc-status">Locked</span>

                                </div>

                            </ItemTemplate>

                        </asp:Repeater>

                    </div>

                </section>

                <asp:Panel ID="pnlPreviewQuiz"
                    runat="server"
                    Visible="false"
                    CssClass="cc-final-quiz-preview">

                    <h2>Final Quiz</h2>

                    <p>
                        Complete all lessons to unlock the final quiz.
                    </p>

                    <span class="cc-meta">

                        <asp:Literal ID="litPreviewQuizDetails"
                            runat="server"
                            Mode="Encode" />

                    </span>

                </asp:Panel>

            </asp:Panel>

            <%-- Enrolled learning workspace --%>

            <asp:Panel ID="pnlWorkspace"
                runat="server"
                Visible="false"
                CssClass="cc-workspace">

                <aside class="cc-sidebar"
                    aria-label="Course curriculum">

                    <asp:Panel ID="pnlCourseCover"
                        runat="server"
                        Visible="false"
                        CssClass="cc-sidebar-cover">

                        <asp:Image ID="imgCourseCover"
                            runat="server"
                            CssClass="cc-course-cover-image"
                            AlternateText="" />

                    </asp:Panel>

                    <div class="cc-sidebar-course">

                        <span class="cc-eyebrow">YOUR COURSE</span>

                        <h1>
                            <asp:Literal ID="litSidebarCourse"
                                runat="server"
                                Mode="Encode" />
                        </h1>

                    </div>

                    <asp:UpdatePanel ID="upSidebarProgress"
                        runat="server"
                        UpdateMode="Always"
                        ChildrenAsTriggers="true">

                        <ContentTemplate>

                            <%-- Lesson progress --%>

                            <div class="cc-progress">

                                <div class="cc-progress-top">

                                    <div>
                                        <small>
                                            <asp:Literal ID="litProgressDetail"
                                                runat="server"
                                                Mode="Encode" />
                                        </small>
                                    </div>

                                    <span class="cc-progress-value">
                                        <asp:Literal ID="litProgressPercent"
                                            runat="server"
                                            Mode="Encode" />%
                                    </span>

                                </div>

                                <div class="cc-progress-track"
                                    aria-hidden="true">

                                    <asp:Literal ID="litProgressFill"
                                        runat="server" />

                                </div>

                                <asp:Label ID="lblCourseStatus"
                                    runat="server"
                                    CssClass="cc-course-status" />

                            </div>

                            <%-- Scrollable lesson list --%>

                            <details class="cc-sidebar-curriculum" open>

                                <summary class="cc-sidebar-heading">
                                    Lessons
                                </summary>

                                <nav class="cc-sidebar-scroll"
                                    aria-label="Lesson navigation">

                                    <div class="cc-sidebar-items">

                                        <asp:Repeater ID="rptSidebarLessons"
                                            runat="server"
                                            OnItemDataBound="rptSidebarLessons_ItemDataBound"
                                            OnItemCommand="rptSidebarLessons_ItemCommand">

                                            <ItemTemplate>

                                                <asp:LinkButton ID="btnSelectLesson"
                                                    runat="server"
                                                    CssClass='<%# (bool)Eval("IsCompleted")
                                                        ? "cc-sidebar-lesson is-completed"
                                                        : "cc-sidebar-lesson" %>'
                                                    CausesValidation="false"
                                                    CommandName="SelectLesson"
                                                    CommandArgument='<%# Eval("Id") %>'>

                                                    <span class="cc-sidebar-status"
                                                        aria-hidden="true">

                                                        <%# (bool)Eval("IsCompleted")
                                                            ? "✓"
                                                            : "○" %>

                                                    </span>

                                                    <span class="cc-sidebar-lesson-text">

                                                        <strong>
                                                            <%# Container.ItemIndex + 1 %>.
                                                            <%#: Eval("Title") %>
                                                        </strong>

                                                        <small>
                                                            <%#: Eval("DurationMinutes") %> min
                                                            &bull;
                                                            <%# (bool)Eval("IsCompleted")
                                                                ? "Completed"
                                                                : "Not completed" %>
                                                        </small>

                                                    </span>

                                                </asp:LinkButton>

                                            </ItemTemplate>

                                        </asp:Repeater>

                                    </div>

                                </nav>

                            </details>

                            <%-- Final quiz --%>

                            <asp:Panel ID="pnlSidebarQuiz"
                                runat="server"
                                Visible="false"
                                CssClass="cc-sidebar-final-quiz">

                                <h2 class="cc-sidebar-quiz-heading">
                                    Final Quiz
                                </h2>

                                <span class="cc-meta">

                                    <asp:Literal ID="litSidebarQuizDetails"
                                        runat="server"
                                        Mode="Encode" />

                                </span>

                                <asp:Label ID="lblQuizAvailability"
                                    runat="server"
                                    CssClass="cc-quiz-availability" />

                                <asp:Button ID="btnOpenQuiz"
                                    runat="server"
                                    Text="Attempt Quiz"
                                    Enabled="false"
                                    CssClass="cc-primary cc-attempt-quiz"
                                    CausesValidation="false"
                                    OnClick="btnOpenQuiz_Click" />

                                <%-- Attempt history --%>

                                <asp:Panel ID="pnlAttemptHistory"
                                    runat="server"
                                    Visible="false"
                                    CssClass="cc-attempt-history">

                                    <asp:Panel ID="pnlNoAttempts"
                                        runat="server"
                                        Visible="false">

                                        <p class="cc-history-empty">
                                            No quiz attempts yet.
                                        </p>

                                    </asp:Panel>

                                    <asp:Repeater ID="rptAttemptHistory"
                                        runat="server"
                                        EnableViewState="false">

                                        <HeaderTemplate>

                                            <details class="cc-history-details">

                                                <summary>Attempt history</summary>

                                                <div class="cc-history-body">

                                                    <p class="cc-history-timezone">
                                                        Newest first &middot;
                                                        Malaysia time (UTC+8)
                                                    </p>

                                                    <div class="cc-history-scroll"
                                                        tabindex="0"
                                                        role="region"
                                                        aria-label="Previous quiz attempts">

                                        </HeaderTemplate>

                                        <ItemTemplate>

                                            <article class="cc-history-item">

                                                <div class="cc-history-row">

                                                    <strong>
                                                        Attempt
                                                        <%#: Eval("AttemptNumber") %>
                                                    </strong>

                                                    <span class='<%# Convert.ToBoolean(Eval("Passed"))
                                                        ? "cc-history-result is-passed"
                                                        : "cc-history-result is-failed" %>'>

                                                        <%# Convert.ToBoolean(Eval("Passed"))
                                                            ? "Passed"
                                                            : "Failed" %>

                                                    </span>

                                                </div>

                                                <div class="cc-history-row">

                                                    <span class="cc-history-date">
                                                        <%#: Eval("AttemptedAtDisplay") %>
                                                    </span>

                                                    <strong class="cc-history-score">
                                                        <%#: Eval("ScorePercent") %>%
                                                    </strong>

                                                </div>

                                            <a class="cc-review-link" href='<%#: ResolveUrl("~/Modules/Learner/Curriculum.aspx") + "?id=" + CourseId.ToString(System.Globalization.CultureInfo.InvariantCulture) + "&result=" + Eval("Id") %>' aria-label='Review attempt <%#: Eval("AttemptNumber") %>'><span>Review answers</span><span aria-hidden="true">&rarr;</span></a>
</article>

                                        </ItemTemplate>

                                        <FooterTemplate>

                                                    </div>

                                                </div>

                                            </details>

                                        </FooterTemplate>

                                    </asp:Repeater>

                                </asp:Panel>

                            </asp:Panel>

                            <%-- Unenrol action --%>

                            <footer class="cc-sidebar-footer">

                                <asp:Button ID="btnUnenroll"
                                    runat="server"
                                    Text="Unenrol from course"
                                    CssClass="cc-unenroll-button"
                                    CausesValidation="false"
                                    OnClick="btnUnenroll_Click"
                                    OnClientClick="return confirm('Unenrol from this course? Your saved lesson completion history will be removed.');" />

                            </footer>

                        </ContentTemplate>

                    </asp:UpdatePanel>

                </aside>

                <section class="cc-learning-content"
                    aria-label="Learning materials and quiz">

                    <%-- Selected lesson --%>

                    <asp:Panel ID="pnlLesson"
                        runat="server"
                        Visible="false"
                        CssClass="cc-lesson-card">

                        <header class="cc-lesson-header">

                            <span class="cc-eyebrow">

                                <asp:Literal ID="litLessonNumber"
                                    runat="server"
                                    Mode="Encode" />

                            </span>

                            <h2>
                                <asp:Literal ID="litLessonTitle"
                                    runat="server"
                                    Mode="Encode" />
                            </h2>

                            <div class="cc-lesson-meta">

                                <span>
                                    <asp:Literal ID="litLessonDuration"
                                        runat="server"
                                        Mode="Encode" />
                                    min
                                </span>

                                <asp:UpdatePanel ID="upLessonStatus"
                                    runat="server"
                                    RenderMode="Inline"
                                    UpdateMode="Always"
                                    ChildrenAsTriggers="true">

                                    <ContentTemplate>

                                        <asp:Label ID="lblLessonStatus"
                                            runat="server"
                                            CssClass="cc-status" />

                                    </ContentTemplate>

                                </asp:UpdatePanel>

                            </div>

                        </header>

                        <div class="cc-lesson-material">

                            <asp:Panel ID="pnlLessonImage"
                                runat="server"
                                Visible="false"
                                CssClass="cc-lesson-image">

                                <asp:Image ID="imgLesson"
                                    runat="server"
                                    CssClass="cc-material-image"
                                    AlternateText="Lesson illustration"
                                    loading="lazy" />

                            </asp:Panel>

                            <div class="cc-lesson-content cc-markdown-content"><asp:Literal ID="litLessonContent" runat="server" Mode="PassThrough" /></div>

                            <asp:Panel ID="pnlCode"
                                runat="server"
                                Visible="false"
                                CssClass="cc-code-section">

                                <h3>Code example</h3>

                                <pre><code><asp:Literal ID="litCodeSnippet"
                                    runat="server"
                                    Mode="Encode" /></code></pre>

                            </asp:Panel>

                            <asp:Panel ID="pnlVideo"
                                runat="server"
                                Visible="false"
                                CssClass="cc-video-section">

                                <h3>Lesson video</h3>

                                <div class="cc-video-player"
                                    style="position:relative;width:100%;aspect-ratio:16/9;overflow:hidden;border-radius:12px;background:#000;">

                                    <asp:Literal ID="litVideoEmbed"
                                        runat="server"
                                        Mode="PassThrough" />

                                </div>

                            </asp:Panel>

                            <asp:Panel ID="pnlAttachment"
                                runat="server"
                                Visible="false"
                                CssClass="cc-attachment-section">

                                <h3>Lesson attachment</h3>

                                <asp:HyperLink ID="lnkAttachment"
                                    runat="server"
                                    CssClass="cc-secondary"
                                    Target="_blank"
                                    rel="noopener noreferrer">

                                    <asp:Literal ID="litAttachmentName"
                                        runat="server"
                                        Mode="Encode" />

                                </asp:HyperLink>

                            </asp:Panel>

                        </div>

                        <asp:UpdatePanel ID="upLessonActions"
                            runat="server"
                            UpdateMode="Always"
                            ChildrenAsTriggers="true">

                            <ContentTemplate>

                                <div class="cc-lesson-completion">

                                    <asp:Button ID="btnToggleComplete"
                                        runat="server"
                                        Text="Mark Completed"
                                        CssClass="cc-primary"
                                        CausesValidation="false"
                                        OnClick="btnToggleComplete_Click" />

                                    <p>
                                        Your lesson completion is saved to your account.
                                    </p>

                                    <asp:UpdateProgress ID="progressLessonSave"
                                        runat="server"
                                        AssociatedUpdatePanelID="upLessonActions"
                                        DisplayAfter="200">

                                        <ProgressTemplate>

                                            <span role="status">
                                                Saving progress...
                                            </span>

                                        </ProgressTemplate>

                                    </asp:UpdateProgress>

                                </div>

                                <footer class="cc-lesson-navigation">

                                    <asp:Button ID="btnPreviousLesson"
                                        runat="server"
                                        Text="← Previous Lesson"
                                        CssClass="cc-secondary"
                                        CausesValidation="false"
                                        OnClick="btnPreviousLesson_Click" />

                                    <span class="cc-lesson-position">

                                        <asp:Literal ID="litLessonPosition"
                                            runat="server"
                                            Mode="Encode" />

                                    </span>

                                    <asp:Button ID="btnNextLesson"
                                        runat="server"
                                        Text="Next Lesson →"
                                        CssClass="cc-primary"
                                        CausesValidation="false"
                                        OnClick="btnNextLesson_Click" />

                                </footer>

                            </ContentTemplate>

                            <Triggers>

                                <asp:AsyncPostBackTrigger
                                    ControlID="btnToggleComplete"
                                    EventName="Click" />

                            </Triggers>

                        </asp:UpdatePanel>

                    </asp:Panel>

                    <%-- Final quiz content --%>

                    <asp:Panel ID="pnlQuiz"
                        runat="server"
                        Visible="false"
                        CssClass="cc-lesson-card cc-quiz-card">

                        <header class="cc-lesson-header">

                            <span class="cc-eyebrow">COURSE QUIZ</span>

                            <h2>
                                <asp:Literal ID="litQuizTitle"
                                    runat="server"
                                    Mode="Encode" />
                            </h2>

                            <p class="cc-meta">

                                <asp:Literal ID="litQuizDetails"
                                    runat="server"
                                    Mode="Encode" />

                            </p>

                        </header>

                        <div class="cc-lesson-material">

                            <div class="cc-lesson-content"><asp:Literal ID="litQuizInstructions"
                                    runat="server"
                                    Mode="Encode" /></div>

                            <asp:Label ID="lblQuizError"
                                runat="server"
                                Visible="false"
                                CssClass="cc-error"
                                role="alert" />

                            <asp:Panel ID="pnlQuizQuestions"
                                runat="server">

                                <asp:Repeater ID="rptQuizQuestions"
                                    runat="server"
                                    OnItemDataBound="rptQuizQuestions_ItemDataBound">

                                    <ItemTemplate>

                                        <fieldset class="cc-question">

                                            <legend>

                                                <span class="cc-question-number">
                                                    Question
                                                    <%# Container.ItemIndex + 1 %>
                                                </span>

                                                <%#: Eval("QuestionText") %>

                                            </legend>

                                            <asp:RadioButtonList ID="rblAnswers"
                                                runat="server"
                                                CssClass="cc-answer-options"
                                                RepeatDirection="Vertical"
                                                RepeatLayout="Flow" />

                                        </fieldset>

                                    </ItemTemplate>

                                </asp:Repeater>

                                <asp:Button ID="btnSubmitQuiz"
                                    runat="server"
                                    Text="Submit Quiz"
                                    CssClass="cc-primary"
                                    CausesValidation="false"
                                    OnClick="btnSubmitQuiz_Click" />

                            </asp:Panel>

                            <asp:Panel ID="pnlQuizResult"
                                runat="server"
                                Visible="false"
                                CssClass="cc-quiz-result"
                                role="status">

                                <h3>
                                    <asp:Literal ID="litQuizResultTitle"
                                        runat="server"
                                        Mode="Encode" />
                                </h3>

                                <p class="cc-quiz-score">

                                    <asp:Literal ID="litQuizScore"
                                        runat="server"
                                        Mode="Encode" />

                                </p>

                                <p>
                                    <asp:Literal ID="litQuizResultMessage"
                                        runat="server"
                                        Mode="Encode" />
                                </p>

                                <section class="cc-attempt-review" aria-label="Detailed attempt review">
                                    <div class="cc-review-heading">
                                        <h3>Answer review</h3>
                                        <span class="cc-review-readonly">Read only</span>
                                    </div>
                                    <% if (AttemptReview == null) { %>
                                        <p class="cc-review-empty">Detailed answers were not recorded for this older attempt. Your saved score is shown above.</p>
                                    <% } else { %>
                                        <p class="cc-review-intro">Pass mark: <%: AttemptReview.PassMark %>% &middot; Answers saved when you took this quiz.</p>
                                        <% for (int questionIndex = 0; questionIndex < AttemptReview.Answers.Count; questionIndex++) {
                                            var answer = AttemptReview.Answers[questionIndex]; %>
                                            <fieldset class="cc-question cc-review-question">
                                                <legend>
                                                    <span class="cc-question-number">Question <%: questionIndex + 1 %></span>
                                                    <span class="cc-review-text"><%: answer.QuestionText %></span>
                                                </legend>
                                                <div class="cc-review-status-row">
                                                    <span class='<%: answer.IsCorrect ? "cc-review-badge is-correct" : "cc-review-badge is-incorrect" %>'><%: answer.IsCorrect ? "Correct" : "Incorrect" %></span>
                                                </div>
                                                <ul class="cc-review-options">
                                                    <% for (int optionIndex = 0; optionIndex < answer.Options.Count; optionIndex++) {
                                                        bool selected = optionIndex == answer.SelectedOptionIndex;
                                                        bool correct = optionIndex == answer.CorrectOptionIndex; %>
                                                        <li class='<%: "cc-review-option" + (correct ? " is-correct" : (selected ? " is-incorrect" : "")) + (selected ? " is-selected" : "") %>'>
                                                            <span class="cc-review-radio" aria-hidden="true"></span>
                                                            <span class="cc-review-option-text"><%: answer.Options[optionIndex] %></span>
                                                            <% if (selected || correct) { %>
                                                                <span class="cc-review-option-label"><%: selected && correct ? "Your answer · Correct" : (selected ? "Your answer" : "Correct answer") %></span>
                                                            <% } %>
                                                        </li>
                                                    <% } %>
                                                </ul>
                                                <div class="cc-review-explanation">
                                                    <h4>Explanation</h4>
                                                    <p class="cc-review-text"><%: string.IsNullOrWhiteSpace(answer.Explanation) ? "No explanation was provided for this question." : answer.Explanation %></p>
                                                </div>
                                            </fieldset>
                                        <% } %>
                                    <% } %>
                                </section>
                                <asp:Button ID="btnRetryQuiz"
                                    runat="server"
                                    Text="Try Again"
                                    CssClass="cc-primary"
                                    CausesValidation="false"
                                    OnClick="btnRetryQuiz_Click" />

                            </asp:Panel>

                        </div>

                        <footer class="cc-lesson-navigation">

                            <asp:Button ID="btnBackToLessons"
                                runat="server"
                                Text="← Back to Lessons"
                                CssClass="cc-secondary"
                                CausesValidation="false"
                                OnClick="btnBackToLessons_Click" />

                        </footer>

                    </asp:Panel>

                    <asp:Panel ID="pnlNoLesson"
                        runat="server"
                        Visible="false"
                        CssClass="cc-empty">

                        <h2>No lessons available yet</h2>

                        <p>
                            Learning materials will appear here once added.
                        </p>

                    </asp:Panel>

                </section>

            </asp:Panel>

            <asp:Panel ID="pnlNoLessonsPreview"
                runat="server"
                Visible="false"
                CssClass="cc-empty">

                No lessons have been added to this course yet.

            </asp:Panel>

        </asp:Panel>

    </div>

<style>
.course-done{width:min(480px,calc(100% - 32px));padding:36px 28px;border:1px solid #ffdce7;border-radius:24px;background:var(--cl-surface,#fff);color:var(--cl-text,#0f172a);text-align:center;box-shadow:0 20px 70px #34142633}.course-done::backdrop{background:#0f172a66;backdrop-filter:blur(4px)}.course-done-close{position:absolute;right:14px;top:10px;border:0;background:transparent;color:inherit;font-size:26px;width:32px;height:32px;cursor:pointer}.course-done-icon{display:grid;place-items:center;width:64px;height:64px;margin:0 auto 18px;background:#fff0f5;color:#c9527d;border-radius:50%}.course-done h2{font-size:24px;margin:0 0 14px}.course-done p{line-height:1.6;color:#64748b}.course-done-actions{display:flex;flex-direction:column;gap:10px;margin-top:24px}.course-done-actions a,.course-done-actions button{padding:12px 16px;border-radius:12px;font:inherit;font-weight:600;text-decoration:none}.course-done-actions a{color:#fff;background:linear-gradient(90deg,#b93b69,#d64578)}.course-done-actions button{border:1px solid #e2e8f0;background:transparent;color:inherit}.course-done :focus-visible{outline:3px solid #c9527d;outline-offset:3px}
</style>
<dialog id="curriculumCompletedDialog" class="course-done" aria-labelledby="courseCompletedTitle" aria-describedby="courseCompletedMessage">
<button type="button" class="course-done-close" aria-label="Close congratulations" onclick="document.getElementById('curriculumCompletedDialog').close()">&times;</button>
<div class="course-done-icon"><svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" aria-hidden="true"><path d="M7 3h10v7a5 5 0 0 1-10 0V3ZM7 5H3v3a4 4 0 0 0 4 4M17 5h4v3a4 4 0 0 1-4 4M12 15v5M8 21h8"/></svg></div>
<h2 id="courseCompletedTitle">Congratulations!</h2><p id="courseCompletedMessage">You've completed <strong><%: courseTitle %></strong>. Put what you've learned into practice with this course's coding challenges.</p>
<div class="course-done-actions"><a href="<%: ResolveUrl("~/Modules/Learner/Workspace")+"?courseId="+CourseId %>" autofocus>Go to Coding Challenges &rarr;</a><button type="button" onclick="document.getElementById('curriculumCompletedDialog').close()">Back to Course</button></div>
</dialog>

</asp:Content>
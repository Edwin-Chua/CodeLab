<%@ Page Title="Coding Challenge"
    Language="C#"
    MasterPageFile="~/Site.Master"
    AutoEventWireup="true"
    Async="true" AsyncTimeout="65"
    CodeBehind="Challenge.aspx.cs"
    Inherits="CodeLab.Modules.Learner.Challenge" %>

<asp:Content ID="Head" ContentPlaceHolderID="HeadContent" runat="server">
    <link href="<%= ResolveUrl("~/Content/LearnerChallenge.css") %>?v=6"
          rel="stylesheet" />
<style>.ch-run-action{position:relative}.ch-run-action .ch-button-run{padding-left:34px}.ch-run-play{position:absolute;left:12px;top:50%;transform:translateY(-50%);width:15px;height:15px;fill:none;stroke:#00e6ac;stroke-width:1.8;stroke-linejoin:round;pointer-events:none;z-index:1}.ch-review-tabs{padding:0!important;overflow:hidden;border-radius:24px!important;border:1px solid #ffe0eb!important;box-shadow:0 2px 4px #00000005}
.ch-review-tabs .ch-output-heading{padding:12px 20px;margin:0;background:#f8fafc;border-bottom:1px solid #ffe0eb;gap:12px;flex-wrap:wrap}
.ch-result-tabs{display:flex;gap:8px}.ch-result-tabs button{display:inline-flex;align-items:center;gap:8px;background:transparent;border:0;border-radius:999px;padding:7px 14px;color:#64748b;font:inherit;font-size:12px;font-weight:700;cursor:pointer}.ch-result-tabs button[aria-selected=true]{background:#fff;color:#d64578;box-shadow:0 1px 3px #0000000d}.ch-result-tabs .ch-icon{width:16px;height:16px;fill:none;stroke:currentColor;stroke-width:1.8}.ch-review-tabs [role=tabpanel]{padding:16px}.ch-review-tabs [hidden]{display:none!important}.ch-review-tabs .ch-console{margin:0;border-radius:16px;background:#020617;color:#e2e8f0;min-height:80px}.ch-review-copy{padding:16px;border-radius:16px;background:#020617;color:#e2e8f0;white-space:pre-wrap;overflow-wrap:anywhere;font-family:Consolas,"Courier New",monospace;line-height:1.8;font-size:12px;min-height:80px}.ch-result-tabs button:focus-visible{outline:2px solid #c9527d;outline-offset:2px}[data-theme=dark] .ch-review-tabs .ch-output-heading{background:#0f172a}[data-theme=dark] .ch-result-tabs button[aria-selected=true]{background:#293548;color:#ffa2a4}
.ch-ai-review{padding:20px;margin-top:16px;border:1px solid #e9d5ff;border-radius:16px;background:var(--cl-surface,#fff);color:var(--cl-text)}.ch-ai-review h3{font-size:16px;color:#9333ea}.ch-ai-review p,.ch-ai-notice{font-size:12px;color:#64748b}.ch-ai-notice{margin-top:12px}</style></asp:Content>

<asp:Content ID="Main" ContentPlaceHolderID="MainContent" runat="server">
    <main class="ch-wrap">

        <svg class="ch-symbols"
            xmlns="http://www.w3.org/2000/svg"
            aria-hidden="true"
            focusable="false">

            <symbol id="ch-back" viewBox="0 0 24 24">
                <path d="m12 5-7 7 7 7M5 12h15" />
            </symbol>

            <symbol id="ch-book" viewBox="0 0 24 24">
                <path d="M12 6c-2-1.7-5.6-2.1-9-1.2v14c3.4-.9 7-.5 9 1.2 2-1.7 5.6-2.1 9-1.2v-14c-3.4-.9-7-.5-9 1.2ZM12 6v14" />
            </symbol>

            <symbol id="ch-terminal" viewBox="0 0 24 24">
                <path d="m4 6 6 6-6 6M12 18h8" />
            </symbol>

            <symbol id="ch-history" viewBox="0 0 24 24">
                <circle cx="12" cy="12" r="9" />
                <path d="M12 7v5l3 2" />
            </symbol>

            <symbol id="ch-reset" viewBox="0 0 24 24">
                <path d="M3 11a9 9 0 1 1 2.6 7M3 4v7h7" />
            </symbol>

            <symbol id="ch-play" viewBox="0 0 24 24">
                <path d="m7 4 13 8-13 8V4Z" />
            </symbol>

            <symbol id="ch-send" viewBox="0 0 24 24">
                <path d="m21 3-7 18-4-7-7-4 18-7ZM10 14 21 3" />
            </symbol>

            <symbol id="ch-copy" viewBox="0 0 24 24">
                <rect x="8" y="8" width="12" height="13" rx="2" />
                <path d="M16 8V5a2 2 0 0 0-2-2H5a2 2 0 0 0-2 2v9a2 2 0 0 0 2 2h3" />
            </symbol>

            <symbol id="ch-expand" viewBox="0 0 24 24">
                <path d="M8 3H3v5M16 3h5v5M21 16v5h-5M8 21H3v-5" />
            </symbol>

            <symbol id="ch-trophy" viewBox="0 0 24 24">
                <path d="M7 3h10v7a5 5 0 0 1-10 0V3ZM7 5H3v3a4 4 0 0 0 4 4M17 5h4v3a4 4 0 0 1-4 4M12 15v4M8 21h8M9 19h6" />
            </symbol>
        </svg>

        <asp:Panel ID="pnlError"
            runat="server"
            Visible="false"
            CssClass="ch-error"
            role="alert">
            <asp:Literal ID="litError"
                runat="server" Mode="Encode" />

            <a href="<%= ResolveUrl("~/Modules/Learner/Workspace.aspx") %>">
                Back to challenges
            </a>
        </asp:Panel>

        <asp:Panel ID="pnlChallenge"
            runat="server"
            Visible="false">

            <!-- Top toolbar -->
            <div class="ch-toolbar">
                <div class="ch-toolbar-navigation">
                    <a class="ch-back-button"
                        href="<%= ResolveUrl("~/Modules/Learner/Workspace.aspx") %>">
                        <svg class="ch-icon" aria-hidden="true">
                            <use href="#ch-back" />
                        </svg>
                        All Challenges
                    </a>

                    <div class="ch-breadcrumb">
                        <span class="ch-breadcrumb-course">
                            <asp:Literal ID="litBreadcrumbCourse"
                                runat="server" Mode="Encode" />
                        </span>

                        <span class="ch-breadcrumb-separator" aria-hidden="true">
                            &rsaquo;
                        </span>

                        <span class="ch-breadcrumb-title" aria-current="page">
                            <asp:Literal ID="litBreadcrumbTitle"
                                runat="server" Mode="Encode" />
                        </span>
                    </div>
                </div>

                <div class="ch-toolbar-actions">
                    <span class="ch-language"
                        title="The language is set by this challenge">
                        <asp:Literal ID="litLanguage"
                            runat="server" Mode="Encode" />
                    </span>

                    <button id="chResetButton"
                        type="button"
                        class="ch-button ch-button-reset">
                        <svg class="ch-icon" aria-hidden="true">
                            <use href="#ch-reset" />
                        </svg>
                        Reset
                    </button>

                    <span class="ch-action-wrapper ch-run-action"><svg class="ch-run-play" viewBox="0 0 24 24" aria-hidden="true"><path d="M7 4.5a1 1 0 0 1 1.5-.86l12 7.5a1 1 0 0 1 0 1.72l-12 7.5A1 1 0 0 1 7 19.5Z" /></svg>
                        <asp:Button ID="btnRun"
                            runat="server"
                            Text="Run Code"
                            CssClass="ch-button ch-button-run"
                            CausesValidation="false"
                            UseSubmitBehavior="true"
                            Enabled="false"
                            data-ch-action="run"
                            OnClick="btnRun_Click" />
                    </span>

                    <span class="ch-action-wrapper">
                        <asp:Button ID="btnSubmit"
                            runat="server"
                            Text="Submit"
                            CssClass="ch-button ch-button-submit"
                            CausesValidation="false"
                            UseSubmitBehavior="true"
                            Enabled="false"
                            data-ch-action="submit"
                            OnClick="btnSubmit_Click" />
                    </span>
                </div>
            </div>

            <div class="ch-layout">

                <!-- Problem and submission history -->
                <section class="ch-problem-panel"
                    aria-label="Challenge details">

                    <div class="ch-tabs"
                        role="tablist"
                        aria-label="Challenge information">

                        <button id="chProblemTab"
                            type="button"
                            class="ch-tab is-active"
                            role="tab"
                            aria-selected="true"
                            aria-controls="chProblemContent"
                            data-ch-tab="chProblemContent">
                            <svg class="ch-icon" aria-hidden="true">
                                <use href="#ch-book" />
                            </svg>
                            Problem
                        </button>

                        <button id="chExpectedTab"
                            type="button"
                            class="ch-tab"
                            role="tab"
                            tabindex="-1"
                            aria-selected="false"
                            aria-controls="chExpectedContent"
                            data-ch-tab="chExpectedContent">
                            <svg class="ch-icon" aria-hidden="true">
                                <use href="#ch-terminal" />
                            </svg>
                            <%: IsMarkup ? "Requirements" : "Expected Output" %>
                        </button>

                        <button id="chSubmissionsTab"
                            type="button"
                            class="ch-tab"
                            role="tab"
                            tabindex="-1"
                            aria-selected="false"
                            aria-controls="chSubmissionsContent"
                            data-ch-tab="chSubmissionsContent">
                            <svg class="ch-icon" aria-hidden="true">
                                <use href="#ch-history" />
                            </svg>
                            Submissions
                            (<asp:Literal ID="litSubmissionCount"
                                runat="server" Mode="Encode" Text="0" />)
                        </button>
                    </div>

                    <div id="chProblemContent"
                        class="ch-tab-content"
                        role="tabpanel"
                        tabindex="0"
                        aria-labelledby="chProblemTab">

                        <div class="ch-problem-meta">
                            <asp:Label ID="lblDifficulty"
                                runat="server"
                                CssClass="ch-difficulty" />

                            <span class="ch-reward">
                                <svg class="ch-icon" aria-hidden="true">
                                    <use href="#ch-trophy" />
                                </svg>
                                <asp:Literal ID="litPointsReward"
                                    runat="server" Mode="Encode" />
                                XP
                            </span>
                        </div>

                        <h1 class="ch-title">
                            <asp:Literal ID="litTitle"
                                runat="server" Mode="Encode" />
                        </h1>

                        <p class="ch-course">
                            From enrolled course:
                            <strong>
                                <asp:Literal ID="litCourseTitle"
                                    runat="server" Mode="Encode" />
                            </strong>
                        </p>

                        <div class="ch-description"><asp:Literal ID="litDescription" runat="server" Mode="Encode" /></div>

                        <div class="ch-progress-summary">
                            <span>
                                Status:
                                <strong>
                                    <asp:Literal ID="litProgressStatus"
                                        runat="server" Mode="Encode" />
                                </strong>
                            </span>

                            <span>
                                Attempts:
                                <strong>
                                    <asp:Literal ID="litAttemptCount"
                                        runat="server" Mode="Encode" />
                                </strong>
                            </span>
                        </div>
                    </div>

                    <div id="chExpectedContent"
                        class="ch-tab-content"
                        role="tabpanel"
                        tabindex="0"
                        aria-labelledby="chExpectedTab"
                        hidden>

                        <h2 class="ch-section-title"><%: IsMarkup ? "Requirements" : "Expected Output" %></h2>
                        <p class="ch-help-text">
                            <%: IsMarkup ? "Your HTML/CSS should meet this checklist. Review checks source code, not a screenshot." : "Your program should print the following output." %>
                        </p>

                        <pre class="ch-output-example"><asp:Literal
                            ID="litExpectedOutput"
                            runat="server"
                            Mode="Encode" /></pre>
                    </div>

                    <div id="chSubmissionsContent"
                        class="ch-tab-content"
                        role="tabpanel"
                        tabindex="0"
                        aria-labelledby="chSubmissionsTab"
                        hidden>

                        <h2 class="ch-section-title">Your Submissions</h2>
                        <p class="ch-help-text">
                            Review your submitted code and results.
                            Dates are shown in Malaysia time (UTC+8).
                        </p>

                        <asp:Panel ID="pnlNoSubmissions"
                            runat="server"
                            Visible="false"
                            CssClass="ch-empty">
                            No submissions yet. Your attempts will appear here
                            after you submit a solution.
                        </asp:Panel>

                        <asp:Repeater ID="rptSubmissions" runat="server">
                            <ItemTemplate>
                                <details class="ch-submission">
                                    <summary class="ch-submission-summary">
                                        <span class='<%#: Eval("StatusCssClass") %>'>
                                            <%#: Eval("Status") %>
                                        </span>

                                        <time datetime='<%# ((DateTime)Eval("SubmittedAt")).ToString("o", System.Globalization.CultureInfo.InvariantCulture) %>'>
                                            <%# ((DateTime)Eval("SubmittedAt")).AddHours(8).ToString("dd MMM yyyy, hh:mm tt", System.Globalization.CultureInfo.InvariantCulture) %>
                                        </time>
                                    </summary>

                                    <div class="ch-submission-body">
                                        <h3>Submitted Code</h3>
                                        <pre class="ch-submitted-code"><code><%#: Eval("SubmittedCode") %></code></pre>

                                        <h3>AI review</h3><pre class="ch-submitted-output"><%#: string.IsNullOrWhiteSpace(Convert.ToString(Eval("AiFeedback"))) ? "No AI review recorded for this older submission." : Convert.ToString(Eval("AiFeedback")) %></pre><h3>Output</h3>
                                        <pre class="ch-submitted-output"><%#: string.IsNullOrEmpty(Convert.ToString(Eval("OutputResult"))) ? "(No output)" : Convert.ToString(Eval("OutputResult")) %></pre>
                                    </div>
                                </details>
                            </ItemTemplate>
                        </asp:Repeater>
                    </div>
                </section>

                <!-- Code editor and output -->
                <section class="ch-editor-column"
                    aria-label="Code editor and output">

                    <div id="chEditorPanel" class="ch-editor-panel">
                        <div class="ch-editor-toolbar">
                            <span class="ch-editor-filename">
                                <svg class="ch-icon" aria-hidden="true">
                                    <use href="#ch-terminal" />
                                </svg>
                                <asp:Literal ID="litFileName"
                                    runat="server" Mode="Encode" />
                            </span>

                            <div class="ch-editor-tools">
                                <label class="ch-font-label"
                                    for="chFontSize">Font</label>

                                <select id="chFontSize"
                                    class="ch-font-select"
                                    aria-label="Editor font size">
                                    <option value="12">12</option>
                                    <option value="14" selected>14</option>
                                    <option value="16">16</option>
                                    <option value="18">18</option>
                                </select>

                                <button id="chExpandButton"
                                    type="button"
                                    class="ch-editor-tool"
                                    aria-label="Expand editor"
                                    aria-pressed="false">
                                    <svg class="ch-icon" aria-hidden="true">
                                        <use href="#ch-expand" />
                                    </svg>
                                </button>

                                <button id="chCopyButton"
                                    type="button"
                                    class="ch-editor-tool">
                                    <svg class="ch-icon" aria-hidden="true">
                                        <use href="#ch-copy" />
                                    </svg>
                                    Copy
                                </button>
                            </div>
                        </div>

                        <div class="ch-editor-body">
                            <pre id="chLineNumbers"
                                class="ch-line-numbers"
                                aria-hidden="true">1</pre>

                            <asp:TextBox ID="txtCode"
                                runat="server"
                                TextMode="MultiLine"
                                Rows="22"
                                CssClass="ch-code-input"
                                ValidateRequestMode="Disabled"
                                aria-label="Challenge code editor"
                                spellcheck="false"
                                autocomplete="off"
                                autocorrect="off"
                                autocapitalize="off"
                                Wrap="false" />
                        </div>
                    </div>

                    <span id="chEditorNotice"
                        class="ch-editor-notice"
                        role="status"
                        aria-live="polite"></span>

                    <section class="ch-output-panel ch-review-tabs" aria-label="Code execution and AI review">
                        <div class="ch-output-heading">
                            <div class="ch-result-tabs" role="tablist" aria-label="Submission feedback">
                                <button type="button" id="chOutputTab" role="tab" aria-selected="true" aria-controls="chOutputContent"><svg class="ch-icon" aria-hidden="true"><use href="#ch-terminal" /></svg><%: IsMarkup ? "Preview" : "Output" %></button>
                                <button type="button" id="chReviewTab" role="tab" aria-selected="false" aria-controls="chReviewContent" tabindex="-1"><svg class="ch-icon" viewBox="0 0 24 24" aria-hidden="true"><path d="m12 3 2 6 6 3-6 2-2 7-2-7-6-2 6-3Z" /></svg>AI Review</button>
                            </div>
                            <asp:Label ID="lblExecutionStatus" runat="server" CssClass="ch-execution-status" Text="Not run" />
                        </div>
                        <div id="chOutputContent" role="tabpanel" aria-labelledby="chOutputTab" tabindex="0">
                            <% if (IsMarkup && PreviewReady) { %>
                            <div class="ch-preview-controls" aria-label="Preview width">
                                <button type="button" onclick="document.getElementById('chHtmlPreview').style.width='100%'">Full width</button>
                                <button type="button" onclick="document.getElementById('chHtmlPreview').style.width='360px'">Mobile (360px)</button>
                            </div>
                            <div class="ch-preview-scroll"><iframe id="chHtmlPreview" title="Your HTML and CSS preview" sandbox="" referrerpolicy="no-referrer" srcdoc="<%: PreviewDocument %>"></iframe></div>
                            <% } %>
                            <pre class="ch-console" role="status" aria-live="polite"><asp:Literal ID="litOutput" runat="server" Mode="Encode" Text="Run your code to see its output. Submit for validation and AI review." /></pre>
                        </div>
                        <div id="chReviewContent" role="tabpanel" aria-labelledby="chReviewTab" tabindex="0" hidden>
                            <div class="ch-review-copy" role="status" aria-live="polite"><%: string.IsNullOrEmpty(AiFeedback) ? "Submit your code to receive an AI review with feedback and suggested improvements." : AiFeedback %></div>
                        </div>
                    </section>
                    <script>
                    (function(){
                        var tabs=[document.getElementById('chOutputTab'),document.getElementById('chReviewTab')];
                        function select(index){tabs.forEach(function(tab,i){var active=i===index;tab.setAttribute('aria-selected',String(active));tab.tabIndex=active?0:-1;document.getElementById(tab.getAttribute('aria-controls')).hidden=!active;});}
                        tabs.forEach(function(tab,i){tab.addEventListener('click',function(){select(i);});tab.addEventListener('keydown',function(e){var next;if(e.key==='ArrowRight'||e.key==='ArrowLeft')next=1-i;else if(e.key==='Home')next=0;else if(e.key==='End')next=1;else return;e.preventDefault();select(next);tabs[next].focus();});});
                    }());
                    </script>
                    <p class="ch-ai-notice">Submitting sends your code and the challenge details to Google Gemini for feedback.</p>
                    <!-- Starter code is populated by the code-behind. -->
                    <asp:HiddenField ID="hdnStarterCode"
                        runat="server"
                        ValidateRequestMode="Disabled" />
                </section>
            </div>
        </asp:Panel>

        <dialog id="chResultDialog"
                class="ch-result-dialog"
                aria-labelledby="chResultTitle"
                aria-describedby="chResultMessage">

            <div class="ch-result-content">
                <span id="chResultBadge"
                      class="ch-result-badge"></span>

                <h2 id="chResultTitle"></h2>

                <p id="chResultMessage"></p>

                <button type="button"
                        class="ch-button ch-button-submit"
                        onclick="document.getElementById('chResultDialog').close();">
                    OK
                </button>
            </div>
        </dialog>
    </main>
    <script src="<%= ResolveUrl("~/Scripts/LearnerChallenge.js") %>?v=4"></script>
</asp:Content>
<%@ Page Title="Leaderboard & Badges" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Leaderboard.aspx.cs" Inherits="CodeLab.Modules.Learner.Leaderboard" %>
<asp:Content ID="Head" ContentPlaceHolderID="HeadContent" runat="server">
<link rel="stylesheet" href="<%= ResolveUrl("~/Content/LearnerDashboard.css") %>?v=3" />
<link rel="stylesheet" href="<%= ResolveUrl("~/Content/LearnerLeaderboard.css") %>?v=9" />
</asp:Content>
<asp:Content ID="Main" ContentPlaceHolderID="MainContent" runat="server">
<main class="ld-wrap">
  <!-- Local SVG symbol library; no external icon package required. -->
  <svg class="ld-symbols" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
    <symbol id="ld-sparkles" viewBox="0 0 24 24"><path d="m12 3 1.8 5.2L19 10l-5.2 1.8L12 17l-1.8-5.2L5 10l5.2-1.8L12 3ZM19 17l.7 1.3L21 19l-1.3.7L19 21l-.7-1.3L17 19l1.3-.7L19 17ZM4 16l.7 1.3L6 18l-1.3.7L4 20l-.7-1.3L2 18l1.3-.7L4 16Z"/></symbol>
    <symbol id="ld-book" viewBox="0 0 24 24"><path d="M12 6c-2-1.7-5.6-2.1-9-1.2v14c3.4-.9 7-.5 9 1.2 2-1.7 5.6-2.1 9-1.2v-14c-3.4-.9-7-.5-9 1.2ZM12 6v14"/></symbol>
    <symbol id="ld-terminal" viewBox="0 0 24 24"><path d="m4 6 6 6-6 6M12 18h8"/></symbol>
    <symbol id="ld-message" viewBox="0 0 24 24"><path d="M5 4h14a2 2 0 0 1 2 2v11a2 2 0 0 1-2 2H9l-6 3V6a2 2 0 0 1 2-2Z"/></symbol>
    <symbol id="ld-trophy" viewBox="0 0 24 24"><path d="M7 3h10v7a5 5 0 0 1-10 0V3ZM7 5H3v3a4 4 0 0 0 4 4M17 5h4v3a4 4 0 0 1-4 4M12 15v4M8 21h8M9 19h6"/></symbol>
    <symbol id="ld-user" viewBox="0 0 24 24"><circle cx="12" cy="8" r="4"/><path d="M4 21a8 8 0 0 1 16 0"/></symbol>
    <symbol id="ld-flame" viewBox="0 0 24 24"><path d="M12 22c4.2 0 7-3.2 7-7.2 0-3.2-1.8-5.7-4-7.8.1 2-1 3.2-2 3.8C12 7.6 11.2 5 9 2 9 7 5 9.3 5 14.8 5 18.8 7.8 22 12 22Z"/></symbol>
    <symbol id="ld-zap" viewBox="0 0 24 24"><path d="m13 2-9 12h7l-1 8 10-13h-7l0-7Z"/></symbol>
    <symbol id="ld-award" viewBox="0 0 24 24"><circle cx="12" cy="8" r="5"/><path d="m8.5 12-2 9L12 18l5.5 3-2-9"/></symbol>
  </svg>
  <nav class="ld-tabs" aria-label="Learner navigation">
    <a class="ld-tab" href="<%= ResolveUrl("~/Modules/Learner/Dashboard.aspx") %>"><svg class="ld-icon"><use href="#ld-sparkles" /></svg>Dashboard</a>
    <a class="ld-tab" href="<%= ResolveUrl("~/Modules/Learner/Courses.aspx") %>"><svg class="ld-icon"><use href="#ld-book" /></svg>Courses &amp; Curriculum</a>
    <a class="ld-tab"
        href="<%= ResolveUrl("~/Modules/Learner/Workspace.aspx") %>">
        <svg class="ld-icon" aria-hidden="true">
            <use href="#ld-terminal" />
        </svg>
        CodeLab Workspace
    </a>
    <a class="ld-tab"
        href="<%= ResolveUrl("~/Modules/Learner/DiscussionForum.aspx") %>">
        <svg class="ld-icon" aria-hidden="true">
            <use href="#ld-message" />
        </svg>
        Discussion Forum
    </a>   
    <a class="ld-tab selected" aria-current="page" href="<%= ResolveUrl("~/Modules/Learner/Leaderboard") %>"><svg class="ld-icon"><use href="#ld-trophy" /></svg>Leaderboard &amp; Badges</a>
    <a class="ld-tab" href="<%= ResolveUrl("~/Modules/Learner/Profile") %>"><svg class="ld-icon"><use href="#ld-user" /></svg>My Profile</a>
    <span class="ld-identity"><span class="ld-avatar"><% if(!string.IsNullOrEmpty(((CodeLab.SiteMaster)Master).LearnerAvatarUrl)){ %><img class="ld-identity-photo" src="<%: ((CodeLab.SiteMaster)Master).LearnerAvatarUrl %>" alt="" referrerpolicy="no-referrer" onerror="this.remove()" /><% } %><%: Initial(Board != null ? Board.Me.Name : LearnerName) %></span><span class="ld-user-meta"><b><%: Board != null ? Board.Me.Name : LearnerName %></b><small>Level <%: Board != null ? Board.Me.Level.ToString() : "�" %> &bull; <%: Board != null ? Board.Me.Points.ToString("N0") : "�" %> XP</small></span></span>
  </nav>
<div class="lb-wrap">
<% if (Board == null) { %>
    <p class="lb-message" role="alert"><%: ErrorMessage ?? "Please sign in to see the leaderboard." %></p>
<% } else { %>
<section aria-labelledby="rankings-title" id="rankings">
    <header class="lb-section-heading">
        <div><h2 id="rankings-title"><svg class="ld-icon" aria-hidden="true"><use href="#ld-trophy" /></svg> Global Learner Rankings</h2><p>All-time achievements across CodeLab. Rankings update when you refresh.</p></div>
        <nav class="lb-switch" aria-label="Rank learners by">
            <a class='<%= ByLevel ? "" : "is-active" %>' href='<%: FilterUrl("xp",BadgeFilter) %>'>Rank by Achievement Points (XP)</a>
            <a class='<%= ByLevel ? "is-active" : "" %>' href='<%: FilterUrl("level",BadgeFilter) %>'>Rank by Level</a>
        </nav>
    </header>
    <div class="lb-podium">
    <% foreach (var entry in Board.Podium) { bool me=entry.LearnerId==Board.Me.LearnerId; %>
        <article class='<%= me ? "lb-leader is-you" : "lb-leader" %>' data-rank="<%: entry.Rank %>">
            <span class="lb-rank-medal" aria-label='<%: "Rank " + entry.Rank %>'><%: entry.Rank %></span>
            <% if(me) { %><span class="lb-you">YOU</span><% } %>
            <% if(entry.Rank == 1) { %><svg class="lb-crown" viewBox="0 0 24 24" aria-hidden="true"><path d="m3 6 5 4 4-7 4 7 5-4-3 13H6Z" /></svg><% } %>
            <span class="lb-avatar lb-avatar-large" aria-hidden="true"><%: Initial(entry.Name) %><% if (Avatar(entry.AvatarUrl) != null) { %><img src="<%: Avatar(entry.AvatarUrl) %>" alt="" referrerpolicy="no-referrer" onerror="this.remove();" /><% } %></span>
            <span class="lb-place"><svg class="ld-icon" aria-hidden="true"><use href='<%: entry.Rank == 1 ? "#ld-trophy" : "#ld-award" %>' /></svg><%: entry.Rank == 1 ? "1ST PLACE" : entry.Rank == 2 ? "2ND PLACE" : "3RD PLACE" %></span>
            <h2><%: entry.Name %></h2><p class="lb-handle">@<%: entry.Username %></p>
            <div class="lb-leader-stats"><div><span>POINTS</span><strong class="lb-xp"><%: entry.Points.ToString("N0") %> XP</strong></div><div><span>LEVEL</span><strong>Lvl <%: entry.Level %></strong></div></div>
        </article>
    <% } %>
    </div>
    <div class="lb-table-scroll" tabindex="0" role="region" aria-label="Learner rankings">
    <table class="lb-table"><caption class="lb-sr-only">All-time learner rankings, page <%: Board.Page %></caption>
    <thead><tr><th scope="col">Rank</th><th scope="col">Learner profile</th><th scope="col">Level &amp; tier</th><th scope="col">Achievement points</th><th scope="col">Badges</th><th scope="col">Completed</th></tr></thead>
    <tbody><% foreach(var entry in Board.Entries) { bool me=entry.LearnerId==Board.Me.LearnerId; %>
    <tr class='<%= me ? "is-you" : "" %>'><td><span class="lb-rank" data-rank="<%: entry.Rank %>"><%: entry.Rank %></span></td>
    <th scope="row"><div class="lb-profile"><span class="lb-avatar" aria-hidden="true"><%: Initial(entry.Name) %><% if (Avatar(entry.AvatarUrl) != null) { %><img src="<%: Avatar(entry.AvatarUrl) %>" alt="" referrerpolicy="no-referrer" onerror="this.remove();" /><% } %></span><div><strong><%: entry.Name %></strong> <% if(me) { %><span class="lb-you-inline">You</span><% } %><small>@<%: entry.Username %></small></div></div></th>
    <td><strong>Level <%: entry.Level %></strong><small><%: entry.LevelTitle %></small></td><td class="lb-xp"><%: entry.Points.ToString("N0") %> XP</td><td><span class="lb-badge-count"><%: entry.Badges %></span></td><td><%: entry.Completed %> course(s)</td></tr>
    <% } %></tbody></table></div>
    <p class="lb-standing">Your rank: <strong>#<%: Board.Me.Rank %></strong> of <%: Board.TotalLearners %> active learners &middot; <%: Board.Me.Points.ToString("N0") %> XP &middot; Equal <%: ByLevel ? "levels and XP totals" : "XP totals" %> share a rank.</p>
    <% if(Board.PageCount>1) { %><nav class="lb-pagination" aria-label="Leaderboard pages"><% if(Board.Page>1) { %><a href='<%: PageUrl(Board.Page-1) %>'>Previous</a><% } %><span>Page <%: Board.Page %> of <%: Board.PageCount %></span><% if(Board.Page<Board.PageCount) { %><a href='<%: PageUrl(Board.Page+1) %>'>Next</a><% } %></nav><% } %>
</section>
<section class="lb-badges-section" id="badges" aria-labelledby="badges-title">
    <header class="lb-section-heading"><div><h2 id="badges-title"><svg class="ld-icon" aria-hidden="true"><use href="#ld-award" /></svg> Earned Badges &amp; Milestone Catalog</h2><p><%: Board.EarnedCount %> of <%: Board.Badges.Count %> unlocked. Keep learning, passing quizzes, and solving challenges.</p></div>
    <nav class="lb-switch lb-filters" aria-label="Filter badges"><% foreach(var filter in new[]{"all","unlocked","locked","coding","curriculum","quiz","xp"}) { %><a class='<%= BadgeFilter==filter ? "is-active" : "" %>' href='<%: FilterUrl(ByLevel ? "level" : "xp",filter) + "#badges" %>'><%: filter.ToUpperInvariant() %></a><% } %></nav></header>
    <div class="lb-badge-grid">
    <% foreach(var badge in VisibleBadges) { %>
        <article class='<%= badge.Earned ? "lb-badge-card" : "lb-badge-card is-locked" %> tier-<%: CodeLab.BLL.LeaderboardManager.GetBadgeTier(badge).ToLowerInvariant() %>'>
            <div class="lb-badge-top"><span class="lb-badge-icon"><svg class="ld-icon" aria-hidden="true"><use href='<%: "#ld-" + badge.Icon %>' /></svg></span><span class="lb-badge-state"><%: badge.Earned ? "UNLOCKED" : "LOCKED" %></span></div>
            <h3><%: badge.Name %></h3><p><%: badge.Description %></p>
            <footer><strong><%: badge.Category.ToUpperInvariant() %></strong><span><% if (badge.Earned) { %>Earned <%: badge.EarnedAtUtc.Value.ToString("dd MMM yyyy") %> (UTC)<% } else { %><%: Math.Min(badge.Current,badge.Target).ToString("N0") %> / <%: badge.Target.ToString("N0") %><% } %></span></footer>
            <progress max="100" value='<%: badge.Percent %>' aria-label='<%: badge.Name + " progress" %>'><%: badge.Percent %>%</progress>
        </article>
    <% } %>
    </div>
    <% if(MatchingBadges==0) { %><p class="lb-message">No badges match this filter yet. Try All to see your next milestones.</p><% } %>
    <% if(MatchingBadges>0) { %>
    <nav class="lb-pagination lb-badge-pagination" aria-label="Badge pages">
        <% if(BadgePage>1) { %><a href="<%: BadgePageUrl(BadgePage-1) %>" rel="prev" aria-label="Previous badge page" title="Previous badge page">&lt;</a><% } else { %><span class="is-disabled" aria-disabled="true" aria-label="Previous badge page">&lt;</span><% } %>
        <% if(BadgePage<BadgePages) { %><a href="<%: BadgePageUrl(BadgePage+1) %>" rel="next" aria-label="Next badge page" title="Next badge page">&gt;</a><% } else { %><span class="is-disabled" aria-disabled="true" aria-label="Next badge page">&gt;</span><% } %>
    </nav>
    <% } %>
    <p class="lb-footnote">Earned badges are permanent, including awards earned before requirements increased. Dates show when eligibility was first recorded (UTC), including existing achievements. Repeating a quiz or challenge counts once. Badges do not award additional XP.</p>
</section>
<% } %>
</div>
</main>
<script>
(function () {
    'use strict';
    if (!window.fetch || !window.AbortController) return;
    var pending;
    document.addEventListener('click', async function (event) {
        var link = event.target.closest('#badges .lb-filters a, #badges .lb-badge-pagination a');
        if (!link || event.button !== 0 || event.ctrlKey || event.metaKey || event.shiftKey || event.altKey) return;
        event.preventDefault();
        if (pending) pending.abort();
        var request = new AbortController();
        pending = request;
        var section = document.getElementById('badges');
        var target = new URL(link.href, location.href);
        // Filtering badges must not reset the independent rankings page.
        var current = new URL(location.href);
        if (current.searchParams.has('page')) target.searchParams.set('page', current.searchParams.get('page'));
        var label = link.getAttribute('aria-label');
        var filter = link.closest('.lb-filters') ? link.textContent.trim() : null;
        var oldError = section.querySelector('.lb-load-error');
        if (oldError) oldError.remove();
        section.setAttribute('aria-busy', 'true');
        try {
            var response = await fetch(target.href, { credentials: 'same-origin', signal: request.signal });
            if (!response.ok) throw new Error('Request failed');
            var documentResult = new DOMParser().parseFromString(await response.text(), 'text/html');
            var replacement = documentResult.getElementById('badges');
            if (!replacement) throw new Error('Badges unavailable');
            if (request.signal.aborted) return;
            section.replaceWith(replacement);
            history.replaceState(history.state, '', target.pathname + target.search + target.hash);
            // Keep subsequent ranking navigation in sync with the selected badge filter.
            document.querySelectorAll('#rankings a[href]').forEach(function (rankingLink) {
                var url = new URL(rankingLink.href, location.href);
                url.searchParams.set('badges', target.searchParams.get('badges') || 'all');
                url.searchParams.set('badgePage', target.searchParams.get('badgePage') || '1');
                rankingLink.href = url.href;
            });
            var focusTarget = filter ? replacement.querySelector('.lb-filters .is-active') :
                Array.from(replacement.querySelectorAll('.lb-badge-pagination a')).find(function (item) {
                    return item.getAttribute('aria-label') === label;
                });
            if (!focusTarget) focusTarget = replacement.querySelector('.lb-filters .is-active');
            if (focusTarget) focusTarget.focus({ preventScroll: true });
        } catch (error) {
            if (error.name !== 'AbortError') {
                var message = document.createElement('p');
                message.className = 'lb-message lb-load-error';
                message.setAttribute('role', 'alert');
                message.textContent = 'Unable to load badges. Please try again. If your session expired, sign in again.';
                section.appendChild(message);
            }
        } finally {
            if (pending === request) {
                pending = null;
                document.getElementById('badges').removeAttribute('aria-busy');
            }
        }
    });
}());

</script>
</asp:Content>
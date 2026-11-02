/*
 * Shared by the Tutor results pages (Quiz Results, Coding Results). Read-only: nothing is posted.
 *
 * 1. Table filters inside [data-results-table]: learner search [data-filter-search], result select
 *    [data-filter-result], course select [data-filter-course]. Rows carry data-name, data-result and data-course.
 * 2. Quiz answer review: buttons [data-review-filter="all|wrong|correct"] show matching [data-review] items.
 * 3. Syntax colours (highlight.js, if loaded) for submitted code.
 */
(function () {
    'use strict';

    function initTable(card) {
        var search = card.querySelector('[data-filter-search]');
        var result = card.querySelector('[data-filter-result]');
        var course = card.querySelector('[data-filter-course]');
        var empty = card.querySelector('[data-filter-empty]');
        var rows = card.querySelectorAll('tbody tr');
        if (!rows.length) { return; }

        function apply() {
            var text = search ? search.value.trim().toLowerCase() : '';
            var wanted = result ? result.value : '';
            var wantedCourse = course ? course.value : '';
            var shown = 0;

            rows.forEach(function (row) {
                var match = (!text || (row.getAttribute('data-name') || '').indexOf(text) !== -1)
                    && (!wanted || row.getAttribute('data-result') === wanted)
                    && (!wantedCourse || row.getAttribute('data-course') === wantedCourse);
                row.hidden = !match;
                if (match) { shown++; }
            });

            if (empty) { empty.hidden = shown > 0; }
        }

        [search, result, course].forEach(function (control) {
            if (control) {
                control.addEventListener('input', apply);
                control.addEventListener('change', apply);
            }
        });
    }

    function initReview() {
        var buttons = document.querySelectorAll('[data-review-filter]');
        var items = document.querySelectorAll('[data-review]');
        var empty = document.querySelector('[data-review-empty]');
        if (!buttons.length) { return; }

        buttons.forEach(function (button) {
            button.addEventListener('click', function () {
                var filter = button.getAttribute('data-review-filter');
                var shown = 0;

                buttons.forEach(function (b) {
                    b.classList.toggle('is-active', b === button);
                    b.setAttribute('aria-pressed', b === button ? 'true' : 'false');
                });

                items.forEach(function (item) {
                    var match = filter === 'all' || item.getAttribute('data-review') === filter;
                    item.hidden = !match;
                    if (match) { shown++; }
                });

                if (empty) { empty.hidden = shown > 0; }
            });
        });
    }

    document.addEventListener('DOMContentLoaded', function () {
        document.querySelectorAll('[data-results-table]').forEach(initTable);
        initReview();

        if (window.hljs) {
            document.querySelectorAll('.cl-ide-code code').forEach(function (block) {
                window.hljs.highlightElement(block);
            });
        }
    });
})();

# QA practice digest (starting point, researched 2026-10-08)

Refresh the parts that matter for the product under test; do not treat this as complete. Tags below say how much to trust each line.

[F] = page fetched and read. [S] = seen in search results only. [K] = no source found, standard practice / inference.

## Exploratory testing, oracles, risk
- Charter: "Explore <area> with <resource> to discover <information>". Time-box. Keep a session note (areas covered, bugs, setup vs test time). [S]
- Oracles (FEW HICCUPPS): Claims, History, Comparable products, Statutes, Purpose, User expectations, Internal consistency, Familiar problems. An oracle says "might be a problem". https://developsense.com/resource/Oracles.pdf [S]
- SFDIPOT (Structure, Function, Data, Interfaces, Platform, Operations, Time): Data and Time are where money bugs sit. https://www.satisfice.com/download/heuristic-test-strategy-model [F landing page]
- Order by risk: cross-tenant access, wrong money, bad input handling, export. [K]

## Test design
- Property/invariant tests: split sums equal the amount; parse-serialise-parse stable; P&L total equals sum of GL. https://hypothesis.readthedocs.io/en/latest/tutorial/introduction.html [F]
- Boundary values for amounts (0, 1, -1, max int, 0.01), counts (lines, rows per request, page counts), dates (FY end, 29 Feb). [K]
- State machine: list the states of the main object and try every illegal transition through the API. [K]
- Decision table and pairwise combinations for the inputs that interact. [K]

## API security
- OWASP API Top 10 2023: https://api-security.owasp.org/editions/2023/en/0x11-t10 [F]
- BOLA: replay every endpoint taking an ID (path, query, body, header) using tenant A's IDs with tenant B's token, including child objects (allocation, pack, job). Matching session user to the ID param is not enough. https://api-security.owasp.org/editions/2023/en/0xa1-broken-object-level-authorization [F]
- Property level / mass assignment: PATCH with extra fields (companyId, owner, sealed, amountCents, createdBy, role); check responses return only what is needed. https://api-security.owasp.org/editions/2023/en/0xa3-broken-object-property-level-authorization [F]
- Resource consumption: upload size, page size, items per request, timeouts, rate limits on upload/export/report. https://api-security.owasp.org/editions/2023/en/0xa4-unrestricted-resource-consumption [F]
- Function level / business flow: staff, admin, seal and purge endpoints as a plain owner; workflow skips (export before confirm, seal twice, edit after seal, restore after purge). [S titles, WSTG]

## Untrusted PDF / upload
- OWASP File Upload cheat sheet [F]: https://cheatsheetseries.owasp.org/cheatsheets/File_Upload_Cheat_Sheet.html - double extension, null byte, case, colon in name, spoofed Content-Type; server stores its own generated name; check magic bytes; uploaded file reachable only through an ownership-checked handler by id.
- Fixtures to build [K]: truncated, encrypted (with/without password), very many pages, FlateDecode stream that expands hugely, deep nesting, embedded JS / OpenAction, PDF/ZIP polyglot. Assert bounded time and memory, a clean 4xx, no worker crash.
- Parser advisory: pdf.js up to 4.1.392 allowed JS execution from a malicious PDF (GHSA-wgrm-67xf-hhpq) [S]; check the parser version in use.

## Financial correctness
- Money: integer minor units, round to the smallest unit. https://martinfowler.com/eaaCatalog/money.html [F]
- [K] Grep for float/parseFloat/toFixed on money; test 0.1+0.2-style inputs, "1,234.50" strings, a 100-cent split three ways (remainder must land deterministically).
- [K] Invariants after every operation: debits equal credits, sub-ledger equals control total, opening + movements = closing, balance sheet balances. On seeded AND uploaded data.
- [K] Double-submit and parallel-submit the same save; expect idempotent result, no duplicate rows. Mongo has no transactions locally, so partial failure of multi-batch saves needs a look.
- [K] Cut-off: 23:59:59 and 00:00:00 +08:00, FY end, 29 Feb, statements spanning a year end; store UTC, display/filter MYT; run a report twice and diff (determinism); a sealed pack must not change.

## Web UI
- WCAG 2.2 target size minimum 24x24 CSS px (AA): https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html [F]. A project's own, stricter rule wins.
- Reflow: 320 CSS px wide, no two-dimensional scroll (data tables exempt, their headings/search/pagination are not): https://www.w3.org/WAI/WCAG22/Understanding/reflow.html [F]
- axe-core on every route in each state (empty, loading, error, dialog open): https://www.deque.com/axe/ [F]. Automated checks are not a pass on their own.
- Keyboard-only pass: tab order, visible focus, Escape closes each dialog, focus returns to trigger, no traps. [K]
- Slow network and forced 500/401/offline per action: skeleton not empty flash, visible error with retry, optimistic update with rollback. [K]

## Reporting
- Title = component + trigger + symptom. One action per step. Include environment. Expected must cite an oracle; actual must be the exact message or value. Severity = technical impact, priority = fix order. Reproduce twice, minimise, rule out stale cache/test data, check against code/docs before filing. (practitioner blogs, convention) [S]

## CSV
- Formula injection: cells starting with = + - @ tab CR LF (and full-width forms) in description/payee/reference; quote, prefix, double internal quotes; no single fix works in every spreadsheet app. https://community.owasp.org/attacks/CSV_Injection [F]

## Default priority order for a multi-tenant data app
1 Cross-tenant object-level access sweep on every id-taking endpoint. 2 Mass assignment on every write. 3 Money invariants as properties. 4 Double and concurrent saves, including any batch path over a size limit. 5 Hostile upload set, bounded time and memory. 6 Upload plumbing: spoofed type and extension, generated names, ownership-checked retrieval. 7 Cut-off, timezone and determinism; stored reports immutable. 8 Export injection with numeric columns intact. 9 Authorisation on state changes (edit after lock, restore after purge, staff routes as a plain user). 10 UI states: axe, keyboard, narrow width, failed network.

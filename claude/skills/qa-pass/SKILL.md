---
name: qa-pass
description: Use when asked to act as strict QA, run a QA pass, test everything on the combined test branch, or before a batch of PRs reaches staging or production. Runs the whole loop - research, independent QA agents, triage, senior-engineer fix agents, one decisions page for the owner, a green combined branch, then tracker, API collection and memory. Not for checking a single change (use qa-verification for that).
---

# QA pass

`qa-verification` checks one change you just made. This skill checks **everything
built so far**, as an independent tester who is trying to find defects, then drives
the fixes to a verified, handed-over branch. It is a stage of the development
lifecycle, not an occasional rescue.

## Where it sits in the lifecycle

```
build -> integrate -> QA pass -> fix -> decide -> ship
```

| Stage | Gate to leave it |
|---|---|
| Build: small PRs, one concern, failing test first | the project's one verify command exits 0 |
| Integrate: one combined test branch holding every open PR | verify exits 0 **on the combined branch**, browser smoke included |
| QA pass (this skill) | findings triaged, S1 confirmed by the lead itself |
| Fix: senior-engineer agents, one branch per concern | each branch tested, pushed, no PR yet |
| Decide: one page for the owner | every decision answered or explicitly parked |
| Ship: PRs, tracker, API collection, memory | merge order and deploy-time steps written down |

**Run a QA pass:** before any batch of PRs reaches staging or production; after a
feature wave of more than a handful of PRs; when the owner asks; and before a
milestone is declared done. A pass is cheap next to finding the same defect in
production.

## Roles

- **Lead** (you): owns scope, data safety, triage, integration, the gate, the
  owner's decisions. The lead never delegates the verdict on an S1.
- **QA agents**: find defects and prove them. They never fix, never commit, never
  touch the owner's checkout or running servers.
- **Senior-engineer agents**: fix one work package each, in their own worktree,
  test first. They push a branch and do not open a PR.
- **Owner**: decides anything that is a product or risk call. Bring each decision
  with your recommendation (see `references/decisions-page.md`).

Delegating: name the agent and why in one line before launching it. Routine fixes go
to a worker; anything on a trust boundary (parsers, auth, money, concurrency) goes
to the deep reasoner.

## Procedure

### 0. Preconditions
- The combined test branch exists and its gate is green. If not, make it so first:
  a QA pass on a red branch reports the red.
- Write down the **protected data** (the owner's real or hand-built accounts) and
  the **known and accepted** items (documented tech debt, things the owner already
  decided). QA agents are told both; accepted items are not re-reported.
- Make a QA folder outside the repo (scratch space). Nothing from a QA pass goes in
  the repository: no briefs, no findings, no decisions.

### 1. Research, briefly, and cite it
Search for current best practice on what you are about to test and keep a digest in
`RESEARCH.md`, tagging every claim **[F]** fetched and read, **[S]** seen in search
results only, **[K]** no source, standard practice or inference. Do not present [S]
or [K] as established fact. `references/research-digest.md` is the starting digest
(exploratory testing and oracles, API security, untrusted uploads, money and
invariants, web accessibility, CSV safety); refresh the parts that matter for this
product rather than redoing it.

### 2. Charters, by area
One charter per area, each "explore <area> with <resource> to discover <information>",
time-boxed. Default areas: static review of the code against the project's own
rules; security and tenancy (every id-taking endpoint replayed as another tenant);
uploads and untrusted input; money and invariants; lifecycle and state transitions;
UI, accessibility and error states; reports and exports. Order by risk: cross-tenant
access, wrong money, bad parse, export.

### 3. The brief
Give every QA agent the same brief (`references/qa-brief.template.md`): target,
data-safety rules, disposable test accounts, tools, method, accepted items, and the
exact finding format. The two rules that matter most: writes only through disposable
accounts the agent creates, and stop immediately on a cross-tenant exposure.

### 4. Run the agents
In parallel, with a concurrency cap (the dev API is one process on a laptop). One
agent owns the shared browser; the rest test over HTTP. Each writes one findings
file and replies with a short summary.

### 5. Triage (lead)
- Merge duplicates; note which findings were independently confirmed.
- Verify every S1 yourself before it goes further. Several findings will turn out to
  be your own recent bugs: say so.
- Group into **work packages** by wave: wave 1 needs no decision; wave 2 is larger
  or web-heavy; wave 3 needs the owner. One concern per package.
- Keep a `TRIAGE.md` with counts by severity and the package list.

### 6. Fix
Hand each work package to a senior-engineer agent with `references/fix-brief.template.md`.
- **Premise check first.** Before the brief goes out, confirm the thing it assumes
  exists (a screen, an endpoint, a branch). Tell the agent to stop and report if the
  premise is false, not to build something larger to make it true.
- Own worktree, branched from the PR that owns the code (not always the default
  branch); never the owner's checkout. Failing test first, seen failing for the right
  reason. One concern, small diff, match the surrounding style.
- **Fix on the branch that owns the code.** A fix found while integrating goes back
  onto that PR's branch, so the PR passes by itself, not only in the combination.
- Agents never use `git stash` (the stash list is shared across worktrees), never
  force-push, and report any incident honestly.
- Evidence standard: say what you measured and what you inferred. A flaky test is
  fixed at its root cause with a measurement; retries and longer timeouts are not
  fixes.

### 7. Integrate and gate
Merge every fix branch into the integration branch, resolve conflicts by hand, then
run the **same command CI runs**, plus the browser smoke, from a clean worktree.
- Read the result from the log's `EXIT` line. A background task's own "exit code 0"
  has been wrong; do not push or hand over on it.
- A failure that appears only in the combination is real: fix it on the branch that
  owns it.
- Hand the owner's local test branch over by fast-forward, last, only when both gates
  are green. Revert any temporary local edit used to run the smoke.
- A dev server cannot prove production behaviour (module URLs, caching, preload).
  Verify those once on a production build, and say in the PR what was and was not run.

### 8. Decisions
Put every owner decision on one page (`references/decisions-page.md`): what, why it
matters, the options, your recommendation, what each choice costs. Record the answers
verbatim in `DECISIONS.md` in the QA folder and act on them. Where an answer rests on
a misunderstanding, correct it with the facts before building.

### 9. Ship paperwork
- PRs: small, one concern, correct base, bodies written for a cold reader and
  claiming only what a test or measurement shows. Draft only while a decision is
  open, and say which decision. No attribution lines anywhere.
- Tracker task per pass with the PR list, decisions and what is still open.
- API collection updated for every changed endpoint (and any description a change
  made false).
- Memory file for the session: PR numbers, decisions, what is owed.
- Deploy-time steps (data migrations, new required settings) written down with the
  PR that needs them, and the owner reminded when the stack nears the live branch.

### 10. Clean up
Wipe disposable QA users, remove worktrees (unlink dependency junctions first),
revert temporary edits, kill servers you started. Confirm the owner's checkout and
protected accounts are untouched.

## Pitfalls this skill exists to prevent

- Reporting "all green" from a background task's exit code instead of the log.
- A fix that passes in the combined branch but fails alone in its own PR.
- Test accounts or fixtures built from real client data, and real client text in PR
  bodies, tests or commit messages. Invented data in the repo, always.
- Opening a PR that asserts something nobody ran.
- A dev-server check standing in for a production-build check.
- Silently widening a task because its premise was false.

See `references/` for the brief, fix brief, decisions page guide and research digest.

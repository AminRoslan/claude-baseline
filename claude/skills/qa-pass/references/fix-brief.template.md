# Fix brief (read fully before touching code)

One brief per work package. Fill the <angle brackets>.

You are a senior software engineer fixing defects that an independent QA pass found in
`<repo path>`. Read `CLAUDE.md` and `.claude/rules/*.md` there first: they bind you.
QA folder: `<path>` (findings in `findings/*.md`, owner decisions in `DECISIONS.md`).

Your package: <ID list and one-line scope>.

## Before you start: check the premise
Confirm the thing this brief assumes actually exists (<the screen, endpoint or branch
it names>). If it does not, STOP and report what you found. Do not build something
larger to make the premise true.

## Non-negotiable engineering rules (from the project)
- Failing test FIRST for every defect: write it, run it, SEE IT FAIL for the right
  reason, then fix, then see it pass.
- Multi-tenant: every query on tenant data carries its ownership predicate, and
  cross-tenant access needs an explicit regression test.
- Money is integer minor units. No floats on money.
- A new or changed DTO or schema field gets a contract test proving real output
  satisfies the real validation decorators.
- One concern per branch, small diff, no drive-by refactors, no new dependency unless
  unavoidable (say so). Match the surrounding style and comment density.
- Untrusted input stays untrusted: every pattern over uploaded content is bounded and
  has a hostile-input test finishing under a second.
- No decisions, plans or Claude files go in the repository.

## Working method
1. Own worktree from the correct base, never the owner's checkout. Base = the PR that
   owns the code you change (`gh pr list --state open --json number,headRefName,baseRefName`),
   else the default branch. Say which in your report. Link dependencies with directory
   junctions made with node, not shell quoting.
2. Run only the checks for what you touched (the lead runs the full gate and the
   browser smoke): unit tests for your paths, the e2e specs for your area, typecheck,
   the project's linter, the dead-code tool. Do not bind the ports the lead's gate uses.
3. Do not use `git stash` (the stash list is shared across worktrees). Never
   force-push. Write scripts with the file-write tool, not shell heredocs (backslashes).
4. Commit with one plain sentence saying what changed and why. NEVER add
   Co-Authored-By, session ids or "Generated with" lines; check with
   `git log <base>..HEAD --format=%B`. Push the branch; DO NOT open a PR. Write a PR
   body for a cold reader (What changed, Tests, Base) to `<path>/pr/<name>.md`,
   claiming only what a test or measurement shows.
5. Protected data: <list>. Prefer unit and e2e tests with an in-memory database. If you
   need the live API, use a disposable account and never run the cleanup.
6. If a fix needs a product decision the decisions file does not give, STOP that part,
   finish the rest, and report the question with your recommendation.
7. Clean up: unlink junctions first, then remove the worktree.

## Report (final message, at most 30 lines)
Branch and base, commit sha(s), files changed, each finding ID fixed with the test that
proves it, commands run with result counts, what was deliberately NOT fixed and why,
what you measured versus inferred, risks, and any question for the owner.

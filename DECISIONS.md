# Decisions

Every rule in this baseline came from something that went wrong. This file records
what, so a rule can be pruned when it stops applying instead of being carried
forever out of superstition.

**How to use it:** before deleting anything from the baseline, find it here. If the
incident cannot happen in the new project — different OS, different database,
different plan tier — delete the rule and its entry together. A baseline that only
ever grows becomes cargo-cult within two projects.

No project, company, account or host names appear below. The incidents are what
transfers; the identifiers are not.

---

## CI and testing

### The e2e suite ran in CI on no one's machine but the author's

An end-to-end suite with its own test-runner config is **not** picked up by a
monorepo task runner's `test` task. So a fully green `pnpm run test` said nothing
about it, and it only ever ran when someone remembered. It held every cross-tenant
authorization regression in the codebase.

**Rule:** `ci.yml.template` runs the e2e suite as an explicit step, in the same job.
Same job, not a parallel one — a second job re-pays checkout, Node setup, install
and cache restore. Measured on the source repo: install 37s, e2e 22s. Parallelise
when a step outgrows a second install, not before.

### Switching e2e on immediately proved it was not runnable anywhere

First CI run died before any assertion: `Configuration key "ANTHROPIC_API_KEY" does
not exist`. Four of five required config keys were being satisfied by whatever
happened to sit in the developer's own `.env`. Three more were queued behind the
first. The same class had already bitten the frontend suite a week earlier, where
CI lacked the client-side Firebase variables.

**Rule:** a test suite's global setup assigns every environment variable the app
requires to boot. Not documented in a README — assigned, in code, unconditionally.
Two consequences fall out for free: the suite becomes runnable on a clean machine,
and a real API key sitting in someone's `.env` can no longer be spent by a test run.

One trap: a credential that gets *parsed* rather than merely read cannot be a
placeholder string. A fake private key failed with `DECODER routines::unsupported`
because the SDK parses the PEM at init. Generate a throwaway keypair in setup
rather than committing one — a real PEM in a repo is something scanners flag and
something people copy.

### Two CI steps that could never fail

A dead-code check and a dependency audit both ran with `continue-on-error: true`,
and both exited non-zero on a normal tree — 35 unused exports, 21 advisories.
Neither could ever fail a build. They had been read once and ignored ever since.

**Rule:** a check is blocking or it is absent. A permanently-red advisory step is
worse than no step, because it trains everyone to ignore a red mark. Making one
blocking is a cleanup task with its own PR, never a flag flipped in passing.

### Branch protection was unavailable, so the deploy got gated instead

The branch protection API returns `403 Upgrade to GitHub Pro or make this repository
public` on a free plan. Nothing could stop code landing on the staging trunk — and a
push to that trunk deployed to a live staging environment with no test in between.

**Rule:** when you cannot stop code landing, stop it deploying. The deploy workflow
carries its own test job and the deploy job `needs:` it.

A `workflow_run` trigger was evaluated and rejected: it fires *after* the triggering
workflow completes, by which point the deploy has already started — which is the
exact failure being prevented. The duplicated test job costs about three minutes per
deploy. That is the price of the gate; there is no version that is both free and
real.

### Parallel test files sharing one stateful resource

One in-memory database instance shared across every spec file, several of which
called an unscoped `deleteMany({})` in cleanup. Running files in parallel let one
file's teardown delete another file's live fixtures mid-test. Surfaced as a flake:
a record created two lines earlier was gone by the next assertion.

**Rule:** tests sharing one external stateful resource run sequentially. That is the
correct fix for the general case, not a workaround for one flaky spec. Scope
cleanup to the file's own fixtures as well — belt and braces, since the next person
to add a spec will not read this.

### A test suite wrote to real cloud storage

A storage factory selected the cloud backend whenever a bucket variable was set. A
machine configured to run the app against staging storage — an entirely reasonable
setup — silently uploaded every test fixture there. One local run left 372 objects
mixed in with real data.

**Rule:** global test setup redirects every external dependency, and does it by
**assigning an empty value rather than deleting the key**. Deleting does not work:
`dotenv` only fills in keys absent from the environment, so a deleted key is handed
straight back from the `.env` file. This is not obvious and costs an hour to
rediscover.

---

## Platform and tooling

### Native binaries blocked by Windows Application Control

On a machine with an Application Control policy, **downloaded** native binaries are
refused while properly installed applications run fine. Two were hit: a compiler's
`.node` binding and a browser automation library's bundled Chromium.

**The general rule, which is the part that transfers:** never fix one of these by
reinstalling, clearing a cache, or letting the tool re-download. The replacement is
blocked for the same reason. Reach for something already installed on the machine,
or a path that needs no native binary at all.

The specific workarounds are machine-specific and are deliberately **not** in this
baseline. They name one machine's paths and one pinned toolchain version, and would
be wrong and confusing on any other.

### A dead-code tool pinned to an old major

Version 6 of the tool moved to a native parser whose binding fails to load on
Windows. Pinned to 5.x.

**Rule:** when a tool is pinned below its latest major, the pin carries a comment
saying which platform breaks and how. A bare version pin gets "helpfully" bumped by
the next person; a pin with a failure mode attached does not.

### A local database that cannot do what production does

The local database ran standalone, so transaction APIs failed on every dev machine
while working in production.

**Rule:** state this in the project's CLAUDE.md gotchas. It is the exact shape that
burns an afternoon — the code is right, the environment is not, and nothing in the
error says so.

### Two browser automation integrations colliding

A plugin-provided browser automation server and a manually configured one were both
present. The manual entry was pointed at an installed browser; the plugin's default
looked for one that was not installed on that machine. Disabling the plugin's server
resolved it.

**Rule:** one automation server, configured once, pointed at a browser known to
exist. When a plugin ships an unconfigured duplicate, disable the plugin's rather
than adding a third configuration.

---

## Version control and process

### Stacked PRs auto-closing

Deleting a merged PR's branch can auto-close a PR stacked on it; the host does not
reliably retarget the child.

**Rule:** never delete a merged branch until the PR above it is confirmed
retargeted. In `references/branching.md`.

### Task ids in branch names

Generated tracker ids appeared in branch names, making `git branch -a` unreadable
and costing a lookup to decode each one.

**Rule:** `<type>/<kebab-summary>`, nothing else. The tracker link goes in the PR
body where it is clickable.

### A rewritten branch left its originals behind

A `filter-branch` had stripped AI attribution trailers from a feature branch, and
the work reached the trunk under new SHAs. What nobody cleaned up was
`refs/original/`, which `filter-branch` writes as a safety net — so two commits
carrying `Co-Authored-By` and a session URL survived in the local object store
for months, unreachable from any branch and invisible to every normal command.

**Rule:** a history rewrite is not finished at the push. Delete `refs/original/`,
expire the reflog and `gc --prune=now`, and confirm with
`git log --all --format='%H %B' | grep -i` that nothing survives.

Before deleting, prove the work survives elsewhere — and compare **patches, not
trees**. Trees diverge legitimately whenever the branch was rebased, which looks
alarming and means nothing. Even `git patch-id` can differ on a rebased commit
because it accounts for context lines; when it does, diff the two diffs and check
that only blob hashes and hunk offsets moved. Then check whether the remote holds
the objects at all (`gh api repos/<o>/<r>/commits/<sha>`, or the host's
equivalent) so you know whether local deletion is actually sufficient.

### Attribution enforced outside the repository

The authorship rule was prose in a config file with nothing behind it.

**Rule:** a global `commit-msg` hook at machine level, not a committed `.githooks/`
directory. Two reasons. It covers every repository on the machine including ones
that do not exist yet. And an in-repo artefact that exists to police AI attribution
advertises that AI is used, which defeats its own purpose.

Accepted limits, stated rather than papered over: a global `core.hooksPath` replaces
per-repo hooks everywhere, and `--no-verify` bypasses it. It is a guard against
forgetting, not against intent. Nothing client-side can be more than that.

### Installing a dev dependency silently disabled that gate

A later project added Husky for conventional-commit linting. Husky sets
`core.hooksPath` to `.husky/_` **repo-locally**, and a repo-local setting overrides
the global one. So the machine-wide attribution gate stopped running in that
repository the moment the install finished. No error, no warning, no output. The
guard was simply gone, and the only way to notice was to reason about why two
mechanisms configure the same git setting.

This is the failure mode the entry above did not anticipate. The gate is not
bypassed by someone choosing to bypass it; it is bypassed by routine tooling that
has no idea the gate exists.

**Rule:** any repository that installs Husky, or anything else that writes
`core.hooksPath`, re-implements the attribution check inside its own
`.husky/commit-msg`, with a comment stating that the duplication is deliberate and
why. Duplication is correct here. A single source would be a single point of silent
failure.

**Generalised:** when a tool configures the same setting a security control relies
on, assume the tool wins and verify. Check `git config core.hooksPath` after
installing anything that touches git plumbing. A control that can be switched off
without producing output is a control you do not have.

### A completion rule nobody checked

"Not done until build, lint, typecheck and the test suite pass locally" sat in a
CLAUDE.md with nothing behind it. No hook, no commit gate, nothing.

**Rule:** `require-completion-gate.ps1` on the Stop event runs the two cheap
halves for real and blocks the turn on failure. Build and tests stay in CI,
because running all four costs about 45 seconds per turn and a hook that slow
gets switched off within a week.

That split is only honest if CI actually blocks. It became true here in the same
pass: CI now runs on pull requests and on pushes to the trunk, and the staging
deploy depends on it. Inheriting the split into a project whose CI is advisory
would be cargo-culting the shape of a rule without the thing that makes it work.

### Three author spellings, one engineer

`git shortlog -sn` reported one person as three, across two email addresses. The
expensive half is not the miscount: it is `git log --author=<spelling>` silently
returning nothing, which reads as an answer rather than a miss.

**Rule:** a `.mailmap` at the repo root, canonicalising every spelling to one
identity. Leave automation identities alone — a web-UI merge really was made by
the web UI, and collapsing that into a person makes the history less accurate.

### PR descriptions written as a conversation

PR bodies were written as replies to the conversation that produced the change —
"you asked whether…" — which is meaningless to a reviewer who did not ask.

**Rule:** PR bodies address the reviewer cold, and state the decisions worth
disagreeing with along with the alternative that was rejected. A PR that only says
what it did invites a review that only checks whether it works.

### Combined branches broke what each passed alone

A dozen PRs were open at once, several stacked, several touching the same screens.
Every one passed the full verification command and CI on its own. Merged into one
test branch they conflicted in four places and broke a fixture field that one PR
removed and another still used; no CI run could show it because the PRs were never
built together.

**Rule:** before handing a test branch to a human, merge every open head into it,
run the full verification command, and put each cross-PR resolution into a PR
branch (not only the test branch) so the merge order stays valid. Say what was left
out and why.

---

## QA and delivery process

The `qa-pass` skill is the procedure. These are the incidents that shaped it.

### Every PR was green and the product was still wrong

About forty PRs were open, each passing the full verification command, and the
combined test branch passed too. A strict, independent QA pass over that branch
found 126 defects: a closing balance that did not carry forward, a delete that left
the reports returning errors, financial-year windows that disagreed between two
accounts of one company, a retried upload that could return another company's job.
None was a cross-tenant leak, which was checked on every id-taking endpoint, but
several were wrong money.

**Rule:** QA is a lifecycle stage with its own gate, run by testers who are told to
find defects and never to fix them, before any batch reaches staging or production.
A passing verify command proves the checks that exist, not the product.

### A background task said "exit code 0" over a failed run

A long verification ran as a background command. The harness reported it completed
with exit code 0; the log's own last line said `EXIT 1`. On the first attempt the
branch was pushed before the log was read.

**Rule:** the result of a gate is the `EXIT` line the command wrote to its own log,
read before anything is pushed or handed over. A task wrapper's exit code is not
evidence.

### The fix only worked in the combination

A test failed only on the combined branch, because it asserted a rule that another
branch had changed. Fixing it on the combined branch alone would have left the
original PR red, or silently wrong, once merged by itself.

**Rule:** a fix found while integrating goes back on the branch that owns the code,
and that branch is pushed. Every PR must pass alone; the combined branch is where
interactions are found, not where they are repaired.

### A brief assumed a screen that did not exist

A follow-up asked for a notice on the screen where an owner corrects a confirmed
payment. The server side of that correction existed; no screen called it. The agent
checked the premise, stopped, built nothing, and reported. Had it pressed on, the
task would have become a new feature disguised as a small notice.

**Rule:** every fix brief starts with a premise check, and says to stop and report
when the premise is false. Confirm the premise yourself before sending the brief
when it is cheap to do so.

### One agent popped another agent's stash

Parallel agents each had a worktree. The stash list belongs to the repository, not
the worktree, so one agent's `git stash pop` applied another agent's stash, and
conflicted in a file it had never touched. Both recovered, but only because neither
had dropped the other's entry.

**Rule:** agents do not use `git stash`. Use a throwaway branch or a commit, which
are per-worktree in effect.

### Flaky tests fixed by waiting longer

Several tests failed only when many suites ran at once. The tempting fix is a retry
or a longer timeout. Measuring instead found two real causes: a role-based query
computing the accessible name of every element, about ten times slower under load
(a 25-card page took 6 to 12 seconds), and the first render paying a cold-start cost
inside a one-second wait. Each was fixed at its cause, with the same assertions.
Two other fixes could not be made to fail on demand; their PRs said so and gave the
probe that showed the race instead.

**Rule:** fix a flaky test at its root cause with a measurement. No retries, no
longer timeouts, no weaker assertions. Say what was measured and what was inferred.

### A dev server stood in for a production build

A feature downloaded every page's code in the background so an unvisited page would
open offline. The smoke test could not prove it: the dev server imports a module as
`file?import` while the preload fetched `file`, so the browser treats them as
different files. It only worked, and was only provable, on a production build.

**Rule:** anything that depends on how assets are named, cached or preloaded is
verified once on a production build, and the PR says what was run and what was not.
Narrow the automated test to what the dev server can show rather than leaving it
asserting something it cannot reach.

### Real client text in test data

A parser fix copied street names and house numbers from real certificates into its
tests. It was caught before a PR existed, and replaced with invented values.

**Rule:** the repository, including tests, commit messages and PR bodies, holds
invented data only. Real samples are used locally, never committed, and appear only
in the private report to the owner, and then only the fields needed to judge the fix.

### Decisions scattered across a long chat

Twelve decisions and nine questions came out of one QA pass. Spread over messages
they would have been answered piecemeal, some missed. They went on one page, each
with options, a recommendation and the cost, and one pasted answer settled most.
One answer rested on a misunderstanding of what a change would switch on, which only
surfaced because the page forced the question to be asked plainly.

**Rule:** every owner decision goes on one page, recommendation first. When an answer
rests on a misunderstanding, correct it with facts and ask again.

### A PR opened as a draft by habit

A change that needs a migration before merge was opened as a draft, although the
owner's practice is to open it ready and say plainly in the body that it must not be
merged yet. The draft status told the owner nothing and made it look unfinished.

**Rule:** a PR is a draft only while a decision about it is open, and its body names
the decision. Anything else is ready for review, with merge conditions stated in the
first line.

---

## Front-end and UX

Sources for the rules below: the WeWeb front-end design guide and Smart Interface
Design Patterns on loading and progress UX. Both are linked from
`claude/skills/frontend-ux/SKILL.md`.

### A toggle that loaded one side at a time

A screen toggled between money in and money out. Only the active side was fetched,
sequentially, because each request was an expensive read on the server; switching
emptied the list and refetched, and every tab switch remounted the table and
refetched again. The owner found the toggle slow and asked why both sides were not
loaded together.

**Rule:** data that a toggle, tab or filter switches between is loaded together and
the switch makes zero requests and shows no empty state. Keep a cache that survives
remounts (stale while revalidate, keyed by record and version, cleared on sign-out),
invalidate after every write, run independent requests in parallel, and apply the
user's action optimistically with a visible rollback. A server cost that justified
one-at-a-time loading is a reason to fix the server, not to make the user wait.

### Loading states designed last

First loads showed the word "Loading" or a blank area, with no skeleton and no
progress for the multi-second loads, and no rule for when to show anything.

**Rule:** choose the indicator by expected wait. Under about one second, none. One
to three seconds, a skeleton that matches the real layout. Three to ten, a
determinate bar. Ten or more, progress, a percentage and a status line, and let the
user keep working. Delay a skeleton about 350 ms and keep it about 400 ms once
shown so it neither flashes nor flickers. Never stack spinners. Design the loading,
empty, error, success and partial states with the ideal one.

### One accent colour doing two jobs

The same orange marked the primary action, the selected tab, progress bars, links
and the active menu item. Twelve to twenty-six pale "OK" buttons competed with a
selected toggle on one screen, and the next step on the case screen was one of
four equal buttons.

**Rule:** one primary action per screen, and a selected state must not look like
the primary action. Show where the user is and what comes next; say each fact once.

### Dialogs without a way out

All fourteen dialog states had no close icon, two closed without returning focus,
and one did not close on Escape.

**Rule:** every dialog has a visible close control, Escape, and returns focus to the
element that opened it. A dialog that must not be dismissed says so in its copy.

### A browser test outside the one command

The browser smoke test ran only as its own CI workflow. Three PRs in one day
passed the full local command and then failed it in CI on a locator that no longer
matched the text. The local command was supposed to match CI.

**Rule:** when a check is cheap enough to run locally (about 40 seconds here), it
belongs in the one verification command. Keep CI's split into jobs if the browser
needs its own runtime, but name the halves so that together they are exactly the
local command.

---

## Configuration

### The agent settings file had become a security dossier

A machine-level settings file had accumulated a description of the whole
organization's infrastructure: cloud account number, every cluster and service name,
which secrets were stored properly and which were sitting in plaintext, and a
teammate's real name. Genuinely useful to a session. Catastrophic in a repository.

**Rule:** `settings.json.template` ships with **no** environment-context key at all,
and it was authored from scratch rather than copied and scrubbed. Scrubbing invites
a later diff that silently restores it. Author that content per-machine; never
commit it anywhere.

Same reasoning for a local-permissions file: it names real infrastructure in its
grant rules and is never templated.

### Project ids inside a user-level skill

A shared, machine-wide skill carried hard-coded tracker and API-collection ids for
one project. Wrong for every other repository on the machine, and awkward to share.

**Rule:** user-level skills carry method; projects carry their own ids in a
project-local config. `claude/skills/pre-pr/pre-pr.config.example.json`.

### A version manager that cannot persist across tool calls

Tool calls run without a shell profile and do not persist environment between calls,
so `nvs use` / `nvm use` silently does not stick. The only thing that crosses that
boundary is injected context.

**Rule:** `node-version-context.ps1` resolves the pinned version's bin directory at
session start and injects the path, rather than trying to mutate a `PATH` that will
not survive.

---

### An advisor model and three workers, set up on trust

Setup: a Sonnet main session at `high` effort, a stronger model on call through
`advisorModel`, and three subagents (`explorer` reads, `worker` edits and runs
tests, `researcher` looks things up) on Sonnet at `medium` effort. The idea is
that the expensive model weighs in only at the moments that change the outcome:
before a plan, when an error repeats, before "done".

What the source machine learned setting it up:

- **The advisor rule is soft.** It is a paragraph in CLAUDE.md; nothing forces
  the call. The first session after setup skipped it on cases that plainly fit.
  Count `"name":"advisor"` in the session transcripts after a week and keep,
  tighten or drop it on that number, not on how sensible it sounds.
- **Overlapping readers.** The built-in `Explore`, a plugin's haiku locator and
  `explorer` all answer "where is X". Left unranked, routing is inconsistent.
  The CLAUDE.md names one per question shape.
- **A plugin editor agent is not a worker.** One had no Bash, so it could not run
  tests, and no `effort` field, so it inherited the session's `high`. Not
  interchangeable with an implementer that verifies.
- **Effort has two layers.** `effortLevel` is only the default for models with no
  saved per-model level. `/effort` writes a `modelSettings` entry keyed by the
  *pinned* model id, and that entry wins. The template deliberately omits it: it
  names a version, and aliases are the rule.
- **Restore gap.** `bootstrap.ps1` copied settings, hooks and skills but not
  agents, so a restore would have come up without the workers and reported
  success. Agents are now part of `-InstallUserConfig`.

## Ignore policy

The source repository ignores `*.md` (except `README.md`) and the whole agent config
directory. This is a real choice with real costs and it is **not** a default.

It fits one engineer on one machine who moves work by copying the directory, and who
wants a reader of the repository to see the code and whether it ships, rather than
how one person's environment is wired.

It is wrong for a team. Shared conventions, plans and decision records belong where
everyone can review and amend them, and an ignored `docs/` means the only copy lives
on a laptop. Two practical consequences, both easy to miss: `*.md` also hides README
files in subdirectories, and anything ignored is invisible to code review by
construction — which is the point and also the risk.

`templates/gitignore.template` carries this reasoning inline, so the choice is made
knowingly rather than inherited.

---

## Plugins

Audited by one question: **what breaks if this is removed?** An unanswerable
question is the answer — it means nothing depends on it and nobody would notice.

Thirteen entries on the source machine, ten enabled. The useful finding was not
which to drop; it was that **two plugins were load-bearing for configuration
outside themselves**, which nothing in the plugin list tells you:

- The secret-scanning plugin's cache directory holds two hook scripts that the
  machine's `settings.json` points at by absolute path. Disabling the plugin
  silently breaks two configured hooks.
- An output-style plugin's cache directory holds the `statusLine` command, path
  including a content hash. Disabling it breaks the status line.

**Rule:** before removing a plugin, grep `settings.json` for its cache path. A
plugin is not only the skills it advertises; anything can point into its
directory, and the reference does not survive the uninstall.

Beyond that the audit sorted into three groups.

*Load-bearing, keep:* the ones providing MCP tools for services the project
actually uses (auth, database, deploy), document generation that produced real
deliverables, and the process-skill collection that injects a session-start
discipline.

*Style, keep but understand:* always-on output modifiers change how an agent
writes and what it chooses to build. Nothing breaks without them, which makes
them easy to mistake for dead weight — they are preference, not decoration, and
should be a deliberate keep rather than an accidental one.

*Removal candidates, all failing the question:* a single-skill plugin whose skill
is never invoked; a web-guidance plugin whose main content is browser-extension
skills for a project with no browser extension; and a 37-skill engineering
collection that overlaps the process-skill collection almost entirely (code
review, debugging, implementation). Overlapping collections are the worst case,
because whichever loads second silently shadows the other and you cannot tell
which guidance you actually got.

A plugin that was already disabled is a finding too: one had been turned off
because it shipped a browser-automation server that collided with a
manually-configured one pointed at the browser this machine actually has. That
is the collision recorded above, and the disabled entry is the fix — worth a
comment so nobody re-enables it.

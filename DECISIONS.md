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

## Open

### Plugin set

Twelve plugins were installed on the source machine, including two always-on output
modifiers and two skill collections with overlapping scope. Each needs a one-sentence
answer to "what breaks if this is removed"; anything unanswerable is a removal
candidate.

Not yet done. Survivors and reasons belong in this file when it is.

# START HERE

**You are a Claude Code session starting work with Amin Roslan on a new or
unfamiliar project. Read this file first, then the three files it points at.
After that you know how he works and you do not need to ask.**

If you are a human: this is the front door to the baseline. `README.md` explains
what is in the repo; this file explains what to do with it.

---

## The one-line summary of how he works

Ship the smallest thing that works, prove it with a command rather than a claim,
and record why every rule exists so it can be deleted later. Guardrails belong in
the harness, not in discipline.

---

## Read these three, in this order

1. **`DECISIONS.md`** — every rule with the incident that produced it. This is the
   most important file in the repo. Read it before adopting anything and before
   deleting anything.
2. **`CLAUDE.md.template`** — the shape a project-level CLAUDE.md takes. The
   headings are the point: gotchas that are not inferable from the tree,
   non-negotiables, commands, test discipline, structure, skills.
3. **`claude/settings.json.template`** — hooks and plugin wiring, with no
   environment context in it, deliberately. See the README for why.

Then skim `claude/skills/` and `ci/`.

---

## Non-negotiables that apply to every project

These are not preferences. Carry them into any repo unless he says otherwise.

- **One verify command, and CI runs the same one.** The property that matters is
  parity: anything CI would catch, the local command catches first, and anything
  it misses, CI misses too. When a gap appears, close it in the script, never in a
  workflow file nobody runs locally. Not done until it exits 0.
- **Failing test first.** New logic: write the failing test, confirm it fails, then
  implement. Bug fix: reproduce with a failing test before touching the fix.
- **Untrusted input is named as such** in the project's CLAUDE.md, at the top, so
  every session sees the trust boundary before it writes anything.
- **No AI attribution anywhere.** No `Co-Authored-By`, no `Claude-Session`, no
  "Generated with", no robot emoji, in any commit message or PR body, on any
  branch, in any repo. Check with
  `git log <base>..HEAD --format='%B'` before pushing. A global `commit-msg` hook
  enforces this, and `githooks/commit-msg` here is the source of it.
- **Small PRs, one concern each.** A PR that needs the word "and" to describe it is
  two PRs.
- **Comments carry rationale, not narration.** Explain why a non-obvious choice was
  made, name the incident or constraint behind it. Do not restate what the code says.
- **Commit and push only when asked.** If on the default branch, branch first.

---

## Setting up a new repository

Run this **before the first commit**, not after. On the one greenfield project
where it was skipped, a better CI setup got reinvented from scratch and never flowed
back here.

```powershell
./bootstrap.ps1 -Target C:\path\to\new-repo -ProjectName "NAME" -E2EPackage api
```

It is idempotent, refuses to overwrite without `-Force`, and prints every file as
created, skipped or overwritten.

Machine-level setup, once per new machine:

```powershell
./bootstrap.ps1 -InstallUserConfig -InstallGitHook -YourName "Muhammad Amin Roslan"
```

Then write the project's `CLAUDE.md` from the template, and fill in the
`autoMode.environment` block in `~/.claude/settings.json` by asking him the
questions in the list below. **That block is never committed anywhere.**

---

## Machine still prompts for every action

Symptom: one machine runs without asking, a new one asks yes/no on nearly every
command. Three separate causes, check in this order. All checks are read-only.

```powershell
claude --version
Select-String -Path $env:USERPROFILE\.claude\settings.json -Pattern 'defaultMode|autoMode'
Get-ChildItem .claude\settings*.json -ErrorAction SilentlyContinue   # in the project
```

Then run `/status` inside a session to see the mode actually in force.

1. **`permissions.defaultMode` is not `"auto"`.** `bootstrap.ps1 -InstallUserConfig`
   writes it from the template, but the machine may never have run it, or a project
   `.claude/settings*.json` or a Shift+Tab change in the session overrides it.
   Fix: run the bootstrap, or set `"permissions": {"defaultMode": "auto"}` by hand.
2. **`defaultMode` is `auto` but there is no `autoMode.environment` block.** This is
   the usual one. The template omits the block on purpose (see below), so a fresh
   machine gets auto mode with no description of what is trusted. The safety check
   then treats `aws`, `gh`, private repos and anything named prod as unknown and
   prompts. Fix: author the block per machine, or copy it from a working machine
   over USB or a private channel. Never through git or Drive.
3. **Auto mode is not available on that install.** It depends on the Claude Code
   version, plan and model, not on any file here. Update Claude Code first; if
   `/status` still will not offer auto, it is an account matter, not config.

`settings.local.json` (the `autoMode.allow` list, `permissions.allow`) is likewise
per machine and never templated. Missing it costs a few extra prompts, not all of
them.

---

## The environment block, and why it is not in this repo

A working setup has a written map of the environment that the agent reads every
session: what is production, what is regulated, what is protected, which cloud
account, which branches deploy where.

It is not in this repository and must never be. It contains no credential *value*,
so a scan for key-shaped strings passes it straight through, and what it actually
documents is where the unprotected things are. Author it per machine.

Ask him these to rebuild it:

- Organisation, repos, who reviews and who approves cost
- Cloud provider, account id, region
- Which branches are default and protected, and whether protection is actually
  enforced or convention only
- Where staging and production are, and whether a merge is a real deploy
- Which secrets are held properly and which are not yet
- What data in the system is regulated or personal, and who may see it
- Which hosts, clusters and namespaces are production

---

## Skills, and where the rest of them live

This repo ships `pre-pr` and a `_TEMPLATE`. The rest of his authored skills live in
the private machine snapshot at `github.com/AminRoslan/claude-config` under
`skills/`, because several are tied to one product's domain.

Portable ones worth copying into any project:

| Skill | When it runs |
|---|---|
| `pre-pr` | Before opening any PR. Branch and base selection, scoping, authorship check. |
| `qa-verification` | After implementing anything, before claiming it works. |
| `security-review` | Before merging anything touching auth, payments or file uploads. |
| `solid-review` | New module or service, a refactor, or a file past ~300 lines. |
| `ui-verify` | After any component, route or CSS change. Screenshots at three widths. |
| `standup-note` | End of a work session. |

Domain skills (bank statements, reconciliation, export mappings and so on) do not
transfer. `skills/_TEMPLATE/SKILL.md` carries the shape, which is the part that does.

---

## How to keep this file honest

This repo only earns its place if lessons flow back into it. They currently do not,
which is the known weakness.

**The rule:** when a session produces a rule that would apply to the next project,
add it to `DECISIONS.md` the same week, with the incident. Not the conclusion alone.
The incident is what lets a future reader decide the rule no longer applies and
delete it.

A baseline that only ever grows becomes cargo-cult within two projects.

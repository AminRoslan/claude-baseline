# claude-baseline

What a working Claude Code setup looks like once the mistakes have already been
made. Extracted from a real monorepo rather than designed up front, so every rule
here has an incident behind it — recorded in [`DECISIONS.md`](DECISIONS.md).

Read `DECISIONS.md` before deleting anything. Read it before keeping anything, too:
a rule whose incident cannot happen in your project is dead weight, and the point of
recording the reasoning is to make the baseline **prunable** rather than
cargo-cult.

**Starting a new project, or an agent session on an unfamiliar one?** Read
[`START-HERE.md`](START-HERE.md) first. It is the front door: what to read, in what
order, and the non-negotiables that apply everywhere.

## What is here

```
START-HERE.md              front door: read order, non-negotiables, new-repo setup
CLAUDE.md.template         project-level CLAUDE.md, structure with placeholders
claude/
  CLAUDE.md.template       user-level ~/.claude/CLAUDE.md
  settings.json.template   shareable settings — deliberately no environment context
  hooks/                   four PowerShell hooks, all fail-open (see hooks/README.md)
  skills/
    _TEMPLATE/             the shape a domain skill takes
    pre-pr/                pre-PR checklist, ids kept in a project-local config
githooks/
  commit-msg               attribution gate, installed globally
ci/
  ci.yml.template          pnpm + turbo + build, lint, typecheck, unit, e2e
  deploy-staging.yml.template   deploy gated on the same suite
templates/
  gitignore.template       including the ignore policy, with its costs stated
bootstrap.ps1              scaffolds from the above
DECISIONS.md               why each piece exists
```

## Bootstrap

Requires PowerShell 7.

```powershell
# Scaffold a new repository
./bootstrap.ps1 -Target C:\work\my-new-repo -ProjectName "MY-APP" -E2EPackage api

# ...and a staging deploy workflow (a shape, not a drop-in — expect to rewrite
# the deploy steps; five AWS placeholders are left unfilled on purpose)
./bootstrap.ps1 -Target C:\work\my-new-repo -ProjectName "MY-APP" -IncludeDeploy

# Machine-level, affects every repo on the machine. Not the default.
./bootstrap.ps1 -InstallUserConfig -InstallGitHook -YourName "Your Name"
```

It is idempotent and refuses to overwrite anything without `-Force`. Every run
prints each file as created, skipped or overwritten, with a count. A second run
with no `-Force` is a no-op that tells you exactly what it left alone.

## Three things worth knowing before adopting any of it

**The ignore policy is a choice, not a default.** `*.md` and the agent config
directory are ignored in the source repo. That suits one engineer on one machine.
It is wrong for a team, for the reasons written into the template itself. Decide;
do not inherit.

**`settings.json.template` has no environment-context key, on purpose.** On the
machine this came from, that key had grown into a written map of the organization's
infrastructure — cloud account number, every service name, which secrets were sitting
in plaintext. Useful to a session, catastrophic in a repository. The template was
written from scratch rather than copied and scrubbed, because scrubbing invites a
later diff that quietly restores it. Author that content per-machine and leave it
out of version control.

**Enforcement lives outside the repository.** The attribution gate installs as a
global `commit-msg` hook, not a committed hooks directory. It covers repos that do
not exist yet, and an in-repo artefact policing AI attribution would advertise the
thing it exists to keep out of sight. A global `core.hooksPath` replaces per-repo
hooks everywhere on the machine, and `--no-verify` bypasses it. Both limits are
accepted, not worked around.

## What is deliberately absent

- **The secret-scanning hooks.** Six lines each, piping stdin into a plugin's CLI.
  Install the plugin and take its wiring rather than vendoring a copy that drifts.
- **Domain skills.** The source repo's were tightly bound to its business rules.
  `skills/_TEMPLATE/` carries their shape, which is the part that transfers.
- **Machine-specific workarounds.** One machine's Application Control policy,
  toolchain paths and pinned versions. `DECISIONS.md` keeps the general lesson —
  never fix a blocked native binary by re-downloading it — without the paths that
  would be wrong anywhere else.
- **Anything that names a real project, account, host or person.**

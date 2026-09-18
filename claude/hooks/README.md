# Hooks

Three hooks, all PowerShell, all fail-open. A hook that wedges a session gets
disabled within a day and then protects nothing, so every one of these exits 0
on any unexpected error and only ever blocks on the specific condition it is
written for.

| Hook | Event | What it does |
|---|---|---|
| `node-version-context.ps1` | SessionStart | Reads `.nvmrc` / `.node-version`, resolves the bin directory, and injects it as context |
| `block-main-push.ps1` | PreToolUse (Bash/PowerShell) | Hard-blocks `git push` that targets `main`/`master` |
| `require-ui-verify.ps1` | Stop | Blocks "done" on a frontend change that was never looked at |

## node-version-context.ps1

Tool calls run `-NoProfile` and do not persist environment between calls, so
`nvs use` (or `fnm use`, or `nvm use`) cannot stick across commands. The only
thing that crosses that boundary is injected context, so the hook resolves the
path and tells the session to prepend it per-command.

Assumes `nvs`. For a different version manager, change the one `nvs which` call.
No-ops silently when no version file is found or the manager is absent, so it is
safe to install unconditionally.

## block-main-push.ps1

With `permissions.defaultMode: "auto"` there are no prompts, so this is the only
real gate against an accidental direct push to a production branch. It catches
both the explicit form (`git push origin main`) and the bare form (`git push`
while `main` is checked out).

It does not know about your branch protection, and deliberately does not care —
protection on a free GitHub plan is unenforceable, and this hook is what fills
that gap locally.

## require-ui-verify.ps1

Fires only when the working tree has uncommitted frontend changes AND no
verification marker newer than the newest of them. The marker is written by
whatever visual-check process you use:

```powershell
[int][math]::Floor(([datetime]::UtcNow - [datetime]'1970-01-01').TotalSeconds) > "$env:USERPROFILE\.claude\.ui-verified"
```

Editing again invalidates the marker, which is the point.

**Configure the `$roots` table at the top** — one entry per repo with a
frontend, mapping repo directory name to frontend path. Ships empty, which makes
the hook a no-op. That is correct for a machine doing no frontend work; it is
not a failure state.

## Not included: the secret-scanning hooks

The machine this was extracted from also ran two PreToolUse/UserPromptSubmit
hooks for secret scanning. They are not here because they are not code worth
carrying — each is six lines piping stdin into `sonar hook ...`, and they come
from installing the `sonarqube` plugin. Install the plugin and take its wiring;
do not vendor a copy that will drift from whatever the plugin expects next.

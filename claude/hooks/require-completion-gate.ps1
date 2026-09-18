# Stop hook: block "done" while lint or typecheck is failing.
#
# The completion rule ("not done until build, lint, typecheck and tests pass")
# is prose in a CLAUDE.md with nothing behind it. This puts something behind the
# two halves that are cheap enough to run every turn.
#
# WHAT IT DOES NOT COVER, on purpose: build and the test suites. Running all
# four adds roughly 45 seconds to every turn that touched code, and a hook that
# slow gets disabled inside a week — at which point it protects nothing. Those
# two belong to CI, which is a defensible split only because CI actually blocks:
# it runs on pull requests and on pushes to the trunk, and the staging deploy
# depends on it. If that stops being true, revisit this.
#
# Fires only when BOTH are true:
#   - the working tree has uncommitted changes to source files
#   - the repo actually defines lint:verify and typecheck scripts
#
# Honours stop_hook_active so a block can never loop.
# Any unexpected error fails OPEN (exit 0) rather than wedging the session.
#
# CONFIGURE ME: $SourcePattern and $Scripts below.

$ErrorActionPreference = 'Stop'

$SourcePattern = '\.(ts|tsx|js|jsx|mts|cts|mjs|cjs|vue|svelte)$'
$Scripts = @('lint:verify', 'typecheck')

try {
    $stdin = [Console]::In.ReadToEnd()
    try { $payload = $stdin | ConvertFrom-Json } catch { exit 0 }

    if ($payload.stop_hook_active -eq $true) { exit 0 }

    $cwd = if ($payload.cwd) { $payload.cwd } else { (Get-Location).Path }
    if (-not (Test-Path $cwd)) { exit 0 }

    Push-Location $cwd
    try {
        $repoRoot = & git rev-parse --show-toplevel 2>$null
        if (-not $repoRoot) { exit 0 }

        # Nothing uncommitted means nothing this turn produced needs checking.
        # Committed work already passed through whatever gate ran before it.
        $changed = & git status --porcelain 2>$null |
            ForEach-Object { ($_ -replace '^.{3}', '').Trim('"') } |
            Where-Object { $_ -match $SourcePattern }
        if (-not $changed) { exit 0 }

        $packageJsonPath = Join-Path $repoRoot 'package.json'
        if (-not (Test-Path $packageJsonPath)) { exit 0 }
        $packageJson = Get-Content $packageJsonPath -Raw | ConvertFrom-Json
        $available = $Scripts | Where-Object { $packageJson.scripts.$_ }
        if (-not $available) { exit 0 }

        # pnpm is nvs-managed and not on PATH, and a -NoProfile tool process
        # inherits no shell profile to put it there. Resolve it next to the
        # node binary nvs reports, and give up quietly if that fails — an
        # unresolvable package manager is an environment problem, not a reason
        # to block someone's turn.
        $nodeExe = $null
        try { $nodeExe = (& nvs which 2>$null | Select-Object -Last 1) } catch { $nodeExe = $null }
        if (-not $nodeExe -or -not (Test-Path $nodeExe)) { exit 0 }
        $pnpm = Join-Path (Split-Path $nodeExe -Parent) 'pnpm.cmd'
        if (-not (Test-Path $pnpm)) { exit 0 }

        $failures = @()
        foreach ($script in $available) {
            $output = & $pnpm run $script 2>&1
            if ($LASTEXITCODE -ne 0) {
                # Last 25 lines: enough for the actual diagnostic, short enough
                # that the message stays readable. The agent can re-run the
                # command itself for the rest.
                $tail = ($output | Select-Object -Last 25) -join "`n"
                $failures += "--- pnpm run $script (exit $LASTEXITCODE) ---`n$tail"
            }
        }

        if ($failures.Count -gt 0) {
            [Console]::Error.WriteLine(
                "The completion gate is failing. CLAUDE.md says work is not done until " +
                "these pass locally, and they do not:`n`n" + ($failures -join "`n`n") +
                "`n`nFix these, then stop again. If a failure is pre-existing and " +
                "unrelated to this change, say so explicitly and stop again."
            )
            exit 2
        }
        exit 0
    }
    finally { Pop-Location }
}
catch {
    # Never wedge a session over a broken check.
    exit 0
}

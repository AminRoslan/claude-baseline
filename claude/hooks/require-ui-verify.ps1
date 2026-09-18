# Stop hook: block "done" on an unverified frontend change.
#
# Fires only when BOTH are true:
#   - the working tree has uncommitted changes under a known frontend path
#   - no ui-verify marker exists that is newer than the newest such change
#
# Honours stop_hook_active so a block can never loop.
# Any unexpected error fails OPEN (exit 0) rather than wedging the session.
#
# CONFIGURE ME: the $roots table below is the only project-specific part.
# One entry per repository that has a frontend, mapping the repo directory
# name to the path its frontend lives under. An empty table makes this hook a
# no-op, which is the correct behaviour for a machine with no frontend work —
# it is not a failure and needs no other change.

$ErrorActionPreference = 'Stop'

$MarkerPath = Join-Path $env:USERPROFILE '.claude\.ui-verified'

try {
    $stdin = [Console]::In.ReadToEnd()
    try { $payload = $stdin | ConvertFrom-Json } catch { exit 0 }

    if ($payload.stop_hook_active -eq $true) { exit 0 }

    $cwd = if ($payload.cwd) { $payload.cwd } else { (Get-Location).Path }
    $norm = $cwd -replace '\\', '/'

    $roots = @(
        # @{ Repo = 'my-monorepo';  Path = 'apps/web' },
        # @{ Repo = 'my-webapp';    Path = 'app' }
    )
    if (-not $roots) { exit 0 }
    $repo = $roots | Where-Object { $norm -match "/$($_.Repo)(/|`$)" } | Select-Object -First 1
    if (-not $repo) { exit 0 }

    Push-Location $cwd
    try {
        $repoRoot = & git rev-parse --show-toplevel 2>$null
        if (-not $repoRoot) { exit 0 }

        $changed = & git status --porcelain -- $repo.Path 2>$null |
            ForEach-Object { ($_ -replace '^.{3}', '').Trim('"') } |
            Where-Object { $_ -match '\.(tsx|jsx|ts|js|css)$' }

        if (-not $changed) { exit 0 }

        $newest = 0
        foreach ($f in $changed) {
            $full = Join-Path $repoRoot $f
            if (Test-Path $full) {
                $secs = [int][math]::Floor(
                    ((Get-Item $full).LastWriteTimeUtc - [datetime]'1970-01-01').TotalSeconds)
                if ($secs -gt $newest) { $newest = $secs }
            }
        }
        if ($newest -eq 0) { exit 0 }

        if (Test-Path $MarkerPath) {
            $stamp = 0
            if ([int]::TryParse((Get-Content $MarkerPath -Raw).Trim(), [ref]$stamp)) {
                if ($stamp -ge $newest) { exit 0 }
            }
        }

        $list = ($changed | Select-Object -First 6) -join ', '
        [Console]::Error.WriteLine(
            "Frontend files changed but not visually verified: $list. " +
            "Run the ui-verify skill - screenshot the affected pages at 375, 768 and 1440, " +
            "read the images, fix what you find, then record it with: " +
            "[int][math]::Floor(([datetime]::UtcNow - [datetime]'1970-01-01').TotalSeconds) > `"$MarkerPath`". " +
            "If this change genuinely has no visual effect, say so explicitly and stop again."
        )
        exit 2
    }
    finally { Pop-Location }
}
catch {
    # Never wedge a session over a broken check.
    exit 0
}

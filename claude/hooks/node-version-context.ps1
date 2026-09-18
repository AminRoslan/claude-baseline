# SessionStart hook: surface the repo's pinned Node version + resolved nvs bin dir.
# Why this exists, not a PATH-mutating hook: Bash/PowerShell tool calls run with
# -NoProfile and don't persist env between calls, so `nvs use` can't stick across
# commands. The only thing that actually crosses that boundary is injected context.

$stdin = [Console]::In.ReadToEnd()
try { $payload = $stdin | ConvertFrom-Json } catch { $payload = $null }
$cwd = if ($payload -and $payload.cwd) { $payload.cwd } else { (Get-Location).Path }

$dir = $cwd
$versionFile = $null
while ($dir) {
    foreach ($name in @(".nvmrc", ".node-version")) {
        $candidate = Join-Path $dir $name
        if (Test-Path $candidate -PathType Leaf) { $versionFile = $candidate; break }
    }
    if ($versionFile) { break }
    $parent = Split-Path $dir -Parent
    if (-not $parent -or $parent -eq $dir) { break }
    $dir = $parent
}

if (-not $versionFile) { exit 0 }

$version = (Get-Content $versionFile -Raw).Trim()
if (-not $version) { exit 0 }

$nodeExe = $null
try {
    $nodeExe = (& nvs which $version 2>$null | Select-Object -Last 1)
    if ($nodeExe) { $nodeExe = $nodeExe.ToString().Trim() }
} catch { $nodeExe = $null }

if (-not $nodeExe -or -not (Test-Path $nodeExe)) { exit 0 }
$binDir = Split-Path $nodeExe -Parent
$fileName = Split-Path $versionFile -Leaf

$msg = "This repo pins Node $version via $fileName. Resolved bin dir: $binDir`n" +
       "Bash/PowerShell tool calls do NOT inherit a shell profile or persist env across calls " +
       "(each call is a fresh -NoProfile process) -- `nvs use` will silently not stick. " +
       "Prepend the resolved bin dir to PATH in every command that runs node/npm/pnpm/bun in this repo, e.g. " +
       "PowerShell: `$env:PATH = '${binDir};' + `$env:PATH ; then your command  |  Bash: PATH=`"${binDir}:`$PATH`" your-command"

$out = @{
    hookSpecificOutput = @{
        hookEventName      = "SessionStart"
        additionalContext  = $msg
    }
} | ConvertTo-Json -Depth 5 -Compress

Write-Output $out
exit 0

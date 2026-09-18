# PreToolUse hook: hard-block `git push` that targets main/master.
# settings.json runs in defaultMode "auto" (no permission prompts), so this is the
# only actual gate against an accidental direct push to main/master.

$stdin = [Console]::In.ReadToEnd()
try { $payload = $stdin | ConvertFrom-Json } catch { exit 0 }
$cmd = $payload.tool_input.command
if (-not $cmd) { exit 0 }
if ($cmd -notmatch 'git\s+push') { exit 0 }

$blocked = $false
$branch = $null

if ($cmd -match 'push[^|;&]*\b(main|master)\b') {
    $blocked = $true
    $branch = $Matches[1]
} elseif ($cmd -match 'git\s+push(\s+--[\w-]+)*(\s+\S+)?\s*(--[\w-]+)?\s*$') {
    # bare `git push` / `git push origin` with no explicit ref -> check current branch
    try { $current = (& git rev-parse --abbrev-ref HEAD 2>$null) } catch { $current = $null }
    if ($current -and $current.Trim() -in @('main', 'master')) {
        $blocked = $true
        $branch = $current.Trim()
    }
}

if ($blocked) {
    [Console]::Error.WriteLine("Blocked: this pushes to '$branch' directly. Confirm explicitly with the user before pushing to main/master, then re-run.")
    exit 2
}

exit 0

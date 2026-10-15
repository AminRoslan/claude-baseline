# Fails on agent frontmatter that is not valid YAML in the one way that keeps happening:
# an unquoted value containing ": " (or starting with a YAML indicator). Claude Code on one
# machine tolerated it, another rejected the agent, so quote every description.
#   pwsh check-agents.ps1 <dir-or-file> [<dir-or-file> ...]
param([Parameter(Mandatory, ValueFromRemainingArguments)][string[]]$Path)
$bad = 0
$files = foreach ($p in $Path) {
  if (Test-Path $p -PathType Container) { Get-ChildItem $p -Recurse -Filter *.md } else { Get-Item $p }
}
foreach ($f in $files) {
  $t = (Get-Content $f.FullName -Raw) -replace "`r`n", "`n"
  if ($t -notmatch '(?s)^---\n(.*?)\n---') { continue }   # not an agent file
  foreach ($line in $Matches[1] -split "`n") {
    if ($line -notmatch '^([A-Za-z][\w-]*):\s+(\S.*)$') { continue }
    $v = $Matches[2]
    if ($v -match '^["''|>\[{]') { continue }              # quoted, block scalar or flow collection
    if ($v -match ': ' -or $v -match ' #' -or $v -match '^[&*!%@`]') {
      Write-Host "INVALID  $($f.FullName): $line" -ForegroundColor Red
      $bad++
    }
  }
}
if ($bad) { Write-Host "$bad unquoted value(s). Wrap the value in double quotes."; exit 1 }
Write-Host "agent frontmatter ok ($(@($files).Count) files)"

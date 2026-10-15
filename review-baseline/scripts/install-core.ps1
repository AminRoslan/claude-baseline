# Installs the review baseline at user level. Run once per machine, and again after pulling baseline updates.
#   pwsh ./review-baseline/scripts/install-core.ps1 [-Force]
# Installs: core agents -> ~/.claude/agents/reviewers/
#           skills (review-contract, review-pass, review-setup) -> ~/.claude/skills/
#           packs + review-pack.ps1 + overlay template -> ~/.claude/review-baseline/ (packs stay OFF until enabled per repo)
# Does NOT touch CLAUDE.md, settings.json or existing QA skills.

param([switch]$Force)
$ErrorActionPreference = 'Stop'
$root       = Split-Path $PSScriptRoot -Parent
$claudeHome = Join-Path $HOME '.claude'
$agentsDst  = Join-Path $claudeHome 'agents/reviewers'
$skillsDst  = Join-Path $claudeHome 'skills'
$baseDst    = Join-Path $claudeHome 'review-baseline'
$marker     = '.from-review-baseline'

New-Item -ItemType Directory -Force -Path $agentsDst, $skillsDst, $baseDst | Out-Null

& (Join-Path $PSScriptRoot 'check-agents.ps1') (Join-Path $root 'core/agents') (Join-Path $root 'packs')
if ($LASTEXITCODE) { throw 'Agent frontmatter is invalid, nothing was installed.' }

function Get-AgentName($path) { if ((Get-Content $path -Raw) -match '(?m)^name:\s*(\S+)') { $Matches[1] } else { throw "No name in $path" } }

# Agent names must be unique across ~/.claude/agents (Claude Code keys agents by name, not path).
$existing = Get-ChildItem (Join-Path $claudeHome 'agents') -Recurse -Filter *.md -ErrorAction SilentlyContinue |
  Where-Object { $_.DirectoryName -ne (Resolve-Path $agentsDst).Path } | ForEach-Object { Get-AgentName $_.FullName }

foreach ($f in Get-ChildItem (Join-Path $root 'core/agents') -Filter *.md) {
  $n = Get-AgentName $f.FullName
  if ($existing -contains $n -and -not $Force) { throw "Agent '$n' already exists elsewhere under ~/.claude/agents. Resolve it or use -Force." }
  Copy-Item $f.FullName $agentsDst -Force; Write-Host "agent   $n"
}

foreach ($d in Get-ChildItem (Join-Path $root 'core/skills') -Directory) {
  $dst = Join-Path $skillsDst $d.Name
  if ((Test-Path $dst) -and -not (Test-Path (Join-Path $dst $marker)) -and -not $Force) { throw "Skill '$($d.Name)' already exists at $dst. Resolve it or use -Force." }
  New-Item -ItemType Directory -Force -Path $dst | Out-Null
  Copy-Item (Join-Path $d.FullName '*') $dst -Recurse -Force
  New-Item -ItemType File -Force -Path (Join-Path $dst $marker) | Out-Null
  Write-Host "skill   $($d.Name)"
}

# Packs are copied to a holding area, NOT into ~/.claude/agents, so they cost nothing until a repo enables them.
$packsDst = Join-Path $baseDst 'packs'
if (Test-Path $packsDst) { Remove-Item $packsDst -Recurse -Force }
Copy-Item (Join-Path $root 'packs') $packsDst -Recurse
New-Item -ItemType Directory -Force -Path (Join-Path $baseDst 'templates') | Out-Null
Copy-Item (Join-Path $root 'templates/review-overlay.md') (Join-Path $baseDst 'templates') -Force
Copy-Item (Join-Path $root 'scripts/review-pack.ps1') $baseDst -Force
Copy-Item (Join-Path $root 'scripts/check-agents.ps1') $baseDst -Force
Write-Host "packs   $((Get-ChildItem $packsDst -Directory).Name -join ', ') (off by default)"

Write-Host "`nNext, per repo:  /review-setup   (or: pwsh ~/.claude/review-baseline/review-pack.ps1 preset <name>)"
Write-Host 'Restart Claude Code if ~/.claude/agents did not exist before.'

# Switch domain review packs on/off for the repo in the current directory.
#   pwsh ~/.claude/review-baseline/review-pack.ps1 list
#   pwsh ~/.claude/review-baseline/review-pack.ps1 enable finance payments
#   pwsh ~/.claude/review-baseline/review-pack.ps1 disable crypto
#   pwsh ~/.claude/review-baseline/review-pack.ps1 preset banking
# Enabling copies the pack's agent into <repo>/.claude/agents/review-packs/ and its routing file into
# <repo>/.claude/review-packs/. Disabling removes both. Re-enabling refreshes from the baseline.

param(
  [Parameter(Position = 0, Mandatory = $true)][ValidateSet('list', 'enable', 'disable', 'preset')][string]$Action,
  [Parameter(Position = 1, ValueFromRemainingArguments = $true)][string[]]$Names
)
$ErrorActionPreference = 'Stop'

$packsRoot = Join-Path $PSScriptRoot 'packs'
if (-not (Test-Path $packsRoot)) { throw "Packs not found at $packsRoot. Run install-core.ps1 from the baseline repo first." }

$presets = [ordered]@{
  'finance'       = @('finance', 'privacy')
  'banking'       = @('finance', 'payments', 'privacy')
  'payments'      = @('payments', 'privacy')
  'crypto'        = @('crypto', 'payments', 'privacy')
  'social'        = @('social', 'privacy')
  'ecommerce'     = @('commerce', 'payments', 'privacy')
  'saas'          = @('privacy')
  'internal-tool' = @()
}

$repo = (git rev-parse --show-toplevel 2>$null)
if (-not $repo) { $repo = (Get-Location).Path }
$claudeDir  = Join-Path $repo '.claude'
$agentsDir  = Join-Path $claudeDir 'agents/review-packs'
$routesDir  = Join-Path $claudeDir 'review-packs'
$overlay    = Join-Path $claudeDir 'review-overlay.md'
$template   = Join-Path $PSScriptRoot 'templates/review-overlay.md'

function Get-Available { Get-ChildItem $packsRoot -Directory | Select-Object -ExpandProperty Name }
function Get-Enabled   { if (Test-Path $routesDir) { Get-ChildItem $routesDir -Filter *.md | ForEach-Object { $_.BaseName } } else { @() } }

function Set-OverlayPacks {
  if (-not (Test-Path $overlay)) {
    New-Item -ItemType Directory -Force -Path $claudeDir | Out-Null
    Copy-Item $template $overlay
    Write-Host "Created $overlay from template - fill in the project facts (or run /review-setup)."
  }
  $enabled = @(Get-Enabled | Sort-Object)
  $line = if ($enabled.Count) { 'Packs: ' + ($enabled -join ', ') } else { 'Packs: <none>' }
  $text = Get-Content -Raw $overlay
  if ($text -match '(?m)^Packs:.*$') { $text = $text -replace '(?m)^Packs:.*$', $line } else { $text = $text.TrimEnd() + "`n`n$line`n" }
  Set-Content -Path $overlay -Value $text -NoNewline
}

function Enable-Pack([string]$name) {
  $dir = Join-Path $packsRoot $name
  if (-not (Test-Path $dir)) { throw "Unknown pack '$name'. Available: $((Get-Available) -join ', ')" }
  New-Item -ItemType Directory -Force -Path $agentsDir, $routesDir | Out-Null
  Copy-Item (Join-Path $dir 'pack.md') (Join-Path $routesDir "$name.md") -Force
  Get-ChildItem $dir -Filter *.md | Where-Object Name -ne 'pack.md' | ForEach-Object { Copy-Item $_.FullName $agentsDir -Force }
  Write-Host "enabled  $name"
}

function Disable-Pack([string]$name) {
  $dir   = Join-Path $packsRoot $name
  $route = Join-Path $routesDir "$name.md"
  if (Test-Path $route) { Remove-Item $route }
  if (Test-Path $dir) {
    Get-ChildItem $dir -Filter *.md | Where-Object Name -ne 'pack.md' | ForEach-Object {
      $t = Join-Path $agentsDir $_.Name; if (Test-Path $t) { Remove-Item $t }
    }
  }
  Write-Host "disabled $name"
}

switch ($Action) {
  'list' {
    $enabled = @(Get-Enabled)
    Write-Host "Repo: $repo`n`nPacks:"
    foreach ($p in Get-Available) {
      $mark = if ($enabled -contains $p) { '[on] ' } else { '[off]' }
      $desc = (Get-Content (Join-Path $packsRoot "$p/pack.md") | Where-Object { $_ -like 'Enable for:*' }) -replace '^Enable for:\s*', ''
      Write-Host ("  {0} {1,-10} {2}" -f $mark, $p, $desc)
    }
    Write-Host "`nPresets:"
    foreach ($k in $presets.Keys) { Write-Host ("  {0,-14} {1}" -f $k, ($(if ($presets[$k].Count) { $presets[$k] -join ', ' } else { '(core only)' }))) }
  }
  'enable'  { if (-not $Names) { throw 'Name at least one pack.' }; $Names | ForEach-Object { Enable-Pack $_ }; Set-OverlayPacks }
  'disable' { if (-not $Names) { throw 'Name at least one pack.' }; $Names | ForEach-Object { Disable-Pack $_ }; Set-OverlayPacks }
  'preset'  {
    if (-not $Names -or -not $presets.Contains($Names[0])) { throw "Unknown preset. Available: $($presets.Keys -join ', ')" }
    Get-Enabled | Where-Object { $presets[$Names[0]] -notcontains $_ } | ForEach-Object { Disable-Pack $_ }
    $presets[$Names[0]] | ForEach-Object { Enable-Pack $_ }
    Set-OverlayPacks
  }
}

if ($Action -ne 'list') {
  git -C $repo check-ignore -q .claude 2>$null
  if ($LASTEXITCODE -ne 0 -and (Test-Path (Join-Path $repo '.git'))) {
    Write-Warning '.claude/ is NOT gitignored in this repo - the overlay and pack agents will be committed if you add them.'
  }
  Write-Host 'Restart Claude Code if .claude/agents did not exist before this run.'
}

#requires -Version 7.0
<#
.SYNOPSIS
  Scaffold a repository (and optionally this machine) from the baseline.

.DESCRIPTION
  Idempotent. Never overwrites an existing file unless -Force is given, and
  reports every file as created, skipped or overwritten. Running it twice with
  no -Force is a no-op that prints a table of skips.

  Three independent parts, each opt-in past the first:

    (default)            repo files: .gitignore, CLAUDE.md, .github/workflows/
    -InstallUserConfig   ~/.claude: settings.json, CLAUDE.md, hooks, skills, agents
    -InstallGitHook      ~/.githooks/commit-msg + git config --global core.hooksPath

  The last two are machine-level and affect every repository on the machine.
  They are deliberately not the default.

.EXAMPLE
  ./bootstrap.ps1 -Target C:\work\my-new-repo -ProjectName "MY-APP"

.EXAMPLE
  ./bootstrap.ps1 -Target C:\work\my-new-repo -ProjectName "MY-APP" `
    -DefaultBranch develop -NodeVersion 24 -E2EPackage api -IncludeDeploy

.EXAMPLE
  ./bootstrap.ps1 -InstallUserConfig -InstallGitHook -YourName "Jane Doe"
#>
[CmdletBinding()]
param(
  # Repository to scaffold. Omit only when doing a machine-level install alone.
  [string]$Target,

  [string]$ProjectName = 'PROJECT',
  [string]$DefaultBranch = 'develop',
  [string]$ProdBranch = 'main',
  [string]$NodeVersion = '24',
  [string]$E2EPackage = 'api',
  [string]$YourName = '',

  # deploy-staging.yml.template is a shape, not a drop-in — opt in knowingly.
  [switch]$IncludeDeploy,

  [switch]$InstallUserConfig,
  [switch]$InstallGitHook,
  [switch]$Force
)

$ErrorActionPreference = 'Stop'
$BaselineRoot = $PSScriptRoot
$results = [System.Collections.Generic.List[object]]::new()

function Add-Result {
  param([string]$Path, [string]$Status, [string]$Note = '')
  $results.Add([pscustomobject]@{ Status = $Status; Path = $Path; Note = $Note })
}

# Single place that decides whether a file may be written. Every write goes
# through here, so -Force means one thing everywhere and "skipped" is never a
# silent outcome.
function Write-Scaffold {
  param(
    [Parameter(Mandatory)][string]$Destination,
    [Parameter(Mandatory)][string]$Content,
    [string]$Note = ''
  )

  if ((Test-Path $Destination) -and -not $Force) {
    Add-Result $Destination 'skipped' 'exists; -Force to overwrite'
    return
  }

  $status = if (Test-Path $Destination) { 'overwritten' } else { 'created' }

  $parent = Split-Path $Destination -Parent
  if ($parent -and -not (Test-Path $parent)) {
    New-Item -ItemType Directory -Path $parent -Force | Out-Null
  }

  # UTF8 without BOM. A BOM breaks a shell script's shebang and upsets some
  # YAML parsers, and PowerShell 5's Set-Content writes one by default.
  [System.IO.File]::WriteAllText($Destination, $Content, [System.Text.UTF8Encoding]::new($false))
  Add-Result $Destination $status $Note
}

function Expand-Tokens {
  param([Parameter(Mandatory)][string]$Text, [Parameter(Mandatory)][hashtable]$Tokens)
  foreach ($key in $Tokens.Keys) {
    $Text = $Text.Replace("{{$key}}", [string]$Tokens[$key])
  }
  return $Text
}

function Read-Template {
  param([Parameter(Mandatory)][string]$RelativePath)
  $full = Join-Path $BaselineRoot $RelativePath
  if (-not (Test-Path $full)) { throw "Template missing from the baseline: $RelativePath" }
  return [System.IO.File]::ReadAllText($full)
}

$tokens = @{
  PROJECT_NAME   = $ProjectName
  DEFAULT_BRANCH = $DefaultBranch
  PROD_BRANCH    = $ProdBranch
  STAGING_BRANCH = $DefaultBranch
  NODE_VERSION   = $NodeVersion
  E2E_PACKAGE    = $E2EPackage
  USERPROFILE    = $env:USERPROFILE
  YOUR_NAME      = if ($YourName) { $YourName } else { '<your name>' }
}

# --- Repository scaffold ------------------------------------------------------

if ($Target) {
  if (-not (Test-Path $Target)) {
    New-Item -ItemType Directory -Path $Target -Force | Out-Null
    Add-Result $Target 'created' 'target directory'
  }
  $Target = (Resolve-Path $Target).Path

  Write-Scaffold -Destination (Join-Path $Target '.gitignore') `
    -Content (Read-Template 'templates/gitignore.template') `
    -Note 'READ the policy comment before keeping the *.md rule'

  Write-Scaffold -Destination (Join-Path $Target 'CLAUDE.md') `
    -Content (Expand-Tokens (Read-Template 'CLAUDE.md.template') $tokens) `
    -Note 'placeholders to fill'

  Write-Scaffold -Destination (Join-Path $Target '.github/workflows/ci.yml') `
    -Content (Expand-Tokens (Read-Template 'ci/ci.yml.template') $tokens)

  if ($IncludeDeploy) {
    Write-Scaffold -Destination (Join-Path $Target '.github/workflows/deploy-staging.yml') `
      -Content (Expand-Tokens (Read-Template 'ci/deploy-staging.yml.template') $tokens) `
      -Note 'shape only; 5 AWS placeholders left unfilled on purpose'
  }

  Write-Scaffold -Destination (Join-Path $Target '.nvmrc') -Content "$NodeVersion`n"
}
elseif (-not ($InstallUserConfig -or $InstallGitHook)) {
  throw 'Nothing to do. Pass -Target to scaffold a repo, or -InstallUserConfig / -InstallGitHook.'
}

# --- Machine-level: ~/.claude -------------------------------------------------

if ($InstallUserConfig) {
  $claudeDir = Join-Path $env:USERPROFILE '.claude'

  Write-Scaffold -Destination (Join-Path $claudeDir 'settings.json') `
    -Content (Expand-Tokens (Read-Template 'claude/settings.json.template') $tokens) `
    -Note 'no autoMode key by design; author that per-machine'

  Write-Scaffold -Destination (Join-Path $claudeDir 'CLAUDE.md') `
    -Content (Expand-Tokens (Read-Template 'claude/CLAUDE.md.template') $tokens)

  foreach ($hook in Get-ChildItem (Join-Path $BaselineRoot 'claude/hooks') -Filter *.ps1) {
    Write-Scaffold -Destination (Join-Path $claudeDir "hooks/$($hook.Name)") `
      -Content ([System.IO.File]::ReadAllText($hook.FullName)) `
      -Note $(if ($hook.Name -eq 'require-ui-verify.ps1') { 'configure the $roots table' } else { '' })
  }

  foreach ($agent in Get-ChildItem (Join-Path $BaselineRoot 'claude/agents') -Filter *.md) {
    Write-Scaffold -Destination (Join-Path $claudeDir "agents/$($agent.Name)") `
      -Content ([System.IO.File]::ReadAllText($agent.FullName))
  }

  foreach ($file in Get-ChildItem (Join-Path $BaselineRoot 'claude/skills') -Recurse -File) {
    $relative = $file.FullName.Substring((Join-Path $BaselineRoot 'claude/skills').Length).TrimStart('\', '/')
    Write-Scaffold -Destination (Join-Path $claudeDir "skills/$relative") `
      -Content ([System.IO.File]::ReadAllText($file.FullName))
  }
}

# --- Machine-level: global commit-msg hook ------------------------------------

if ($InstallGitHook) {
  $hooksDir = Join-Path $env:USERPROFILE '.githooks'

  # LF only. Git for Windows runs hooks through sh, and a CRLF shebang line
  # fails with a "bad interpreter" error that names a path with a stray \r.
  $hookBody = (Read-Template 'githooks/commit-msg') -replace "`r`n", "`n"
  Write-Scaffold -Destination (Join-Path $hooksDir 'commit-msg') -Content $hookBody

  $existing = (& git config --global --get core.hooksPath) 2>$null
  if ($existing -and $existing -ne $hooksDir -and -not $Force) {
    Add-Result 'core.hooksPath' 'skipped' "already set to '$existing'; -Force to change"
  }
  elseif ($existing -eq $hooksDir) {
    Add-Result 'core.hooksPath' 'skipped' 'already correct'
  }
  else {
    & git config --global core.hooksPath $hooksDir
    Add-Result 'core.hooksPath' 'created' $hooksDir
    Write-Warning 'A global core.hooksPath REPLACES per-repo .git/hooks everywhere on this machine.'
  }
}

# --- Report -------------------------------------------------------------------

$results | Format-Table -AutoSize Status, Path, Note | Out-String -Width 200 | Write-Host

$created = @($results | Where-Object Status -eq 'created').Count
$over    = @($results | Where-Object Status -eq 'overwritten').Count
$skipped = @($results | Where-Object Status -eq 'skipped').Count
Write-Host "created: $created  overwritten: $over  skipped: $skipped"

if ($skipped -gt 0 -and -not $Force) {
  Write-Host 'Nothing existing was touched. Re-run with -Force to replace the skipped files.'
}

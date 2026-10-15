# review-baseline

A portable code-review team for Claude Code that works for any project, employer or domain.

- **Core** (always on, every repo): five domain-neutral, read-only reviewers.
- **Packs** (off by default): one domain reviewer each, switched on per repo by project type.
- **Overlay** (per repo): `.claude/review-overlay.md` holds the facts that change between projects, such as stack, tenancy, jurisdiction, regulations, timezone and trust-boundary paths. Nothing project- or country-specific is hard-coded in the baseline.

## Core reviewers

| Agent | Catches | Model / effort | Trigger |
|---|---|---|---|
| `correctness-reviewer` | Logic, async/concurrency and error bugs; tests that wouldn't catch a regression. Runs tests in its own worktree | sonnet / medium | Every PR |
| `security-reviewer` | AuthZ/object/tenant access, injection, uploads, SSRF, secrets, deps, data exposure | sonnet / high | Entry points, auth, input, deps, personal data |
| `data-integrity-reviewer` | Schema vs existing data, migrations, atomicity, races, idempotency, indexes, precision, time | sonnet / high | Models, queries, migrations, writing jobs |
| `ui-a11y-reviewer` | UI states, forms, accessibility, responsiveness, consistency | sonnet / low | UI changes |
| `release-reviewer` | Deploy ordering, version coexistence, rollback, config, CI, observability | sonnet / medium | Before staging/prod; infra/CI changes |

## Domain packs

| Pack | Reviewer | For | Opus at release QA |
|---|---|---|---|
| `finance` | finance-reviewer | Accounting, tax, payroll, invoicing, reporting | yes |
| `payments` | payments-reviewer | Banking, wallets, PSPs, payouts, billing, KYC/AML hooks | yes |
| `crypto` | crypto-reviewer | Custody, signing, chain interaction, smart contracts | yes |
| `social` | social-reviewer | UGC, feeds, messaging, follow/block, moderation | no |
| `privacy` | privacy-reviewer | Heavy personal data under whichever law the overlay names | no |
| `commerce` | commerce-reviewer | Catalogue, pricing, promos, inventory, orders | no |
| `ingestion` | ingestion-reviewer | Uploads, OCR, parsers, imports, ETL | yes |

Presets: `finance`, `banking`, `payments`, `crypto`, `social`, `ecommerce`, `saas`, `internal-tool`. Run `review-pack.ps1 list` to see what each enables.

Packs can be combined. An accounting SaaS that imports bank statements uses `finance` + `ingestion` + `privacy`; a crypto exchange uses `crypto` + `payments` + `privacy`.

## Install (once per machine)

```powershell
pwsh ./review-baseline/scripts/install-core.ps1
```
- Core agents go to `~/.claude/agents/reviewers/`.
- Skills go to `~/.claude/skills/`.
- Packs are parked in `~/.claude/review-baseline/`. Parked packs aren't in any agent folder, so they cost nothing until a repo enables them.
- The installer refuses to overwrite an agent or skill with the same name unless you pass `-Force`.
- It doesn't touch CLAUDE.md or settings.json. See INTEGRATION.md for the optional wiring.

## Per project

In Claude Code, run `/review-setup`. It detects the stack and domain, proposes a preset, asks you for jurisdiction and regulations (it never guesses them), then enables the packs and fills the overlay.

Or switch packs directly from the repo root:
```powershell
pwsh ~/.claude/review-baseline/review-pack.ps1 preset banking
pwsh ~/.claude/review-baseline/review-pack.ps1 enable ingestion
pwsh ~/.claude/review-baseline/review-pack.ps1 disable payments
pwsh ~/.claude/review-baseline/review-pack.ps1 list
```
Enabling copies the pack agent into `<repo>/.claude/agents/review-packs/` and its routing file into `<repo>/.claude/review-packs/`. Disabling removes both. The script warns if `.claude/` isn't gitignored in that repo, which matters at an employer whose repos commit `.claude/`.

## Use

| When | Command |
|---|---|
| New repo or project type changes | `/review-setup` |
| Every PR | `/review-pass` |
| Force or limit reviewers | `/review-pass --add security-reviewer` · `--only correctness-reviewer` |
| Before staging/prod | Your release-QA skill, wired per INTEGRATION.md |

## Updating
Pull the baseline repo, re-run `install-core.ps1`, then re-run `review-pack.ps1 enable <packs>` in each repo to refresh its pack copies.

## Writing your own agents
Quote the `description` value. An unquoted colon (`...charters in qa-pass: test...`) is invalid YAML and some Claude Code installs reject the agent. `pwsh ~/.claude/review-baseline/check-agents.ps1 <dir>` flags it; `install-core.ps1` runs it first.

## Design choices
- **Severity plus proof instead of grades.** S1 and S2 findings need a failing test or a traced code path. The verdict is derived from severity, not scored.
- **Routed, not broadcast.** A typical PR runs 2–4 reviewers.
- **Read-only.** Reviewers can't edit, commit, spawn agents or add AI attribution.
- **Regulations only from the overlay.** Reviewers mark unverified legal claims and ask instead of assuming a country's rules.
- **Model aliases only.** No pinned IDs anywhere.
- **Weekly grading.** Every run logs to `.claude/review-log.jsonl`. A reviewer that produces no accepted S1/S2 findings in two weeks drops to on-request only.

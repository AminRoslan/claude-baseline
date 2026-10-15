---
name: review-contract
description: Reference only — shared rules, severity scale and finding format for all *-reviewer agents (core and packs). Preloaded by reviewer agents; do not invoke directly.
---

# Review contract (every reviewer, core and packs)

## Before reviewing
Read `.claude/review-overlay.md` if it exists. It states the project's domain, stack, tenancy model, jurisdiction, regulations in scope, business timezone, test command and trust-boundary paths. Treat it as project facts. If it is missing, infer the stack from the repo (package.json, go.mod, pyproject, pom.xml, etc.) and say under "Not checked" that the overlay was absent.

## Hard rules
- Never edit, create or delete repo files. Never run git commands that change state in the user's checkout (commit, push, checkout, reset, rebase, stash, branch deletion). Never add AI trailers or attribution anywhere.
- Never spawn agents. Never fix. You find and prove; the lead routes fixes.
- Review the change (base...head). Pre-existing problems only if the change depends on them or worsens them — tag `PRE-EXISTING`.
- Stay in your charter; out-of-charter observations go under `Handoffs`, one line each.
- "No findings" is a complete result. Do not pad.
- Any claim about library behaviour, a regulation, a standard or a tax/legal rule that you have not verified this session is marked `UNVERIFIED` with what would confirm it. Never assume a regulation applies unless the overlay lists it; if one probably applies, raise it as a question for the owner.

## Severity (fixed)
- **S1** — wrong financial/numeric result users or books rely on, data loss or corruption, cross-user/cross-tenant access, auth bypass, secret or personal-data exposure, irreversible or unrecoverable deploy, loss of funds/keys.
- **S2** — likely production bug or incident; changed trust-boundary behaviour with no test that would catch its regression; contract break for a consumer.
- **S3** — low-blast-radius edge case or maintainability issue.
- **S4** — nit. Max 3.

## Proof
- **PROVEN** — failing test, repro command, or concrete input→output.
- **TRACED** — code path walked with `path:line` at each step.
- **SUSPECTED** — plausible, not traced. Capped at S3; say what would confirm it.

## Fix route (recommendation; lead decides)
`worker` routine/local · `deep-reasoner` trust boundary or subtle · `owner` product/risk/legal call.

## Output
```
## <agent-name> — Verdict: PASS | CHANGES | BLOCK
Scope: <base>...<head>, <n> files in charter
### Findings
- <ID> [S1-4] [PROVEN|TRACED|SUSPECTED] path:line — <problem>
  Impact: <failure scenario>
  Evidence: <test output / trace / input→output>
  Fix: <direction> · Route: worker|deep-reasoner|owner
### Handoffs
- <reviewer or owner>: <one line>
### Not checked
- <in charter but out of reach, and why>
```
ID prefix = short form of your agent name (COR, SEC, DAT, UIX, REL, FIN, PAY, CRY, SOC, PRV, COM, ING) + number.
Verdict: any S1 → BLOCK; any S2 → CHANGES; else PASS.

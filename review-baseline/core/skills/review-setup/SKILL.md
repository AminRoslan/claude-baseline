---
name: review-setup
description: Set up or change the review configuration for the current repo — detect stack and domain, draft .claude/review-overlay.md, and switch domain packs on or off (finance, payments, crypto, social, privacy, commerce, ingestion). Use on /review-setup, "enable the finance pack", "this is a crypto project", or when starting work in a new repo.
---

# /review-setup

Configures review for this repo. Changes only `.claude/` in the repo; never commits.

Args (optional): `enable <pack...>`, `disable <pack...>`, `preset <name>`, `list`. No args = guided setup.

## Guided setup
1. Detect: language/framework, database, frontend presence, infra (Dockerfile, CI, IaC), multi-tenancy hints (tenantId/orgId/workspaceId scoping), and domain signals (ledgers, payments, wallets, posts/feeds, catalogue/orders, file imports, personal data fields). Report what you found, with file evidence.
2. Propose: a preset and/or individual packs, one line each on why. Available packs and presets come from `pwsh ~/.claude/review-baseline/review-pack.ps1 list`.
3. Ask the owner to confirm (or edit) the packs, plus the facts you cannot detect: jurisdiction, regulations in scope, business timezone, whether minors may use the product. Do not guess regulations.
4. Run `pwsh ~/.claude/review-baseline/review-pack.ps1 preset <name>` or `enable <packs>` from the repo root.
5. Fill `.claude/review-overlay.md` from the template the script created: detected facts plus the owner's answers. Keep it under ~30 lines.
6. Show the final overlay and enabled packs.

## Direct commands
`enable`, `disable`, `preset`, `list` → run the script with the same arguments from the repo root and show its output.

If `.claude/` is tracked in git here (check `git check-ignore .claude`), tell the owner the overlay and pack agents will be committed with the repo, and ask before writing.

---
name: review-pass
description: Per-PR review in any project — routes core reviewers plus whichever domain packs this repo has enabled, verifies and merges findings into one verdict and an owner decisions list. Use on /review-pass, "review this PR", or before writing a PR description. For a batch going to staging/production use the release QA flow (e.g. qa-pass) instead.
---

# /review-pass

You are the lead: route, dispatch, verify, merge, hand decisions to the owner. You do not fix during the review.

Args (optional): `--base <ref>` (default: overlay `Base branch`, else merge-base with `develop`, `main`, `master`), `--head <ref>` (default `HEAD`), `--add <agent>`, `--only <agent,...>`.

## 1. Load project config
- `.claude/review-overlay.md` — domain, stack, tenancy, jurisdiction, regulations, timezone, test command, trust boundaries, skips.
- `.claude/review-packs/*.md` — one file per enabled domain pack, with its agent name and routing triggers.
If neither exists, run core reviewers only and suggest `/review-setup` in the report.

## 2. Scope
`git diff --name-only <base>...<head>` and `git diff --stat <base>...<head>`. Reviewers read refs, not the working tree — uncommitted work must be committed to a branch first.
Trivial (docs/comments/format-only; lockfile-only patch bump with green CI) → "trivial — review skipped", stop.

## 3. Route
Always: `correctness-reviewer`.

Core, add when the diff touches:
| Signal | Add |
|---|---|
| entry points (routes, handlers, resolvers, RPC, socket events), auth, permissions, middleware, external input, uploads, outbound HTTP, webhooks, new dependencies, personal-data fields | `security-reviewer` |
| models/schemas/entities, repositories/queries, migrations, indexes, caches, data-writing jobs/consumers | `data-integrity-reviewer` |
| UI code, styles, user-facing text | `ui-a11y-reviewer` |
| build, CI, infrastructure, containers, env/config, queues, schedulers | `release-reviewer` |

Packs: for each `.claude/review-packs/<pack>.md`, add its agent if the diff matches its triggers (paths, names, or content). Overlay `Trust boundaries` force the listed reviewers for matching paths; overlay `Skip reviewers` removes them. Then apply `--only` / `--add`.

State the roster with a one-line reason per reviewer before dispatching.

## 4. Dispatch
All selected reviewers in parallel in one message. Always set `subagent_type` explicitly — never fall back to general-purpose. Resolve refs to SHAs first (`git rev-parse`). Each prompt: base SHA, head SHA, in-charter file list, ticket/acceptance criteria if known, "Follow review-contract."
Reviewers that run with `isolation: worktree` (correctness-reviewer) branch from the default branch and do not see gitignored files, so `.claude/review-overlay.md` is absent for them: paste the overlay text into every reviewer prompt. Don't pass `model` here; frontmatter decides.

## 5. Verify and merge
1. Dedupe same-root-cause findings (keep highest severity, credit all IDs).
2. Read the cited code yourself for every S1, every S2, and any disputed finding. Drop what doesn't hold, with a one-line reason.
3. S1 verdicts are yours alone.
4. Conflicts: evidence wins (PROVEN > TRACED > SUSPECTED). Product, risk or legal trade-offs go to the owner.

## 6. Report
```
# Review pass — <BLOCK | CHANGES | PASS>
<base>..<head> · reviewers: <list> · packs enabled: <list|none> · files: <n>

## Must fix (S1/S2)
1. <ID> [S1] path:line — problem → fix · route: deep-reasoner

## Decisions for owner
1. <question> — Recommend: <option>, because <reason>. Alternative: <option>.

## Consider (S3, max 8)
## Dropped (<n>): <ID> — reason
## Not checked: <gaps, skipped reviewers and why>
```

## 7. Log
Mandatory: a report is not final until its lines are written, one per dispatched reviewer, in this repo's `.claude/review-log.jsonl` (create it if missing). Skipped or failed dispatches get a line too, with `"findings":0` and a `"note"`.

`{"date":"<ISO>","skill":"review-pass","repo":"<dir name>","head":"<sha>","agent":"<name>","findings":<n>,"s1":<n>,"s2":<n>,"dropped":<n>,"accepted":null}`

Acceptance: once the owner has decided, rewrite this run's lines and set `accepted` to the number of that reviewer's findings the owner accepted (fix routed, or confirmed as real). Leave it `null` only while a decision is open, and say so in the report. This is the only data that shows which reviewers earn their cost.

## 8. After
Offer to route fixes by each finding's route: `worker` routine, `deep-reasoner` trust boundary; `owner` items wait. If those agents don't exist on this machine, use the main session. Fixers never commit with AI trailers and never open PRs.

# Branching model

<!--
  Generic form. Fill the placeholders and delete the branches you do not use.
  Bracketed notes like this one explain why each rule exists; strip them once
  the file is adapted, or keep them — they are the part that survives review.
-->

GitHub branch protection may be **convention-only** — a free plan cannot enforce it, so
"protected" below can mean "don't push directly", not "the server will stop you". Say which
applies to your repos, plainly. A rule everyone believes is enforced, and is not, is worse
than a rule everyone knows is manual.

Branches in order of trust:

- **`{{PROD_BRANCH}}`** — production. No direct pushes. Updated only via PR from
  `{{STAGING_BRANCH}}` or a `hotfix/*`. State explicitly whether merging here deploys.
  A tag-triggered release (`vMAJOR.MINOR.PATCH`) keeps "merged" and "released" as two
  separate decisions, which is usually what you want.
- **`{{STAGING_BRANCH}}`** — staging. Every push triggers the staging deploy.
  **Treat any merge here as a live deploy, not a no-op.** This single sentence prevents
  more incidents than anything else in this file.
- **`feature/*`** — one branch per PR-sized concern, not a whole module. Branch off
  `{{STAGING_BRANCH}}` tip, target it, delete after merge.
- **`hotfix/*`** — a corrective fix to existing behaviour, not new capability. Base depends
  on where the bug actually lives:
  - **Production-only, urgent** — branch off `{{PROD_BRANCH}}` tip so the fix does not drag
    in unreleased work. Target `{{PROD_BRANCH}}`. Once merged and released, merge or
    cherry-pick the same fix back into `{{STAGING_BRANCH}}` or it is silently lost at the
    next release.
  - **Pre-production** (the bug is on `{{STAGING_BRANCH}}` and never reached production) —
    branch off `{{STAGING_BRANCH}}` tip and target it. Use this rather than `feature/*`
    whenever the change fixes something instead of adding something.

## Naming

`<type>/<kebab-summary>` where type is `feature`, `fix` or `hotfix`. The summary is plain
English describing the change, straight from the task title.

Never embed a task id or any other generated code in the branch name — not as a prefix, a
suffix, or a middle segment:

| Wrong | Right |
|---|---|
| `fix/CU-z8xxxxx-verify-spotlight-fallback` | `fix/verify-spotlight-fallback` |
| `feature/TICKET-412-staging-docs-credentials` | `feature/staging-docs-credentials` |

The tracker link goes in the PR body and in the task comment. It does not go in the branch
name, where it is unreadable to a teammate scanning `git branch -a` and costs a lookup to
decode.

## Stacked work

Branch B off branch A's tip, not off `{{STAGING_BRANCH}}`, until A merges. One
`gh pr create --base <A>` per PR in the stack — targeting the trunk for every PR makes each
one show a cumulative diff, so a correctly-scoped PR looks enormous.

Deleting a merged PR's branch can auto-close a PR stacked on it; GitHub does not reliably
retarget. Never delete a merged branch until the PR above it is confirmed retargeted. If one
does get closed, reopen as a fresh PR against the correct base rather than trying to
resurrect the closed one.

## Tags

Only cut a `v*` tag from `{{PROD_BRANCH}}` after the intended state has merged in and been
verified on staging. The tag *is* the release trigger — never tag speculatively.

## Verifying a deploy actually landed

A green Actions run only proves the image built and the deploy API call returned. It does not
prove the new revision is serving traffic. Confirm the rollout itself: exactly one PRIMARY
deployment, a completed rollout state, running count equal to desired count — then cross-check
that revision's image tag against the merged commit SHA.

Service names are frequently not the same as cluster names. List them rather than assuming.

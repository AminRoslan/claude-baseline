---
name: pre-pr
description: Use before opening a pull request in any repo — scope, base branch, branch naming, tracker task, API collection, authorship check and PR body. Also when a PR was opened without these and needs fixing up.
---

# Before opening a PR

Six checks. Run all six before `gh pr create`, not after a reviewer flags something.

<!--
  Adapting this: check 3 and 4 are the only project-specific parts. Keep real
  tracker and collection ids OUT of this file — put them in a project-local
  config the skill reads, or in the project's own CLAUDE.md. A user-level skill
  is shared across every repo on the machine; ids in it are both wrong for most
  of those repos and awkward to share later. See pre-pr.config.example.json.
-->

## 1. Scope — one PR, one concern

`git diff <base> --stat`. If the diff describes more than one thing, split it into stacked
PRs *before* opening anything. Line count is not the test — "does this PR describe one
thing" is.

Stacked PRs: `gh pr create --base <previous-branch>`, never the trunk for every PR in a
stack. Otherwise PR2 and PR3 show cumulative diffs until PR1 merges, and a correctly-scoped
PR looks huge.

Fill a "Known follow-ups" note for anything deliberately deferred rather than cramming it in.

## 2. Base branch and name

See `references/branching.md`. Short version: feature work branches off the staging trunk and
targets it; a fix to already-released code branches off the production branch and targets
that, then gets merged back.

Name: `feature/<kebab-summary>`, `fix/<kebab-summary>` or `hotfix/<kebab-summary>`. Nothing
else goes in the name — **never** a task id, a ticket number or any other generated code.
The tracker link belongs in the PR body where a human can click it; a branch name is read by
teammates scanning `git branch`, and an opaque id there costs a lookup and tells them nothing.

Pick the name a human teammate would pick from the task title, not a restatement of tooling
or plan-doc naming.

## 3. Tracker task — mandatory, including chores

No work is done without a task reflecting it. Small cleanups count: a one-line retroactive
task beats no task.

New feature work gets a subtask under the relevant parent. An existing task gets a comment
with what shipped, PR links, open decisions, plus a status update.

<!-- Board and list ids: pre-pr.config.example.json, kept per-project. -->

## 4. API collection — every new or changed endpoint

Backend repos only. If the repo exposes an HTTP API and this PR adds or changes an endpoint,
the shared collection is updated in the same session — not "later".

<!-- Collection and workspace ids: pre-pr.config.example.json, kept per-project. -->

## 5. Authorship

`git log <base>..HEAD --format='%B'` — check for attribution trailers. Check the PR title and
body too, not just commits.

The commit-msg hook in the baseline's `githooks/` catches this automatically, but `--no-verify`
bypasses it and the hook never sees a PR body. Keep the manual check.

## 6. PR body

Describe what changed and why, addressed to the reviewer, cold. Assume they have no context
from any conversation that produced the change.

- No internal planning artefacts: no plan-document paths, no "task N", no "subagent", no
  brief or report filenames, no reference to a review pipeline that is not part of the
  project's real engineering process.
- No conversational framing. "You asked whether..." means nothing to someone who did not ask.
- If a design doc is worth linking, say what it covers in plain words.
- State the decisions a reviewer might disagree with, and what the alternative was. A PR that
  only says what it did invites a review that only checks whether it works.

**Cross-PR linkage goes in the body at open time, not a later comment.** If this PR depends
on, supersedes, is superseded by, or should be reviewed alongside another — including a fix
living in a different PR that this review will likely raise — put a short "Related PRs" note
in the body the moment it opens.

## After opening

Two failure modes, both from real postmortems:

- **Two branches implementing the same area differently is a fork.** Retire one immediately
  and explicitly — close the losing lineage's PRs with a comment pointing at the winner.
  Leaving both open "to be safe" makes the eventual reconciliation more expensive every day.
- **A PR sitting at COMMENTED for more than a few days is a signal.** Resolve the open
  question or close it. The trunk moves underneath, and by the time anyone looks again the
  original review barely applies to the drifted diff.

Before planning *new* work, check open PRs first:

```
gh pr list --repo <owner/repo> --state open \
  --json number,title,headRefName,baseRefName,reviewDecision,mergeable
```

Two competing architectures once ran in parallel for over a week because nobody checked.

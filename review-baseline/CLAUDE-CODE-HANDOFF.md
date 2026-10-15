# Paste into Claude Code from the claude-baseline repo (once per machine)

I've added `review-baseline/` to this repo: domain-neutral core reviewers, domain packs that are off by default and switched on per repo, the skills review-contract, review-pass and review-setup, and the scripts install-core.ps1 and review-pack.ps1. Integrate it with my live setup in ~/.claude. Show me a diff before writing each file.

1. Read `review-baseline/README.md` and `review-baseline/INTEGRATION.md`. Then read `~/.claude/CLAUDE.md`, `~/.claude/settings.json`, all of `~/.claude/agents/`, and my release-QA skill (qa-pass) if it exists.
2. Report name clashes with agents or skills I already have, and overlaps between my QA charters and the reviewers or packs. Change nothing yet.
3. Run `pwsh ./review-baseline/scripts/install-core.ps1`.
4. If qa-pass exists, apply the INTEGRATION.md changes to it: explicit subagent_type, opus only for trust-boundary reviewers and packs with `escalate_in_qa_pass: true`, review-contract, and the log line. Keep the rest of qa-pass unchanged. Anything domain-specific in qa-pass (money, parsing, etc.) should move into the matching pack, not stay hard-coded.
5. Add the two CLAUDE.md lines from INTEGRATION.md. Remove routing lines for agents with zero use. Change nothing else.
6. List plugin agents that overlap correctness-reviewer, and ask me before denying any.
7. Grep ~/.claude for pinned model IDs and list them.
8. Confirm nothing you wrote adds AI attribution or co-author trailers. Don't commit; I commit myself.
9. Then, in one project I name, run `/review-setup`, then `/review-pass` on a recent PR range, and show me both outputs.

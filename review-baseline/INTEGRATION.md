# Integrating with an existing setup (escalation agents, QA flow, CLAUDE.md)

The baseline works on a bare machine. Everything below is optional wiring for a setup that already has fixer agents and a release-QA skill (e.g. `worker`, `deep-reasoner`, `fable-architect`, `qa-pass`).

## Roles in the loop

```
build ─► /review-pass (per PR) ─► integrate ─► release QA (batch) ─► fix ─► owner decides ─► ship
           core + enabled packs                 same reviewers, trust-boundary ones on opus,
           models from frontmatter              release-reviewer always
fixes: worker (routine) · deep-reasoner (trust boundary / 2 failures) · fable-architect only via an owner decision
```

- Reviewers find and prove. They have no `Agent` tool, so they cannot spawn, fix or escalate.
- A finding's `Route:` is a recommendation; the lead decides. Redesign-sized fixes become an owner decision first.

## Release-QA skill (e.g. qa-pass) — changes

1. **Explicit agent types.** Every QA dispatch names its `subagent_type`. Map existing charters to reviewers:

| QA charter | subagent_type |
|---|---|
| test adequacy / regressions | `correctness-reviewer` |
| security, tenancy | `security-reviewer` |
| data integrity, migrations | `data-integrity-reviewer` |
| UI, accessibility | `ui-a11y-reviewer` |
| release readiness | `release-reviewer` (always at this gate) |
| domain charter (money, payments, crypto, UGC, ingestion…) | the enabled pack's agent, from `.claude/review-packs/*.md` |
| routine fix package | `worker` |
| trust-boundary fix package | `deep-reasoner` |

2. **Escalate depth only here.** Pass `model: "opus"` on the Agent call for `security-reviewer`, `data-integrity-reviewer`, and every enabled pack whose `pack.md` says `escalate_in_qa_pass: true`. The per-call model overrides frontmatter, so per-PR runs stay on Sonnet.
3. **One format.** "Follow review-contract" in every QA prompt. S1 verdicts stay with the lead.
4. **Log** with the same line as review-pass, `"skill":"qa-pass"`.

## Global CLAUDE.md — two lines

```
- Reviews: /review-setup once per repo; /review-pass per PR; release QA before staging/prod. *-reviewer agents only find and prove; fixes go to worker or deep-reasoner.
- Escalation: deep-reasoner only for trust boundaries (auth, tenancy, money, parsers, concurrency) or after 2 failed attempts; CRUD, UI and build-from-spec go to worker.
```

## Overlap to resolve
- Any plugin reviewer (e.g. a compression plugin's reviewer agent) overlapping `correctness-reviewer`: keep one. Deny the other with `Agent(<exact registered name>)` in `permissions.deny`; check the exact name in the @-mention typeahead first, since plugin agents register under a scoped name.
- Remove routing lines for agents with zero use.

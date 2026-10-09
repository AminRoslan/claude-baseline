# The decisions page

The owner decides product and risk calls. Everything that needs a decision goes on
**one page**, so nothing is hidden in a long chat and the answers come back in one
paste.

## Format

Publish it as a private page (an artifact) when the host supports one; otherwise a
single markdown file. One card per decision, each with:

1. **Title in plain words**, and an ID (D1, D2, ...). No jargon the owner has not used.
2. **What is happening today**, with a number or a concrete example from the real data.
3. **Why it matters**: what goes wrong for a user or for money if nothing is decided.
4. **Options**, two or three, each with what it costs (effort, risk, what it changes
   for existing data or users). Always include "leave as is" when it is a real option.
5. **Your recommendation**, first, with the reason in one sentence. The owner can
   disagree, but should never have to guess what you would do.
6. **Answer control**: one choice per option plus a free-text note, and a state for
   "undecided".

At the top: counts (decisions, undecided), and a single **copy answers** control that
produces a compact text block (`D1 A`, `D2 B - note ...`) to paste back. Remember the
answers locally so the page survives a reload. Keep it usable at phone width.

Separate **decisions** from **questions about how it works** the owner may ask. If an
answer shows a misunderstanding (for example "does this switch something on?"),
answer the question with facts, mark the decision undecided, and ask again.

## After the answers

- Record them verbatim in the QA folder's `DECISIONS.md`.
- Anything the owner parks keeps its PR as a draft with the open decision named in the
  body; once answered, update the body, record the choice and why, and mark it ready.
- A decision that changes what staging or production will do (a migration, a new
  required setting, a switch that ships off) gets a line in the deploy notes of the PR
  that needs it, and a reminder to the owner when the stack nears the live branch.

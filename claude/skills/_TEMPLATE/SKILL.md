---
name: {{skill-name}}
description: Use when {{the concrete trigger}} — {{the specific files, requirement ids or symptoms}}, or debugging why {{the symptom someone would actually search for}}
---

# {{Skill Title}}

<!--
  THE DESCRIPTION FIELD IS THE WHOLE SKILL until it fires.
  It is matched against the task, so it must contain the words someone would
  actually use. "Use when working with payments" never matches. "Use when
  touching refund, chargeback or settlement-status logic — FR-031 to FR-035,
  or debugging why an order shows payment_pending after a successful capture"
  matches, because it carries the file area, the requirement ids and the
  symptom.

  A skill is worth writing when getting something right requires knowledge that
  is TRUE, NON-OBVIOUS, and COSTLY TO REDERIVE. If a careful reading of the code
  gives the same answer in five minutes, do not write a skill — the skill will
  go stale and the code will not.
-->

## Overview

<!--
  Open with the distinction that is most often collapsed. Domain skills earn
  their keep by separating things that share a name.

  A table is usually the right shape:

  | Check | File | What it compares | Result |
  |---|---|---|---|

  Name real files and real functions. A skill that describes an area without
  naming anything in it cannot be verified and will rot unnoticed.
-->

## Key invariants

<!--
  The core of the skill. Each entry is something that is true, non-obvious, and
  breaks quietly when violated. State what happens when it is violated — the
  consequence is what makes it stick.

  Good entries look like:
    - **X runs over every row, included or not.** <why> ... Never drop <field>
      when recomputing, or <specific silent corruption>.
    - **Status 'partial' means one side was never verified.** Rolling it up as
      'ok' overstates confidence; don't "simplify" the ternary in <function>.

  If an entry could be replaced by a code comment, put it in the code instead.
  If it spans three files, it belongs here.
-->

- **{{INVARIANT}}** — {{why it holds, and what breaks silently if it is violated}}.

## {{Where this actually blocks something}}

<!--
  Optional but high-value: the one place the rules above have teeth — a
  validation gate, an exception, a hard stop. Say plainly what does NOT exist
  too. "There is no admin bypass; the role field is stored but never enforced"
  prevents an afternoon spent looking for one.
-->

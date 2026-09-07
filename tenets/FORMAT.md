# How to Write Tenets

Tenets are the WHY layer — high-level, language-agnostic constraints that
encode *why* something matters. They sit at the top of a four-layer system:
Tenet (WHY) → Strategy (HOW) → Protocol (WHAT) → Guard (CHECK).

Tenets are not prose rules or tutorials. They are named concepts with a
tight definition, violations, and a one-line why.

## Format

Every tenet file has two parts: a tight **tenet block** and a
**rationale section**.

### Tenet block

```
# [Tenet Name]
[One constraint, clearly stated.]

VIOLATIONS:
- [Failure mode — concrete, recognizable, language-agnostic.]
  Examples:
  - [A specific instance that makes this failure mode recognizable.]
  - [Another instance — illustrative, not exhaustive.]
- [Additional failure modes as needed — especially subtle ones agents are
  likely to produce without realizing it.]

WHY: [One sentence: the mechanism, what goes wrong without it.]
```

### Rationale section

```
---
<!-- Rationale below — read when creating strategies, reviewing, or
questioning the tenet. Not needed for routine application. -->

## Rationale

[How this tenet was arrived at. Edge cases. What this tenet is NOT.
Tensions with other tenets and how they resolve. Cross-references to
sibling tenets.]

### [Subsection as needed]

[Define ambiguous terms. Carve out exceptions. Explain what the tenet
covers and what it doesn't.]
```

Agents read only the tenet block for routine application (checking code,
listing tenets, quick violation checks). The rationale is for deeper work:
creating strategies, reviewing tenets, resolving ambiguous cases, or
onboarding new contributors.

### Cross-references in rationale

Cross-references go in a `### Cross-references` bulleted list at the end of
the rationale. Each bullet starts with the tenet name in bold, then
explains the connection: `- **Tenet Name** (tag): explanation.`

Tags clarify the nature of the relationship:

- `(complementary)` — two halves of the same concern, both needed together.
- `(upstream)` — this tenet's outputs feed the referenced tenet's
  inputs.
- `(tension)` — genuine pull in opposite directions; the resolution is
  documented in the explanation.
- `(yields to)` — this tenet defers when the referenced tenet applies.

Format: `- **Tenet Name** (tag): explanation.`

**Mirror policy:** if tenet A references tenet B, tenet B must
reference tenet A. The explanations differ per direction — A explains the
relationship from A's perspective, B from B's. Symmetric presence, asymmetric
explanation.

Cross-references are tenet-to-tenet only. Strategies reference their
tenet via the `TENET:` line; tenets do not formally cross-reference
the strategy layer. Strategy mentions may appear naturally in rationale prose
but do not belong in the `### Cross-references` list.

For the full relationship graph and family placement, see
[RELATIONSHIPS.md](RELATIONSHIPS.md).

## Example

```
# Fail Early and Loud
Code must surface problems visibly and early rather than absorbing them into
implicit defaults, silent fallbacks, or hidden paths.

VIOLATIONS:
- Silent data corruption through default substitution
  Examples:
  - A hashmap lookup returns null, a downstream null-check substitutes a
    default, and the bug surfaces three layers later as wrong data in
    production.
  - A missing config key falls through to a hardcoded default, creating a
    working-but-wrong system that passes all tests.
- Hidden control flow in tests — a parameterized test uses
  `if tc.expectError` to branch between error and success assertions,
  hiding which path actually executed when the test fails.

WHY: Every silent failure is a bug that compounds — the distance between cause
and discovery is the cost.

---
<!-- Rationale below — read when creating strategies, reviewing, or
questioning the tenet. Not needed for routine application. -->

## Rationale

[What "early" means, what "loud" means, why explicit fallbacks like circuit
breakers are not violations, how conditional test logic belongs here, etc.]
```

## Why this format works

- The **name** gives agents and humans a shorthand. You can say "FEAL
  violation" and the agent knows exactly what you mean without re-reading the
  rule. Names should be memorable and conversational — something you'd say at
  a whiteboard, not in a corporate memo.
- The **definition** states one constraint clearly. If you can't say it in one
  sentence (with qualifying clauses as needed), you don't understand the
  tenet yet — or you have two tenets hiding in one.
- The **violations** are the most important part. They give the agent failure
  modes to recognize, not just a rule to memorize. Violations must be
  language-agnostic: "object" not "struct", "hashmap" not "hash". See
  "The case for violations only" below for the design theory.
- The **why** encodes the mechanism, so agents can apply the tenet in novel
  situations rather than just pattern-matching on familiar ones.
- The **rationale** captures the thinking for future editors: how ambiguous
  terms should be interpreted, what doesn't count as a violation, how this
  tenet relates to others. It's institutional memory.

## The case for violations only

The violation-only format is a guiding theory we're testing: constraining by
defining the boundary works better than prescribing the interior. See
[WORKFLOW.md](../docs/WORKFLOW.md#design-theory-boundary-based-constraints) for
the full system-level theory. This section covers what it means for writing
violations.

**Good takes many forms.** Showing examples of correct code risks implying
only those forms are valid. Violations define what's prohibited and leave the
solution space open — everything that doesn't violate a tenet is allowed.

**Each violation must be a distinct failure mode.** Before adding a violation,
check whether rewording an existing one would cover the same ground — if so,
reword instead of adding. When a failure mode benefits from concrete instances,
use an `Examples:` block with sub-bullets — the label reinforces that these
are illustrative, not exhaustive.

**Subtle violations are the highest value.** The obvious failure mode is easy —
agents catch it themselves. The subtle violations, where code technically
follows the letter of the tenet but violates its spirit, are the ones
that slip through. Prioritize documenting those.

**If two violations need different WHYs, split the tenet.** All violations
for one tenet share the same mechanism of harm.

## What tenets are NOT

- Tactical implementation rules (e.g. "use `require` over `assert`") — these
  belong in protocols or guards, not tenets.
- Tutorials or background reading — agents don't need context, they need
  constraints.
- Long prose — length is not depth. If the tenet block needs three
  paragraphs, it's probably two tenets. (The rationale section can be as
  long as it needs to be.)

## When tenets conflict

Most apparent tenet conflicts dissolve on closer inspection. Three
patterns:

1. **Misidentified tenet.** The decision isn't governed by the tenet
   you think it is. Choosing an assertion library isn't an Earned Abstraction
   question (you're adopting a tool, not creating an abstraction) — it's a
   protocol-level choice informed by whichever tenets the tool serves.
   Before declaring a conflict, verify each tenet actually applies.

2. **CBC yields when the pattern itself is the problem.** Already documented
   in CBC's rationale. If the established pattern violates FEAL, BYN, or
   another tenet, fix the pattern everywhere rather than perpetuating it.

3. **Genuine tension — use PBP.** When two tenets genuinely pull in
   opposite directions, Practicality Beats Purity governs: articulate the
   tradeoff, convince at least one other person, document the decision. If
   you're resolving the same tension repeatedly, the tenets need a
   strategy that encodes the resolution.

There is no fixed hierarchy among tenets. Context determines which
constraint matters most. The process — identify which tenets actually
apply, check if CBC's yield rule resolves it, fall back to PBP — is the
hierarchy.

## Source

Informed by Steve Yegge's Gas Town/Beads approach: named tenets (GUPP,
ZFC, MEOW) with terse definitions that agents invoke by name. The violation
example format is our own addition based on what makes tenets actionable
rather than decorative. The rationale section was added to capture institutional
memory — the reasoning that future editors need to make good updates.

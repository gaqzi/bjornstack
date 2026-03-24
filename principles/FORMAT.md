# How to Write Principles

Principles are the WHY layer — high-level, language-agnostic constraints that
encode *why* something matters. They sit at the top of a four-layer system:
Principle (WHY) → Strategy (HOW) → Guideline (WHAT) → Guard (CHECK).

Principles are not prose rules or tutorials. They are named concepts with a
tight definition, a violation example, and a one-line why.

## Format

Every principle file has two parts: a tight **principle block** and a
**rationale section**.

### Principle block

```
# [Principle Name]
[One constraint, clearly stated.]
VIOLATION: [Concrete example of what wrong looks like.]
VIOLATION: [Optional — a second example that clarifies a borderline case.]
WHY: [One sentence: the mechanism, what goes wrong without it.]
```

### Rationale section

```
---
<!-- Rationale below — read when creating strategies, reviewing, or
questioning the principle. Not needed for routine application. -->

## Rationale

[How this principle was arrived at. Edge cases. What this principle is NOT.
Tensions with other principles and how they resolve. Cross-references to
sibling principles.]

### [Subsection as needed]

[Define ambiguous terms. Carve out exceptions. Explain what the principle
covers and what it doesn't.]
```

Agents read only the principle block for routine application (checking code,
listing principles, quick violation checks). The rationale is for deeper work:
creating strategies, reviewing principles, resolving ambiguous cases, or
onboarding new contributors.

### Cross-references in rationale

Cross-references go in a `### Cross-references` bulleted list at the end of
the rationale. Each bullet starts with the principle name in bold, then
explains the connection: `- **Principle Name** (tag): explanation.`

Tags clarify the nature of the relationship:

- `(complementary)` — two halves of the same concern, both needed together.
- `(upstream)` — this principle's outputs feed the referenced principle's
  inputs.
- `(tension)` — genuine pull in opposite directions; the resolution is
  documented in the explanation.
- `(yields to)` — this principle defers when the referenced principle applies.

Format: `- **Principle Name** (tag): explanation.`

**Mirror policy:** if principle A references principle B, principle B must
reference principle A. The explanations differ per direction — A explains the
relationship from A's perspective, B from B's. Symmetric presence, asymmetric
explanation.

Cross-references are principle-to-principle only. Strategies reference their
principle via the `PRINCIPLE:` line; principles do not formally cross-reference
the strategy layer. Strategy mentions may appear naturally in rationale prose
but do not belong in the `### Cross-references` list.

For the full relationship graph and family placement, see
[RELATIONSHIPS.md](RELATIONSHIPS.md).

## Example

```
# Fail Early and Loud
Code must surface problems visibly and early rather than absorbing them into
implicit defaults, silent fallbacks, or hidden paths.
VIOLATION: A hashmap lookup returns null, a downstream null-check substitutes
a default, and the bug surfaces three layers later as wrong data in production.
VIOLATION: A parameterized test uses `if tc.expectError` to branch between
error and success assertions, hiding which path actually executed when the
test fails.
WHY: Every silent failure is a bug that compounds — the distance between cause
and discovery is the cost.

---
<!-- Rationale below — read when creating strategies, reviewing, or
questioning the principle. Not needed for routine application. -->

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
  principle yet — or you have two principles hiding in one.
- The **violation example** is the most important part. It gives the agent a
  pattern to recognize, not just a rule to memorize. Violations must be
  language-agnostic: "object" not "struct", "hashmap" not "hash".
- The **why** encodes the mechanism, so agents can apply the principle in novel
  situations rather than just pattern-matching on familiar ones.
- The **rationale** captures the thinking for future editors: how ambiguous
  terms should be interpreted, what doesn't count as a violation, how this
  principle relates to others. It's institutional memory.

## What principles are NOT

- Tactical implementation rules (e.g. "use `require` over `assert`") — these
  belong in protocols or guards, not principles.
- Tutorials or background reading — agents don't need context, they need
  constraints.
- Long prose — length is not depth. If the principle block needs three
  paragraphs, it's probably two principles. (The rationale section can be as
  long as it needs to be.)

## When principles conflict

Most apparent principle conflicts dissolve on closer inspection. Three
patterns:

1. **Misidentified principle.** The decision isn't governed by the principle
   you think it is. Choosing an assertion library isn't an Earned Abstraction
   question (you're adopting a tool, not creating an abstraction) — it's a
   protocol-level choice informed by whichever principles the tool serves.
   Before declaring a conflict, verify each principle actually applies.

2. **CBC yields when the pattern itself is the problem.** Already documented
   in CBC's rationale. If the established pattern violates FEAL, BYN, or
   another principle, fix the pattern everywhere rather than perpetuating it.

3. **Genuine tension — use PBP.** When two principles genuinely pull in
   opposite directions, Practicality Beats Purity governs: articulate the
   tradeoff, convince at least one other person, document the decision. If
   you're resolving the same tension repeatedly, the principles need a
   strategy that encodes the resolution.

There is no fixed hierarchy among principles. Context determines which
constraint matters most. The process — identify which principles actually
apply, check if CBC's yield rule resolves it, fall back to PBP — is the
hierarchy.

## Source

Informed by Steve Yegge's Gas Town/Beads approach: named principles (GUPP,
ZFC, MEOW) with terse definitions that agents invoke by name. The violation
example format is our own addition based on what makes principles actionable
rather than decorative. The rationale section was added to capture institutional
memory — the reasoning that future editors need to make good updates.

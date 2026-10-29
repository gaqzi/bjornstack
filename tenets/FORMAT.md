# How to Write Tenets

Tenets are the WHY layer — high-level, language-agnostic constraints that
encode *why* something matters. They sit at the top of a four-layer system:
Tenet (WHY) → Strategy (HOW) → Protocol (WHAT) → Guard (CHECK).

Tenets are not prose rules or tutorials. They are named concepts with a
tight definition, Good and Bad cases where they help, violations, and a
one-line why.

## Format

Every tenet file has two parts: a tight **tenet block** and a
**rationale section**.

### Tenet block

```
# [Tenet Name]
[One constraint, clearly stated.]

- Good: [Optional. The property that makes it good]; such as [one
  form], or [a contrasting form].
- Bad: [Optional. A case on the wrong side of the boundary.]

VIOLATIONS:
- [Failure mode — concrete, recognizable, language-agnostic.]
  Examples:
  - [A specific instance that makes this failure mode recognizable.]
  - [Another instance — illustrative, not exhaustive.]
- [Additional failure modes as needed — especially subtle ones agents are
  likely to produce without realizing it.]

WHY: [One sentence: the mechanism, what goes wrong without it.]
```

### Good and Bad cases

A tenet states its constraint first. It may then carry Good and Bad
cases that illustrate the constraint; they never replace it. A Good case
names the property that makes it good and shows it in two contrasting
forms (contrasting: forms that differ in kind, not only in detail), so
the reader learns the property, not one way to reach it. Bad cases and
VIOLATIONS mark the boundary.

Delete the cases and the constraint must still apply on its own. A case
must not add a condition the constraint doesn't state, or drop one it
does; if it needs to, change the constraint.

- FAIL: "Good: exit at startup when a config key is missing."
- PASS: "Good: a missing required value is reported where it is first
  noticed, naming the value; such as refusing to start, or failing the
  one request that needed it."

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

- Good: nothing continues as if the problem were not there, and the
  failure names what is wrong; such as startup stopping with "config
  /etc/app.yaml: missing key db.url", or a CSV import rejected with
  every bad row listed.
- Good: a fallback someone chose, that signals it is in use; such as a
  cache serving last hour's prices marked as stale, or a degraded flag
  on the service's health check.
- Bad: a price lookup fails and the page shows a price of zero.

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
- The **Good and Bad cases** show where the constraint applies and where it
  stops. Each Good case names a property, so the agent learns what makes
  an answer acceptable rather than one answer to copy.
- The **violations** give the agent failure modes to recognize, not just a
  rule to memorize. Violations must be language-agnostic: "object" not
  "struct", "hashmap" not "hash". See "Good cases, Bad cases and
  violations" below for the design theory.
- The **why** encodes the mechanism, so agents can apply the tenet in novel
  situations rather than just pattern-matching on familiar ones.
- The **rationale** captures the thinking for future editors: how ambiguous
  terms should be interpreted, what doesn't count as a violation, how this
  tenet relates to others. It's institutional memory.

## Good cases, Bad cases and violations

See [WORKFLOW.md](../docs/WORKFLOW.md#design-theory-procedures-boundaries-and-examples)
for the system-level reasoning. This section covers what it means for
writing a tenet.

**A Good case names the property, in two forms.** Good takes many forms.
When blind readers applied tenets to concrete cases, a Good case that
named a single form narrowed them: they took that form as the only valid
answer and doubted other valid ones. A Good case that named the property
and showed two contrasting forms never ruled out a valid answer. Readers
often copy a Good form outright; two forms that differ keep the copy
within the property.

**Violations alone leave readers guessing.** Violations say what is
wrong but not that a nearby choice is fine. In a small comparison,
readers given only violations guessed more often, and a violation
example made them doubt a valid answer that resembled it. Readers who
also had Good cases decided more cases and ruled out none.

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
ZFC, MEOW) with terse definitions that agents invoke by name. The Good,
Bad and violation format is our own addition based on what makes tenets
actionable rather than decorative. The rationale section was added to
capture institutional memory — the reasoning that future editors need to
make good updates.

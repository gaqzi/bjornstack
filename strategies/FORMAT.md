# How to Write Strategies

Strategies are the HOW layer — the abstract, language-agnostic approach that
bridges a tenet (WHY) to a protocol (WHAT in language X).

A tenet says *why something matters*. A strategy says *how to achieve it*
as an abstract recipe. A protocol says *what to do concretely* in a specific
language or framework.

**Strategies are primarily an authoring tool.** They are consumed when
generating language-specific protocols and are available as reference material
when a generated protocol needs disambiguation. Their purpose is to help
express abstractly *what the technique is* before getting pulled into the
specifics of a target language or stack. When a tenet can be made into a
repeatable technique, the path is always tenet → strategy → protocol. The
exception is pure-judgment tenets where the technique can't be abstracted
into repeatable steps.

## Format

```
# [Strategy Name]
TENET: [Tenet name this strategy serves]

1. [Step 1 — the procedure, abstract and conceptual.]
   - Good: [Optional. The property that makes it good]; such as [one
     form], or [a contrasting form].
   - Bad: [Optional. A case on the wrong side of the boundary.]
2. [Step 2]
3. [Step 3]
...

OUTCOMES:
- [Observable result 1 — something you can check]
- [Observable result 2]

MISAPPLICATIONS:
- [What it looks like when this strategy is applied in the wrong context.]
  Examples:
  - [A specific instance that makes this misapplication recognizable.]
- [What it looks like when this strategy is applied too aggressively.]

SKIP WHEN: [When this strategy doesn't apply — the situation doesn't call for this technique.]
```

### Good and Bad cases

A step states its procedure first. It may then carry Good and Bad cases
that illustrate the procedure; they never replace it. A Good case names
the property that makes it good and shows it in two contrasting forms
(contrasting: forms that differ in kind, not only in detail), so the
reader learns the property, not one way to reach it. Bad cases and
MISAPPLICATIONS mark the boundary.

Delete the cases and the step must still be followable on its own. A case
must not add a condition the step doesn't state, or drop one it does; if
it needs to, change the step.

- FAIL: "Good: pass the time zone as an argument."
- PASS: "Good: the zone comes from the caller, never the machine; such
  as an argument, or a request context that carries it."

### Forked strategies

When a strategy's first step is a classification that leads to fundamentally
different paths, use nested numbering. The top-level steps are the decision
point and each path; sub-steps belong to their path:

```
# [Strategy Name]
TENET: [Tenet name]

1. [Classification step — how to determine which path applies.]
   - [Path A condition]: continue at step 2.
   - [Path B condition]: continue at step 3.
2. [Path A label]:
   1. [Path A step 1]
   2. [Path A step 2]
3. [Path B label]:
   1. [Path B step 1]
   2. [Path B step 2]
   3. [Path B step 3]

OUTCOMES:
...
```

The paths can be asymmetric — if one path is genuinely simpler, it has fewer
steps. Don't pad the shorter path to match. Reference nested steps with
dotted notation (e.g., "step 3.2" means path B, sub-step 2).

Use forks only when the classification creates genuinely different procedures.
If the paths share most steps and differ in one or two, a flat strategy with
a conditional note is clearer.

### Rationale section (optional)

When a strategy's reasoning needs more context — why certain steps exist,
how the technique applies across languages, edge cases — add a rationale
section below a `---` separator, matching the tenet format:

```
---
<!-- Rationale below — read when creating protocols, reviewing, or
questioning the strategy. Not needed for routine application. -->

## Rationale

### [Subsection as needed]

[Why this technique works. Cross-language considerations. What the steps
don't cover and why. Edge cases that protocol authors should understand.]
```

Guideline authors read the rationale when translating the strategy to a
specific language. It's where language-agnostic reasoning meets the
specifics of implementation — "tests reveal the surface" as a concept,
before becoming "_test packages" in Go or "import from the public API" in
Python.

### Cross-references in rationale

Cross-references go in a `### Cross-references` bulleted list at the end of
the rationale. Each bullet starts with the strategy name in bold, then
explains the connection: `- **Strategy Name**: explanation.` When a
relationship needs multiple paragraphs — ownership boundaries, handoff
points, composition logic — promote it to its own
`### Relationship to [Name]` subsection above the cross-references list.

Optional parenthetical tags can follow the strategy name to clarify the
nature of the connection:

- `(downstream)` — the referenced strategy builds on this one. Clarifies
  directionality when both strategies cross-reference each other.
- `(TENET)` — a tenet abbreviation like `(FEAL)`, `(NSF)`, `(CoC)`,
  `(HTD)`. Indicates which tenet the connection primarily serves.
  Use when the link exists because of a specific tenet, not just
  proximity.

Format: `- **Strategy Name** (tag): explanation.`

**Mirroring policy:** A reference from A→B does not require B→A. When adding
a cross-reference, ask: "Would someone reading B benefit from knowing about
A?" If yes, add a mirror from B's perspective. If no, leave it
one-directional.

**Meta-strategy exception:** A meta-strategy (e.g., `testing.md`) dispatches
to sub-strategies in its steps — those inline references *are* the
cross-references. A separate `### Cross-references` section listing the same
sub-strategies would be redundant. Sub-strategies should still reference the
meta-strategy back (via `### Relationship to the meta-strategy` or inline),
but the meta→sub direction is covered structurally by the steps themselves.

For the full relationship graph and family placement, see
[RELATIONSHIPS.md](RELATIONSHIPS.md).

## Example

```
# Data-Driven Test Cases
TENET: No Conditional Test Logic

1. Identify the variations — what changes between test cases?
2. Extract those variations into data: inputs, expected outputs,
   and case descriptions.
   - Good: each case is plain data the one body reads; such as a
     hand-written row per case, or cases generated by sweeping an input
     across a range.
   - Bad: a row carries a flag the body checks to decide which
     assertion to run.
3. Write a single test body that operates on one case.
4. Have the framework iterate the data through that body.
5. Each case runs in isolation — a failure in one doesn't skip others.

OUTCOMES:
- Each test case failure is independently identifiable.
- The test body contains no branching logic.
- Adding a new case requires only adding data, not changing code.

MISAPPLICATIONS:
- A "table" that still contains conditional logic inside the loop body —
  the structure looks data-driven but the execution isn't.
- Each row requires fundamentally different setup. If the cases don't share
  a single code path, they aren't one strategy — they're separate tests.

SKIP WHEN: Only one case exists. A single test function is fine.
```

## Why this format works

- The **name** is a short noun phrase (2-4 words), same convention as
  tenets. It gives agents and humans a shorthand to refer to the approach.
- The **TENET link** makes the WHY→HOW chain explicit. Every strategy
  serves at least one tenet.
- The **numbered steps** are the core of the strategy. They describe an
  idealized procedure at a conceptual level — no language-specific details.
  This is what makes strategies *meta-procedural*: they explain how to think
  about the problem, not how to type the solution. When a strategy starts
  with a classification that creates divergent paths, nested numbering makes
  the fork structural rather than relying on prose cues like "continue at
  step N."
- **Good and Bad cases** under a step show where its procedure applies and
  where it stops. They illustrate the procedure and never replace it. See
  "Why steps carry Good and Bad cases" below.
- **OUTCOMES** are observable results that validate the strategy was applied
  correctly. These are the natural bridge to guards — when an outcome can be
  checked mechanically, it's a guard candidate. Protocols can add more
  language-specific outcomes on top.
- **MISAPPLICATIONS** instead of VIOLATIONS — strategies can be misapplied
  (over-engineering, wrong context), not simply violated. You *violate* a
  tenet: you broke a constraint. You *misapply* a strategy: you used a
  technique where it doesn't fit or used it badly. A tenet is a law, a
  strategy is a tool. Each misapplication is a distinct failure mode,
  covering wrong-context use and over-application; use `Examples:`
  sub-bullets when a failure mode benefits from concrete instances.
- **SKIP WHEN** makes it explicit when this specific strategy is not the right
  fit — typically when a different strategy for the same tenet applies, or
  when the situation doesn't call for this technique.

## Why steps carry Good and Bad cases

See [WORKFLOW.md](../docs/WORKFLOW.md#design-theory-procedures-boundaries-and-examples)
for the system-level reasoning.

**The procedure comes first.** Readers treat a list of examples as the
complete set: given only examples, they produce those cases and nothing
more. A step that states how to find the cases lets the reader find ones
the examples never mention.

**A Good case names the property, in two forms.** When blind readers
applied strategies to concrete cases, a Good case that named a single
form narrowed them: they took that form as the only valid answer and
doubted other valid ones. A Good case that named the property and showed
two contrasting forms never ruled out a valid answer, and readers decided
as many cases as with the steps alone, or more. Readers often copy a
Good form outright; two forms that differ show which part is the
property and which part is incidental, so a copy stays within the
property.

**Bad cases and MISAPPLICATIONS mark the boundary.** They say what is
wrong but not that a nearby choice is fine; Good cases say that. On
strategies the procedure carried most of the weight: readers with steps
alone guessed no more than readers who also had cases.

## File naming

Strategy files use kebab-case of the strategy name: "Data-Driven Test
Cases" → `data-driven-test-cases.md`. When a strategy has sub-strategies,
the parent uses a plain name (`testing.md`) and sub-strategies use double
underscore: `testing__unit.md`, `testing__integration.md`. The `__` reads
as "testing → unit" and keeps everything flat in `strategies/`.

## What strategies are NOT

- **Tenets.** If it can be said in one sentence as a constraint, with
  violations marking its boundary, it's a tenet. Strategies need space to
  describe a technique.
- **Protocols.** If it references a specific language, framework, or tool,
  it's a protocol step. Strategies are language-agnostic.
- **Tutorials.** Strategies describe *what to do conceptually*, not *how to
  learn it*. No background reading, no motivation beyond the TENET link.

## How strategies relate to other layers

```
Tenet        → WHY     "Tests must not contain conditional logic"        ← loaded into project
Strategy     → HOW     Data-Driven Test Cases (the abstract technique)   ← input to protocol generation
Protocol     → WHAT    Go: table-driven tests with t.Run subtests        ← generated, loaded into project
Guard        → CHECK   testnoifs linter: rejects if/switch in tests      ← loaded into project, runs automatically
```

A single tenet may have multiple strategies (different approaches to the
same WHY). A single strategy may have multiple protocols (same approach
adapted per language). Not every protocol step produces guards — some require
judgment that can't be mechanized.

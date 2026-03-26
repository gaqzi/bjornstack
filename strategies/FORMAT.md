# How to Write Strategies

Strategies are the HOW layer — the abstract, language-agnostic approach that
bridges a principle (WHY) to a protocol (WHAT in language X).

A principle says *why something matters*. A strategy says *how to achieve it*
as an abstract recipe. A protocol says *what to do concretely* in a specific
language or framework.

**Strategies are primarily an authoring tool.** They are consumed when
generating language-specific protocols and are available as reference material
when a generated protocol needs disambiguation. Their purpose is to help
express abstractly *what the technique is* before getting pulled into the
specifics of a target language or stack. When a principle can be made into a
repeatable technique, the path is always principle → strategy → protocol. The
exception is pure-judgment principles where the technique can't be abstracted
into repeatable steps.

## Format

```
# [Strategy Name]
PRINCIPLE: [Principle name this strategy serves]

1. [Step 1 — abstract, conceptual]
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

### Forked strategies

When a strategy's first step is a classification that leads to fundamentally
different paths, use nested numbering. The top-level steps are the decision
point and each path; sub-steps belong to their path:

```
# [Strategy Name]
PRINCIPLE: [Principle name]

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
section below a `---` separator, matching the principle format:

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
- `(PRINCIPLE)` — a principle abbreviation like `(FEAL)`, `(NSF)`, `(CoC)`,
  `(HTD)`. Indicates which principle the connection primarily serves.
  Use when the link exists because of a specific principle, not just
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
PRINCIPLE: No Conditional Test Logic

1. Identify the variations — what changes between test cases?
2. Extract those variations into data: inputs, expected outputs,
   and case descriptions.
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
  principles. It gives agents and humans a shorthand to refer to the approach.
- The **PRINCIPLE link** makes the WHY→HOW chain explicit. Every strategy
  serves at least one principle.
- The **numbered steps** are the core of the strategy. They describe an
  idealized procedure at a conceptual level — no language-specific details.
  This is what makes strategies *meta-procedural*: they explain how to think
  about the problem, not how to type the solution. When a strategy starts
  with a classification that creates divergent paths, nested numbering makes
  the fork structural rather than relying on prose cues like "continue at
  step N."
- **OUTCOMES** are observable results that validate the strategy was applied
  correctly. These are the natural bridge to guards — when an outcome can be
  checked mechanically, it's a guard candidate. Protocols can add more
  language-specific outcomes on top.
- **MISAPPLICATIONS** instead of VIOLATIONS — strategies can be misapplied
  (over-engineering, wrong context), not simply violated. See "The case for
  misapplications over positive examples" below for why. Each misapplication
  is a distinct failure mode; use `Examples:` sub-bullets when a failure mode
  benefits from concrete instances.
- **SKIP WHEN** makes it explicit when this specific strategy is not the right
  fit — typically when a different strategy for the same principle applies, or
  when the situation doesn't call for this technique.

## The case for misapplications over positive examples

The same boundary-based theory behind VIOLATIONS in principles applies here.
See [WORKFLOW.md](../docs/WORKFLOW.md#design-theory-boundary-based-constraints)
for the full system-level reasoning.

**Why "misapplications" instead of "violations."** You *violate* a principle —
you broke a constraint. You *misapply* a strategy — you used a technique where
it doesn't fit or used it badly. A principle is a law, a strategy is a tool.
The format (bulleted list) matches VIOLATIONS: for consistency, but the name
reflects the different relationship.

**Strategies already guide the thinking process.** The numbered steps describe
how to approach the problem; OUTCOMES describe what to check. MISAPPLICATIONS
complement them by showing what the technique looks like when it goes wrong.
Each misapplication should be a distinct failure mode covering wrong-context
use and over-application.

## File naming

Strategy files use kebab-case of the strategy name: "Data-Driven Test
Cases" → `data-driven-test-cases.md`. When a strategy has sub-strategies,
the parent uses a plain name (`testing.md`) and sub-strategies use double
underscore: `testing__unit.md`, `testing__integration.md`. The `__` reads
as "testing → unit" and keeps everything flat in `strategies/`.

## What strategies are NOT

- **Principles.** If it can be said in one sentence and has a violation
  example, it's a principle. Strategies need space to describe a technique.
- **Protocols.** If it references a specific language, framework, or tool,
  it's a protocol step. Strategies are language-agnostic.
- **Tutorials.** Strategies describe *what to do conceptually*, not *how to
  learn it*. No background reading, no motivation beyond the PRINCIPLE link.

## How strategies relate to other layers

```
Principle    → WHY     "Tests must not contain conditional logic"        ← loaded into project
Strategy     → HOW     Data-Driven Test Cases (the abstract technique)   ← input to protocol generation
Protocol     → WHAT    Go: table-driven tests with t.Run subtests        ← generated, loaded into project
Guard        → CHECK   testnoifs linter: rejects if/switch in tests      ← loaded into project, runs automatically
```

A single principle may have multiple strategies (different approaches to the
same WHY). A single strategy may have multiple protocols (same approach
adapted per language). Not every protocol step produces guards — some require
judgment that can't be mechanized.

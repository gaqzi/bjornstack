# How to Write Strategies

Strategies are the HOW layer — the abstract, language-agnostic approach that
bridges a principle (WHY) to a guideline (WHAT in language X).

A principle says *why something matters*. A strategy says *how to achieve it*
as an abstract recipe. A guideline says *what to do concretely* in a specific
language or framework.

Not every principle needs a strategy. When a principle is direct enough that
guidelines can implement it without an intermediate step, skip the strategy.
The SKIP WHEN field makes this explicit.

## Format

```
## [Strategy Name]
PRINCIPLE: [Principle name this strategy serves]

1. [Step 1 — abstract, conceptual]
2. [Step 2]
3. [Step 3]
...

OUTCOMES:
- [Observable result 1 — something you can check]
- [Observable result 2]

MISAPPLICATION: [What it looks like when this strategy is applied badly
or in the wrong context.]
SKIP WHEN: [When the principle is direct enough to go straight to guidelines.]
```

## Example

```
## Data-Driven Test Cases
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

MISAPPLICATION: A "table" that still contains conditional logic inside
the loop body, or where each row requires fundamentally different setup.
If the cases don't share a single code path, they aren't one strategy —
they're separate tests.
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
  about the problem, not how to type the solution.
- **OUTCOMES** are observable results that validate the strategy was applied
  correctly. These are the natural bridge to guards — when an outcome can be
  checked mechanically, it's a guard candidate. Guidelines can add more
  language-specific outcomes on top.
- **MISAPPLICATION** instead of VIOLATION. Strategies can be applied badly
  (over-engineering, wrong context) rather than simply violated. This field
  shows what the strategy looks like when it goes wrong — a pattern to
  recognize and correct.
- **SKIP WHEN** makes it explicit when the strategy layer is unnecessary.
  Some principles are direct enough that guidelines can implement them
  without an intermediate abstraction.

## What strategies are NOT

- **Principles.** If it can be said in one sentence and has a violation
  example, it's a principle. Strategies need space to describe a technique.
- **Guidelines.** If it references a specific language, framework, or tool,
  it's a guideline. Strategies are language-agnostic.
- **Tutorials.** Strategies describe *what to do conceptually*, not *how to
  learn it*. No background reading, no motivation beyond the PRINCIPLE link.

## How strategies relate to other layers

```
Principle    → WHY     "Tests must not contain conditional logic"
Strategy     → HOW     Data-Driven Test Cases (the abstract technique)
Guideline    → WHAT    Go: table-driven tests with t.Run subtests
Guard        → CHECK   testnoifs linter: rejects if in test bodies
```

A single principle may have multiple strategies (different approaches to the
same WHY). A single strategy may have multiple guidelines (same approach
adapted per language). Not every path uses all four layers.

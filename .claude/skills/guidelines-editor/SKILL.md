---
name: guidelines-editor
description: >
  Write, review, and refine language-specific guidelines — the WHAT layer that
  turns abstract strategies into concrete implementation steps for a specific
  language. Use this skill whenever the user wants to create guidelines for a
  principle or strategy in a target language, review existing guidelines, check
  whether a strategy step translates directly or needs divergence documentation,
  or assess which guideline steps are guard candidates. Also trigger when handed
  off from strategy-editor, when the user asks "how do I do this in Go?",
  "what's the Go implementation for...", "create guidelines for...", or mentions
  the guidelines layer or WHAT layer — even if they don't use the word
  "guideline" explicitly.
---

# Guidelines Editor

Write, review, and refine language-specific guidelines that implement strategies
for a target language.

Read `references/FORMAT.md` before proceeding — it defines the strategy format
you'll be reading and deriving from. Read `references/DIVERGENCE.md` for when a
language can't follow a strategy step as-is.

## Prerequisites

Before creating guidelines, verify all three prerequisites. Stop and redirect
the user if any are missing.

1. **A principle exists.** Glob `principles/*.md` (excluding FORMAT.md) for the
   principle name. If it doesn't exist, stop — tell the user to create it first
   with principle-editor.

2. **A strategy exists.** Glob `strategies/*.md` (excluding FORMAT.md and
   DIVERGENCE.md) for a strategy that serves the principle. Read each
   strategy file's `PRINCIPLE:` field to find matches. If no strategy
   exists, stop — tell the user to create one first with strategy-editor.
   Guidelines implement strategies; without a strategy, there's nothing to
   implement.

   If multiple strategies serve the same principle, ask the user which one
   to implement — each gets its own guideline directory.

3. **A target language is specified.** Ask the user if not provided. The
   language determines the directory (`implementation/<lang>/`) and the
   concrete details in each step.

## What you produce

### Guideline file

Written to `implementation/<lang>/<strategy-name>/guidelines.md`. The
directory name uses the kebab-case strategy name.

```
## [Guideline Name]
STRATEGY: [Strategy name this guideline implements]
PRINCIPLE: [Principle name]
LANGUAGE: [Target language]

1. [Concrete, language-specific step derived from strategy step 1]
2. [Step 2]
...

OUTCOMES: [Optional — only if this language surfaces additional observable
results beyond the strategy's outcomes. Do not repeat strategy outcomes.]

MISAPPLICATION: [Optional — only if this language has its own way of getting
the guideline wrong that the strategy's misapplication doesn't cover.]

GUARD CANDIDATES:
- Step N: [What can be mechanically checked]
  CHECK: [How a linter/CI would check it]
```

Name is a concrete, language-specific noun phrase. It describes what you
do in this language — not the abstract strategy name. Derived from the
strategy name but made concrete: "Data-Driven Test Cases" becomes
"Table-Driven Tests with t.Run Subtests."

### Annotated example

```
## Table-Driven Tests with t.Run Subtests
```
Name: concrete, language-specific. Describes what you actually do in this
language — not the abstract strategy name.

```
STRATEGY: Data-Driven Test Cases
PRINCIPLE: No Conditional Test Logic
LANGUAGE: Go
```
Links to both the strategy (HOW) and the principle (WHY). The language
makes it explicit which implementation this is.

```
1. Define a test case struct with fields for: name, inputs, expected
   outputs, and any setup data.
2. Create a slice of test cases as a variable named `tests` or `cases`
   at the top of the test function.
3. Range over the slice with `for _, tc := range tests`.
4. Call `t.Run(tc.name, func(t *testing.T) { ... })` for each case.
5. Inside the subtest, use only `tc` fields — no external state.
6. Assert with `require` (not `assert`) so failures stop the subtest
   immediately.
```
6 steps. Each is concrete and Go-specific: struct types, `t.Run`, `require`
vs `assert`. These are derived from the strategy's abstract steps but
translated into what you actually type in Go. A developer who knows Go
can follow these steps without guessing.

```
OUTCOMES:
- `go test -v` output shows each subtest by name with pass/fail status.
- A failing subtest does not prevent other subtests from running.
```
Two language-specific outcomes. The strategy's outcomes ("each test case
failure is independently identifiable", "the test body contains no
branching logic", "adding a new case requires only adding data") still
apply — they're inherited, not repeated. These additions are things only
Go can say because they reference `go test -v` and subtest isolation
behavior.

```
MISAPPLICATION: Using `assert` instead of `require` in subtests — the
subtest continues after the first failure, producing cascading errors
that obscure which case actually failed.
```
A Go-specific trap. The strategy's misapplication covers the abstract
failure mode (conditional logic in the loop body). This covers a
language-specific trap someone following the guideline could fall into.
Only include MISAPPLICATION when the language has its own way of going
wrong that the strategy doesn't predict.

```
GUARD CANDIDATES:
- Step 4: Every test with multiple cases uses `t.Run` subtests.
  CHECK: AST check — test functions with range loops must contain
  t.Run calls.
- Step 6: Subtests use `require`, not `assert`.
  CHECK: Lint rule — `assert.*` calls inside `t.Run` callbacks.
```
Two guard candidates. Each references a specific step and describes what
a mechanical check would look for. Not every step is a guard candidate —
steps 1-3 and 5 require judgment about struct design and variable naming.

Guidelines typically have more steps than their strategy — abstract steps
split into concrete ones. If you have fewer steps than the strategy, check
that you haven't restated strategy steps instead of making them concrete.
If you have many more, check that you haven't drifted into tutorial
territory.

### Divergence file

Written to `implementation/<lang>/<strategy-name>/divergences.md` when a
strategy step can't be followed as-is. Uses the format from
`references/DIVERGENCE.md`:

```
DIVERGES FROM: [Strategy Name]
STEP: [N] ("[quoted strategy step text]")
REASON: [Why — language limitation, ecosystem convention, or better
alternative exists]
APPROACH: [What we do instead and why it still serves the principle]
```

### Not-applicable file

Written to `implementation/<lang>/<strategy-name>/not-applicable.md` when a
principle genuinely doesn't apply to a target language:

```
## [Principle Name] — Not Applicable to [Language]
REASON: [Why this principle doesn't apply]
```

This tells the audit script and future contributors that the gap is
intentional, not an oversight.

## Modes

### Create

User provides a principle name, strategy name, and target language (or the
skill asks for them).

1. Read the principle from `principles/<name>.md`
2. Read the strategy from `strategies/<name>.md`
3. For each strategy step, derive a concrete language-specific guideline step:
   a. **Translates directly** — The strategy step maps to a clear
      language-specific construct. Write the concrete step.
   b. **Translates with adaptation** — The language has a different mechanism
      that achieves the same goal. Write the adapted step AND document the
      divergence in `divergences.md`.
   c. **Not applicable** — The strategy step has no equivalent in this
      language. Skip it and note why. If most steps don't apply, consider
      whether the principle itself is not-applicable.
4. For each guideline step, assess guard candidacy. All three must be true:
   - **Binary** — The check passes or fails with no judgment required.
   - **Mechanizable** — A linter, AST check, or CI gate can detect violations.
   - **Low false positives** — `// nolint` escapes stay exceptional.
5. Assemble the guideline in the exact format
6. Run every quality check (see below)
7. If any check fails, revise and show the improved version
8. Present the final guideline with:
   - A mapping showing which strategy step produced which guideline step
   - Any divergences found
   - Guard candidates identified
9. Wait for user approval before writing

### Review

User provides existing guidelines. Evaluate against every quality check.
Lead with a summary: which checks pass, which fail. Then for each failure,
show the failing text, explain what's wrong, and provide a concrete rewrite.

Also check:
- Are guidelines still aligned with the current strategy? (strategy may have
  been updated since guidelines were written)
- Are divergences properly documented?
- Are guard candidates correctly identified? (missed any? false positives?)

### Update

User wants to revise existing guidelines — because the strategy evolved, a
guard was implemented, or language conventions changed. Read the existing
guideline and divergence files. Diff the proposed change against the quality
checks. Flag if the change breaks strategy traceability. After approval,
update the files in place.

### Not-applicable

When a principle genuinely doesn't apply to a target language. This mode
can be invoked directly when you already know a principle doesn't apply,
or reached from Create mode step 3c when most strategy steps turn out to
be not-applicable.

Don't create empty guideline files. Write the not-applicable file (see
"What you produce") explaining why.

### When triggered from strategy-editor

The strategy name and principle name are your starting points — they'll be
in the conversation or in a beads issue. Ask the user which language to
target and proceed with the Create mode.

## Quality checks

Run every check on every guideline you produce or review.

### Traceability check

This is the most important check. Every guideline step must trace back to
and serve a strategy step (or explicitly note a divergence). And every
strategy step must be accounted for in the guidelines — either implemented,
adapted with divergence, or noted as not-applicable with a reason.

The test: given the strategy, can you draw a line from each strategy step to
its guideline step(s), and does each guideline step actually achieve what the
strategy step describes? If any strategy step is unaccounted for, the
guideline is incomplete. If a guideline step traces to a strategy step but
doesn't serve it, the guideline is wrong.

FAIL: A guideline with 3 steps when the strategy has 5 — two strategy steps
are silently dropped.
PASS: A guideline with 6 steps derived from a 5-step strategy, with a note
that strategy step 2 was split into two concrete steps for clarity.

### Concreteness check

Every step must be concrete enough that a developer can follow it without
guessing. The step should reference language-specific constructs, types,
functions, or patterns.

The test: could a developer who knows the language but not the strategy
follow this step and produce correct code? If you're uncertain whether a
construct is idiomatic in this language, flag the step for user review
rather than guessing — a wrong idiom is worse than an honest question.

FAIL: "Iterate the test data through the test body." (This is the strategy
step repeated — not a guideline.)
PASS: "Range over the slice with `for _, tc := range tests`." (Concrete Go
code.)

### Divergence check

If a guideline step differs from its strategy step, a divergence must be
documented. The divergence must explain:
- Which strategy step it diverges from (by number and text)
- Why (language limitation, ecosystem convention, or better alternative)
- What the approach is and why it still serves the principle

FAIL: A guideline that silently uses a different approach from the strategy.
PASS: A divergence entry that explains the difference and traces back to the
principle.

### Guard candidacy check

Every guideline step must be assessed for guard candidacy. Steps that meet
the three criteria (binary, mechanizable, low false positives) are guard
candidates. Steps that don't are noted as requiring judgment.

FAIL: A guideline with no guard candidates section.
PASS: A guard candidates section that lists candidates with CHECK
descriptions, or explicitly states "None" with a reason.

### Layer check

Guidelines exist in the WHAT layer. Check for these common misplacements:

1. **Strategy disguised as guideline.** If the step is abstract and
   language-agnostic, it belongs in the strategy, not the guideline.
   FAIL: "Extract variations into data." (This is a strategy step.)
   FIX: The guideline step is "Define a test case struct with fields for
   name, inputs, and expected outputs."

2. **Guard disguised as guideline.** If the step is a pure mechanical check
   with zero judgment, it's a guard. Flag it as a guard candidate.
   FAIL: Including "run the linter" as a guideline step.
   FIX: The linter rule is a guard. The guideline step is the implementation
   pattern the linter checks for.

3. **Principle restated as guideline.** If the step says "why" instead of
   "what", it's the principle leaking down.
   FAIL: "Ensure tests don't contain conditional logic."
   FIX: The guideline step is the concrete technique: "Use `t.Run` for
   subtests."

## After approval

Once the user approves the guideline, complete these steps in order.

### 1. Verify prerequisites

Confirm the principle and strategy files exist:
- `principles/<principle-name>.md`
- `strategies/<strategy-name>.md`

If either is missing, stop and tell the user.

### 2. Uniqueness check

Check `implementation/<lang>/<strategy-name>/` for an existing
`guidelines.md`. If one exists:

- **Same strategy, same language** — This is an update, not a create. Use
  Update mode instead, or confirm the user wants to overwrite.
- **Different strategy, same principle** — Both can coexist in separate
  directories. This is fine.

### 3. Create the implementation directory

Create `implementation/<lang>/<strategy-name>/` if it doesn't exist. Use
kebab-case for the directory name matching the strategy file name.

### 4. Write the guideline file

Write the guideline to `implementation/<lang>/<strategy-name>/guidelines.md`.

### 5. Write divergences (if any)

If any divergences were identified, write them to
`implementation/<lang>/<strategy-name>/divergences.md`.

### 6. Create beads for guard candidates

For each guard candidate, create a beads issue with type `task` and
priority `3`. Title: "Design [language] guard: [check description]".
Description should reference the strategy name, guideline step number,
CHECK description, and the guideline file path.

### 7. Offer next steps

**Strategy discovery.** If during guideline creation you noticed the
abstract technique hasn't been documented as a strategy yet (entry point
#3 from the workflow), suggest creating it. Create a bead for
strategy-editor.

**New language.** If this is the first guideline for this language, tell
the user to add it to the supported languages table in `docs/WORKFLOW.md`
and `README.md`.

## Edge cases

- **Multiple strategies for one principle.** Create separate guideline
  directories for each strategy. They're independent implementations.
  `implementation/go/data-driven-test-cases/` and
  `implementation/go/property-based-testing/` can both exist.

- **No strategy exists and user declines to create one.** Question why
  there can be a guideline but no abstraction that's more generic. This seem
  to indicate not enough thought has gone into the strategy.

- **Strategy discovered during guideline creation.** If you realize the
  abstract technique hasn't been documented as a strategy yet, suggest
  creating it first. This is discovery entry point #3 from the workflow.
  Create a bead for strategy-editor.

- **Existing guidelines need updating.** When a strategy is updated, its
  guidelines may need updating too. Use the Update mode. Don't silently
  create a second guideline file.

- **Language has no equivalent construct.** If a strategy step fundamentally
  can't be implemented in the target language (not just differently — truly
  can't), this may mean the principle is not-applicable to this language.
  Use the Not-applicable mode and write the explanation file.

- **Judgment-only principles.** When a principle requires human judgment and
  its guidelines can't produce guard candidates, write guidelines normally.
  In the guard candidates section, state:
  ```
  GUARD CANDIDATES:
  None. This principle requires judgment to apply. [Brief explanation.]
  ```
  This is legitimate — not every guideline produces guards.

- **User wants to write a batch.** When creating guidelines for multiple
  strategies or languages, work through them one at a time. Don't try to
  produce many guidelines at once — quality drops. Present them individually
  for review.
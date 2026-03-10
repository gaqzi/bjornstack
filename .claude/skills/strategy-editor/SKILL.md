---
name: strategy-editor
description: >
  Write, review, and refine strategies — the HOW layer that bridges principles
  (WHY) to guidelines (WHAT). Use this skill whenever the user wants to create
  a new strategy, review or improve an existing strategy, convert a technique
  or best practice into a strategy, or check whether something belongs in the
  strategy layer vs. another layer. Also trigger when handed off from
  principle-editor, when the user describes a multi-step abstract technique,
  asks "how do I follow this principle?", "what's the approach for...",
  "what's the pattern for...", or mentions the strategy layer or HOW layer —
  even if they don't use the word "strategy" explicitly.
---

# Strategy Editor

Write, review, and refine strategies that bridge principles to guidelines.

**Strategies are an authoring tool, not a runtime artifact.** They are consumed
by guideline authors (human or AI) when creating language-specific guidelines —
they are not loaded into projects. Their purpose is to help express abstractly
*what the technique is* before getting pulled into the specifics of a target
language or stack. This matters for growth: when you add a second or third
language, the strategy ensures consistency across all guidelines derived from
it. Every principle gets a strategy.

Read `references/FORMAT.md` before proceeding. It defines the exact format and
explains why each part matters. Read `references/DIVERGENCE.md` when reviewing
a strategy or when evaluating whether steps are abstract enough for languages
to follow or diverge from cleanly.

## What you produce

Every strategy follows this exact structure:

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
SKIP WHEN: [When this specific strategy adds no value — when a different
strategy for the same principle is a better fit.]
```

No exceptions. If the output doesn't match this structure, revise until it does.

### Annotated example

This is what a complete strategy looks like and why each part works:

```
## Data-Driven Test Cases
```
Name: 3-word noun phrase. Works as shorthand.

```
PRINCIPLE: No Conditional Test Logic
```
Links to a real principle file in `principles/`.

```
1. Identify the variations — what changes between test cases?
2. Extract those variations into data: inputs, expected outputs,
   and case descriptions.
3. Write a single test body that operates on one case.
4. Have the framework iterate the data through that body.
5. Each case runs in isolation — a failure in one doesn't skip others.
```
5 steps. No language references. Each step is a distinct decision point —
you could pause between any two and hand off to someone else. The insight:
decompose variations into data and let the framework iterate. A motivated
but not-yet-senior engineer wouldn't necessarily arrive at this from the
principle alone.

```
OUTCOMES:
- Each test case failure is independently identifiable.
- The test body contains no branching logic.
- Adding a new case requires only adding data, not changing code.
```
3 outcomes, each checkable by looking at the result. Every outcome traces
back to the steps. Together they satisfy the principle.

```
MISAPPLICATION: A "table" that still contains conditional logic inside
the loop body, or where each row requires fundamentally different setup.
If the cases don't share a single code path, they aren't one strategy —
they're separate tests.
```
2 sentences. Specific enough to recognize in real code.

```
SKIP WHEN: Only one case exists. A single test function is fine.
```
Genuinely common case where a different strategy for the same principle
is a better fit (or the strategy simply doesn't apply to the situation).

## Modes

### Create

User describes a technique or provides a principle name. Produce a strategy.

The user often arrives with a principle and a loose collection of ideas —
things to watch for, habits that work, instincts about the right approach.
This isn't a strategy yet, it's raw material. Your job is to find the
technique hiding in it. Ask: "What's the sequence? When you follow this
principle well, what do you do first, then next?" The answers reveal the
steps. If the ideas don't form a sequence — they're just a list of tips —
they might be multiple strategies, or they might be guidelines rather than
a strategy.

1. Shape the raw material into a technique (see above)
2. Draft the strategy in the exact format
3. Run every quality check (see below)
4. If any check fails, revise and show the improved version
5. Present the final strategy with a brief note on any tradeoffs or
   judgment calls you made
6. Wait for user approval before writing. Do not proceed to the
   after-approval workflow until the user confirms.

### Review

User provides a draft strategy. Evaluate it against every quality check.
Lead with a summary: which checks pass, which fail. Then for each failure,
show the failing text, explain what's wrong, and provide a concrete rewrite.
If a fix to one part would ripple into others (e.g., changing a step affects
an outcome), call out the ripple explicitly.

### Extract

User provides prose docs, best practices, or technical descriptions. For each
distinct technique:

1. Decide if it's actually a strategy (vs. principle, guideline, or guard)
2. If it's a strategy, produce it in the format
3. If it's not, say what it is and why — suggest where it belongs instead.
   For principles, create a bead for principle-editor to handle separately.
   For guidelines, note which strategy they'd implement.

### Update

User wants to revise an existing strategy — because the principle evolved, a
guideline revealed a step doesn't translate, or experience showed a step is
wrong. Read the existing strategy file. Diff the proposed change against the
quality and coherence checks. Flag if the change breaks step-outcome tracing
or introduces language-specific content. After approval, update the file in
place.

### When triggered from principle-editor

The principle name is your starting point. If the principle-editor's layer
check caught a strategy disguised as a principle, the technique is already
in the conversation — extract it. Otherwise, ask the user what technique or
approach they have in mind for following the principle. Don't invent one
unprompted.

## Quality checks

Run every check on every strategy you produce or review. These are not
optional.

### Insight check

This is the most important check. A strategy encodes a technique that a
motivated but not-yet-senior engineer would need help arriving at from the
principle alone. The principle tells them *why* — the strategy shows them
*how* in a way they couldn't confidently figure out themselves. A senior
engineer might see the path; a staff engineer probably would. But the
strategy makes that path explicit and repeatable for everyone.

The test: would a capable engineer who believes in the principle still
struggle with *what to actually do*? If yes, the strategy is earning its
place. If the steps are just the principle rephrased as instructions, there's
no technique — delete the strategy.

EXAMPLE — restatement vs. strategy:

Restatement: Principle is "No Conditional Test Logic." Strategy steps are
"1. Don't use if statements in tests. 2. Don't use switch statements in
tests. 3. Keep test logic linear." These are just the principle repeated as
instructions. There's no technique here — an engineer reading the principle
could produce these steps on their own.

Strategy: Same principle, but the steps are "Identify the variations between
test cases. Extract them into data. Write a single test body. Have the
framework iterate." This is an actual technique — the insight is the
data-extraction decomposition. An engineer who's never done this before
wouldn't necessarily arrive here from the principle alone.

### Format checks

- **Name is a short noun phrase.** 2-4 words. It must work as a shorthand
  agents and humans can reference by name.
  FAIL: "How To Write Data-Driven Tests Using Tables."
  PASS: "Data-Driven Test Cases."

- **PRINCIPLE link references a real principle.** Flag during drafting if
  the principle doesn't exist in `principles/` yet — note it for the user
  but don't block the draft. The after-approval workflow will resolve this
  before writing.
  FAIL: `PRINCIPLE: Good Testing` (not a real principle file).
  PASS: `PRINCIPLE: No Conditional Test Logic` (exists in principles/).

- **Steps are numbered, abstract, and language-agnostic.** Steps describe
  a conceptual procedure, not language-specific code. No function names,
  no framework APIs, no syntax examples. If someone needs to know Go or
  Python to understand a step, it belongs in a guideline.
  FAIL: "3. Use `t.Run(name, func(t *testing.T) { ... })` for each case."
  PASS: "3. Write a single test body that operates on one case."

  Strategies typically have 3-7 steps. 1-2 steps suggests the content is
  really a principle. 8+ steps suggests a tutorial or a strategy that should
  be decomposed.

  Each step represents a distinct decision or phase transition. If two steps
  could be done simultaneously without choosing between them, collapse them.
  If one step requires making a choice and then acting on it, split it. The
  test: could you pause between steps and hand off to someone else? If yes,
  it's a real step boundary.

- **OUTCOMES are observable.** Each outcome is something you can check by
  looking at the result — not a vague aspiration. 2-4 outcomes is typical.
  One outcome suggests the strategy only does one thing — consider whether
  it's really a strategy. Five or more suggests the strategy is doing too
  much or the outcomes aren't at the right level of abstraction.
  FAIL: "Tests are more maintainable."
  PASS: "Adding a new case requires only adding data, not changing code."

- **MISAPPLICATION is realistic.** It describes what actually goes wrong
  when the strategy is applied badly or in the wrong context. Not a
  hypothetical — a pattern someone would recognize in real code. Unlike
  VIOLATION in principles (breaking a rule), MISAPPLICATION describes
  applying the strategy where it doesn't fit or over-engineering with it.
  1-3 sentences. Specific enough to recognize, concise enough to scan.
  FAIL: "Someone might use this wrong."
  PASS: "A 'table' that still contains conditional logic inside the loop
  body, or where each row requires fundamentally different setup."

- **SKIP WHEN is present and honest.** It states when this specific strategy
  is not the right fit — when a different strategy for the same principle
  applies, or when the situation doesn't call for this technique. This helps
  users choose between multiple strategies for the same principle.
  FAIL: (missing entirely)
  PASS: "Only one case exists. A single test function is fine."

### Layer check

Strategies exist in a four-layer system. Make sure the strategy is in the
right layer.

```
Principle    → WHY     One sentence + violations. Why something matters.     ← loaded into project
Strategy     → HOW     Numbered steps + outcomes. Abstract technique.        ← used when writing guidelines
Guideline    → WHAT    Language-specific implementation. What to do in Go.   ← loaded into project
Guard        → CHECK   Mechanical checks. Zero judgment. Linter rules.      ← loaded into project, runs automatically
```

Check for these common misplacements:

1. **Principle disguised as strategy.** If it can be said in one sentence
   with a violation example and doesn't need multiple steps, it's a
   principle. Strategies need space to describe a technique.
   FAIL: A strategy whose steps boil down to "just don't do the bad thing."
   FIX: Extract the one-sentence rule as a principle. The strategy is the
   technique for how to avoid it.

2. **Guideline disguised as strategy.** If any step references a specific
   language, framework, or tool, it's a guideline. Strategies are
   language-agnostic.
   FAIL: "4. Use `t.Run` to create subtests for each row."
   FIX: The strategy step is "Have the framework iterate the data through
   that body." The `t.Run` detail belongs in a Go guideline.

3. **Tutorial disguised as strategy.** If it includes background reading,
   motivation beyond the PRINCIPLE link, or learning context, it's a
   tutorial. Strategies describe *what to do conceptually*, not *how to
   learn it*.
   FAIL: A strategy that spends three steps explaining why the technique
   matters before getting to what to do.
   FIX: The "why" is the principle. The strategy starts at step 1 of the
   technique.

### Coherence check

These checks ensure the strategy hangs together as a whole.

1. **Steps follow from the principle.** Each step should be traceable to
   the principle it serves. If a step doesn't help achieve the principle,
   it doesn't belong.
   FAIL: A strategy for "No Conditional Test Logic" that includes a step
   about measuring code coverage — related to testing but doesn't serve
   the principle.

2. **Outcomes satisfy the principle.** If all outcomes are met, the
   principle should be satisfied. If there's a gap, add an outcome or
   question whether the strategy fully serves the principle.
   FAIL: Outcomes mention "no branching in tests" but don't mention
   independent failure identification — the principle isn't fully satisfied.

3. **Every outcome traces to a step, every step contributes to an outcome.**
   If an outcome doesn't trace back to any step, a step is missing. If a
   step doesn't contribute to any outcome, the step doesn't belong or an
   outcome is missing.

4. **Misapplication is realistic.** Someone reading the misapplication
   should think "yes, I've seen that" or "yes, I could imagine doing
   that." If it's contrived, rewrite it.
   FAIL: "Someone uses this for the wrong language" — too vague to
   recognize.

5. **Skip-when is honest.** It should describe a genuinely common case
   where this specific strategy is not the right fit — typically when a
   different strategy for the same principle applies, or the situation
   doesn't call for this technique. If the strategy is the only one for
   its principle, skip-when describes when the technique doesn't apply.
   FAIL: "When you don't have any tests" — dodges the question instead
   of describing when the strategy is the wrong choice.

## After approval

Once the user approves the strategy, complete these steps in order.

### 1. Uniqueness check

Glob `strategies/*.md` (excluding FORMAT.md and DIVERGENCE.md). For each
existing strategy, compare the name and principle link against the new one:

- **Name collision** — Same or nearly identical name. Resolve before writing.
- **Semantic overlap** — Different name but serves the same principle with
  the same technique. Show both to the user and ask: merge, differentiate,
  or abort?
- **Same principle, different technique** — This is fine. A single principle
  can have multiple strategies (independent and complementary approaches to
  solve the same WHY).

If no conflicts, proceed.

### 2. Verify the principle exists

Check that the principle referenced in the PRINCIPLE field exists in
`principles/`. If it doesn't:

- Ask the user if they want to create the principle first using
  principle-editor
- Or confirm this is a well-known principle that will be created separately

Don't write a strategy that points to a nonexistent principle without
acknowledgment.

### 3. Write the strategy file

Write the strategy to `strategies/<kebab-name>.md` using the exact format.
The filename uses the kebab-case version of the strategy name (e.g.,
"Data-Driven Test Cases" → `data-driven-test-cases.md`).

### 4. Offer guideline handoff

Check whether the strategy would benefit from a language-specific guideline.
Two signals:

1. **"How do I do this in Go/Python/etc?"** — The strategy's steps could be
   implemented differently per language. That implementation is a guideline.
2. **OUTCOMES suggest language-specific checks.** — An outcome like "each
   case runs in isolation" might map to `t.Run` in Go but `@parametrize`
   in Python.

**Always offer, never force.** Say something like:

> "This strategy could benefit from a guideline for [language]. Want to
> create one?"

If the user accepts, create a beads task with title "Create [language]
guideline for [Strategy Name]" and description that includes both the
strategy and principle names. If they decline, do nothing — they can create
it later.

Every strategy needs guidelines for each supported language. The guideline
is where the abstract technique becomes concrete and actionable.

## Edge cases

- **Multiple principles.** A strategy primarily serves one principle but
  may support others. Use the primary principle in the PRINCIPLE field.
  Mention secondary connections in the strategy description if useful, but
  don't over-link.

- **Strategy without a principle yet.** A technique that doesn't have a
  principle is a *discovery opportunity*, not an error. Ask: "What goes
  wrong if someone doesn't follow this technique?" The answer is the
  principle. Draft the strategy, then offer to hand *up* to
  principle-editor to articulate the WHY, by creating a bead linked 
  to this strategy. This is the reverse of the normal flow — 
  principle-editor usually hands down to strategy-editor — but discovering 
  principles from techniques is legitimate and common.

- **Multiple strategies for one principle.** Two patterns are common and
  both are legitimate:

  1. **Complementary techniques in the same domain.** "Data-Driven Test
     Cases" and "Property-Based Testing" both serve "No Conditional Test
     Logic" in tests. Sometimes you pick one, sometimes both. Each
     strategy's SKIP WHEN should clarify when to prefer it over the
     other — this is how users decide.

  2. **Same principle, different domains.** "Fail Loudly" might produce
     "Error Propagation" (application code: bubble errors, abort early)
     and "Fail-Fast Assertions" (tests: require over assert). These
     aren't competing — they're parallel applications of the same WHY
     in different contexts. Each strategy should name its domain clearly.

- **User wants to write a batch.** When converting a large document into
  strategies, work through them one at a time. Don't try to produce many
  strategies at once — quality drops. Present them in groups of 2-3 for
  review.
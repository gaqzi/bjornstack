---
name: principle-editor
description: >
  Write, review, and refine engineering principles in a structured format
  optimized for both humans and AI agents. Use this skill whenever the user
  wants to create a new principle, review or improve an existing principle,
  convert prose rules or ideas into principles, or check whether something
  qualifies as a principle vs. a guideline or guard. Also trigger when the
  user mentions AGENTS.md principles, CLAUDE.md principles, engineering
  tenets, or asks "is this a good principle?" — even if they don't use the
  word "principle" explicitly.
---

# Principle Editor

Write, review, and refine engineering principles that are clear to both humans
and AI agents.

Read `references/FORMAT.md` before proceeding. It defines the exact format and
explains why each part matters.

## What you produce

Every principle follows this exact structure:

```
## [Principle Name]
[One sentence: what the rule is.]
VIOLATION: [Concrete example of what wrong looks like.]
VIOLATION: [Optional — a second example that clarifies a borderline case.]
WHY: [One sentence: the mechanism — what goes wrong without it.]
```

No exceptions. If the output doesn't match this structure, revise until it does.

### Annotated example

This is what a complete principle looks like and why each part works:

```
## Coordinator/Logic Separation
```
Name: 3-word noun phrase. Works as shorthand — you can say "CLS violation"
and the agent knows exactly what you mean.

```
Objects either coordinate collaborators or perform business logic — never both.
```
One sentence. One period. If you need more, you have two principles hiding
in one. The em-dash signals the constraint boundary.

```
VIOLATION: A struct that calls external services AND contains conditional
business logic.
```
One concrete example. Someone looking at real code should be able to point at
it and say "that — that's the violation." This principle uses one violation
because the boundary is clear. Use a second violation only when it draws a
line that reasonable people would argue about (see "Boundary-clarifying
violations" in Edge cases).

```
WHY: Mixed objects are hard to test and obscure intent.
```
One sentence. States the mechanism — what breaks and how. Not "because mixing
is bad" (restates the rule) but "hard to test and obscure intent" (names the
consequences). The WHY should be short enough to remember but specific enough
to apply in novel situations.

## Modes

### Create

User describes a concept, rule, or constraint. Produce a principle.

The user often arrives with a vague rule, a frustration, or an instinct about
what matters. This isn't a principle yet — it's raw material. Your job is to
find the one-sentence constraint hiding in it. Ask: "What goes wrong when
this is violated?" The answer reveals the definition and WHY. If the answer
is "everything" or "it's just bad," help decompose into something observable.

1. Shape the raw input into a one-sentence constraint (see above)
2. Draft the principle in the exact format
3. Run every quality check (see below)
4. If any check fails, revise and show the improved version
5. Present the final principle with a brief note on any tradeoffs or
   judgment calls you made
6. Wait for user approval before writing. Do not proceed to the
   after-approval workflow until the user confirms.

### Review

User provides a draft principle. Evaluate it against every quality check.
Lead with a summary: which checks pass, which fail. Then for each failure,
show the failing text, explain what's wrong, and provide a concrete rewrite.
If a fix to one part would ripple into others (e.g., changing the definition
affects what counts as a violation), call out the ripple explicitly. Don't
just say "this could be improved" — show the improved version.

### Update

User wants to revise an existing principle — because a strategy revealed the
definition is too narrow, a guideline showed a violation doesn't cover a real
case, or experience proved the WHY is wrong. Read the existing principle file.
Diff the proposed change against the quality checks. Flag if the change would
invalidate existing strategies that reference this principle. After approval,
update the file in place.

### Extract

User provides prose rules, a document, or a list of ideas. For each
distinct concept:

1. Decide if it's actually a principle (vs. strategy, guideline, guard, or
   aspiration)
2. If it's a principle, produce it in the format
3. If it's not, say what it is and why — then create a bead to route it
   to the right layer:
   - Strategy → bead for strategy-editor (include the principle it serves)
   - Guideline → bead for guidelines-editor (include which strategy it
     implements and which language)
   - Guard → bead for guard-designer (include which guideline step it checks)

## Quality checks

Run every check on every principle you produce or review. These are not
optional.

### Format checks

- **Name is a short noun phrase.** 2-4 words. It must work as a shorthand
  agents and humans can invoke by name ("ZFC violation!", "GUPP violation!").
  FAIL: "We Should Always Separate Coordination From Logic."
  PASS: "Coordinator/Logic Separation."

- **Definition is exactly one sentence.** One period. If you need more, you
  have two principles hiding in one. Split them.
  FAIL: "Objects either coordinate or perform logic. They should never do
  both because it makes testing hard."
  PASS: "Objects either coordinate collaborators or perform business logic —
  never both."

- **Violation is a concrete, recognizable example.** Not abstract. Someone
  looking at real code or a real design should be able to point at it and
  say "that — that's the violation." 1-2 sentences. Most principles need
  one violation. Use a second only when it draws a boundary that reasonable
  people would argue about — it encodes the designer's judgment about where
  the line sits. If the two violations describe genuinely different failure
  modes (each needing its own WHY), you have two principles — split them.
  FAIL: "Code that doesn't follow the principle."
  PASS: "A struct that calls external services AND contains conditional
  business logic."

- **Why states the mechanism.** It explains what breaks and how — not just
  that something is "bad" or restates the rule in different words. One
  sentence. Short enough to remember, specific enough to apply in novel
  situations. Name consequences, not feelings.
  FAIL: "Because mixing coordination and logic is wrong."
  PASS: "Mixed objects are hard to test and obscure intent."

### Actionability check

This is the most important check. A principle must be actionable — there
must be at least one clear way to follow it, even if that way requires
judgment.

Ask two questions:

1. **Can the violation be detected?** Could an agent or human look at
   current code or design and recognize "this is happening right now"?
   If detection requires omniscience (e.g., "this will cause a bug in
   production"), the principle needs to be decomposed into something
   observable.

2. **Can the violation be avoided by changing a specific behavior?**
   There must be at least one concrete thing you could do differently.
   Not necessarily spelled out in the principle — that's what guidelines
   are for — but the principle must point toward action, not just toward
   wishing.

The quick test: "If an agent violated this, could you point at the specific
thing they did wrong and describe what they should have done instead?"

- If yes → principle.
- If the answer is "they should have just been better" → aspiration, not
  a principle. Reject it and help decompose it into something observable.

EXAMPLE — aspiration vs. principle:

Aspiration: "We don't release buggy code."
Why it fails: no one can look at their work and know what to do differently.
Detection requires knowing the future. There's no specific behavior to change.

Decomposed into real principles:
- "Test-Driven Boundaries" — Every public API boundary has tests that
  exercise its contract before the implementation is considered complete.
- "No Blind Deploys" — Every deployment is preceded by automated checks
  that gate the release on passing tests and health signals.

### Layer check

Principles exist in a four-layer system. Make sure the principle is in the
right layer.

- **Principles** — WHY: high-level, language-agnostic constraints that encode
  *why* something matters. They require judgment to apply.
- **Strategies** — HOW: abstract, language-agnostic techniques that bridge
  a principle to a guideline. They describe a conceptual recipe.
- **Guidelines** — WHAT: tactical, language-specific implementation steps.
  They tell you what to do concretely to follow a principle or strategy.
- **Guards** — CHECK: mechanical checks with zero judgment — linter rules,
  CI gates. They reject, they don't advise.

Check for these common misplacements:

1. **Guideline disguised as principle.** If it prescribes specific steps
   or references a specific language/framework, it's a guideline. Nudge
   the user to promote the *why* behind it into the principle.
   FAIL: "Use table-driven tests when you have multiple input cases."
   FIX: The principle is "No Conditional Test Logic." The table-driven
   approach is a guideline that implements it.

2. **Strategy disguised as principle.** If it describes a multi-step
   technique without language specifics, it's a strategy, not a principle.
   Principles are one sentence. Strategies need space for steps.
   FAIL: "Identify variations, extract to data, write one test body,
   iterate."
   FIX: The principle is "No Conditional Test Logic." The technique is a
   strategy called "Data-Driven Test Cases."

3. **Guard disguised as principle.** If it can be checked mechanically
   with zero human judgment, it's a guard. It belongs in a linter or CI.
   FAIL: "No if statements in test bodies."
   FIX: This is a guard (linter rule). The principle behind it is
   "No Conditional Test Logic" — the *why* is that conditionals in tests
   hide which case failed and make tests act as multiple tests in a
   trenchcoat.

4. **Language-specific principle.** Principles are language-agnostic. If
   the principle references Go interfaces, TypeScript generics, or any
   language-specific construct, abstract up. Language-specific
   implementation belongs in guidelines.
   FAIL: "All Go interfaces must be defined by the consumer."
   FIX: "Consumer-Defined Contracts" — Abstractions are defined by the
   code that depends on them, not the code that implements them.

## After approval

Once the user approves the principle, complete these steps in order.

### 1. Uniqueness check

Glob `principles/*.md` (excluding FORMAT.md). For each existing principle,
compare the name and definition against the new one:

- **Name collision** — Same or nearly identical name. Resolve before writing.
- **Semantic overlap** — Different name but the definition covers the same
  constraint. Show both to the user and ask: merge, differentiate, or abort?

If no conflicts, proceed.

### 2. Write the principle file

Write the principle to `principles/<kebab-name>.md` using the exact format
from FORMAT.md. The filename uses the kebab-case version of the principle
name (e.g., "No Conditional Test Logic" → `no-conditional-test-logic.md`).

### 3. Offer strategy handoff

Check whether the principle would benefit from a strategy. Two signals:

1. **"So what do I do instead?"** — The principle says "don't do X" and the
   natural follow-up is how to avoid it. That technique is a strategy.
2. **Layer check caught a strategy.** — You identified a multi-step technique
   disguised as a principle. After extracting the real principle, offer to
   create the technique as a strategy.

**Always offer, never force.** Say something like:

> "This principle could benefit from a strategy that describes how to follow
> it. Want to create one?"

If the user accepts, create a beads task to create the strategy using
the strategy-editor with the principle name pre-filled. If they decline,
do nothing — they can create it later.

Not every principle needs a strategy. Some principles stand alone because
the "how" is obvious or context-dependent.

## Edge cases

- **Principle requires judgment and that's fine.** Not every principle needs
  to become a guideline or guard. Some principles stay principles forever
  because the check can't be mechanized. That's legitimate. The test is
  actionability, not mechanizability.

- **Boundary-clarifying violations.** A second violation example is useful
  when it draws a line that reasonable people could argue about. It encodes
  the designer's judgment about where the boundary sits. But if the
  violations describe genuinely different failure modes, that's a sign you
  have two principles. The test: do both violations fail for the same *why*?
  If yes, keep them together. If each needs its own *why*, split.

- **User wants to write a batch.** When converting a large document into
  principles, work through them one at a time. Don't try to produce 15
  principles at once — quality drops. Present them in groups of 3-5 for
  review.

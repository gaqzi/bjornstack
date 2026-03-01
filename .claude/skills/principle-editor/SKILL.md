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

## Modes

### Create

User describes a concept, rule, or constraint. Produce a principle.

1. Draft the principle in the exact format
2. Run every quality check (see below)
3. If any check fails, revise and show the improved version
4. Present the final principle with a brief note on any tradeoffs or
   judgment calls you made

### Review

User provides a draft principle. Evaluate it against every quality check.
For each failure, explain what's wrong and offer a concrete rewrite.
Don't just say "this could be improved"; show the improved version.

### Extract

User provides prose rules, a document, or a list of ideas. For each
distinct concept:

1. Decide if it's actually a principle (vs. guideline, guard, or aspiration)
2. If it's a principle, produce it in the format
3. If it's not, say what it is and why — suggest where it belongs instead

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
  say "that — that's the violation."
  FAIL: "Code that doesn't follow the principle."
  PASS: "A struct that calls external services AND contains conditional
  business logic."

- **Why states the mechanism.** It explains what breaks and how — not just
  that something is "bad" or restates the rule in different words.
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

Principles exist in a three-layer system. Make sure the principle is in the
right layer.

- **Principles** are high-level, language-agnostic constraints that encode
  *why* something matters. They require judgment to apply.
- **Guidelines** are tactical, language-specific implementation steps. They
  tell you *how* to follow a principle.
- **Guards** are mechanical checks with zero judgment — linter rules, CI
  gates. They reject, they don't advise.

Check for two common misplacements:

1. **Guideline disguised as principle.** If it prescribes specific steps
   or references a specific language/framework, it's a guideline. Nudge
   the user to promote the *why* behind it into the principle.
   FAIL: "Use table-driven tests when you have multiple input cases."
   FIX: The principle is "No Conditional Test Logic." The table-driven
   approach is a guideline that implements it.

2. **Guard disguised as principle.** If it can be checked mechanically
   with zero human judgment, it's a guard. It belongs in a linter or CI.
   FAIL: "No if statements in test bodies."
   FIX: This is a guard (linter rule). The principle behind it is
   "No Conditional Test Logic" — the *why* is that conditionals in tests
   hide which case failed and make tests act as multiple tests in a
   trenchcoat.

3. **Language-specific principle.** Principles are language-agnostic. If
   the principle references Go interfaces, TypeScript generics, or any
   language-specific construct, abstract up. Language-specific
   implementation belongs in guidelines.
   FAIL: "All Go interfaces must be defined by the consumer."
   FIX: "Consumer-Defined Contracts" — Abstractions are defined by the
   code that depends on them, not the code that implements them.

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

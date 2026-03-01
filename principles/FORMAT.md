# How to Write Principles

Principles are not prose rules or tutorials. They are named concepts with a
tight definition, a violation example, and a one-line why.

## Format

```
## [Principle Name]
[One sentence: what the rule is.]
VIOLATION: [Concrete example of what wrong looks like.]
WHY: [One sentence: the mechanism, what goes wrong without it.]
```

## Example

```
## Coordinator/Logic Separation
Objects either coordinate collaborators or perform business logic, never both.
VIOLATION: A struct that calls external services AND contains conditional business logic.
WHY: Mixed objects are hard to test and obscure intent.
```

## Why this format works

- The **name** gives agents a shorthand. You can say "ZFC violation" and the
  agent knows exactly what you mean without re-reading the rule.
- The **definition** is one sentence because if you can't say it in one
  sentence, you don't understand the principle yet.
- The **violation example** is the most important part, it gives the agent a
  pattern to recognize, not just a rule to memorize.
- The **why** encodes the mechanism, so agents can apply the principle in novel
  situations rather than just pattern-matching on familiar ones.

## What principles are NOT

- Tactical implementation rules (e.g. "use `require` over `assert`"), these
  belong in guidelines or guards, not principles.
- Tutorials or background reading, agents don't need context, they need
  constraints.
- Long prose, length is not depth. If a principle needs three paragraphs, it's
  probably two principles.

## Source

Informed by Steve Yegge's Gas Town/Beads approach: named principles (GUPP,
ZFC, MEOW) with terse definitions that agents invoke by name. The violation
example format is our own addition based on what makes principles actionable
rather than decorative.

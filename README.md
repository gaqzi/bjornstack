# bjornstack

My attempt at trusting the code AI agents produce.

bjornstack is engineering judgment as code. It decomposes the standards you'd
normally keep in your head into four layers, principles (WHY), strategies
(HOW), guidelines (WHAT), and guards (CHECK), so both humans and AI agents
can follow them as protocols. The goal isn't removing human review, it's shrinking the effort of review
by making the output more cohesive and constrained from the start.

Think engineering manifesto with teeth.

I haven't solved trustworthy code. This is the experiment. The idea is that if
I make my standards explicit and enforceable enough, agents produce code that's
closer to what I'd write myself, and the review becomes "does this look right?"
instead of "what did it do and why?"

This is how *I* build software. You'll probably disagree with some of it.
That's the point, fork it, replace my opinions with yours, and you've got
your own stack. Mine is shortened to `bs` for a reason.

## Why this exists

AI agents write most of my code now. And I'm still reviewing the code because
I don't trust it, and [constraints are the path to trust][vc], so I create them to give
agents fewer options and therefore higher likelihood of doing what I want. Without explicit standards, I get
code that works but I *maybe* trust, and code I don't fully trust is code
I have to re-read, re-verify, and eventually rewrite.

[vc]: https://bjorn.now/crumb/2026-02-26-how-steve-yegge-gets-quality-when-vibing/

bjornstack makes my standards explicit, layered, and enforceable:

- **Principles** — WHY: what matters and why
- **Strategies** — HOW: abstract, language-agnostic techniques
- **Guidelines** — WHAT: language-specific implementation steps
- **Guards** — CHECK: mechanical enforcement, no judgment required

The difference from a typical engineering standards doc is the focus on
mechanical enforcement. An agent will follow the same steps time after time. A human won't.

The upfront work of writing principles, strategies, and guidelines exists so
you don't have to re-derive the reasoning every time. When a decision needs
revisiting, you trace back to the rationale and evaluate from first
principles, not from memory, nor from "we've always done it this way." As a
colleague liked to say, "the job is to optimize for 'thanks, past self.'"

## What this is for

The principles here all come from trying to achieve these outcomes:

- **Deliver stable software, faster** — the right constraints and automation
  help avoid mistakes, and having them in place lets you adapt when
  circumstances change instead of being locked into long development cycles.

- **Limit the impact of incidents** — when something goes wrong (and it will),
  the blast radius is small, the signals are there, and the rollback is cheap.
  The litmus test: can an operator at 3am bring the system back to healthy
  without remembering edge cases or reading source code? If the system is
  clear enough to operate under pressure — names mean what they say, signals
  show what's broken, recovery doesn't require heroics — then the design is
  doing its job. Principles like
  [No Shared Fate](principles/no-shared-fate.md),
  [Don't Fly Blind](principles/dont-fly-blind.md), and
  [Many More Much Smaller Steps](principles/many-more-much-smaller-steps.md)
  work together to make incidents survivable rather than catastrophic.

## The four layers

### Principles — WHY

High-level constraints that encode *why* something matters. Language-agnostic.

Each principle has a name, a one-sentence definition, a violation example, and
a why. The name gives agents (and humans) a shorthand. The violation example
is the most important part, it shows you what *wrong* looks like so you can
spot it.

See [principles/FORMAT.md](principles/FORMAT.md) for the full format spec.

### Strategies — HOW

The abstract, language-agnostic technique that makes a principle actionable.
Strategies describe a technique step-by-step in an idealized setting, without
language-specific constraints. Most principles get one.

**Strategies are an authoring tool, not a runtime artifact.** They are consumed
by guideline authors (human or AI) when creating language-specific guidelines.
They are not loaded into projects. Their purpose is to help you express
abstractly *what the technique is* before getting pulled into the specifics of
a target language or stack. This matters for growth — when you add a second or
third language, the strategy ensures consistency across all guidelines derived
from it.

See [strategies/FORMAT.md](strategies/FORMAT.md) for the full format spec.

### Guidelines — WHAT

Tactical implementation steps for when principles alone aren't enough to act on.
Guidelines are language-specific, the same principle (and strategy) looks
different in Go vs. TypeScript.

Procedural steps to achieve a principle. Not necessarily the _only way_ but a
way. Usually followed without thought as the "golden path" until a better
approach is tested and validated. If there are multiple known valid ways,
a rubric exists to decide approach first.

When a guideline can't follow a strategy due to language limitations or
ecosystem conventions, it documents the divergence. See
[strategies/DIVERGENCE.md](strategies/DIVERGENCE.md).

### Guards — CHECK

Mechanical checks that block violations before they land. If there's no wiggle
room, it's a guard, implemented as linter rules, CI checks, or other automated
gatekeepers. Guards don't advise, they reject. The `// nolint` escape hatch
exists but should be exceedingly rare.

If you've read Building Evolutionary Architectures, these are
[fitness functions](https://www.thoughtworks.com/insights/books/building-evolutionaryarchitectures-second-edition),
automated integrity checks that protect specific properties of the codebase.
Linter rules are one implementation. The layer could grow to include other
automated checks over time.

## How things move between layers

Principles are discovered first. When a principle needs an abstract technique
to be actionable, it becomes a strategy. When a strategy needs language-specific
steps, it becomes a guideline. When a guideline can be checked with zero human
judgment, it becomes a guard.

```
Principle    → WHY     "Tests must not contain conditional logic"        ← loaded into project
Strategy     → HOW     Data-Driven Test Cases (the abstract technique)   ← used when writing guidelines
Guideline    → WHAT    Go: table-driven tests with t.Run subtests        ← loaded into project
Guard        → CHECK   testnoifs linter: rejects if/switch in tests      ← loaded into project, runs automatically
```

Principles flow through strategies to guidelines for each target language. Not
everything reaches the guard layer — some guidelines require judgment and can't
be mechanized. And some principles are pure judgment calls that stay principles
without strategies or guidelines. But when a principle can be made into a
repeatable technique, the path is always principle → strategy → guideline.

## Language support

| Language   | Status      |
|------------|-------------|
| Go         | In progress |

Principles and strategies are shared across all languages. Guidelines and
guards are language-specific.

## Installation

Installation tooling is planned. For now, copy what you need.

```bash
# planned:
bs install go
```

<!--
## Planned guards (Go)

- **testnoifs**, no `if` statements in test bodies
- **testifyonlyrequire**, use `require` over `assert` (fail fast, don't
  accumulate errors)
- **remembrall**, dynamic nudges for things that must change together
- **typedecl**, keep type invariants true through changes
-->

## License

This work is licensed under [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/).

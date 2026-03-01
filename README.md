# bjornstack

My attempt at trusting the code AI agents produce.

bjornstack is a layered system of coding standards, principles, implementation
guidelines, and automated guards, that you can install into a project.
It's an engineering manifesto with teeth. Readable by humans, executable by
AI agents, guarded by linters.

I haven't solved trustworthy code. This is the experiment. The idea is that if
I make my standards explicit and enforceable enough, I can stop re-reading
everything agents write and start trusting the output. That's the theory,
anyway.

This is how *I* build software. You'll probably disagree with some of it.
That's the point, fork it, replace my opinions with yours, and you've got
your own stack.

## Why this exists

AI agents write most of my code now. And I'm still reviewing the code because
I don't trust it, and [the way to get there][vc] is to create constraints so
they're likely to do what I want. Without explicit standards, I get
code that works but that I *maybe* trust, and code I don't fully trust is code
I have to re-read, re-verify, and eventually rewrite.

[vc]: https://bjorn.now/crumb/2026-02-26-how-steve-yegge-gets-quality-when-vibing/

bjornstack makes my standards explicit, layered, and enforceable:

- **Principles** constrain and express how we design our system,
  what is important to us, and why
- **Guidelines** are derived from principles and give us step-by-step
  instructions for implementation
- **Guards** flow from principles and block violations mechanically,
  no judgment required

Think engineering manifesto, standards, tenets, etc. that you'd see in any
organization, just made to be well-understood by agents too. And a stronger
focus on mechanistic enforcement through agents or linters. Because the
agent will follow the same steps time after time where a human loses focus.

## The three layers

### Principles

High-level constraints that encode *why* something matters. Language-agnostic.

Each principle has a name, a one-sentence definition, a violation example, and
a why. The name gives agents (and humans) a shorthand. The violation example
is the most important part, it shows you what *wrong* looks like so you can
spot it.

See [principles/FORMAT.md](principles/FORMAT.md) for the full format spec.

### Guidelines

Tactical implementation steps for when principles alone aren't enough to act on.
Guidelines are language-specific, the same principle looks different in Go
vs. TypeScript.

Procedural steps to achieve a principle. Not necessarily the _only way_ but a
way. Usually followed without thought as the "golden path" until a better
approach is tested and validated. If there are multiple known valid ways,
a rubric exists to decide approach first.

### Guards

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

Principles are discovered first. When a principle needs more specificity to be
actionable, it becomes a guideline. When a guideline can be checked with zero
human judgment, it becomes a guard.

```
Principle    → "Tests must not contain conditional logic"
Guideline    → How to restructure a test with ifs into table-driven tests
               or separate test functions
Guard        → testnoifs linter: mechanically rejects if in test bodies
```

Not everything moves down. Some principles stay principles because they require
judgment. Some guidelines never become guards because the check can't be
mechanized.

## Language support

| Language   | Status      |
|------------|-------------|
| Go         | In progress |

Principles are shared across all languages. Guidelines and guards are
language-specific.

## Installation

Installation tooling is planned. For now, copy what you need.

```bash
# planned:
bs install go
```

## Planned guards (Go)

- **testnoifs**, no `if` statements in test bodies
- **testifyonlyrequire**, use `require` over `assert` (fail fast, don't
  accumulate errors)
- **remembrall**, dynamic nudges for things that must change together
- **typedecl**, keep type invariants true through changes

# bjornstack Workflow

How to work with the four-layer system: creating principles, strategies,
guidelines, and guards, and how the editor skills connect them.

## The four layers

```
Principle    → WHY     "Tests must not contain conditional logic"
Strategy     → HOW     Data-Driven Test Cases (the abstract technique)
Guideline    → WHAT    Go: table-driven tests with t.Run subtests
Guard        → CHECK   testnoifs linter: rejects if in test bodies
```

Each layer has a different purpose:

- **Principles** (WHY) — High-level, language-agnostic constraints. One
  sentence, a violation example, a why. They encode *why* something matters.
- **Strategies** (HOW) — Abstract, language-agnostic techniques. Numbered
  steps, observable outcomes, misapplication notes. They bridge a principle
  to a guideline without referencing any language.
- **Guidelines** (WHAT) — Tactical, language-specific implementation. They
  tell you what to do concretely in language X to follow a principle or
  strategy.
- **Guards** (CHECK) — Mechanical checks with zero judgment. Linter rules,
  CI gates. They reject, they don't advise.

Not everything moves through all four layers. Some principles stay 
principles because they require judgment. Some guidelines never become
guards because the check can't be mechanized.

## File organization

```
principles/
  FORMAT.md                          # How to write principles
  <principle-name>.md                # Individual principle files

strategies/
  FORMAT.md                          # How to write strategies
  DIVERGENCE.md                      # When guidelines diverge from strategies
  <strategy-name>.md                 # Individual strategy files

implementation/
  <lang>/                            # e.g. go/, typescript/
    <principle-or-strategy-name>/
      guidelines.md                  # Language-specific implementation steps
      divergences.md                 # Where this language diverges from strategy

script/
  audit-principles                   # Scans for gaps (planned)
```

Filenames use kebab-case: `no-conditional-test-logic.md`,
`data-driven-test-cases.md`.

## Supported languages

| Language   | Status      |
|------------|-------------|
| Go         | In progress |

Principles and strategies are shared across all languages. Guidelines and
guards are language-specific.

### Adding a new language

1. Create `implementation/<lang>/` directory.
2. For each principle that has guidelines, create
   `implementation/<lang>/<name>/guidelines.md`.
3. If a guideline diverges from a strategy, add `divergences.md` in the same
   directory. Use the format in `strategies/DIVERGENCE.md`.
4. Add the language to the table above and in `README.md`.
5. Run the audit script to check for gaps.

## The editor skills

Three editor skills drive the pipeline. Each is a separate Claude Code skill
that can be invoked independently.

| Skill              | Layer      | Invocation         |
|--------------------|------------|--------------------|
| principle-editor   | Principles | `/principle-editor`|
| strategy-editor    | Strategies | `/strategy-editor` |
| guidelines-editor  | Guidelines | `/guidelines-editor`|

### Separate skills, optional handoff

The editors are **not** a wizard or pipeline. They can each be invoked
independently. After completing work in one layer, the skill **offers** to hand
off to the next layer. The user can accept, decline, or note it for later.

Why separate:

- **Single responsibility.** Each skill does one thing well. The quality
  checks, format rules, and mental model are different per layer.
- **Batch workflows.** You might define five principles in a session, then
  come back for strategies later. A mandatory pipeline blocks that.
- **Quality.** Creating a good principle demands focus. Forcing an immediate
  pivot to strategy mode risks half-baked strategies.

### How work flows between skills

#### principle-editor → strategy-editor

**When:** After creating or reviewing a principle, if the principle needs a
non-obvious technique to follow.

**Signals:**

- The principle says "don't do X" and the natural response is "so what do I do
  instead?" — the answer is a strategy.
- The layer check caught a strategy disguised as a principle. After extracting
  the real principle, the technique becomes a strategy.

**Offer:** *"This principle could benefit from a strategy. Want to create one?"*

If accepted, invoke strategy-editor with the principle name pre-filled.

#### strategy-editor → guidelines-editor

**When:** After creating a strategy, if language-specific implementation would
be non-trivial.

**Signal:** The strategy's steps could be implemented differently per language,
or the outcomes suggest language-specific checks.

**Offer:** *"Want to create a guideline that implements this strategy in
[language]?"*

If accepted, invoke guidelines-editor with the strategy and principle
pre-filled.

#### guidelines-editor → guard definition

**When:** After creating a guideline, if any step can be checked mechanically
with zero judgment.

**Signal:** A guideline step is a binary check — it either passes or fails,
no context needed.

**Offer:** *"This guideline step could be enforced as a guard. Want to define
one?"*

### How strategies are discovered

Strategies emerge from three entry points:

1. **During principle creation.** The principle-editor's layer check may catch
   a strategy disguised as a principle, or the principle may naturally suggest
   "how do I follow this?" — both lead to strategy work.

2. **Explicit request.** The user directly invokes the strategy-editor with a
   principle name or technique description.

3. **During guideline creation.** The guidelines-editor discovers that the
   abstract technique it implements hasn't been documented as a strategy yet.
   It suggests creating the strategy first (suggestion, not blocker).

## The audit script

`script/audit-principles` scans the file system for gaps. It checks:

1. **Missing strategies.** Every principle that would benefit from a strategy
   has one in `strategies/`.
2. **Missing guidelines.** Every principle × supported language has guidelines
   in `implementation/<lang>/<name>/`.
3. **Stale guidelines.** No guideline file is stale relative to its strategy
   (compares modification times).
4. **Undocumented divergences.** If a guideline diverges from a strategy, a
   `divergences.md` file exists.

The audit reports gaps clearly and can optionally create beads issues for them.

## Guard candidates

Not every guideline step becomes a guard. A step is a **guard candidate** when:

- The check is binary — it passes or fails with no judgment required.
- The check can be mechanized — a linter, CI gate, or script can detect it.
- False positives are rare enough that `// nolint` escapes stay exceptional.

Guard candidates are identified during guideline creation. The guidelines-editor
flags them and offers to define a guard. Candidates that aren't implemented yet
are tracked as beads issues.

## Judgment-only principles

Some principles require human judgment and will never become guards. That's
legitimate. The test is **actionability**, not **mechanizability**:

- Can someone look at code and recognize a violation? → Actionable.
- Can they describe what should have been done differently? → Actionable.
- Does following it require omniscience or predicting the future? → Not a
  principle, decompose it.

Judgment-only principles stay in the principles layer. They may have strategies
and guidelines, but those guidelines won't produce guards.

## Not-applicable handling

Not every principle applies to every language. When a principle is genuinely
not applicable to a language:

- Don't create empty guideline files.
- The audit script skips known not-applicable combinations.
- Document the reason in the principle file or in a project-level configuration
  if the pattern recurs.
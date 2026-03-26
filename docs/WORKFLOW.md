# bjornstack Workflow

How to work with the four-layer system: creating principles, strategies,
protocols, and guards, and how the editor skills connect them.

## The four layers

```
Principle    → WHY     "Tests must not contain conditional logic"
Strategy     → HOW     Data-Driven Test Cases (the abstract technique)
Protocol     → WHAT    Go design protocol: table-driven tests with t.Run subtests
Guard        → CHECK   testnoifs linter: rejects if in test bodies
```

Each layer has a different purpose:

- **Principles** (WHY) — High-level, language-agnostic constraints. One
  sentence, violations, a why. They encode *why* something matters.
- **Strategies** (HOW) — Abstract, language-agnostic techniques. Numbered
  steps, observable outcomes, misapplications. They bridge a principle
  to actionable technique without referencing any language.
- **Protocols** (WHAT) — Stage-based workflows that compose principles and
  strategies into step-by-step decision trees for design, implementation,
  and review. Generated from the layers above plus language configuration.
  Deviate at your own risk.
- **Guards** (CHECK) — Mechanical checks with zero judgment. Linter rules,
  CI gates. They reject, they don't advise.

Not everything moves through all four layers. Some principles stay
principles because they require judgment. Some protocol steps never become
guards because the check can't be mechanized.

## Design theory: boundary-based constraints

The system is built on a guiding theory we're testing: constraining by
defining what's wrong works better than prescribing what's right.

**Violations define the boundary, not the interior.** Good implementations
take many forms — the system doesn't enumerate them. Instead, principles list
failure modes (VIOLATIONS) and strategies list misuse patterns
(MISAPPLICATIONS). Everything that doesn't cross those boundaries is allowed.
This is a laws-not-prescriptions model: define what's prohibited, leave the
rest open.

**Three components work together:**

- **Violations / misapplications** — the boundary. Pattern-recognition
  targets that an agent scanning code should recognize: "that is the
  violation." Each must be a distinct failure mode. When a failure mode
  benefits from concrete instances, sub-bullets under an `Examples:` label
  make it recognizable without being exhaustive.
- **WHY mechanism** — the generalization. Encodes the causal reasoning so
  agents can apply the principle to situations no violation example
  anticipated. Violations calibrate the boundary; WHY generalizes beyond it.
- **Strategies and protocols** — the thinking process. Strategy steps and
  protocol decision trees guide how to approach the problem, not what the
  output should look like. An agent following "identify variations, extract
  to data, write one body, iterate" will arrive at different implementations
  depending on language and context. The technique is prescribed; the
  artifact is not. An agent that finds a novel approach violating no
  principles is free to take it.

**Why not positive examples?** Positive examples prescribe output — "make it
look like this." The system deliberately avoids that. Strategies and protocols
prescribe technique and thinking process — "approach it this way" — which
guides without constraining the solution space. An agent given examples of
"good code" tends to interpolate between them rather than reasoning from the
constraint. An agent given a thinking process derives its own solutions.

**Why "misapplications" in strategies, not "violations"?** You *violate* a
principle — you broke a constraint. You *misapply* a strategy — you used a
technique badly or in the wrong context. The terms reflect the different
relationship: principles are laws, strategies are tools. The format is
consistent (both use bulleted lists); the naming is deliberately different.

This is a theory, not proven truth. We believe boundary-based constraints
combined with structured thinking processes leave agents more room to find
novel solutions than output-based guidance would. Protocols haven't been
generated yet — strategy steps and outcomes currently carry the
thinking-process layer. If we discover the theory doesn't hold, the format
evolves.

## How protocols work

Protocols are **generated artifacts**, compiled from principles, strategies,
and language configuration. They are not hand-maintained documents. When an
input changes — a strategy is refined, a principle is added, a language
config is updated — the protocols are regenerated.

This matters for scale. With 9 principles, 18 strategies, and multiple
target languages, hand-maintaining per-strategy documents per language
creates a combinatorial maintenance burden. Generated protocols keep the
intellectual work in the input layers (principles and strategies) where it
belongs.

### Three stage protocols

Protocols are organized by **workflow stage**, not by strategy. Instead of
a separate document for each strategy in each language, protocols compose
multiple strategies into a coherent workflow for each stage of development:

- **Design protocol** — Collaborative discovery. The agent facilitates, asks
  questions, and applies principles in sequence to identify domains, classify
  components, name concepts, and plan increments. Strategies provide
  acceptance criteria for the design, not execution steps.
- **Implementation protocol** — Execution against a design. The agent follows
  the agreed design, writes code, and applies strategies as concrete steps.
  Language configuration provides tooling preferences.
- **Review protocol** — Evaluation against criteria. The agent checks work
  against strategy outcomes and identifies guard candidates.

Each stage has distinct **agent behavior expectations**:

| Stage          | Agent behavior     | Content loaded                          |
|----------------|--------------------|-----------------------------------------|
| Design         | Facilitate, ask    | Principles (as questions), strategy rationale |
| Implementation | Execute, follow    | Strategy steps, language config          |
| Review         | Evaluate, check    | Strategy outcomes, guard candidates      |

### Coordinator and subagent pattern

Protocols use a **coordinator + subagent** architecture:

- The **coordinator** (the agent the human interacts with) holds the
  protocol — the ordering, the questions to ask, the decision tree. It does
  not load principle or strategy content directly. Its job is orchestration
  and synthesis.
- **Subagents** are spawned for deep analysis. Each subagent is loaded with
  a specific principle and its relevant strategies, focused on one analytical
  task. Results flow back to the coordinator for synthesis and presentation
  to the human.

Why this separation:

- **Mode enforcement is structural.** The coordinator can't drift into
  delivery mode because it doesn't have detailed content loaded — its job is
  to direct, not to produce.
- **Context stays clean.** The human-facing conversation isn't polluted with
  thousands of tokens of principle and strategy text. The coordinator
  presents synthesized findings.
- **Each subagent gets focused context.** A subagent loaded with one
  principle and two strategies has ideal conditions for deep analysis.

The delegation pattern varies by stage:

- **Design**: Mostly sequential — each principle's output feeds the next.
  The coordinator facilitates discussion between each subagent's analysis.
- **Implementation**: More parallel — multiple strategies can be applied to
  independent parts of the codebase simultaneously.
- **Review**: Heavily parallel — multiple principles can be evaluated against
  the code at the same time, with results aggregated into a single review.

### Principle ordering in design

Principles have a natural dependency sequence for design work. Each
principle's output feeds the next:

1. **Structure Is Intent** — identify domains from what the system does
2. **Compute or Coordinate** — classify each piece as logic or wiring
3. **Be Your Name** — name everything so qualified names communicate behavior
4. **Many More Much Smaller Steps** — slice into smallest coherent increments
5. **Fail Early and Loud** — design error paths as first-class concerns

The design protocol applies principles in this order. Not all principles
appear in every design — the protocol includes decision points for which
principles are relevant to the current task.

### "Ask before proposing" in design

Design mode uses a specific technique: **extract the user's mental model
before building your own.** The person who described the requirements already
has a mental model. Extracting it ("what domains do you see here?") is
faster and more accurate than building one from scratch and iterating on the
delta. This is built into the design protocol as step 1 — before any
principle is applied, the coordinator asks the user what they see.

### Strategies as reference material

Strategies serve two roles:

1. **Generation input** — consumed when generating protocols. The generation
   process reads strategies to produce the concrete protocol steps.
2. **Runtime reference** — available when the generated protocol isn't clear
   enough for a specific situation. An implementer can request the full
   strategy ("can I see the full Compute or Coordinate strategy?") or the
   strategy rationale to resolve ambiguity. This should be rare — if it
   happens frequently, it signals the protocol needs improvement.

Strategies are not loaded by default during execution. They are pulled in
on demand, either by the protocol when disambiguation is needed, or by the
human when they want to understand the reasoning behind a protocol step.

### Language configuration

Each target language has a configuration that captures tooling preferences
and ecosystem conventions. This configuration is an input to protocol
generation — the same strategy produces different protocol steps depending
on the language config.

Language config captures two types of information:

- **Design patterns** — how the language's type system, module system, and
  idioms map to abstract concepts (e.g., Go interfaces for contracts,
  Python protocols for structural typing).
- **Tooling preferences** — specific libraries and conventions
  (e.g., testify for assertions in Go, table-driven test style, t.Helper()
  for test helpers).

The format and location of language configuration is not yet defined.

### Validation

Generated protocols need test cases: known-good inputs (spec + principles +
strategies) paired with known-good designs and implementations. These detect
regressions when inputs change. Not needed for the initial prototype but
critical as the system grows.

## File organization

```
principles/
  FORMAT.md                          # How to write principles
  <principle-name>.md                # Individual principle files

strategies/
  FORMAT.md                          # How to write strategies
  <strategy-name>.md                 # Individual strategy files

implementation/
  <lang>/                            # e.g. go/, typescript/
    config.yaml                      # Language tooling preferences (planned)

guards/
  <lang>/                            # e.g. go/, typescript/
    <guard-name>.md                  # Guard design documents

script/
  audit-principles                   # Scans for gaps (planned)
```

Filenames use kebab-case: `no-conditional-test-logic.md`,
`data-driven-test-cases.md`.

## Supported languages

| Language   | Status      |
|------------|-------------|
| Go         | In progress |

Principles and strategies are shared across all languages. Protocols and
guards are language-specific.

### Adding a new language

1. Create `implementation/<lang>/` directory with `config.yaml`.
2. Generate protocols for the language using the protocol generation skill.
3. Review the generated protocols for language-specific accuracy.
4. Add the language to the table above and in `README.md`.
5. Run the audit script to check for gaps.

## The editor skills

Three editor skills handle the authoring layers. Each is a separate Claude
Code skill that can be invoked independently.

| Skill              | Layer      | Invocation         |
|--------------------|------------|--------------------|
| principle-editor   | Principles | `/principle-editor`|
| strategy-editor    | Strategies | `/strategy-editor` |
| guard-designer     | Guards     | `/guard-designer`  |

A fourth skill generates protocols from the authored content. This skill is
planned but not yet built.

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

#### strategy-editor → protocol regeneration

**When:** After creating or updating a strategy, if the change affects
generated protocols.

**Signal:** The strategy's steps or outcomes changed in a way that would
alter the generated protocol steps for one or more languages.

**Offer:** *"This strategy change may affect generated protocols. Want me
to create a bead to track regeneration?"*

If protocols have been generated, create a bead to track regeneration for
affected languages, noting what changed and why.

### How strategies are discovered

Strategies emerge from three entry points:

1. **During principle creation.** The principle-editor's layer check may catch
   a strategy disguised as a principle, or the principle may naturally suggest
   "how do I follow this?" — both lead to strategy work.

2. **Explicit request.** The user directly invokes the strategy-editor with a
   principle name or technique description.

3. **During protocol review.** When reviewing a generated protocol, the
   reviewer discovers that the abstract technique hasn't been documented as a
   strategy yet. It suggests creating the strategy first.

## The audit script

`script/audit-principles` scans the file system for gaps. It checks:

1. **Missing strategies.** Every principle that would benefit from a strategy
   has one in `strategies/`.
2. **Stale protocols.** Generated protocols are older than their input
   strategies or principles (compares modification times).
3. **Missing language coverage.** Every supported language has generated
   protocols.

The audit reports gaps clearly and can optionally create beads issues for them.

## Guard candidates

Guard candidates are identified from strategy outcomes and language-specific
patterns in generated protocols. A step is a **guard candidate** when:

- The check is binary — it passes or fails with no judgment required.
- The check can be mechanized — a linter, CI gate, or script can detect it.
- False positives are rare enough that `// nolint` escapes stay exceptional.

Guard candidates are tracked as beads issues. When someone picks up a guard
candidate bead, they invoke guard-designer, which designs the full guard:
tool selection, rejection/acceptance patterns, false positive assessment,
escape hatch, and implementation plan.

## Judgment-only principles

Some principles require human judgment and will never become guards. That's
legitimate. The test is **actionability**, not **mechanizability**:

- Can someone look at code and recognize a violation? → Actionable.
- Can they describe what should have been done differently? → Actionable.
- Does following it require omniscience or predicting the future? → Not a
  principle, decompose it.

Judgment-only principles stay in the principles layer. They may have
strategies that inform protocol steps, but those steps won't produce guards.

## Not-applicable handling

Not every principle applies to every language. When a principle is genuinely
not applicable to a language:

- The language configuration documents which principles don't apply and why.
- The audit script skips known not-applicable combinations.
- Generated protocols omit steps for non-applicable principles.

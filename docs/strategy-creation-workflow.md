# Strategy Creation Workflow

How strategies enter the system, how they connect to principles above and
guidelines below, and how the editor skills hand off between layers.

## Decision: separate skills, optional handoff

The principle-editor, strategy-editor, and guidelines-editor are **separate
skills** that can each be invoked independently. They are not a wizard or
pipeline. After completing work in one layer, the skill **offers** to hand off
to the next layer when context suggests it would be valuable. The user can
accept, decline, or note it for later.

### Why separate

- **Single responsibility.** Each skill does one thing well. The quality checks,
  format rules, and mental model are different for each layer.
- **Batch workflows.** You might define five principles in a session, then come
  back for strategies later. A mandatory pipeline blocks that.
- **Quality.** Creating a good principle already demands focus. Forcing an
  immediate pivot to strategy mode risks half-baked strategies written before
  the principle has settled.

### Why offer handoff

- **Natural progression.** After WHY, the next question is usually HOW.
  Surfacing the option keeps it visible.
- **Reduces forgotten work.** Strategies that need creating get surfaced when
  the context is fresh, even if the user defers.
- **Layer misplacement catch.** The principle-editor already identifies
  strategies disguised as principles. A handoff turns that rejection into a
  productive redirect.

## How strategies are discovered

Strategies emerge from three entry points.

### 1. During principle creation

The principle-editor's layer check may surface strategy-layer work in two ways:

**Strategy disguised as principle.** The user submits a multi-step technique
as a principle. The principle-editor catches this and should:

1. Extract the underlying principle (the WHY) and present it
2. Save the principle if the user approves
3. Offer: *"The technique you described is a strategy, not a principle. I've
   extracted the principle above. Want to create the technique as a strategy?"*

**Principle is sound, but "so how?"** After a principle is saved, the
principle-editor should check: does following this principle require a
non-obvious technique? If the principle says "don't do X" and the natural
response is "so what do I do instead?", a strategy fills that gap.

Offer: *"This principle might benefit from a strategy that describes how to
follow it. Want to define one?"*

### 2. Explicit request

The user directly invokes the strategy-editor. Examples:

- "Create a strategy for the No Conditional Test Logic principle"
- "Define a strategy called Data-Driven Test Cases"
- `/strategy-editor` (direct skill invocation)

### 3. During guideline creation

When creating a guideline, the guidelines-editor may discover that the abstract
technique it implements hasn't been documented. It should suggest creating the
strategy first: *"This guideline implements a technique that isn't documented
as a strategy yet. Want to create the strategy first?"*

This is a suggestion, not a blocker. Guidelines can exist without strategies.

## Handoff patterns

### principle-editor → strategy-editor

**When:** After creating or reviewing a principle, if the principle needs a
non-obvious technique to follow.

**Signal:** The principle's WHY implies "don't do X" and the natural response is
"so what should I do instead?" — or the layer check caught a strategy disguised
as a principle.

**Offer:** *"This principle could benefit from a strategy. Want to create one?"*

**If accepted:** Invoke the strategy-editor with the principle name pre-filled.
The user doesn't need to re-explain the context.

**If declined:** No action. The user can create the strategy later independently.

### strategy-editor → guidelines-editor

**When:** After creating a strategy, if language-specific implementation would
be non-trivial.

**Signal:** The strategy's numbered steps could be implemented differently
per language, or the OUTCOMES suggest language-specific checks.

**Offer:** *"Want to create a guideline that implements this strategy in
[language]?"*

**If accepted:** Invoke the guidelines-editor with the strategy name and
principle name pre-filled.

### guidelines-editor → guard definition

**When:** After creating a guideline, if any step can be checked mechanically
with zero judgment.

**Signal:** A guideline step is a binary check — it either passes or fails,
no context needed.

**Offer:** *"This guideline step could be enforced as a guard. Want to define
one?"*

## What the strategy-editor needs to do

The strategy-editor skill has three modes, mirroring the principle-editor:

### Create

1. User describes a technique, or provides a principle that needs a strategy
2. Draft the strategy in the exact format (see `strategies/FORMAT.md`)
3. Run quality checks (see below)
4. If any check fails, revise and show the improved version
5. Present the final strategy
6. Offer handoff to guidelines-editor

### Review

1. User provides a draft strategy
2. Evaluate against every quality check
3. For each failure, show a concrete rewrite

### Extract

1. User provides prose docs, internal wikis, or best practices
2. For each distinct technique, decide if it's a strategy (vs. principle,
   guideline, or something else)
3. Produce formatted strategies for valid concepts
4. Flag anything that belongs in a different layer

### Quality checks

**Format checks:**

- Name is a short noun phrase (2-4 words)
- PRINCIPLE link is present and references a real principle name
- Steps are numbered, abstract, and conceptual (no language-specific details)
- OUTCOMES are observable — someone can check if they hold
- MISAPPLICATION shows what the strategy looks like when applied badly
- SKIP WHEN is present and describes when to go straight to guidelines

**Layer check:**

- Not a principle (needs multiple steps; can't be said in one sentence)
- Not a guideline (no language/framework references; language-agnostic)
- Not a tutorial (no background reading, no motivation beyond PRINCIPLE link)

**Coherence check:**

- Steps logically follow from the linked principle
- OUTCOMES would actually satisfy the principle if achieved
- MISAPPLICATION is a realistic failure mode, not a straw man
- SKIP WHEN is honest — doesn't claim the strategy is always needed

## File organization

```
strategies/
  FORMAT.md             # How to write strategies (exists)
  DIVERGENCE.md         # When guidelines diverge (exists)
  [strategy-name].md    # Individual strategy files
```

Each strategy file defines one strategy. Strategy names use kebab-case for
filenames: `data-driven-test-cases.md`.
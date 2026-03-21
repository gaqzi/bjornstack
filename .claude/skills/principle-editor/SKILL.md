---
name: principle-editor
description: >
  Write, review, and refine engineering principles in a structured format
  optimized for both humans and AI agents. Use this skill whenever the user
  wants to create a new principle, review or improve an existing principle,
  convert prose rules or ideas into principles, or check whether something
  qualifies as a principle vs. a strategy, protocol, or guard. Also trigger when the
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

Every principle file has two parts: a tight **principle block** that agents
match against, and a **rationale section** that captures the thinking.

### Principle block

```
# [Principle Name]
[One constraint, clearly stated.]
VIOLATION: [Concrete example of what wrong looks like.]
VIOLATION: [Optional — a second example that clarifies a borderline case.]
WHY: [One sentence: the mechanism — what goes wrong without it.]
```

### Rationale section

Below the principle block, separated by `---` and an HTML comment:

```
---
<!-- Rationale below — read when creating strategies, reviewing, or
questioning the principle. Not needed for routine application. -->

## Rationale

[The thinking behind the principle. How it was arrived at. Edge cases.
What this principle is NOT. Tensions with other principles and how they
resolve.]
```

Agents read only the principle block for routine application. The rationale
is for deeper work: creating strategies, reviewing principles, resolving
ambiguous cases, or onboarding new contributors.

### Annotated example

This is what a complete principle looks like and why each part works:

```
# Fail Early and Loud
```
Name: 4 words, memorable, conversational. You'd say "that's a FEAL violation"
at a whiteboard. Works as a TLA. Someone hearing it for the first time gets
the gist before reading the definition.

```
Code must surface problems visibly and early rather than absorbing them into
implicit defaults, silent fallbacks, or hidden paths.
```
One constraint, clearly stated. The em-dash and qualifying phrases ("implicit",
"silent", "hidden") carve out what IS and ISN'T a violation. If a qualifying
clause can be removed and the principle still makes sense, the clause belongs
in the rationale instead.

```
VIOLATION: A hashmap lookup returns null, a downstream null-check substitutes
a default, and the bug surfaces three layers later as wrong data in production.
```
Concrete, recognizable, language-agnostic. Uses "hashmap" not "hash" (Ruby) or
"map" (Go). Uses "object" not "struct." Someone looking at real code should be
able to point at it and say "that — that's the violation."

```
WHY: Every silent failure is a bug that compounds — the distance between cause
and discovery is the cost.
```
States the mechanism — what breaks and how. Not "because silent failures are
bad" (restates the rule) but names the specific consequence (compounding cost
of distance). Short enough to remember, specific enough to apply in novel
situations.

## Voice

Principles should sound like a person explaining something at a whiteboard,
not like a corporate policy document. The user's natural language and lived
experience are the richest source material.

- **Names**: "Fail Early and Loud" not "Proactive Failure Surfacing."
  "Consistent Beats Correct" not "Pattern Adherence Prioritization."
- **Definitions**: "the reader should never scan boilerplate to find what
  actually changed" not "boilerplate should be minimized to optimize for
  differential readability."
- **Rationale**: write for someone reading this for the first time who doesn't
  know the author. No first-person ("I", "my colleague"). No corporate
  jargon ("stakeholder alignment", "peer agreement"). Say it plainly.

The test: read it aloud. If it sounds like a memo, rewrite it.

## Modes

### Create

User describes a concept, rule, or constraint. Produce a principle.

The user often arrives with a vague rule, a frustration, or an instinct about
what matters. This isn't a principle yet — it's raw material. Their stories,
frustrations, and natural language are valuable — encourage them. The phrase
they use to explain the idea to a friend is often better than any formal name.

#### Step 1: Explore

Don't draft too early. The first identification is rarely the right one — it's
usually a symptom of a broader principle.

- Ask: "What goes wrong when this is violated?" The answer reveals the
  definition and WHY.
- Ask: "What other things share this same WHY?" If multiple candidates share
  a WHY, they're strategies/protocols for one principle, not separate
  principles. Zoom out.
- If the answer to "what goes wrong" is "everything" or "it's just bad,"
  help decompose into something observable.
- The actionability check is the zoom-out limiter: if the principle becomes
  so abstract that violations are vague, you've zoomed too far.

#### Step 2: Name

Generate 5-10 name options. Don't converge too early. Good names tend to
emerge from the user's own language — listen for phrases they naturally use.

The naming test (all must pass):
- **Short**: 2-5 words.
- **Memorable**: you'd remember it after hearing it once.
- **Conversational**: you'd say it at a whiteboard or in a code review.
- **Invocable**: "[Name] violation!" makes sense.

Don't require noun phrases. "Fail Early and Loud", "Consistent Beats Correct",
"Be Your Name", "Highlight the Difference" — none are noun phrases, all are
excellent principle names. TLAs/eTLAs (FEAL, CBC, BYN, HtD) are a bonus when
they fall out naturally but not a requirement.

FAIL: "Proactive Failure Surface Optimization." Corporate, forgettable.
PASS: "Fail Early and Loud." Human, sticky, immediately clear.

#### Step 3: Draft

Produce the principle block in the exact format.

#### Step 4: Quality checks

Run every quality check (see below).

#### Step 5: Red team

If other principles exist, stress-test against the set:
- **Tensions**: does this principle conflict with any existing one? If so,
  which yields and why? Resolve in the rationale.
- **Overlaps**: does this principle cover the same constraint as an existing
  one with different words? If so, merge, differentiate, or abort.
- **Gaps**: does adding this principle reveal something missing from the set?
- **Ambiguous terms**: read every word in the definition. Could any term be
  misread? ("immediately" could mean "stop at the first error."
  "objects" could sound OO-specific.) Stress-test and tighten.
- **Novelty**: is this just an existing concept (screaming architecture, SRP,
  YAGNI) with a new name? If so, be honest about the relationship. Either
  acknowledge the lineage or genuinely differentiate.
- **Agent-actionability**: can an agent use this principle to make decisions
  about code? Can it detect violations in a changeset or codebase? If
  detection requires infrastructure knowledge the agent won't have
  (dashboards, deployment topology), is the principle still valuable as a
  constraint the agent raises or as guidance for what the agent should
  emit? Be honest about the difference — a principle that agents can
  mechanically check is stronger than one they can only remind about, but
  both are legitimate.

#### Step 6: Present and wait

Present the final principle with a brief note on any tradeoffs or judgment
calls. Wait for user approval before writing. Do not proceed to the
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
definition is too narrow, a protocol showed a violation doesn't cover a real
case, or experience proved the WHY is wrong. Read the existing principle file.
Diff the proposed change against the quality checks. Grep `strategies/*.md`
for strategies that reference this principle — for each, check whether their
steps still serve the updated definition and WHY. Flag any that don't. After
approval, update the file in place.

### Extract

User provides prose rules, a document, or a list of ideas.

#### Step 1: Explore before classifying

Don't jump to formal drafts. Present your initial read of the material:
- Which concepts look like principles (and why)
- Which look like strategies, protocols, or guards (and why)
- Where you suspect the real principle is broader than any single rule

Discuss with the user. Encourage them to share stories and frustrations
behind the rules — the lived experience often reveals the real principle
that the written rule was approximating.

#### Step 2: Zoom out

For each candidate principle, ask "what other rules in this document share
the same WHY?" Group them. Often 3-4 written rules are strategies/protocols
for one principle that hasn't been named yet.

#### Step 3: For each distinct principle

1. Decide if it's actually a principle (vs. strategy, protocol, guard, or
   aspiration)
2. If it's a principle, produce it in the format and run quality checks
3. If it's an aspiration, reject it — explain why it's not actionable and
   help decompose it into observable principles (see Actionability check).
   Produce each decomposed principle through step 2.
4. If it belongs in another layer, say what it is and why — then route it
   to the highest missing layer in the design chain for the relevant
   principle. Check what exists:
   - No strategy yet → bead for strategy-editor
   - Strategy exists, no protocol → bead for protocol generation
   - Strategy and protocol exist → bead for guard-designer

   Group all discoveries for the same principle into one bead. Include
   downstream discoveries as context in the bead description — a guard
   idea found in prose might inform strategy design. Each layer's design
   may reshape what reaches the next, and downstream editors' handoff
   workflows will carry valid ideas forward. Discoveries that don't
   survive the design chain were probably wrong.
5. If it enriches an existing principle — a new framing, lineage
   reference, edge case, or boundary clarification that strengthens
   a rationale without changing the principle block — draft the
   rationale addition and present it alongside new principles. Read
   the existing rationale first to avoid duplication or contradiction.
   When a rationale enrichment has a corresponding strategy, add a
   forward reference ("The X strategy makes this operational") to
   connect the layers.

#### Step 4: Red team the set

Once all candidates are drafted, red team the full set (see Create step 5).
Present in groups of 3-5 for review. Don't try to finalize 15 principles at
once — quality drops.

## Quality checks

Run every check on every principle you produce or review. These are not
optional.

### Format checks

- **Name is memorable, conversational, and invocable.** 2-5 words. It must
  work as shorthand agents and humans can invoke by name. You'd say it at a
  whiteboard. The "[Name] violation!" test must sound natural. Don't require
  noun phrases — verb phrases, imperative phrases, and short declarative
  phrases all work.
  FAIL: "Proactive Failure Surface Optimization."
  PASS: "Fail Early and Loud."
  FAIL: "We Should Always Separate Coordination From Logic."
  PASS: "Compute or Coordinate."

- **Definition states one constraint clearly.** The constraint should be
  expressible as one sentence, though qualifying clauses (em-dashes,
  subordinate phrases) are fine when they carve out what IS and ISN'T a
  violation. The test: if a qualifying clause can be removed and the principle
  still makes sense, the clause is elaboration that belongs in the rationale.
  If removing it changes what counts as a violation, it's part of the
  constraint.
  FAIL: "Objects either coordinate or perform logic. They should never do
  both because it makes testing hard." (Two sentences, second restates WHY.)
  PASS: "Code must surface problems visibly and early rather than absorbing
  them into implicit defaults, silent fallbacks, or hidden paths."

- **Violation is a concrete, recognizable, language-agnostic example.**
  Not abstract. Someone looking at real code or a real design should be able
  to point at it and say "that — that's the violation." 1-2 sentences. Use
  language-agnostic terms: "object" not "struct", "hashmap" not "hash",
  "parameterized test" not "table test". Most principles need one violation.
  Use a second only when it draws a boundary that reasonable people would
  argue about — it encodes the designer's judgment about where the line sits.
  If the two violations describe genuinely different failure modes (each
  needing its own WHY), you have two principles — split them.
  FAIL: "Code that doesn't follow the principle."
  PASS: "A hashmap lookup returns null, a downstream null-check substitutes
  a default, and the bug surfaces three layers later as wrong data in
  production."

- **Why states the mechanism.** It explains what breaks and how — not just
  that something is "bad" or restates the rule in different words. One
  sentence. Short enough to remember, specific enough to apply in novel
  situations. Name consequences, not feelings.
  FAIL: "Because mixing coordination and logic is wrong."
  PASS: "Mixed code obscures intent and makes testing harder — you can't tell
  whether a failure is in the logic or the wiring."

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
   Not necessarily spelled out in the principle — that's what protocols
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
  *why* something matters. Loaded into projects.
- **Strategies** — HOW: abstract, language-agnostic techniques that make a
  principle actionable. Used by protocol authors (human or AI) when creating
  protocols — not loaded into projects.
- **Protocols** — WHAT: tactical, language-specific implementation steps.
  Loaded into projects.
- **Guards** — CHECK: mechanical checks with zero judgment — linter rules,
  CI gates. Loaded into projects, run automatically.

Check for these common misplacements:

1. **Protocol disguised as principle.** If it prescribes specific steps
   or references a specific language/framework, it's a protocol. Nudge
   the user to promote the *why* behind it into the principle.
   FAIL: "Use table-driven tests when you have multiple input cases."
   FIX: The principle is "Fail Early and Loud." The table-driven approach
   is a protocol that implements it via the "Parameterized Test Structure"
   strategy.

2. **Strategy disguised as principle.** If it describes a multi-step
   technique without language specifics, it's a strategy, not a principle.
   Principles are one constraint. Strategies need space for steps.
   FAIL: "Identify variations, extract to data, write one test body,
   iterate."
   FIX: The principle is "Highlight the Difference." The technique is a
   strategy called "Parameterized Test Structure."

3. **Guard disguised as principle.** If it can be checked mechanically
   with zero human judgment, it's a guard. It belongs in a linter or CI.
   FAIL: "No if statements in test bodies."
   FIX: This is a guard (linter rule). The principle behind it is
   "Fail Early and Loud" — the *why* is that conditionals in tests
   hide which case failed and make tests act as multiple tests in a
   trenchcoat.

4. **Language-specific principle.** Principles are language-agnostic. If
   the principle references Go interfaces, TypeScript generics, or any
   language-specific construct, abstract up. Language-specific
   implementation belongs in protocols.
   FAIL: "All Go interfaces must be defined by the consumer."
   FIX: "Consumer-Defined Contracts" — Abstractions are defined by the
   code that depends on them, not the code that implements them.

### Rationale quality check

After writing the rationale section, verify it covers:

- **Ambiguous terms defined.** If the definition uses words that could be
  misread ("early", "loud", "independent"), the rationale defines what they
  mean and what they don't.
- **What this is NOT.** Carve out the exceptions — things that look like
  violations but aren't (e.g., explicit circuit breakers are not FEAL
  violations).
- **Tensions resolved.** If this principle can conflict with another, the
  rationale says which yields and why.
- **Sibling cross-references.** If this principle was split from another or
  shares a clear boundary with one, the rationale links them and explains
  the boundary.
- **No first-person.** The rationale should make sense if someone copies it
  who doesn't know the author.
- **Lineage acknowledged.** If the principle builds on an existing concept
  (screaming architecture, SRP, fail-fast), say so and explain what's the
  same and what's different.

## After approval

Once the user approves the principle(s), complete these steps in order.

### 1. Uniqueness check

Glob `principles/*.md` (excluding FORMAT.md). For each existing principle,
compare the name and definition against the new one:

- **Name collision** — Same or nearly identical name. Resolve before writing.
- **Semantic overlap** — Different name but the definition covers the same
  constraint. Show both to the user and ask: merge, differentiate, or abort?

If no conflicts, proceed.

### 2. Write the principle file

Write the principle to `principles/<kebab-name>.md` using the format from
FORMAT.md — principle block followed by rationale section. The filename uses
the kebab-case version of the principle name (e.g., "Fail Early and Loud" →
`fail-early-and-loud.md`).

When writing multiple principles at once, write all files in parallel.

### 3. Offer strategy handoff

Most principles need a strategy. The strategy is where the abstract technique
gets worked out before language-specific protocols are written. This ensures
consistency across languages and prevents protocol authors from each
independently inventing their own approach.

The exception is pure-judgment principles — principles where the technique
can't be abstracted into repeatable steps. These stay principles without
strategies or protocols.

For principles that do get strategies, create a bead with type `task`,
priority `3`, title "Create strategy for [Principle Name]", and description
that includes:
- Which principle(s) the strategy serves
- Expected protocols underneath (language-specific implementation steps)
- Guard candidates (mechanical checks that could enforce protocol steps)
- Cross-references to related strategies

If the layer check caught a multi-step technique disguised as a principle,
note the extracted technique in the bead description — it's a head start
for the strategy-editor.

## Edge cases

- **Principle requires judgment and that's fine.** Not every principle needs
  a strategy or protocols. Some principles are pure judgment calls that
  stay principles forever because the technique can't be abstracted into
  repeatable steps. That's legitimate. The test is actionability, not
  mechanizability.

- **Boundary-clarifying violations.** See the violation format check for
  when to use a second violation and when to split into two principles.

- **User wants to write a batch.** When converting a large document into
  principles, work through the exploration and zoom-out steps first. Present
  candidates in groups of 3-5 for review. Don't try to produce 15 principles
  at once — quality drops.

- **Meta-principles.** Some principles constrain how you use other principles
  (e.g., "Practicality Beats Purity" — when and how to break principles).
  These are legitimate and follow the same format. They're recognizable
  because their violations describe principle-following behavior, not code
  behavior.

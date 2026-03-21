# Earned Abstraction
PRINCIPLE: Earned Abstraction

1. Before implementing, search for existing solutions to the same
   problem.
   - Describe the abstract pattern your solution follows — what it
     does, not how.
   - If PATTERNS.md exists, consult it — is this pattern family
     already represented? If not, search the code directly.
   - Search using the vocabulary's established terms, or by purpose
     if no vocabulary exists.
   - Count the distinct cases found — implementations that solve a
     similar problem, not call sites using the same implementation.
     With one case, you can't distinguish pattern from accident.
     With two, you might overfit to what they share.
2. With fewer than three cases, keep the duplication.
   - Name the implementation for the business problem it solves —
     that happens regardless of case count.
   - When the pattern is a plausible building block — something
     likely to recur across domains — register the pattern family
     in PATTERNS.md and annotate the implementation so the
     vocabulary's terms appear in searchable code. This is the
     signal that lets future implementations discover they're
     case #3. If PATTERNS.md doesn't exist yet, create it.
3. At three or more cases, evaluate whether they share a genuine
   shared part. Identify what's stable across all cases and what
   varies. The stable part is the candidate abstraction; the varying
   parts are its extension points, not its parameters. If the
   analysis reveals a genuine shared part, proceed to step 4.
   - When the boundary is unclear, list the operations each case
     performs, diff them, and group: operations in all cases are
     stable; operations in some cases are varying. Present the
     grouping with the proposed boundary.
   - When cases vary at fundamentally different points — same
     mechanics but different reasons and different axes of change —
     there is no shared part worth extracting. Give them names
     that reflect their distinct purposes, group them as a pattern
     family in the vocabulary, and document why they're separate
     despite the mechanical similarity. Re-evaluate when new cases
     join the family — a new case may reveal a shared part that
     wasn't visible before.
4. Extract: the shared part becomes shared code; each varying
   behavior becomes a named collaborator — any unit of code the
   shared part delegates to, selected through composition rather
   than configuration.
   - Before extracting, verify the design doesn't require callers
     to configure which behavior path to follow. Boolean
     parameters, enum switches, large config structs where each
     caller uses a different subset, or conditionals that select
     between fundamentally different behaviors all mean varying
     parts are still in the shared part. Each distinct path is a
     use case that needs its own collaborator, not another config
     field.
   - Name each concrete case for the business problem it solves,
     not its relationship to the shared part. Update the
     vocabulary to reflect the extraction.
   - When accommodating a new case would require existing callers
     to change, or would add configuration that existing callers
     must explicitly opt out of, the abstraction is no longer
     earned for this case. Copy the implementation out, make it
     independent, and document in the vocabulary why it diverged.

OUTCOMES:
- Every abstraction traces to three or more concrete cases that
  share a genuine shared part — not just mechanical similarity.
- No abstraction requires callers to configure which behavior
  path to follow — varying behavior is encapsulated in named
  collaborators, not booleans, enums, or caller-specific config.
- Non-abstracted cases remain duplicated with names that reflect
  their distinct purposes and documented reasoning in the
  vocabulary for why they're separate.
- Pattern families are registered in the vocabulary with consistent
  terms — search by those terms finds all members and any
  documented reasons for intentional separation.

MISAPPLICATION: Treating three mechanical similarities as an
automatic extraction trigger without evaluating whether they share
a genuine shared part. Applying the rule of three so rigidly that
obvious patterns from two well-understood cases are ignored when a
third is clearly imminent. "Extracting" with a strategy pattern
that's just configuration bloat with extra indirection — a type
hierarchy that doesn't clarify what varies and what's shared. Using
the vocabulary to gatekeep — PATTERNS.md describes what exists, not
what must exist. It's a discovery aid, not a governance mechanism.
SKIP WHEN: Local helpers within a single file. Extracting repetition
to a file-scoped helper has one consumer, costs nothing to undo, and
serves Highlight the Difference — it's not the kind of cross-consumer
abstraction this strategy governs.

---
<!-- Rationale below — read when creating protocols, reviewing, or
questioning the strategy. Not needed for routine application. -->

## Rationale

### The pattern vocabulary

Steps 1, 2, 3, and 4 all reference a pattern vocabulary — a living
taxonomy of the codebase's pattern families maintained in PATTERNS.md.
This is the mechanism that makes EA's discovery step work reliably.
Without it, discovery depends on naming luck: the implementer and
the searcher independently choosing the same terms.

The vocabulary is a glossary, not a directory listing. It contains
terms, relationships, and descriptions of each family member — not
file paths or case counts. Search finds the implementations; the
vocabulary establishes what to search for. Paths go stale when code
moves; terms stay relevant because they describe purpose, not
location. Case counts go stale when code changes; search is the
source of truth for how many implementations exist.

The strategy works without a vocabulary — step 1 falls back to
searching the code directly — but works significantly better with
one. The vocabulary is what turns pattern discovery from naming luck
into a reliable process.

The vocabulary primarily serves infrastructure patterns — building
blocks that recur across business domains. These are the patterns
most likely to be independently reimplemented because they solve
technical problems (resilience, serialization, validation) rather
than domain problems. Domain-level patterns can emerge too, but
domain structure is primarily handled by Domain-First Packaging.

Register a pattern when you recognize it as a plausible building
block, not every function you write. The failure mode of not
registering is continued duplication — which step 2 says is the
safe default.

The vocabulary is a cache of discovery, not a source of truth — the
code is the source of truth. If vocabulary entries don't match
search results — families missing known patterns, members listed
that no longer exist — update the vocabulary as part of the current
task.

### Families and species

The vocabulary uses a taxonomic structure. A pattern family groups
mechanically similar implementations the way a genus groups related
species — shared mechanics, different purposes.

Some pattern families are consumed by other patterns or by domain
code. The vocabulary captures these composition relationships — how
patterns relate and how they're expected to be used together — so
that discovering one pattern leads to discovering the patterns it
composes with. This topology prevents correct-in-isolation,
incorrect-in-context usage.

Each family entry has:

- A **family description** — the abstract mechanical pattern shared
  by all members. "Sends a notification to a recipient through a
  specific channel."
- **Species entries** — each concrete implementation, named for its
  specific purpose, with a one-line description of what it does and
  how it differs. The species name gives you the search term; the
  description tells you what purpose it serves.
- **Composition topology** (when applicable) — how domain or
  application code is expected to use the infrastructure pattern.
  Not the specific implementations, but the technique for plugging
  in.
- **Separation rationale** (when applicable) — why members of the
  same family are intentionally not abstracted despite mechanical
  similarity. This prevents future attempts to merge them without
  context.

Example:

```
## Notification Dispatching
Send a notification to a recipient through a specific channel.

Shared interface: a notification carries a recipient, a message,
and a purpose — the caller sends without knowing the channel.

- **Email dispatcher** — converts notification payload into MIME
  format with attachments, delivers via SMTP or SES
- **Webhook dispatcher** — converts notification payload into
  signed JSON, delivers via HTTP with retry
- **SMS dispatcher** — converts notification payload into
  character-limited text, delivers via carrier API

Abstraction earned at the business level: "send notification" is
the shared interface. Each species converts the domain payload
into channel-specific format and owns its delivery semantics.

### Domain notifiers
Each domain implements a notifier that maps its domain events
into notification payloads and declares which dispatch channels
to support. The notifier owns the business decision of which
channels are appropriate for its domain — the dispatcher
infrastructure handles delivery. Search for "notifier" within
domain packages to find existing implementations.
```

The family name lives in the vocabulary. The species names live in
the code. Code annotations use the species term so search connects
the code to the vocabulary entry.

### Vocabulary maintenance

The vocabulary is maintained through the strategy's own steps:

- **Step 1 consults it** — before implementing, check whether the
  pattern family exists and review its species and composition
  patterns.
- **Step 2 registers new entries** — when keeping duplication, add
  the pattern family or add a species to an existing family.
- **Step 3 documents separation decisions** — when cases are
  mechanically similar but functionally distinct, the vocabulary
  records why and what distinct names they carry.
- **Step 4 updates after extraction** — when a shared part is
  extracted, the vocabulary reflects the new structure.

Code review enforces vocabulary discipline: new implementations
use established terms or explicitly extend the vocabulary with
rationale for the new term. Reviewers check that annotations in
code match vocabulary entries, that separation decisions are
documented when applicable, and that composition patterns are
followed or explicitly diverged from.

### Naming as the decision made durable

When step 3 concludes that mechanically similar cases shouldn't be
abstracted, the most important action is giving them different
names that reflect their distinct purposes. Without differentiated
names, the decision is invisible — the next person sees
identically-named things and asks "why aren't these consolidated?"
They'll either waste effort rediscovering the answer or force an
abstraction that was already evaluated and rejected.

Different names make the decision self-documenting. No one tries to
merge `RetryWithBackoff` and `CircuitBreaker` without analysis,
because the names signal distinct purposes. This is where Earned
Abstraction and Be Your Name reinforce each other: EA decides
whether to abstract, BYN makes that decision visible through naming.

### Configuration bloat and Compute or Coordinate

Step 4's configuration bloat check connects to the Compute or
Coordinate principle. An abstraction with mode flags or
caller-specific config subsets is usually mixing coordination and
computation — the shared parts coordinate, the configured parts
compute different things. Refactoring into named collaborators is
decomposing into a coordinator (shared part) and computations (each
collaborator). The coordinator doesn't know which collaborator it's
running; the collaborator doesn't know about the coordinator's other
callers. This separation makes both independently testable per the
Unit Testing strategy.

The smell isn't limited to booleans. A config struct with fifteen
fields where each caller sets a different three is the same
problem — the caller is telling the abstraction which behavior path
to take, just with more ceremony. The test: if removing a config
field would break only one caller, that field represents a use case
that should be a named collaborator, not a configuration option.

### The un-earning path

An abstraction can be legitimately earned at extraction time but
become too broad when a new variance point emerges. The new case
needs something the shared part can't provide without distorting it
for the existing callers.

The trigger: accommodating the new case would require existing
callers to change, or would add configuration that existing callers
must explicitly opt out of. When this happens, the right response
is copying the implementation out — making the divergent case
independent. This isn't failure; it's the abstraction's boundary
becoming clearer through use. The vocabulary documents why the case
diverged, preventing future attempts to re-merge it. The remaining
cases may still be well-served by the shared part.

This is the temporal complement to step 3's "don't extract"
decision. Step 3 says "don't merge things that look similar but
aren't." Step 4's sub-bullet says "un-merge things that were
similar but diverged."

### Scope exclusions

Two things that look like premature abstractions but aren't:

**Dependencies you adopt.** Using a battle-tested library is a tool
choice, not a speculative abstraction. EA governs abstractions you
create — your own interfaces, helpers, and generic frameworks — not
dependencies you adopt. The question for dependencies is whether
they serve the principles you live by, not whether you've seen three
cases.

**Testability seams.** An interface defined so a coordinator can be
independently tested is earned by the testing need — there's a
concrete consumer (the test) that requires it. This isn't
speculation from a single case; it's a response to a real
constraint.

### Beyond code

EA applies to manual processes and automation decisions. A runbook
is a concrete process. Automation is its abstraction. The same rule
of three applies: don't automate a procedure you've only run once.
The first run reveals what the runbook missed, the second shows what
varies, the third reveals the real pattern. Premature automation
encodes assumptions from too few cases and breaks on real variation.

### Cross-references

- **Unit Testing**: Uses collaborator count as a complexity signal.
  When a coordinator has many collaborators, some may be premature
  abstractions that should still be duplicated code.
- **Test Data Builders** (downstream): A concrete example of earned
  abstraction — extract a builder only after 3+ tests need the same
  setup pattern.
- **Be Your Name**: Naming family members differently when not
  abstracting is BYN applied at the point of EA's decision. Naming
  shared parts and collaborators well when extracting is BYN applied
  at the point of EA's action.
- **Consistent Beats Correct**: Reinforces step 2 — keep duplication
  and stay consistent with codebase patterns rather than introduce
  an abstraction that might be wrong. Also drives vocabulary
  consistency: same pattern, same terms.
- **Highlight the Difference**: SKIP WHEN references HTD — local
  helpers that extract repetition within a file serve HTD, not EA.
- **Domain-First Packaging**: DFP's step 6 covers wrapping adopted
  dependencies at the boundary. EA's scope exclusion notes that
  adopted dependencies aren't premature abstractions — DFP ensures
  they don't leak into domain interfaces regardless.

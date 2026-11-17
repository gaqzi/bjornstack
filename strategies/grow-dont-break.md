# Grow Don't Break
TENET: No Shared Fate

1. Classify the change to a public contract as additive or subtractive
   by how it behaves, not by how it looks. Consumers include code that
   implements the contract as well as code that calls it.
   - Additive: new fields, new endpoints, new enum values, new optional
     parameters — when every existing consumer that relies only on what
     the contract promises keeps working unchanged.
   - Subtractive: removing, renaming, narrowing types, changing the
     meaning of what exists — including adding a field that alters the
     behavior of existing ones, or adding something existing consumers
     must now supply: a required input for callers, or a member for
     implementers.
   - Bad: calling a new `priority` field additive when it changes how
     the existing `status` transitions work — no field was removed, but
     the meaning of an existing one changed.
2. Apply additive changes directly — they cannot break existing consumers.
   A consumer that doesn't know about a new field ignores it; a consumer
   that doesn't call a new endpoint never notices it.
3. When a change appears subtractive, add the new version alongside the
   old. The old version continues to work — for now.
   - A rename becomes a new field plus deprecation of the old.
   - A behavior change becomes a new endpoint with the new behavior.
   - A type narrowing becomes a new stricter type alongside the original.
   - A member every implementer must supply goes on a new contract that
     extends the old; existing implementers keep satisfying the old one.
   - Good: consumers of the old version notice nothing while the new one
     exists; such as a renamed field added beside the old one, or a v1
     endpoint kept as a thin wrapper that calls v2 and maps the response
     back to v1's shape.
4. For internal contracts (you control all consumers): grow then
   subtract — migrate every consumer to the new version, then remove
   the old.
   - Ordering matters: add new, migrate consumers, remove old — never
     remove before all consumers have moved. This is the Tidy or Change
     pattern: structural addition and behavioral migration as separate
     steps.
   - No deprecation period needed because you can change both sides.
   - When migration spans multiple PRs, track the phases explicitly so
     the old version isn't forgotten.
   - Good: the old version is removed only after its last consumer has
     moved; such as add, migrate, and remove within one PR, or the new
     version behind a flag, made the default once every consumer uses it,
     then the flag removed along with the old path.
5. For external contracts (library consumers, API clients you don't
   control): deprecate rather than break. Mark the old version as
   deprecated, document its replacement, and let it continue to function.
   - When the deprecated field isn't load-bearing for consumers, the wire
     contract can hold — a field that returns empty data isn't broken at
     the protocol level, even though the business meaning changed.
   - When consumers depend on the field's value for display or logic,
     step 3 applies instead: add a new field with the new meaning, keep
     the old field returning its documented value.
   - Accumulate deprecations until the maintenance cost justifies a major
     version that batches the removals.
   - Security vulnerabilities require urgent action — contact affected
     consumers, coordinate a timeline, and prepare to break. Most
     security issues aren't immediate shutdowns but "fix as quickly as
     possible so we don't have to shut down." Act in conjunction with
     those who depend on you, not unilaterally.
6. For planned major versions: announce the timeline before the break,
   provide migration guidance, and give consumers enough runway to move.
   A single deprecation rarely justifies a major version — batch when
   the accumulated maintenance cost exceeds the migration cost consumers
   will pay.

OUTCOMES:
- Additive changes never break existing consumers — internal or external.
- Internal subtractive changes follow grow-then-subtract: the new version
  is available before the old is removed, and removal happens promptly
  after migration.
- External subtractive changes only appear at major version boundaries,
  where consumers explicitly choose to upgrade — except security fixes,
  which are coordinated urgently with affected consumers.
- Deprecated elements have a documented replacement and a removal timeline
  before they disappear.

MISAPPLICATIONS:
- Treating internal callers as external consumers — deprecation
  periods and version management for code you control. Internal
  contracts use grow-then-subtract: add, migrate, remove.
- Treating external consumers as internal — "we'll just tell them
  to update" — breaking consumers without a version boundary.
- Accumulating deprecated features forever without a removal plan —
  growth without pruning becomes bloat.
SKIP WHEN: Early prototyping before any consumer depends on the contract —
internal or external. Once a consumer exists, the contract is a promise.
Also: purely internal changes within a single package with no callers
or implementers beyond it — there's no contract to grow or break.

---
<!-- Rationale below — read when creating protocols, reviewing, or
questioning the strategy. Not needed for routine application. -->

## Rationale

### Accretion, not breakage

Rich Hickey's framing: a system that grows is one others can depend on; a
system that breaks teaches its consumers to fear upgrades. The technique is
simple — contracts only expand — but the discipline is hard because every
subtractive change feels justified in isolation. Step 3 is the core skill:
learning to see subtractive changes as additive opportunities.

### Internal vs external asymmetry

GDB applies to both internal and external contracts, but the lifecycle
differs. Internally, the grow-then-subtract cycle completes in hours or
days — add the new interface, migrate callers (possibly in the same PR),
remove the old. Externally, the cycle stretches to weeks or months because
you can't control when consumers migrate. The technique is the same (always
grow first); the holding period is what differs.

For codebases where migration spans multiple PRs — a monorepo with many
callers, or a large internal refactor — the three phases (add, migrate,
remove) are the same, just distributed in time. Track them explicitly
(issue tracker, bead, etc.) so the old version doesn't linger indefinitely.
The mechanism is still internal: you control all callers, you just need
coordination tooling rather than deprecation announcements.

### Wire contract vs business contract

The deprecation technique in step 5 exploits a useful distinction: the wire
contract (field exists, type is correct, request succeeds) can hold while
the business contract (field contains meaningful data) changes. A field
returning empty data doesn't crash consumers at the protocol level — it
signals obsolescence without breaking integration.

The harder case is when the business contract must change but can't simply
be emptied — the old meaning is load-bearing for consumers. A pricing field
that consumers use to display costs can't just go empty without breaking
their UX, even if the wire contract technically holds. In these cases, the
wire-contract-holds technique doesn't apply. Step 3's approach is the
fallback: add a new field with the new meaning, keep the old field
returning its documented value, and deprecate the old. The old field
continues to work as consumers expect while the new field carries the
updated business meaning. This costs more — you're maintaining two live
business contracts — but it's the only way to change business semantics
without breaking consumers.

### Old versions as wrappers

When introducing a new version of a contract, consider making the old
version a thin wrapper around the new implementation. Instead of
maintaining two parallel implementations, the v1 endpoint calls v2
internally and maps the response back to v1's shape. This shrinks the
maintenance surface: you maintain the mapping layer, not a separate code
path. The only paths you maintain independently are those where v1 behavior
was explicitly removed in v2 — the mapping can't bridge a genuine semantic
gap. This is a design consideration, not a hard rule — sometimes the old
and new versions are different enough that a wrapper adds more complexity
than it saves.

### Producer-side and consumer-side

This strategy governs the producer side: how to evolve contracts without
breaking consumers. Scrub on Entry governs the consumer side: by validating
only acted-on fields and discarding the rest, consumers naturally tolerate
additive changes. The two strategies are complementary — producers grow,
consumers tolerate growth. Together they eliminate shared fate at the
contract boundary.

### Relationship to Boundary Communication

Boundary Communication defines what contracts are — public interfaces with
single owners, where internals can change freely. BC step 5 explicitly
references this strategy: "changes to [contract types] are additive, not
breaking — Grow Don't Break governs how contracts evolve." BC creates the
boundary; GDB keeps the boundary stable as the system changes.

### Relationship to Intentionally Public

Intentionally Public governs what gets exported at the code level — the
initial decision of what's in the public surface. GDB governs what happens
after: once something is public, it can't be removed without a version
boundary (external) or a tracked migration (internal). IP decides the
surface; GDB prevents it from shrinking without deliberate process. The
distinction: IP operates within a package (code-level visibility), GDB
operates at contract boundaries (evolution over time).

### Relationship to Flag Your Changes

GDB's "add alongside" — new endpoints, new versions, new fields — is
inherently opt-in and needs no flag. Flag Your Changes picks up where
GDB's additive approach runs out: when existing behavior must change for
current users, and the change can't be offered as a new thing to opt
into. GDB handles growth; FYC handles transition.

Flags can also serve as the migration mechanism within GDB's
grow-then-subtract cycle (step 4). New contract version behind a flag →
migrate consumers → flag becomes default → remove old path. The flag
makes the cycle visible and controllable.

### Additive in form, breaking in behavior

A change can be additive in form but breaking in behavior. Adding a
`priority` field to an order that changes how existing `status` transitions
work is technically additive — no field was removed — but consumers relying
on the old status semantics break. If an existing consumer that relies
only on what the contract promises would behave differently, the change
is subtractive and goes out as a new version beside the old (steps 3-5),
so consumers opt into the new behavior instead of discovering it. Go's
`encoding/json/v2` is this rule at library scale: it changes how the
original package behaves, so it is a new package beside the original
rather than a change to it.

Adding a method to an interface is a case that is easy to miss, because
it is additive for callers and breaking for implementers: every type that
implements the interface stops satisfying it until it adds the method.
Adding a required method breaks implementers in Go, TypeScript and Java.
It is usually additive where the interface supplies a default
implementation, as a Java default method does, or marks the member
optional, as TypeScript allows. Each language's protocol says how to
grow an interface there without breaking implementers.

### Batching economics

Major versions are expensive for consumers — each one requires evaluation,
testing, and migration. Batching deprecations into infrequent major
versions means consumers pay the migration cost once for many changes. The
tradeoff: longer deprecation periods mean maintaining old paths longer. The
right time to cut a major version is when the maintenance cost of
deprecated paths exceeds the migration cost consumers will pay — not when
you have one thing to deprecate.

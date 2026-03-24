# Boundary Communication
PRINCIPLE: No Shared Fate

1. Find the shared data — look for data that more than one unit reads,
   writes, or changes. A database table two services query. A struct two
   packages modify. A global variable read across module boundaries. Each
   instance is a boundary that needs a clear owner. Shared constants and
   read-only configuration don't count — this is about data that at least
   one unit can change.
2. Assign a single owner — one unit owns the data: it decides what values
   are valid, accepts changes, and is the source of truth.
   - When ownership is obvious (one unit validates and changes the data,
     others only read): assign it.
   - When both units validate the data: check whether they enforce
     different rules — if so, they own different data that shares a name,
     and each gets its own version with conversion when data crosses
     between them. The pricing service says prices can't be negative; the
     admin service allows negative overrides — they own different data
     called "price."
   - When the rules genuinely overlap: present the finding — these units
     enforce identical rules on the same data and likely belong in one
     package.
3. Make the contract explicit — the owner exposes data through a public
   interface: exported functions and types at the package level, API
   endpoints or event schemas at the service level. Everything behind the
   contract is private. The contract should describe what the owner
   provides, not how it works inside.
4. Remove every back door — any path that bypasses the public contract is
   shared fate waiting to happen. Importing another package's internal
   types, querying another service's database, reading shared mutable
   globals — all the same pattern. Replace each with a call through the
   contract. If the back door accesses data the contract doesn't expose,
   either extend the contract or determine the consumer doesn't need it.
   "Just reading" another unit's internals is still a back door: an
   internal change in the owner will break the reader.
5. Verify independence — change something behind the contract: a private
   function, an internal data structure, how data is stored. If any
   consumer would notice, the boundary leaks — something private is being
   depended on directly. The contract types themselves (exported structs,
   API schemas) are meant to be depended on; changes to those are
   additive, not breaking — Grow Don't Break governs how contracts evolve.

OUTCOMES:
- Each piece of shared data has exactly one unit that owns it.
- Units interact only through public contracts — no unit reads or writes
  another's internal state.
- An owner can change its internals (private functions, storage schema,
  internal structure) without any consumer noticing.
- A failure or change in one unit cannot silently corrupt data in another.

MISAPPLICATION: Creating separate databases but still sharing type
definitions or ORM models between services — the coupling moved from
runtime to build time. Or splitting every piece of data into its own
service, creating network overhead and complexity for data that belongs
together. Also: defining a public API but with consumers still importing
internal types "for convenience" — the contract exists on paper but the
code couples through the back door.
SKIP WHEN: The units genuinely belong together — they validate the same
data with the same rules and always change in lockstep. That's one unit,
not two. Domain-First Packaging determines whether things belong together;
this strategy governs how they communicate once they don't.

---
<!-- Rationale below — read when creating protocols, reviewing, or
questioning the strategy. Not needed for routine application. -->

## Rationale

### The aggregate root connection

This strategy's ownership model — one unit validates, constrains, and is
the source of truth for related data — is the same insight as DDD's
aggregate root pattern. An aggregate root is the single entry point for
all changes to a cluster of related objects, ensuring invariants hold
through one interface. You don't need full DDD aggregates to follow this
strategy, but when ownership decisions get hard, the aggregate root
question helps: "if I had to route every change to this data through one
place, where would that place be?"

### The ownership question

An invariant is a rule about data that must always hold true — "prices
are positive," "emails contain @," "end date is after start date." The
unit that defines and enforces these rules owns the data. Step 2 is the
hardest because it requires understanding invariants, not just data flow.

Two services that both "use" user profiles may have completely different
ownership claims — one validates email format, the other validates billing
addresses. They don't own "the user" — they own different aspects that
happen to share a name. When you spot different invariants, you're looking
at different data.

When neither unit clearly validates or constrains the data, look at
mutation patterns: which unit creates and most actively changes this data?
The creator is usually the owner — but if another unit enriches or
transforms it substantially, it may be the real authority.

Ownership can shift as systems evolve. A data type that started in the
orders service might now be primarily validated and enriched by the
fulfillment service. When you notice a unit doing more validation than
the nominal owner, that's a signal to reassign ownership — not to add a
second validator.

Data arriving from another unit — whether a function argument or an API
response — is external data. Validate it at entry (see Scrub on Entry).
The result: each unit trusts only its own validated view of the world.

### Shared contract types

When data crosses a boundary, its shape — the contract type — needs to
live somewhere both sides can depend on. Three patterns, in order of
preference:

1. **Import from the owner.** The owning unit defines the type as part of
   its public contract. Consumers import it directly. This is the default
   and the simplest: clear dependency direction, the owner controls the
   shape. Most exported structs and domain types follow this pattern —
   they're created by the owner to be used by consumers.

2. **Shared contract package.** When no single unit owns the type — an
   event that flows between units, a message format, a shared identifier —
   it lives in a small, stable package both sides import. This package
   contains only boundary types, not logic. Think of it as a shared
   contract layer: it exists solely to define what crosses boundaries. The package
   has a specific, named purpose — `events` or `contracts/pricing` — not
   `common` or `shared`. If it grows to contain types from unrelated
   boundaries, it's becoming a grab-bag; split it by boundary.

3. **Own versions with conversion.** When units have genuinely different
   models of the "same" data — different validation rules, different
   relevant fields — each defines its own type and converts at the
   boundary. This is maximum independence at the cost of conversion code.
   The conversion itself is a boundary concern (see Scrub on Entry).

Default to 1. Move to 2 when there's no clear owner. Move to 3 when
models genuinely diverge — typically when crossing bounded contexts where
each side's internal model should evolve independently.

### Bidirectional communication

When unit A needs to send data to B and B needs to send data to A, the
temptation is a circular dependency. Two resolutions:

- **Coordinator.** A third unit imports both A and B and orchestrates the
  flow. The coordinator depends on the the domain packages it coordinates but contains no
  domain logic of its own (see Compute or Coordinate). A and B never
  import each other.
- **Event-based.** Each unit publishes through its contract. The other
  subscribes without a direct import. No circular dependency, but
  introduces eventual consistency.

Within a process, prefer the coordinator — it's a named concept that
depends on the domain packages it coordinates and makes the data flow explicit. Across
services, event-based communication avoids tight coupling.

### Relationship to Domain-First Packaging

DFP determines *where things go* — it creates boundaries by organizing
code into domain packages (Structure Is Intent). This strategy determines
*how units communicate once separated* — it governs what crosses those
boundaries (No Shared Fate). Both are needed: well-placed boundaries with
leaky communication still create shared fate. DFP creates the structure;
this strategy keeps the structure honest.

### Scale differences

The enforcement mechanism differs by scale. At the package level, language
visibility rules (exported vs unexported) enforce the contract — a
consumer physically can't access private internals in most languages. At
the service level, the network boundary enforces it. The principle is
identical; only the mechanism changes. Service boundaries are harder to
violate accidentally but also harder to refactor when wrong. Package
boundaries are easier to violate ("just make it public") but also easier
to fix.

### Sync vs async at the service level

At the service level, the contract choice has failure-mode implications. Synchronous calls (APIs) couple the
consumer's availability to the owner's — if the owner is down, the
consumer fails. Asynchronous communication (events, messages) lets
consumers maintain local projections that tolerate owner downtime, at the
cost of eventual consistency. The choice depends on failure tolerance:
a checkout service needs the current price (synchronous); a recommendation
service can work with slightly stale order history (asynchronous).

### Relationship to Contract Testing

This strategy defines contracts between units — ownership, explicit
interfaces, no back doors. Contract Testing is the verification mechanism:
it encodes the expectations from step 3's contracts as tests and catches
drift before it becomes shared fate. This strategy creates the contracts;
Contract Testing proves they hold.

### Cross-references

- **Grow Don't Break**: GDB governs how BC's contracts evolve over time —
  changes are additive, not breaking. BC creates the boundary; GDB keeps
  it stable as the system changes.
- **Flag Your Changes**: FYC's flags live within BC's ownership model —
  a pricing flag lives in the pricing boundary. Flags don't create new
  boundaries; they sit within existing ones.

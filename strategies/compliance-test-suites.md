# Compliance Test Suites
PRINCIPLE: No Shared Fate

1. Check the trigger: a boundary interface has two or more
   implementations that must honor the same behavioral contract.
   - Multiple production implementations are the strongest case —
     Redis vs. SQS vs. RabbitMQ as message queues, Postgres vs.
     SQLite as stores. The suite is written once; each
     implementation proves compliance.
   - A hand-rolled in-memory test double used in coordinator tests
     also counts — without shared verification, coordinator tests
     have shared fate with the double's fidelity.
   - One implementation, no test double → test directly per Unit
     Testing strategy.
   - Two or more → continue at step 2.
2. Write a shared test function alongside the interface definition,
   parameterized by a factory. The factory creates a ready-to-use
   implementation with isolated state per call. The test function
   exercises the interface's behavioral contract — what the interface
   promises, not how any implementation fulfills it.
3. Structure scenarios around the interface's operations. For each
   operation the interface declares:
   - One success path exercising the core behavior.
   - Each error condition the interface contract specifies (not-found,
     duplicate, invalid input — whatever the types and documentation
     declare).
   - Boundary behavior the contract implies (empty collections, zero
     values, idempotent re-calls).
   - Mutation scenarios verifying the implementation returns
     independent copies, not references to stored state.
   - When the boundary between contract behavior and implementation
     detail is unclear: if it's visible through the interface's types
     and return values, it's contract; if it requires knowing the
     underlying mechanism, it's implementation. If still ambiguous,
     the interface contract is underspecified — flag for review.
   Use builders (per Test Data Builders) to construct scenario inputs
   and expected outputs — the compliance suite delegates object
   construction, it doesn't own it.
4. Each implementation provides its own factory and invokes the shared
   test function. The factory handles infrastructure setup, data
   scoping (per Isolated Test Execution), and cleanup.
5. Test implementation-specific behavior separately. Behavior beyond
   the interface contract — performance characteristics, storage-
   specific edge cases, migration compatibility — lives in the
   implementation's own test file, not the compliance suite.

OUTCOMES:
- Every implementation of a boundary interface passes the same
  behavioral test suite — behavioral divergence between
  implementations is caught automatically.
- Adding a new implementation requires only providing a factory —
  test scenarios already exist.
- Interface contract changes surface as failures across all
  implementations simultaneously — no implementation silently
  inherits assumptions from an older version.
- The compliance suite contains no implementation-specific logic —
  it tests what the interface promises, not how.
- Test doubles used in coordinator tests pass the same suite as
  production implementations — coordinator test results don't
  depend on double fidelity.

MISAPPLICATIONS:
- Testing storage details instead of behavioral contract — row
  counts, query plans, cache hit rates. The suite tests what goes
  in and what comes out, not how.
- A compliance suite for a single-implementation interface with no
  test double — the technique earns its keep through shared
  verification.
- A suite so exhaustive it duplicates tests that belong in the
  implementation's own file — implementation-specific behavior
  tested in the compliance suite couples all implementations to
  one's details.
SKIP WHEN: Only one implementation exists with no test double and no
concrete second implementation planned. The Unit Testing strategy
covers direct testing without the indirection of a shared suite.

---
<!-- Rationale below — read when creating protocols, reviewing, or
questioning the strategy. Not needed for routine application. -->

## Rationale

### Why No Shared Fate

Multiple implementations of the same interface are already coupled —
they must behave identically, that's the whole point of the interface.
Without a compliance suite, this coupling is invisible and unverified.
Each implementation has its own tests that may or may not cover the
same behavior. The system's correctness rests on an assumption nobody
has proved: that separately-written test suites happen to enforce the
same contract.

The compliance suite makes that coupling explicit and verifiable. One
contract, defined once, proved by each implementation independently.
Now the coupling works for you instead of against you — you can swap
any implementation and know it meets the same behavioral standard.

### The trust chain: compliance → doubles → coordinator tests

This is the strategy's most important non-obvious consequence. Unit
Testing step 3.3 says "replace every direct collaborator with a test
double." But what makes those doubles trustworthy?

The compliance suite. When both the Postgres adapter and the in-memory
double pass the same suite, coordinator tests that use the in-memory
double can trust their results — the double behaves like the real
thing because both prove compliance with the same contract.

Without this, coordinator tests have shared fate with the fidelity of
their doubles. Tests pass with the in-memory double, but if the double
doesn't match Postgres behavior, the coordinator works in tests and
breaks in production.

### The serialization boundary

In-memory implementations and real implementations differ in a way
that's easy to miss: the serialization boundary. A database-backed
implementation serializes objects to rows on write and deserializes
back to new objects on read — every retrieval returns an independent
copy. An in-memory implementation stores and returns references to the
same objects in memory.

This creates a class of subtle bugs that only surface when
implementations diverge:

- **Store-then-mutate**: test stores an object, mutates it after
  storing, then retrieves it. The in-memory implementation returns
  the mutated version (same reference); the database returns the
  original (serialized at write time).
- **Retrieve-then-mutate**: test retrieves an object and modifies a
  field. The in-memory implementation's stored copy changes too (same
  reference); the database's stored row is unaffected.
- **Shared nested structures**: an in-memory implementation stores a
  reference to a slice or map field. Two tests that retrieve the
  "same" object share the underlying memory — mutating one affects
  the other, violating test isolation in a way that never happens
  with a database.

These bugs are invisible in implementation-specific tests — each
implementation is internally consistent. The divergence only surfaces
when coordinator code relies on one behavior and production provides
the other. Step 3's mutation scenarios exist to catch this class.

### Business behavior vs. implementation concerns

The compliance suite tests observable business behavior — what a
consumer calling the interface can see. If the interface declares
`GetTop(n)`, the suite verifies all implementations return the same
N items in the same order. SQL does this with `ORDER BY score LIMIT n`;
in-memory does it with a sort and slice. The implementations are
fundamentally different, but the suite verifies they agree on what,
not how.

Implementation-specific tests (step 5) cover what the compliance suite
can't: query performance under load, database-specific quirks (JSONB
indexing behavior, connection pool exhaustion), retry semantics, cache
eviction timing. These are real concerns about how the implementation
fulfills the contract.

The line: if a consumer calling the interface can observe the
difference, it's contract behavior — test it in the compliance suite.
If only someone reading the implementation can observe it, it's an
implementation concern — test it in the implementation's own file.

### Hand-rolled doubles vs. auto-generated mocks

Most coordinator tests use auto-generated mocks — specify return
values per test, verify calls happened. This works when the
coordinator's relationship to the collaborator is simple: call a
method, get a result, pass it along. The Unit Testing strategy's
all-or-none mocking rule applies regardless of which approach you
choose.

Compliance suites with hand-rolled doubles earn their place when the
interface contract involves stateful behavior across operations —
what Create stores affects what Get returns, what Publish sends
affects what Subscribe yields. With auto-mocks, each coordinator
test re-encodes these behavioral relationships: "when Get is called,
return X." That encoding becomes the test's responsibility, varies
per test, and can silently diverge from real behavior.

A hand-rolled in-memory implementation encodes the behavioral logic
once. The compliance suite proves it matches the real implementation.
Every coordinator test then gets realistic stateful behavior without
re-encoding it — the double just works like the real thing, because
the suite proved it does. The investment is higher upfront but
amortizes across every test that uses the double.

This doesn't mean auto-mocks are wrong. For stateless interfaces or
simple request-response patterns, auto-mocks are simpler and
sufficient. Compliance suites are for contracts where the behavioral
relationships between operations are the thing you need to get right.

### Interface design feedback

When compliance scenarios are hard to write — error conditions are
ambiguous, success criteria depend on implementation details — the
interface contract is underspecified. Writing the compliance suite
alongside the first implementation forces the contract to be explicit.

### Grow Don't Break as a cross-cutting benefit

When an interface evolves — a new method added, an error condition
tightened — the compliance suite catches every implementation
(including test doubles) that hasn't caught up. This primarily serves
GDB, not NSF — noted as a cross-cutting benefit, not an outcome.

### Cross-references

- **Isolated Test Execution**: ITE provides the isolation technique
  the factory parameter implements. Step 4 explicitly references ITE.
- **Test Data Builders**: TDB provides the builder pattern for
  scenario inputs and expected outputs. Step 3 explicitly references
  TDB.
- **Unit Testing**: CoC's classification creates the boundary
  interfaces that compliance suites test. The trust chain above
  explains how compliance suites make Unit Testing's test doubles
  safe to depend on.
- **Contract Testing**: Contract testing verifies agreements with
  *external* parties. Compliance testing verifies implementations of
  *internal* interfaces. Both prevent shared fate, at different
  boundaries.

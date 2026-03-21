# Black Box Integration Testing
PRINCIPLE: Don't Fly Blind

1. Enter through the public interface. Identify how consumers interact with
   the system — HTTP endpoints, browser interactions, CLI commands. The test
   sends a request through that interface and asserts on what comes back. No
   calling internal functions or importing internal packages.
2. Run real internal components, stub everything outside the service
   boundary. The service's database, cache, sidecar workers, and
   background processors run for real. Other services, third-party APIs,
   and managed infrastructure are stubbed or replaced with local
   equivalents. The line: if it deploys as part of this service, it's
   real; if it's across a service boundary, it's stubbed.
3. Scope each test's data for parallel execution. Each test creates its
   own isolated slice and operates entirely within it. Tests must not
   assume an empty database or depend on data from other tests. The
   Isolated Test Execution strategy provides the full technique.
   - The natural scope is usually a user, tenant, or document — whatever
     the system already partitions by.
   - When no natural scoping identity exists (global configuration,
     system-level settings), use a unique namespace or key prefix per test.
4. Organize tests by feature, not by implementation. Each test file or
   group maps to a user-visible capability ("checkout," "user
   registration"), not to an internal module.
   - When grouping is unclear: list the endpoints or commands involved,
     look for shared nouns (the resource or concept they operate on), and
     name the group after that concept.
   - Present the grouping for review if the concept isn't obvious.
5. Budget one happy path and one unhappy path per feature boundary. The
   happy path proves the full stack works for the core scenario. The
   unhappy path proves the system handles the most important failure mode
   a consumer would hit.
   - When unclear which failure to test: list the failure modes a consumer
     could hit at this boundary, rank by blast radius (data loss > wrong
     result > degraded experience > cosmetic), and test the top one.
   - If ranking is ambiguous, present the top two candidates with their
     blast radius reasoning for review.

OUTCOMES:
- Every feature boundary has at least one test that exercises the full
  path through the public interface with real infrastructure.
- External services are stubbed — test failures indicate our system is
  wrong, not that an external service is down.
- Tests produce reliable signal under parallel execution — no false
  failures from data collisions between tests.
- Tests survive internal refactoring — reorganizing packages or renaming
  internal functions doesn't break tests that only touch the public
  interface.
- New integration tests are justified by a new feature boundary or a bug
  that no lower layer could catch — not by new internal complexity.

MISAPPLICATION: Testing every code path through integration tests because
"it's more realistic" — leading to a slow, brittle suite where failures
don't localize. Or writing integration tests that import internal packages
to set up state, coupling the test to implementation structure and losing
the black box constraint. Or stubbing the database to "make tests faster"
— losing the signal that queries, migrations, and constraints actually work.
SKIP WHEN: The code is a pure library with no integration boundaries —
unit tests via the Unit Testing strategy are the only layer that applies.

---
<!-- Rationale below — read when creating protocols, reviewing, or
questioning the strategy. Not needed for routine application. -->

## Rationale

### Why real internal components, stubbed external services

The value of a black box integration test is proving the full stack works
within the service boundary — request enters, hits real database queries,
real cache lookups, real worker processing, and produces a real response.
Stubbing the database defeats this: you lose signal on whether queries
work, migrations applied correctly, and constraints hold.

Other services are external even when your team owns them. If service A's
test suite requires service B to be running, the tests have shared fate —
service B's deployment, bugs, or downtime break service A's tests. Stubs
isolate the signal to this service's behavior.

For managed infrastructure like SQS or S3, local equivalents (localstack,
MinIO) preserve the signal without depending on cloud availability. The
message flow is part of your service; the specific queue provider isn't.

### Parallel execution requires data scoping, not database isolation

The intuitive approach to test isolation is giving each test its own database.
This is expensive, slow, and doesn't match production. The better approach:
each test scopes its data under a unique identity (user, tenant, organization)
and queries only within that scope. Tests share the same database just like
production serves multiple consumers on the same infrastructure.

This makes tests realistic — they exercise the same concurrent-access patterns
production sees. And it eliminates a class of flaky tests for the right
reason: not because tests are isolated by infrastructure, but because each
test's data is invisible to other tests by design. If a test can only see its
own user's data, it can't be affected by another test's user.

When a test needs to verify behavior on the second execution (idempotency,
retry logic), it reuses its own scoped identity — that's intentional state
reuse within one test, not accidental sharing between tests.

### What "feature boundary" means

A feature boundary is where a consumer-visible capability enters the system.
For an HTTP API, each resource or workflow is a boundary — "create an order,"
"authenticate a user." For a CLI, each command or subcommand. For a browser
app, each user flow.

The boundary is defined by what consumers see, not by how the code is
organized internally. Two endpoints that serve the same feature
(`POST /orders` and `GET /orders/{id}`) share a boundary. Two endpoints
in the same Go package that serve different features are different
boundaries.

### Why one happy, one unhappy

Black box integration tests are expensive: they spin up real infrastructure,
make real network calls, and run slower than unit tests. Each test must
justify its cost in signal. The happy path proves the wiring works
end-to-end. The unhappy path proves the system handles the most important
consumer-facing failure.

This budget isn't a hard cap — it's a forcing function. When you want a
third integration test, ask: could a unit test catch this instead? Usually
it can. The integration test proves the path; unit tests prove the details
along the path. See the meta-strategy's step 5 for when bugs escape upward.

### Black box means feature-organized

When tests can only reach the public interface, they naturally organize
around what the system does (features) rather than how the code is
structured (packages). This is self-reinforcing: feature-organized tests
don't break when you refactor internals, and the inability to import
internals prevents accidental coupling. Language-specific protocols
determine where these tests live in the filesystem, but the organizational
principle is the same everywhere.

### What a black box integration test failure tells you

A failing black box integration test gives a broad signal: the system's
behavior through its public interface doesn't match expectations. The cause
could be wiring (components not connected correctly), data (query or
migration broken), or logic (business rule wrong). This breadth is the
tradeoff for testing the full stack.

When a black box integration test fails, the diagnostic sequence is:
reproduce the failure, identify the layer where the actual behavior diverges
from expected, then add a unit test at that layer before fixing. This is the
meta-strategy's step 5 in practice — the integration test caught it, now
push the test down so a cheaper test catches it next time.

### Cross-cutting principles

Steps 3 and 4 draw from No Shared Fate and Structure is Intent respectively.
Data scoping (step 3) is an isolation technique; feature organization
(step 4) is a structural choice. Both serve Don't Fly Blind through signal
quality — flaky tests from data collisions and implementation-coupled tests
that break on refactoring both degrade the signal that tells you whether
the system works. The primary principle is DFB; the techniques borrow from
NSF and SII to make the signal reliable and interpretable.

### Relationship to the meta-strategy

This sub-strategy provides the technique for the meta-strategy's step 3
bullet: "Behavior as consumers see it → black box integration test." The
meta-strategy selects when to use black box integration tests; this strategy
explains how to write them. The meta-strategy's step 5 (push bugs to the
cheapest layer) applies to all test layers and isn't repeated here.

### Cross-references

- **Public API Surface Testing**: PAST tests at the package boundary;
  this strategy tests at the system boundary (HTTP, CLI). Different scope,
  same posture — exercise through the public interface only.

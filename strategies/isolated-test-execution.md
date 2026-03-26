# Isolated Test Execution
PRINCIPLE: No Shared Fate

1. Scope each test's state under a unique identity. Create a fresh user,
   tenant, or document — whatever the system naturally partitions by — and
   run all test operations within that scope. When no natural scoping
   identity exists (global configuration, system-level settings), use a
   unique namespace or key prefix.
   - When the natural scope isn't obvious: list the entities the test
     creates or modifies, identify which entity other operations are
     queried through, and scope under that entity.
2. Use factories for test setup, not fixtures or shared state. Each test
   calls a factory that creates its scoped identity and any required
   state. Factories are invoked per-test — no package-level mutable
   variables, no suite-level setup, no test-file-level initialization
   that produces mutable state shared between tests. (Package-level
   constants and read-only configuration are fine — shared immutable
   state doesn't create coupling.)
3. Default factories to deterministic, production-realistic data. Given
   the same scoped identity, the factory should produce the same state
   every time — realistic field values, correct relationships,
   production-appropriate defaults. Not zero values, not random data,
   not placeholder strings. When a test needs a specific value, it
   overrides that field explicitly — the override is the only thing
   that differs from the factory default, making the test's intent
   visible at a glance. Secondary unique fields (emails, slugs) should
   incorporate the scoped identity from step 1 to prevent collisions
   across tests.
4. Validate parallel safety. Tests must pass when run concurrently with
   arbitrary other tests, on a database containing arbitrary other test
   data. If a test fails only when run alone (requires a clean database)
   or only when run with specific other tests (data collision), the
   scoping from step 1 is incomplete.
   - When a parallel failure occurs: identify which data the failing test
     reads or writes that isn't scoped under its unique identity, and
     scope it.
   - Clearing the database before a test run is fine — it resets
     accumulated data without affecting per-test isolation. Do not clear
     between individual tests or after a run — inter-test clearing is
     infrastructure isolation (not data scoping), and post-run data is
     valuable for debugging failures.

OUTCOMES:
- Each test operates within its own scoped slice of shared infrastructure
  — no test can observe or affect another test's data.
- Given the same scoped identity, test factories produce the same state
  on every call — test-specific overrides are explicit and visible in
  the test.
- No package-level mutable variables exist in test files.
- Tests pass regardless of execution order, in parallel, on a database
  with existing data.

MISAPPLICATIONS:
- Infrastructure isolation instead of data scoping — a factory that
  creates "isolated" state but relies on a clean database to avoid
  collisions. The isolation is through infrastructure (empty DB per
  test), not data scoping (unique identity on shared infrastructure).
- Random data for variation — non-deterministic factory data
  introduces non-deterministic failures, and every debugging session
  starts with "what data did the factory produce this time?" instead
  of "what did my code change?"
SKIP WHEN: Tests that don't share mutable infrastructure. Computation
tests have no external state; coordinator tests replace all collaborators
with per-test doubles (see Unit Testing strategy). This strategy applies
when tests share real infrastructure — databases, caches, queues — and
need data-level isolation.

---
<!-- Rationale below — read when creating protocols, reviewing, or
questioning the strategy. Not needed for routine application. -->

## Rationale

### Data scoping, not infrastructure isolation

The intuitive approach to test isolation is giving each test its own
database — a clean slate guarantees no collisions. This is expensive,
slow, and doesn't match production. Production serves multiple tenants on
shared infrastructure; tests should do the same. Each test creates a
unique identity and operates within that identity's scope. Tests share
the database just like production users share the system.

This is why data scoping eliminates the need for per-test infrastructure:
when each test's data is invisible to other tests by design, the database
can contain anything and tests still pass. No teardown required, no
ordering dependencies, no "reset before each test."

### Deterministic data and No Shared Fate

Random test data introduces a form of shared fate between test success
and random state. A test that passes 99% of the time and fails when the
random name contains a special character is a non-deterministic failure —
exactly what NSF exists to prevent. Deterministic factories eliminate
this coupling: the same factory call always produces the same data, so
failures are always reproducible.

Deterministic data also makes tests self-describing. When the only
differences between a test and the factory defaults are the explicit
overrides, you can read the test and immediately see what matters — the
overrides ARE the test scenario. With random data, you can't tell what's
intentional and what's noise.

### Production-realistic defaults and Fail Early and Loud

Step 3's insistence on production-realistic field values is primarily a
FEAL concern that manifests in test setup. When factories produce zero
values, empty strings, or placeholder data that wouldn't exist in
production, tests exercise code paths that production never hits. Bugs
that surface with realistic data stay hidden.

The connection to NSF: if factories produce identical placeholder data
across tests (every user gets `Name: "test"`), secondary unique
constraints cause collisions between tests that appear properly scoped.
Incorporating the scoped identity into secondary unique fields (step 3)
is both a realism and an isolation technique.

Cross-reference: Scrub on Entry (FEAL) establishes the pattern of making
boundaries explicit. The same principle applies here — the boundary
between "what the factory provides" and "what the test overrides" should
be explicit and intentional.

### Transaction rollback as isolation

A common alternative to data scoping is wrapping each test in a
transaction and rolling back afterward. This looks like isolation — each
test sees a clean slate — but it changes transactional behavior compared
to production. Tests can't verify commit hooks, multi-transaction flows,
or concurrent access patterns. For unit-level adapter tests that need
speed, transaction rollback is a legitimate tradeoff. For integration
tests that need to prove the full path works, it masks the same class of
bugs as in-memory substitution — the test environment behaves differently
from production in ways that matter.

### Infrastructure fidelity is a test layer concern

This strategy prescribes data isolation, not infrastructure choice. Unit
tests should be fast — in-memory substitutes for databases are
appropriate at that layer. The adapter that bridges to real infrastructure
(e.g., a PostgreSQL adapter) should have its own integration tests that
run against real infrastructure and follow this strategy's isolation
technique. Not every unit test flows through real PostgreSQL — but a test
somewhere must verify the adapter works against real infrastructure. This
is a Test Layer Selection decision, not an isolation decision.

### Relationship to Unit Testing

The Unit Testing strategy classifies code as computation or coordination
and prescribes different testing approaches. This strategy operates at a
different level — it covers how test state is set up:

- **Computation tests**: Naturally isolated (no external state). This
  strategy's SKIP WHEN applies.
- **Coordinator tests**: Isolation through mocking (all collaborators
  replaced per-test, per Unit Testing step 3.3). This strategy's SKIP
  WHEN applies — mock lifecycle is per-test by design.
- **Integration tests**: Need explicit data scoping (this strategy's
  primary domain). Black Box Integration Testing step 3 references this
  strategy.

### Scaling

As test suites grow, isolation becomes critical. A small suite can
tolerate shared state and sequential execution — collisions are rare and
debugging is manageable. A large suite cannot. This strategy front-loads
the isolation investment so that adding tests doesn't increase pain.
When every test scopes its own data, the hundredth test is as safe to
add as the first. Parallel execution comes for free because isolation
was the design, not an afterthought.

### Cross-references

- **Test Data Builders** (downstream): Provides the pattern for how
  factories are structured — composable, override-friendly, maintainable.
- **Compliance Test Suites** (downstream): Uses factories to set up the
  state needed for compliance verification.
- **Parameterized Test Structure**: PTS step 4's uniform body ensures
  independent case execution; ITE provides the data-level isolation
  that makes parallel test execution safe.
- **Whole-Object Assertion**: WOA extends ITE's determinism principle
  from setup to assertions — deterministic factories for test inputs
  pair with deterministic expected values.

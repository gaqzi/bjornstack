# No Shared Fate
Units that should be independently testable, deployable, or changeable must not couple through shared mutable state — each operates in isolation so that one's failure cannot silently break another.
VIOLATION: Two tests that pass individually but fail when run in parallel because they both read and write the same database row.
VIOLATION: Two services sharing a database where one team's migration breaks the other's queries.
WHY: Shared mutable state creates invisible coupling — failures become non-deterministic and root causes become untraceable.

---
<!-- Rationale below — read when creating strategies, reviewing, or
questioning the principle. Not needed for routine application. -->

## Rationale

When independent things share mutable state, they aren't independent anymore.
They just look independent until one of them changes. Then you get the worst
kind of failure: non-deterministic, unreproducible, and untraceable.

### In testing

Tests must run in parallel. Parallel tests are fast, and fast tests are tests
you actually want to run. But parallel execution requires isolation — and
isolation doesn't mean each test gets its own database. It means each test
scopes its data so it can't collide with other tests.

The practical approach: create a unique user (or team, or document — whatever
the natural scope is) for each test case, and scope all operations under that
identity. Each test works in its own slice of the shared infrastructure, just
like production works with multiple tenants on the same system. If you need to
test what happens the second time an operation runs, reuse that test's scoped
identity — that's intentional shared state within a single test, not accidental
shared state between tests.

Tests that scope their data properly work regardless of what else is in the
database — no pristine empty state required, just like production.

### In services

Services that share a database have shared fate. One team's migration can
break another team's queries. One service's write patterns can degrade another
service's read performance. The fix is service boundaries with explicit
communication — each service owns its data and exposes it through an API or
messages. No reaching into another service's tables.

This is a hard line: services communicate through APIs or messages, not through
shared databases. If two services need the same data, one owns it and the
other requests it. This costs more upfront but eliminates an entire class of
coupling failures.

### In deployment

If deploying service A requires also deploying service B, they have shared
fate. Independent deployability is one of the core benefits of service
boundaries. When services share a database schema, you lose this — schema
changes must be coordinated across all dependent services, which means
coordinated deployments, which means shared fate.

### The "but it's easier to share" trap

Sharing state is always easier in the short term. One database is simpler than
two services with an API between them. A shared test fixture is simpler than
per-test factories. Global state is simpler than dependency injection. But
shared state trades short-term simplicity for long-term coupling, and the
coupling cost grows with the number of things sharing the state. The math
always catches up.

### Shared immutable state is fine

This principle is about *mutable* state. Shared configuration, constants,
and read-only reference data are not violations — they can't cause one unit's
change to break another because they don't change. The moment the shared state
becomes writable, No Shared Fate applies.

# Fail Early and Loud
Code must surface problems visibly and early rather than absorbing them into implicit defaults, silent fallbacks, or hidden paths.
VIOLATION: A hashmap lookup returns null, a downstream null-check substitutes a default, and the bug surfaces three layers later as wrong data in production.
VIOLATION: A parameterized test uses `if tc.expectError` to branch between error and success assertions, hiding which path actually executed when the test fails.
WHY: Every silent failure is a bug that compounds — the distance between cause and discovery is the cost.

---
<!-- Rationale below — read when creating strategies, reviewing, or
questioning the principle. Not needed for routine application. -->

## Rationale

The original insight came from a Ruby codebase: you'd fetch a value from a
hash and get nil instead of the value you expected. Then a nil-check in the
implementation would provide a "safe" default. Then another layer would accept
that default as normal input. Three layers of code coordinating — unwittingly —
to produce a production bug that's nearly impossible to trace.

The fix is philosophical: **prefer things that go boom.** An exception at the
point of failure is infinitely more useful than wrong data three layers later.

### What "early" means

"Early" means at the point where the problem is detectable, not at the first
possible moment. Batching validation errors (returning all 5 form errors at
once instead of stopping at the first) is not a violation — you're still
surfacing everything, you're just batching the surface. The violation is when
errors are silently absorbed, not when they're collected.

### What "loud" means

"Loud" means the failure is visible to the developer without requiring them to
trace through code. An exception with a stack trace is loud. A log line buried
in verbose output is not. A test that fails with a clear message pointing at
the problem is loud. A test that passes but tested the wrong path is silent.

### Explicit fallbacks are not violations

Circuit breakers, graceful degradation, cached responses when an API is down —
these are explicit, designed fallbacks where the code *loudly chooses* to
degrade. The system knows it's degrading and signals that fact. The violation
is *implicit* fallbacks where no one decided to degrade and no one knows it's
happening.

### Why conditional test logic belongs here

A test with `if tc.expectError` has two hidden paths. When the test fails, you
don't know which path executed. The failure is silent in the same way a
swallowed null is silent — the test looked like it ran, but you can't tell what
it actually tested. Replacing conditionals with strategy functions (every test
case calls the same code path) makes the test fail early and loud.

### Whole-object assertions belong here

Asserting on two fields when the object has ten is a quiet death for the other
eight. If `ApplyDiscount` accidentally zeros out `TaxRate`, a check on
`TotalPrice` and `Discount` won't notice. Whole-object comparison catches
unintended side effects — it's the "fail loud" principle applied to assertions.

### Defaults that diverge from production belong here

A test helper that defaults to an in-memory store when production uses
PostgreSQL is an implicit fallback. You think you're testing production
behavior, but you're testing a convenient fiction. If you must have defaults,
they should match what production uses. Development and staging environments
pick different options explicitly.

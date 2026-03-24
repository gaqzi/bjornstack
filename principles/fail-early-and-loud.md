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

### Assertion messages are the "loud" in test failures

A test that fails with "expected true, got false" went boom — but it didn't
tell you anything. Some frameworks don't even report which assertion in a test
body failed, just that the test failed — you end up debugging the wrong line
because nothing told you which one triggered it. A loud assertion message says
what was expected, what actually happened, and in what context, without
requiring the developer to open the test source. The concrete mechanism varies
by language and framework (diff output, format strings, custom matchers), but
the principle is universal: if a failure message requires reading code to
understand what went wrong, it isn't loud enough.

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

### External boundary validation belongs here

When data arrives from an external system — an API response, a message from
a queue, a webhook payload — the temptation is to be "liberal in what you
accept" (Postel's Law). In practice, liberal acceptance means silently
absorbing garbage that poisons your domain interior. An empty field that should have a
value, amounts that don't sum up, enum values you've never seen — accepting
these silently is the same failure mode as swallowing a null. The bug
surfaces later, far from the point where you could have caught it.

FEAL at system boundaries means: validate what you act on, ignore what you
don't recognize. An unknown field in a response is safe to ignore — you're
not making decisions based on it, and ignoring additions lets the upstream
system grow (consistent with No Shared Fate's Grow Don't Break strategy).
But an enum value you don't recognize in a field you *do* act on is unsafe —
you'd be making decisions on something you don't understand. The line is:
if your code branches on it, computes with it, or stores it as a fact,
validate it. If it's just passing through or you don't use it, let it be.

The goal is a tight domain interior that only works with pristine objects — data that
has passed all checks on the fields that matter before it enters your
domain logic. This is the same idea as DDD's anti-corruption layer: your
system's interior should never have to wonder whether the data it acts on
is valid. It refines Postel's Law rather than rejecting it outright: be
tolerant of additions you don't use, strict about values you depend on.

The Scrub on Entry strategy makes this operational.

### Defaults that diverge from production belong here

A test helper that defaults to an in-memory store when production uses
PostgreSQL is an implicit fallback. You think you're testing production
behavior, but you're testing a convenient fiction. If you must have defaults,
they should match what production uses. Development and staging environments
pick different options explicitly.

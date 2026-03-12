# Test Layer Selection
PRINCIPLE: Don't Fly Blind

1. Start from the walking skeleton. The first test for a new feature or
   boundary proves the path works end-to-end — a request enters through
   its public interface, passes through coordination, and produces a
   result. This is a black box integration test.
2. Push tests down to the cheapest layer that catches the failure. Unit
   tests are fast and precise — if a bug can be caught by testing a
   function in isolation, don't test it through an integration test.
   Integration tests are slow and broad — reserve them for behavior that
   unit tests can't see.
3. Select the layer by what you're verifying. Unit tests and black box
   integration tests apply to nearly every project. Contract and
   end-to-end tests are adopted per-project based on need.
   - Logic and computation → unit test (per Unit Testing strategy).
   - Behavior as consumers see it → black box integration test. Test
     through the public interface (HTTP for an API, browser for a UI,
     commands for a CLI). External dependencies are always stubbed —
     this verifies our behavior, not theirs.
   - Agreements with external parties → contract test. Either validate
     a contract provided by an external party, or provide consumer-driven
     contract tests for what we depend on. If we provide something for
     others, validate our integration per their contracts as well.
   - Full flows through the real system → end-to-end test. Points at
     prod or a staging/dev environment to verify it all works together.
4. Budget each layer differently. Black box integration tests: one happy
   path and one unhappy path per boundary — they're slow, so each must
   earn its place. Contract tests: cover what we actually use and depend
   on. End-to-end tests: major flows and areas with the most risk. The
   balance requires judgment — when unclear, ask what failure would be
   most expensive to miss, and test that path.
5. When a bug escapes to a higher layer, add a test at the lowest layer
   that would have caught it. A production bug that a unit test could
   catch becomes a unit test, not another integration test. If no lower
   layer could catch it, the bug is genuinely about integration — add
   the test where it's visible.

OUTCOMES:
- Every new feature has at least one black box integration test proving
  the path works before unit tests are written underneath.
- Each test exists at the cheapest layer that can catch its failure class.
- Black box integration tests stub all external dependencies.
- Bug fixes include a test at the lowest layer that would have caught
  the bug.

MISAPPLICATION: Writing only unit tests with no integration test proving
the path is wired — all the parts work in isolation but the system doesn't
work. Or the inverse: testing everything through integration tests because
"it's more realistic," leading to a slow, brittle suite where failures
don't localize.
SKIP WHEN: The code is a pure library with no integration boundaries —
unit tests are the only layer that applies, and the Unit Testing strategy
covers it directly.

---
<!-- Rationale below — read when creating guidelines, reviewing, or
questioning the strategy. Not needed for routine application. -->

## Rationale

### Walking skeleton first

The MMMSS walking skeleton — "the smallest deployable thing that proves
the path works end-to-end" — maps directly to step 1. The first test for
a feature is the integration test that proves the wiring works. This test
exists before any unit tests, because a system where all the parts work
in isolation but aren't wired correctly is a system that doesn't work.
Unit tests fill in underneath: once the path is proven, push detail tests
down to the cheapest layer.

### Why Don't Fly Blind, not No Shared Fate

The strategy is about *having signals at each level* — knowing when
something is broken. That's DFB. NSF is a secondary benefit: BB
integration tests don't break when externals change because they're
stubbed, which is isolation (NSF). But the driver is signal coverage,
not isolation. You choose test layers to ensure you can see failures at
every relevant boundary, not primarily to decouple test suites from each
other.

### Why black box integration tests stub externals

A BB integration test answers: "does our system do what it should?" If
external dependencies are real, a test failure might mean our code is
broken, or it might mean an external service is down. The signal becomes
unreliable — you can't tell whose fault it is. Stubbing externals
isolates the signal to our behavior. Contract tests and e2e tests exist
as separate layers precisely for this: contracts verify external
agreements, e2e verifies the full chain. Each layer has a clear signal.

### Black box tests are organized by feature, not implementation

BB integration tests verify behaviors and features, not internal
structure. They exercise the system through its public interface and
shouldn't depend on internal packages. This means they're naturally
organized by what the system does (features, user flows) rather than
by how the code is structured (packages, modules). The physical
organization reinforces the black box constraint — when tests can't
reach internals, they can't accidentally test them. Language-specific
guidelines determine where these tests live in the filesystem.

### Budget is judgment, not formula

Step 4 gives heuristics, not rules. The "2 per boundary" guideline for
BB integration tests is a starting point. Contract test coverage follows
from what we actually depend on. E2e test count follows from risk
assessment — the payment flow gets more coverage than the settings page.
When the right budget is unclear: identify which failure would be most
expensive to miss, start there, and expand only when a gap is
demonstrated by step 5.

### Sub-strategies serve their own principles

This meta-strategy orchestrates test layers under Don't Fly Blind.
Sub-strategies each serve their own primary principle. This isn't a
conflict — the meta-strategy selects the layer, the sub-strategy
provides the technique.

### The test ice cream cone

The default failure mode is an inverted pyramid: many e2e tests, few
unit tests. This happens when teams start testing from the user's
perspective (natural and well-intentioned) without pushing tests down.
The result is a slow, flaky suite where every failure requires
investigation to localize. Step 2 exists specifically to counteract
this — always ask "could a cheaper test catch this?"

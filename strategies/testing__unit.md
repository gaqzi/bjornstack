# Unit Testing
PRINCIPLE: Compute or Coordinate

1. Classify the code under test: does it call other objects and pass data
   between them? If classification is unclear, the code is likely mixing
   concerns — refactor until it classifies cleanly.
2. Computation (no collaborators):
   1. Test with real inputs and outputs — no mocks, no test doubles. The
      function's signature and types define the test surface.
   2. Cover the meaningful input space: valid cases, boundary conditions,
      and error cases. Each test verifies a return value or side effect
      directly.
3. Coordination (calls collaborators):
   1. List the direct collaborators — the objects the coordinator calls
      directly. Ignore their transitive dependencies. If a coordinator
      has more than four, look for domain concepts hiding in the
      collaboration — two or more objects often form a cohesive whole
      that could become a single dependency.
   2. Verify every collaborator is received, not created. If the
      coordinator constructs its own dependencies or reads global state,
      those are hidden collaborators — they can't be replaced in tests.
   3. Replace every direct collaborator with a test double. All of them,
      never a subset.
   4. Write N+1 tests: one error-path test per collaborator that can
      fail, plus one happy-path test where all collaborators succeed.
   5. If the test count significantly exceeds N+1, or the coordinator
      contains conditionals beyond error checks, it's likely mixing
      computation into coordination — extract the logic.

OUTCOMES:
- Computation tests use real values only — no test doubles.
- Every coordinator's direct collaborators are received as dependencies
  and replaced with test doubles — no real implementations, no hidden
  construction.
- Coordinator test count approximates N+1: one error path per failable
  collaborator plus one success path.
- Coordinator test failures indicate wiring problems, not logic problems.
- No coordinator has more than four direct collaborators.

MISAPPLICATION: Mocking transitive dependencies (a collaborator's own
dependencies) instead of only direct ones, creating brittle tests coupled
to internal wiring two layers deep. Or treating the collaborator-count
heuristic as a hard limit — sometimes a coordinator legitimately
orchestrates five services in a pipeline, and splitting would create two
coordinators that must run in sequence.
SKIP WHEN: The code is a thin wrapper or trivial accessor where
classification adds ceremony without insight — the test is obvious from
reading the function signature.

---
<!-- Rationale below — read when creating guidelines, reviewing, or
questioning the strategy. Not needed for routine application. -->

## Rationale

### Foundation vocabulary

This strategy establishes the compute/coordinate testing vocabulary that
downstream strategies reference. The classification descends from Jay
Fields' solitary vs. sociable unit tests (*Working Effectively with Unit
Tests*) via Justin Searls' compute-or-collaborate framing — which we adopt
because it names what the code *does* rather than how the test *behaves*.
"Isolated Test Execution" assumes you've already classified code to know
what to isolate. "Public API Surface Testing" assumes you know which side
of the split you're testing. "Earned Abstraction" uses collaborator count
as an extraction signal. Changes to the vocabulary here propagate
everywhere — hold this strategy to a higher coherence bar than most.

### Why all-or-none serves Consistent Beats Correct

Step 3.3's all-or-none rule exists because of CBC's second violation:
"Mocking some collaborators with real implementations and others with test
doubles in the same test because 'this one is simple enough to use
directly.'" When a coordinator test mixes real and mock dependencies, a
failure could be a wiring problem *or* a behavior change in the real
dependency. The all-or-none rule eliminates that ambiguity — every
coordinator test failure means wiring, every computation test failure means
logic. The consistency makes failures interpretable without investigation.

### The trivial-transform edge case

A coordinator that does `result := svc.Get(id); name := toUpper(result.Name);
svc2.Save(name)` — is `toUpper` computation? Is it a hidden collaborator?

Neither. A trivial inline transform (a single expression, no conditionals)
is still coordination. The test: if removing the transform doesn't change
the test structure — you'd still mock the same collaborators — it's not
computation worth extracting. More importantly, the transform's effect is
visible in what gets passed to the next collaborator. If `toUpper`
disappeared or was wrong, the mock expectation on `svc2.Save` would catch
it — the test already covers this behavior without separate logic tests.

Forcing extraction of every inline transform violates Practicality Beats
Purity. The boundary is conditionals: if the transform has branches, error
cases, or multi-step logic, it's computation hiding inside coordination.
Extract it. If it's a single expression, leave it.

### Coordinators that scrub

A coordinator's collaborator may be responsible for scrubbing — an HTTP
handler that calls a mapper to convert raw input into domain types is
coordinating validation, not performing it. The handler receives a request,
calls a collaborator to scrub it into domain types, then calls services
with clean data. The scrubbing collaborator is tested separately as
computation. The handler's test mocks the scrubber like any other
collaborator and verifies the wiring: raw input goes in, scrubbed output
gets passed along.

### Why N+1

Each collaborator error path is independent — the coordinator's job is to
propagate the failure, not to recover from it. One test per failure mode
proves the wiring handles it. The happy path proves the wiring works when
nothing fails. If you find yourself needing significantly more tests, the
coordinator likely contains decision logic that should be computation.

### Relationship to the meta-strategy

This sub-strategy provides the technique for the meta-strategy's step 3
bullet: "Logic and computation → unit test." The meta-strategy selects when
to use unit tests; this strategy explains how to write them by classifying
code as computation or coordination. The meta-strategy's SKIP WHEN also
delegates directly here — when no integration boundaries exist, unit tests
are the only layer and this strategy covers it.

### Cross-references

- **Domain-First Packaging**: Where domain types live between compute and
  coordinate modules. Coordinators pass domain types between collaborators
  — those types should live at the domain boundary, not be owned by either
  side.
- **Scrub on Entry**: See "Coordinators that scrub" above. A coordinator
  delegates scrubbing to a collaborator rather than performing it inline.
  The boundary validation is computation; the coordinator just wires it.
- **Isolated Test Execution**: ITE governs test state setup when tests
  share real infrastructure. Computation tests (no external state) and
  coordinator tests (all collaborators mocked) don't need it — integration
  tests that hit real databases or caches do.
- **Earned Abstraction**: EA's configuration bloat check (step 4) is a
  complementary detection signal — when an abstraction requires callers to
  configure which behavior path to follow, the coordinator is mixing
  computation into coordination. Collaborator count (step 3.1 here) and
  configuration bloat (EA step 4) detect the same problem from different
  angles.
- **Public API Surface Testing**: PAST determines testing posture — test
  through the public surface. UT classifies code as computation or
  coordination; PAST says to exercise it through the public API. The two
  compose: classify, then test through the public surface.
- **Compliance Test Suites**: CTS verifies interface implementations
  using the boundary interfaces that UT's compute/coordinate classification
  creates. The trust chain runs through UT's test doubles.
- **Parameterized Test Structure**: PTS provides the table-driven
  structure for computation tests. UT classifies code as computation; PTS
  structures the resulting test cases into input/expected/assertion rows.

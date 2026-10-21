# Unit Testing
TENET: Compute or Coordinate

1. Classify the code under test: does it call other objects and pass data
   between them? If classification is unclear, the code is likely mixing
   concerns — refactor until it classifies cleanly.
2. Computation (no collaborators):
   1. Test with real inputs and outputs — no mocks, no test doubles,
      even for other pure functions it calls. The function's
      signature and types define the test surface.
      Every test spells that signature out, so check its values are
      cohesive. Three or four are fine; past that, they usually
      describe something in the domain worth naming — pass that. The
      number prompts the question; it is not a limit. Pass what the
      function works on: nothing much bigger than it uses, and nothing
      invented for this one call.
   2. Cover the meaningful input space: valid cases, boundary conditions,
      and error cases. Each test verifies a return value or side effect
      directly.
3. Coordination (calls collaborators):
   1. List the direct collaborators — the objects the coordinator calls
      directly, including what starts its work, such as a timer or a
      queue it waits on. Ignore their transitive dependencies. If a
      coordinator has more than four, look for domain concepts hiding
      in the collaboration — two or more objects often form a cohesive
      whole that could become a single dependency.
   2. Verify every collaborator is received fully set up, not created.
      If the coordinator constructs its own dependencies, reads
      global state, or calls package functions that do real work —
      I/O, or domain logic with branches — those are hidden
      collaborators: they can't be replaced in tests. Diagnostic
      logging and metrics, unlike audit records the work requires,
      are the accepted exception: passing them through every call
      costs more than it gives, so they are not collaborators and
      stay out of the count, the doubles and the N+1 tests.
      For each data value in its signature, ask what it is for. One
      the coordinator acts on — a request, a message, an order its
      caller loaded, and anything that comes with it, such as a
      format the user picked — is its input. One fixed before the
      call that only says how or for whom to do the work — which
      tenant it serves, how many items to fetch at a time — is chosen
      while setting up the work: build it into the collaborator that
      uses it, so the coordinator never hands it on. Values one
      collaborator returns and the coordinator passes to another are
      its work, not its signature.
   3. Replace every direct collaborator with a test double. All of them,
      never a subset. Where a double lives, and when to reuse one,
      follows Test Data Builders step 2.
   4. Write N+1 tests: one error-path test per collaborator that can
      fail, plus one happy-path test where all collaborators succeed.
      Each error-path test verifies that this coordinator's own error
      interface is consistent — callers should not need to know which
      internal collaborator failed. User-facing coordinators deliver
      errors appropriately for their context (HTTP status codes,
      user-safe messages), either directly or via a formatting
      collaborator.
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
- Coordinators with more than four direct collaborators are rare, and
  each has been checked for a domain concept that would combine some
  of them.
- Every signature says what its function works on — not much more
  than it uses, and no wrapper made for one call.
- Besides its collaborators, a coordinator takes only the input it
  acts on — no value chosen while setting up the work passes through
  it to reach a collaborator.

MISAPPLICATIONS:
- Mocking transitive dependencies — replacing a collaborator's own
  dependencies instead of only direct ones, creating brittle tests
  coupled to internal wiring two layers deep.
- Mixing mocked and real collaborators — replacing some but not all
  direct collaborators with test doubles, making failures
  uninterpretable (wiring problem vs. logic change in the real
  dependency).
- Splitting a coordinator to hit the collaborator-count heuristic
  when no cohesive domain concept unifies a subset — if all
  collaborators serve the same purpose, bundling them under an
  artificial boundary just moves wiring around without clarifying
  anything.
- Passing more than the function uses — one large value in place of
  the few things the function reads, so the signature no longer says
  what it uses and every caller must build all of it; at its worst, a
  god object. As a rule of thumb, pass a whole object when the
  function reads about half its fields or needs the object itself,
  such as to attach it to another; otherwise pass the fields it
  reads, or what a method it would call returns.
  Examples:
  - `Summarize(state)`, where `state` carries every record the
    program holds.
  - `Invoice(order, customer)`, where the invoice reads the
    customer's name out of fifteen fields and calls
    `customer.BillingAddress()` — pass the name and the address.
- A wrapper made for one call — a type that exists only to carry one
  function's arguments, often repeating fields of a real domain
  object.
  Examples:
  - `Price(PriceParams{Base, Discount, TaxRate, Shipping, Qty})`, when
    callers already hold the quote those values came from.
  - `Rename(RenameFields{ID, Name})` — two values that need no
    wrapper.
  - `Notify(user, message, NotifyOptions{Channel, Urgent})` — flags
    that choose which behavior runs are the problem Earned
    Abstraction step 4 covers; wrapping them only hides it.
- Turning a coordinator's input into a collaborator — what it acts on
  is its input, not part of setting up the work; wrapping it in a
  provider object to keep the signature collaborator-only hides what
  the call is about. A queue the coordinator already waits on is a
  collaborator; a wrapper built to hand over one value is not.

SKIP WHEN: The code is a thin wrapper or trivial accessor where
classification adds ceremony without insight — the test is obvious from
reading the function signature.

---
<!-- Rationale below — read when creating protocols, reviewing, or
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

Step 3.3's all-or-none rule exists because mixing mocked and real
collaborators makes failures uninterpretable — a failure could be a
wiring problem *or* a behavior change in the real dependency. The
all-or-none rule eliminates that ambiguity: every coordinator test
failure means wiring, every computation test failure means logic.
The consistency makes failures interpretable without investigation.
This is also why it's listed as a MISAPPLICATION above — it's the
most common way the strategy goes wrong in practice.

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

### Signatures that say what they work on

A signature is what every caller and every test spells out, so it
should say what the function works on. For computation that is its
values: a long list says it in pieces nobody has named, a god object
doesn't say it at all, and a one-call wrapper says it twice — once in
the wrapper and again in the object its fields came from.

Which concept to name depends on what is being built. Pairs of x and
y values might become points, or points might become richer shapes;
that is seldom clear up front, and the name should follow the domain
as it grows rather than be settled in one go.

A coordinator's work is calling collaborators, so its signature should
be its collaborators and the input it acts on. Take a coordinator
that copies new records from a source into a store:
`Sync(source, store, tenant, batchSize, runID)`. Sync acts on the
records the source returns; none of the three values is among them.
The tenant and batch size only say whom to fetch for and how many at
a time, and the run ID only labels what the store writes, so Sync
does nothing with them but hand them on. Built into the source and
the store, they leave `Sync(source, store)`: calls, and checks on
what they return. The tests shrink with it: each builds its doubles
already set up instead of repeating five arguments.

### Why N+1

Each collaborator error path is independent — the coordinator's job is
to present a consistent error interface to its callers, not to recover
from failures. One test per failure mode proves the coordinator handles
it and that callers don't need to know which collaborator failed. The
happy path proves the wiring works when nothing fails. If you find
yourself needing significantly more tests, the coordinator likely
contains decision logic that should be computation.

This consistent error interface is what makes one unhappy path
integration test enough at the layer above (see Outside-In Development
Loop). Because each coordinator's N+1 error tests verify consistent
handling per collaborator, the integration test only needs to prove the
error path is wired end-to-end — it doesn't re-test each failure mode.

### Relationship to the meta-strategy

This sub-strategy provides the technique for the meta-strategy's step 3
bullet: "Logic and computation → unit test." The meta-strategy selects when
to use unit tests; this strategy explains how to write them by classifying
code as computation or coordination. The meta-strategy's SKIP WHEN also
delegates directly here — when no integration boundaries exist, unit tests
are the only layer and this strategy covers it.

### Cross-references

- **Be Your Name**: The signature checks in steps 2.1 and 3.2 apply
  BYN's test that understanding comes from reading signatures — a
  signature should say what its function works on.
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
  creates. The trust chain runs through UT's stateful test doubles.
- **Parameterized Test Structure**: PTS provides the table-driven
  structure for computation tests. UT classifies code as computation; PTS
  structures the resulting test cases into input/expected/assertion rows.
- **Outside-In Development Loop**: Determines the order in which
  coordinator and computation tests are written. Coordinator tests come
  first (defining interfaces via mocks), computation tests second
  (satisfying them). The consistent error interface from step 3.4 is
  what makes one unhappy path integration test sufficient.

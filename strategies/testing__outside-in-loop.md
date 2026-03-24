# Outside-In Development Loop
PRINCIPLE: Many More Much Smaller Steps

Happy path: the user accomplished what the feature intends. Unhappy
path: the user tried but couldn't, given the feature's rules.

The entry point for any feature — HTTP handler, CLI command, message
consumer — is a coordinator. It validates input, delegates work to
collaborators, and presents a consistent error interface to its callers
— they should not need to know which collaborator failed. User-facing
coordinators deliver errors appropriately for their context: HTTP status
codes, user-safe messages, sanitized errors that don't leak internals.

1. Write the happy path integration test. Before any implementation
   exists, write a black box integration test that exercises the
   feature's success path through its public interface. This test
   fails — the feature doesn't exist yet. The failing test defines
   "done."
2. Write coordinator tests. The integration test implies a top-level
   coordinator. Write unit tests for it first, mocking every
   collaborator. Each mocked collaborator is a contract: "I need
   something that does this." Interfaces emerge from the coordinator's
   needs, not from speculation about what computation will be required.
3. Implement the computation that collaborators demand. Write unit tests
   for each computation node, then implement it. Computation only
   exists because a coordinator wants to collaborate with it. Errors
   propagate mechanically — every error is returned, never ignored, but
   no effort goes into user-facing messages or graceful degradation.
4. Run all tests after each unit is complete, including the outer
   integration test. The integration test may still fail, but the
   failure message changes as more pieces connect. A changing failure
   message is progress signal. When the integration test goes green,
   the happy path is done.
5. Design the unhappy path. Review the feature for failure scenarios
   that need intentional handling — user-facing error messages, graceful
   degradation, designed error responses. If the mechanical propagation
   from the happy path is acceptable, the feature is done. If a failure
   scenario needs designed behavior, write one integration test that
   proves errors reach the user through the full stack, then run steps
   2–4 again.
   When an existing test already covers the same failure scenario,
   prefer reusing it over adding a new one.
   - If the "error handling" introduces new business logic (new
     thresholds, fallback behaviors, alternative flows), it's a
     separate feature — give it its own loop from step 1.

OUTCOMES:
- The integration test exists before any implementation code.
- Coordinator tests are written before computation tests — interfaces
  emerge from what coordinators need, not from bottom-up guessing.
- Computation nodes exist only because a coordinator requires them as
  collaborators — no speculative code.
- No error is silently dropped in happy path code — every error is
  returned, even when the response isn't yet user-facing.
- The unhappy path adds intentional error handling as a distinct
  development pass — user-facing messages, graceful degradation, and
  recovery logic are features, not afterthoughts.
- One unhappy path integration test per feature boundary — the
  coordinator's unit tests cover consistent error handling across
  collaborators.

MISAPPLICATION: Writing the integration test, then building the entire
feature in one pass, then running the integration test at the end. The
loop's value is the frequent check against the outer test, not just
writing it first. Or starting from the computation leaves and building
up — this inverts the loop, forcing you to guess at interfaces rather
than discovering them from what the coordinator needs.
SKIP WHEN: The change is a bug fix where the failing test already exists
(a regression test) or a pure refactoring where existing tests define
the contract. The loop applies to new feature development, not to all
test-driven work.

---
<!-- Rationale below — read when creating protocols, reviewing, or
questioning the strategy. Not needed for routine application. -->

## Rationale

### Why MMMSS, not Don't Fly Blind

The outer test provides signal (DFB), but the strategy's core insight is
the development ordering — each unit test is a "much smaller step" toward
making the outer test green. Test Layer Selection already covers the
signal aspect (which layers to test, why integration tests come first).
This strategy covers the incremental development cycle that Test Layer
Selection's steps 1 and 2 compose into. The cycle descends from two
lineages: BDD's outside-in approach (acceptance test defines done,
development proceeds inward) and Freeman & Pryce's *Growing
Object-Oriented Software, Guided by Tests* (mocks as design tools,
coordinator-first development to discover interfaces from demand). No
BDD tooling or ceremony is required — the insight is structural.

### The integration test as design driver

Writing the integration test first forces you to define how the user
interacts with the feature before you know how it works internally. This
constrains implementation to only what's needed to make that interaction
work — no speculative internals, no premature abstraction. When writing
the integration test feels hard, that's design feedback: the interface
isn't clear yet, and figuring it out now is cheaper than discovering it
after building the internals.

### Why coordinators first, computation second

The outside-in direction continues past the integration test into the
unit test layer. Starting at the coordinator means you discover
interfaces from demand, not supply. The coordinator's test says "I need
a collaborator that takes X and returns Y" — that's a contract. When
you then implement that collaborator as computation, you know exactly
what it needs to do and nothing more.

Starting from computation inverts this: you guess what interfaces will
be needed, build them, then discover the coordinator wants something
slightly different. The coordinator-first ordering is why the Unit
Testing strategy uses all-mocked collaborators — at the time you write
the coordinator test, the collaborators don't exist yet. The mocks
aren't a testing convenience, they're a design tool.

### The test pyramid's hidden layer

Coordinator tests and computation tests are both "unit tests" by the
speed definition — they run in single-digit milliseconds. But they test
fundamentally different things: coordinator tests verify wiring (with
mocks), computation tests verify logic (with real values). The
traditional test pyramid groups them together because they're both fast,
but in the outside-in loop they occupy different positions: coordinator
tests come first (defining interfaces) and computation tests come second
(satisfying them). Someone familiar with the pyramid may treat them as
interchangeable — this strategy says they're not.

### Happy and unhappy paths are separate development passes

The unhappy path pass treats error handling as a feature. The original
payment feature's unhappy path might be: "when the fraud service is
unreachable, return a clear error telling the user to try again shortly"
— designed behavior on top of what would otherwise be a raw propagated
error.

Some "error handling" is really new business logic. "Let payments under
$5 through when the fraud service is down" isn't the payment feature's
unhappy path — it's a separate feature (fraud service circuit breaker)
with its own loop. Its happy path: payment under $5 with fraud service
down succeeds. Its unhappy path: payment of $5.01 with fraud service
down still fails, and the error message doesn't reveal the threshold
because that would encourage fraud. The circuit breaker feature's
unhappy path might already be covered by the original payment feature's
"fraud service unreachable" test — that test might use a $1000 payment,
so tightening it to $5.01 doesn't fundamentally change what it tests
but captures unintended changes to the $5 business rule — this is
what "prefer reusing it" means in step 5: tighten existing test data
to sit just outside the new boundary rather than adding a redundant
test. Bolting business logic onto another feature's error path creates
tangled, undertested behavior. Giving it its own loop means it gets its own
integration test, coordinator design, and unhappy path — unless existing
tests already cover the scenarios.

The two-pass separation prevents two failure modes: (1) ignoring errors
during happy path development ("we'll handle errors later" — they never
get handled), and (2) over-engineering error handling before the core
feature works ("let me design the error responses first" — the feature
never ships). Mechanical propagation in the happy path ensures nothing
is lost; the unhappy path pass ensures the important failures get
designed, not just propagated.

### Why one unhappy path integration test is enough

The entry point coordinator's consistent error interface — callers don't
need to know which collaborator failed — is already unit-tested with
mocked collaborators (step 2). Each collaborator's failure modes are
covered by its own unit tests. The integration test proves one thing:
when an error occurs somewhere in the stack, the full path works and
the user sees a designed response. Testing every collaborator's failure
through the integration layer re-tests what the unit layer already
covers, creating slow, redundant tests that violate the meta-strategy's
"push tests to the cheapest layer" principle.

### Relationship to the meta-strategy

This strategy bridges the meta-strategy's steps 1 and 2 into a
development cycle. The meta-strategy says *what* to test at each layer;
this strategy says *in what order* to write the tests and code during
implementation. It is a primary input to implementation protocol
generation — the protocol's test-writing sequence should follow this
loop.

### Cross-references

- **Test Layer Selection**: The meta-strategy whose steps 1 and 2
  compose into this development cycle. This strategy operationalizes
  that composition.
- **Unit Testing**: Provides the technique for steps 2 and 3. The
  compute/coordinate classification determines which side of the loop
  you're on: coordinator tests define interfaces (step 2), computation
  tests satisfy them (step 3). The all-mocked-collaborators rule is
  load-bearing here — at step 2, the collaborators don't exist yet.
- **Black Box Integration Testing**: Provides the technique for steps
  1 and 5 — how to write the outer integration tests that define "done"
  for both happy and unhappy paths. Its budget (one happy, one unhappy
  per feature boundary) maps directly to two passes of the loop.

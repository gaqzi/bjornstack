# Compute or Coordinate
Code either performs computation (business logic) or orchestrates collaborators — never both.

- Good: computation that takes all its data as input and returns a
  result, with no collaborators; such as a pricing function given the
  cart and the tax table, or a validator that returns the list of
  errors it found.
- Good: a coordinator that only calls collaborators, passes data
  between them and handles their errors; such as a checkout handler
  that fetches the cart, calls the pricing function and saves the
  order, or one that upper-cases a name between a fetch and a save.
- Bad: a coordinator that fetches an order, applies a discount only
  when the customer is a member, and saves it.

VIOLATIONS:
- Mixed computation and coordination — a function that depends on
  collaborators AND contains business logic, conditional or not. Computation
  is a pure function; anything with side effects or collaborator
  dependencies is coordination. When both appear together, the logic
  can't be tested without the wiring.
- Data transformation disguised as coordination — a coordinator that
  maps, filters, or reshapes data between collaborators, embedding
  business rules in what looks like wiring.
  Examples:
  - A coordinator receives a result from collaborator A, conditionally
    reshapes it, then passes it to collaborator B — the reshape has
    edge cases worth testing independently but can't be tested without
    mocking both collaborators.
  - An orchestrator's "mapping" function grows conditionals as new
    cases arrive, becoming computation that's trapped inside
    coordination.

WHY: Mixed code obscures intent and makes testing harder — you can't tell whether a failure is in the logic or the wiring.

---
<!-- Rationale below — read when creating strategies, reviewing, or
questioning the tenet. Not needed for routine application. -->

## Rationale

This is the backbone tenet. Every piece of code falls into one of two
roles:

- **Computation (business logic)**: ideally a pure function. You pass in all
  the data, some calculation happens, you get a result. No side effects, no
  dependencies. These are trivially testable with real inputs and outputs.
- **Coordination (orchestration)**: calling other objects, passing data between
  them, handling their errors. Coordinators are simple — they don't compute,
  they wire things together. These are tested with mocks.

When you mix the two, pain follows. A coordinator with business logic needs
mocks for the coordination AND real assertions for the logic. You end up
chasing cascading failures when real logic changes break mock setups, writing
dozens of tests for one method, and cursing the test suite you built.

### How to classify code

Ask one question: "Is this code calling other objects and passing data between
them?"

- **YES** → it's a coordinator. Mock all direct collaborators, test data flow
  and error handling.
- **NO** → it's business logic. Use real inputs and outputs, no mocks.

If you can't clearly classify the code, that's a smell — it's probably mixing
concerns and should be refactored.

### The trivial-transform edge case

A coordinator that does `result := svcA.Get(id); name := strings.ToUpper(result.Name); return svcB.Save(name)` — is `strings.ToUpper` "computation"?

No. A trivial inline transform (one operation or a short chain of them) is
still coordination: its result shows up in what the coordinator passes on
or returns, so the coordinator's own tests already cover it. A transform
that needs test cases of its own is computation, even when it fits on one
line; the usual causes are conditionals, branches, error cases, or a rule the domain
defines, such as a total from quantity, price and tax.

### Where domain types live

Domain types that flow between compute and coordination modules live at the
boundary — typically the domain package root. If a coordinator owns the type,
computation modules must import from coordination, violating the separation.
If a computation module owns a type that coordinators pass around, the
dependency direction is correct (coordinators naturally depend on the things
they coordinate). When a type has no clear primary producer, it belongs at the
package root as shared domain vocabulary.

### Why this enables everything else

This tenet is foundational because it determines your entire testing
strategy. Once you classify code, you know:
- Whether to use mocks (coordination) or real values (computation)
- How many tests to expect (N+1 for a coordinator with N collaborators that
  can fail: one error-path test for each, plus one happy path they share;
  thorough coverage for computation)
- What a failure means (wiring problem vs. logic problem)

Every other testing tenet builds on this classification.

### Cross-references

- **Structure Is Intent** (complementary): the directory tree should reflect
  the compute/coordinate classification — structure makes the roles visible
  without reading implementations.
- **Earned Abstraction** (upstream): premature abstractions produce objects
  that both compute and coordinate because the abstraction doesn't understand
  its own role yet. CoC's classification is downstream of EA's discipline.

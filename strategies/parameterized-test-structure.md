# Parameterized Test Structure
PRINCIPLE: Highlight the Difference

1. Prefer individual tests for 1-2 cases. When 3+ cases exercise the
   same operation with different inputs, parameterize.
   - The test: could a single test body handle every case without
     conditionals? If cases need fundamentally different setup or
     execution, they're separate tests, not one table.
2. Define every field in every case — inputs, expected values, and a
   case name that describes the situation and expected outcome. No
   implicit defaults, no omitted fields. The cases form a scannable
   grid where differences between cases jump out.
   - Case names describe the situation and expected outcome — they
     read as sentences and serve as specifications. "expired token
     returns authentication error" not "test3" or "error case."
3. When assertion logic varies between cases, encode the difference
   as an assertion function — each case carries its own assertion
   and the test body calls it uniformly.
   - When it's unclear whether assertion differences warrant a
     function: if the assertion can be parameterized as expected
     values (step 2), prefer that. If the assertion needs different
     logic (error check vs value comparison vs side-effect
     verification), use an assertion function. When still unclear,
     ask: would removing the assertion difference make two cases
     identical? If yes, the difference belongs in an assertion
     function.
   - Success and error cases can share a table when they share the
     same input structure. The assertion function is what varies,
     not the shape of the case.
4. Write a single test body that executes identically for every case.
   No conditionals. The body is a template; the cases are the data.

OUTCOMES:
- Case names read as specifications — scanning the case list reveals
  what behaviors are tested.
- All fields are visible in every case — a reviewer sees what differs
  without scanning boilerplate.
- The test body contains no branching logic.
- Each case failure is independently identifiable by its scenario name.
- Adding a new case requires only adding data, not changing code.

MISAPPLICATION: A table where the test body still branches on case
fields — `if tc.expectError` hiding which path executed. Or cases
with fundamentally different setup crammed into one table, hiding
complexity behind shared structure instead of highlighting differences.
Or fields omitted via language defaults, making cases look identical
when they differ.
SKIP WHEN: 1-2 cases — individual test functions are clearer. Cases
that don't share a single code path — they're separate tests.
Coordinator tests where each case tests a different collaborator's
failure — the Unit Testing strategy's N+1 pattern gives these their
own structure.

---
<!-- Rationale below — read when creating protocols, reviewing, or
questioning the strategy. Not needed for routine application. -->

## Rationale

### Assertion functions, not conditionals

The most common failure mode in parameterized tests is `if tc.expectError`
in the test body. This creates two hidden paths — when the test fails,
you don't know which path executed. The fix is to replace the conditional
with a function that each case provides. The test body calls it
uniformly; the function IS the assertion. Error cases carry an
error-checking function, success cases carry a value-checking function.
No branching in the body, and every case's assertion strategy is visible
as a field in the case definition.

This pattern is the Gang of Four Strategy pattern applied to test
assertions — each case selects its assertion behavior through
composition rather than conditional logic. We call them "assertion
functions" rather than "strategy functions" to avoid collision with
this project's use of "strategy" for the HOW layer.

The `if/switch` prohibition in test bodies is a direct consequence of
this pattern. When every case carries its own assertion function, there
is no reason for the body to branch. This is enforceable as a lint
rule — a guard candidate for any language protocol derived from this
strategy.

### Why all fields explicit

Languages with zero-value defaults (Go's zero structs, Python's
keyword arguments) tempt authors to omit fields that "don't matter"
for a case. This hides differences. A case that omits `expectedError`
looks identical to a case where `expectedError` is intentionally empty.
The reviewer can't tell whether the omission is meaningful or lazy.

Requiring every field in every case costs verbosity but buys
scannability — the eye can sweep a column and spot the one case where
a value differs. This is the core of Highlight the Difference applied
to test structure: make the grid uniform so variations pop.

When verbosity becomes a problem (12+ fields per case), that's a signal:
either the function under test does too much, or the test needs builders
to compress setup data. See the interaction with Test Data Builders
below.

### Division of labor with Test Data Builders

TDB and PTS serve the same principle (Highlight the Difference) through
complementary mechanisms:

- **TDB** hides *domain object* defaults — `a.User(withEmail("x"))`
  shows only the override. The builder encapsulates construction.
- **PTS** shows *case-level* fields — every case declares its name,
  inputs, expected values, and assertion function. The table
  structure makes the grid scannable.

Builders populate the *values* inside PTS cases. PTS structures the
*cases themselves*. They compose naturally: a parameterized test uses
builders to create its input and expected data, and the table structure
highlights how those builder calls differ across cases.

### Naming as specification

Case names are the first thing a reader sees — in the test file and in
failure output. A name like "expired token returns authentication error"
tells the reader exactly what scenario is covered and what the expected
behavior is, without reading the case body. Short names like "error" or
"test3" force the reader to inspect field values to understand the case.

Long descriptive names are preferred over short vague ones. The minor
cost in line length is repaid every time someone reads a test failure
or scans the case list to understand what behaviors are tested. This
is BDD-style naming — the case list reads as a behavioral specification
of the function under test.

### Relationship to Compute or Coordinate

PTS applies primarily to computation tests — functions with clear
inputs and outputs where the same operation is exercised across many
variations. Coordinator tests follow the Unit Testing strategy's N+1
pattern, where each case tests a different collaborator's failure.
These are structurally different tests (different mock setup), not
variations of the same behavior.

The uncommon exception: when multiple coordinator test cases share
identical structure (e.g., three collaborators that all fail the same
way with the same error-handling assertion), parameterization may
apply. But default to N+1 individual tests for coordinators — the
Unit Testing strategy already gives them clear structure, and
parameterizing them obscures which collaborator is being tested.

### Cross-references

- **Test Data Builders** (HTD): provides the data creation pattern
  that populates PTS cases. TDB step 4 (modifiers) creates the
  per-case overrides.
- **Whole-Object Assertion** (FEAL): the assertion function pattern
  in step 3 is where WOA plugs in — asserting against the full
  builder output catches unintended side effects.
- **Isolated Test Execution** (NSF): ITE provides data-level
  isolation across tests; PTS step 4's uniform body ensures each
  case executes independently within a single test.
- **Unit Testing** (CoC): PTS applies within the computation path;
  coordinator tests use N+1 structure instead.

# Be Your Name
Code declares its behavior through names so that understanding comes from reading signatures, not implementations.
VIOLATION: A function named `process` that parses CSV, validates rows, and writes to a database — discoverable only by reading the body.
VIOLATION: A test named "TestService_HappyPath" that doesn't describe what scenario is being tested or what outcome is expected.
WHY: A bad name is a lie that every caller pays for — each reader must re-derive what the author already knew.

---
<!-- Rationale below — read when creating strategies, reviewing, or
questioning the principle. Not needed for routine application. -->

## Rationale

This principle is about playing with open cards. Code should be who it says it
is. A function named `calculateTax` should BE a tax calculator, not just carry
that label while also validating input, fetching exchange rates, and writing
audit logs. The name is a contract — every caller trusts it.

### Names are the cheapest documentation

Comments go stale. Documentation drifts. But names are read every time the
code is used — at every call site, in every stack trace, in every code review.
A good name is documentation that can't go out of date because it's verified
every time someone reads the code. A bad name is worse than no name because it
actively misleads.

### The cost of a bad name compounds

When `process` does three things, every person who calls it must read the
implementation to know what it does. If 10 developers read that function over a
year, you've spent 10x the time the author saved by not thinking of a good
name. And some of those 10 will misunderstand it, creating bugs that compound
further.

### Test names are specifications

A test named "TestService_HappyPath" tells you nothing. A test named
"an empty cart sums to zero" tells you exactly what's being tested, what the
input condition is, and what the expected outcome is. When this test fails, the
name alone tells you what broke. BDD-style test names — describing the
situation and the expected outcome — turn your test suite into a living
specification.

### Package names are promises

A package named `utils` promises nothing and delivers less. A package named
`cart` or `pricing` or `notifications` tells you what domain it owns. You know
what belongs in it and — just as importantly — what doesn't.

### Cross-references

- **Structure Is Intent** (complementary): SII covers organization — where you
  put things. BYN covers naming — what you call them. Together they ensure both
  labels and layout communicate purpose. Good names in bad structure or bad
  names in good structure are each half-failures.
- **Consistent Beats Correct** (yields to BYN): when the established naming
  convention is vague or misleading, CBC defers — fix the names everywhere
  rather than perpetuating a pattern that violates BYN.

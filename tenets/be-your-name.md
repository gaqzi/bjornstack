# Be Your Name
Code declares its behavior through names so that understanding comes from reading signatures, not implementations.
VIOLATIONS:
- Overloaded names hiding multiple responsibilities — a name that
  covers several unrelated operations, discoverable only by reading
  the implementation.
  Examples:
  - A function named `process` that parses CSV, validates rows, and
    writes to a database.
  - A package named `common` or `helpers` that accumulates unrelated
    functions grouped only by not fitting elsewhere.
- Vague test names that don't specify behavior — a test name that
  describes implementation structure rather than the scenario and
  expected outcome.
  Examples:
  - "TestService_HappyPath" — doesn't say what scenario is being
    tested or what outcome is expected.
- A short name read far from where it is defined — the reader has to
  go and find what it means before the line makes sense.
  Examples:
  - A two-letter field defined in one file and used across a module:
    reading one function means learning the whole module first.
  - An abbreviation in a public name, read at every call site with no
    definition in sight.

WHY: A bad name is a lie that every caller pays for — each reader must re-derive what the author already knew.

---
<!-- Rationale below — read when creating strategies, reviewing, or
questioning the tenet. Not needed for routine application. -->

## Rationale

This tenet is about playing with open cards. Code should be who it says it
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

### Name length grows with distance

A name has to carry its meaning as far as it travels. A field read across
a module needs a full name. Descriptive names are the default. A short
name works only where its definition is in sight: a loop index two lines
from its declaration, or an algorithm's parts where the code reads better
as a shape — index arithmetic over a buffer, a formula — defined by an
overview in the same scope (a function, a type, a file header) and used
inside that scope alone. A reader should never have to understand a
whole module to read one variable. This is the scope rule from Robert C.
Martin's Clean Code: the longer a name's reach, the longer the name.

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

# Test Data Builders
PRINCIPLE: Highlight the Difference

1. Define a builder per domain type that produces a complete, valid
   instance with production-realistic defaults for every field — not
   zero values, not random data, not placeholder strings. This
   baseline is what all tests deviate from.
   - Each builder instantiation creates new, independent state.
     Nested structures — collections, maps, embedded objects — are
     fresh. No test can mutate another test's data through shared
     references.
   - When the domain type evolves (a field is added, a constraint
     tightens), the builder is the single place where the default
     is updated. Tests that don't care about the change continue
     to work.
2. Organize all builders under a single, well-named entry point per
   project. The entry point provides discoverability — all available
   builders in one place — and the composition reads as a sentence
   describing the test's data: "a user, persisted, with email X."
3. When a builder constructs a related domain object, delegate to
   that object's builder. An order builder that needs a user uses
   the user builder, not inline construction. Defaults stay
   consistent across the dependency chain, and a change to the
   user's defaults propagates automatically.
   - Tests customize composed objects by passing pre-built instances
     as overrides (step 4): "an order, with user (a user, with
     email X)."
   - At build time, the builder resolves relationships between
     composed objects — cross-references, identifiers, and any
     mechanical wiring the domain requires. Tests don't manually
     wire foreign keys.
4. Provide named modifiers for single-field overrides and a
   general-purpose mutation mechanism for one-off adjustments.
   - Each named modifier sets one field to a caller-specified
     value. Tests compose modifiers to express their scenario —
     the combination of modifiers IS the test's intent.
   - When a test needs a field combination that doesn't recur, use
     a mutation function rather than a dedicated modifier. This
     prevents the builder API from growing unbounded with
     single-use methods.
5. Extract named state methods for recurring multi-field overrides.
   When multiple tests need the same cluster of field changes,
   extract a method that applies all related fields together.
   Common categories include lifecycle states ("Persisted",
   "Expired"), validation states ("Invalid"), and business-case
   states ("Grandfathered", "OverLimit") — but name the state for
   what it represents in the domain, not for which category it
   falls into. State methods compose with each other and with
   single-field modifiers.
6. Use builders for both test input and expected values. The same
   builder that creates setup data constructs the expected object
   for assertions. When a test overrides one field, the expected
   value uses the same builder with the same overrides — making the
   assertion highlight exactly what the operation should have
   changed.

OUTCOMES:
- Each test's setup shows only the fields relevant to its scenario,
  and builder composition reads as a sentence describing the test
  data — everything else is the builder's default.
- A bare builder call with no overrides produces a complete,
  production-realistic instance — each call creates a new,
  independent object, and overrides represent intentional deviations,
  not compensations for incomplete defaults.
- When a domain type gains a new field, one builder update absorbs
  the change — no test shows additional setup noise for fields it
  doesn't care about.
- Named state methods describe domain concepts ("Persisted",
  "Invalid", "Grandfathered"), not field combinations — reading a
  test reveals intent, not mechanics.
- Assertions use the same builders as setup, making each assertion
  highlight exactly what the operation changed.

MISAPPLICATION: A builder that requires callers to set most fields
before use — the defaults aren't realistic enough to stand alone, so
every test still specifies five fields, just through a different API.
Or extracting builders too early — a builder for a type used in only
one test within the same domain adds indirection without earning the
"highlight the difference" benefit. Or state methods that encode
test-specific scenarios rather than domain states —
"ForTestUserCreation" instead of "Persisted."
SKIP WHEN: Types with few fields where inline construction already
highlights the difference (a coordinate with x and y). Or a type
constructed in only one test file within the same domain — until a
second file needs it or it's needed cross-domain, inline construction
is sufficient.

---
<!-- Rationale below — read when creating protocols, reviewing, or
questioning the strategy. Not needed for routine application. -->

## Rationale

### Origin

This strategy is derived from the test data builder pattern in Jay
Fields' *Working Effectively with Unit Tests*. The core insight — test
setup should highlight what's unique about each test by hiding shared
construction behind sensible defaults — is the foundation everything
else builds on. The "a" entry point convention also originates from
WEWUT: the builder reads as natural language, making tests
self-describing.

### Three principles, one technique

The primary principle is Highlight the Difference: builders exist so
tests show only what varies. But the technique serves two secondary
principles through the same mechanism:

**No Shared Fate** — When a domain type evolves, every test that
constructs it inline breaks. Builders absorb structural changes in
one place. Each instantiation creates independent state, so tests
can't corrupt each other through shared references — particularly
important for nested structures like slices and maps.

**Fail Early and Loud** — Production-realistic defaults prevent bugs
where tests pass because they exercise code paths that only exist
with zero or empty values. The "Invalid" state method makes FEAL
explicit in the other direction: a test calling "Invalid" is loudly
declaring "this is the error path."

If a builder accumulates many state methods, that's a signal about
the domain type, not the builder — a type with ten distinct named
states may be carrying too many responsibilities.

### Build-time relationship resolution

Step 3's build step does more than return an object — it resolves
relationships between composed objects. When an order builder
composes a user builder, the build step sets the order's user
identifier to the user's identifier and handles any mechanical
relationship setup the domain requires.

This makes step 6 more powerful than it appears: when the same
builder constructs expected values, relationships are resolved
identically. Tests don't manually wire expected foreign keys — the
builder handles it for both setup and assertions, so assertions
highlight domain changes, not relationship mechanics.

### Relationship to Earned Abstraction

EA's rule of three is relaxed for builders because the cost of NOT
having one — repeated construction, shared-reference bugs, type
evolution fragility — is higher than for most abstractions:

- **Same domain**: once a second test file constructs the same type,
  extract.
- **Cross domain**: from the first use — the builder encapsulates
  construction knowledge that shouldn't leak across boundaries.

EA step 1 still applies: before creating a builder, check whether
one already exists. The progression before a shared builder is:
inline construction (one test) → local helper (multiple tests, one
file) → shared builder (multiple files or cross-domain).

### Builder composition, not inheritance

Builders compose, not inherit. Each builder is independent. When it
needs a related object (step 3), it delegates to that object's
builder. Shared construction patterns across types are a recurring
concept, not a reason for a shared base class.

### Cross-references

- **Whole-Object Assertion** (downstream): Builds on step 6 —
  asserting against the full builder output catches unintended
  side effects.
- **Parameterized Test Structure** (downstream): Uses builders to
  create the varying inputs in each test case row.
- **Compliance Test Suites** (downstream): Uses builders to
  construct the state needed for compliance verification across
  implementations.
- **Isolated Test Execution**: ITE steps 2-3 prescribe factories
  with deterministic, realistic data. This strategy provides the
  structural pattern for those factories.
- **Earned Abstraction**: EA's rule of three is relaxed for
  builders — see threshold discussion above.
- **Be Your Name**: State method naming is BYN applied to test
  helpers.
- **Domain-First Packaging**: Builders live in a shared package
  (step 2), not per-domain. DFP governs the domain types builders
  construct, not where builders themselves live.

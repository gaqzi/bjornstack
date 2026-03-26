# Whole-Object Assertion
PRINCIPLE: Fail Early and Loud

1. Assert against the complete expected object, not selected fields.
   When an operation returns or modifies a structure, compare the full
   result to a fully-specified expected value — every unchecked field
   is a silent failure waiting to happen.
2. Make every field in the result deterministic so whole-object
   comparison is possible. Prefer approaches higher in this hierarchy:
   - **Inject a controlled source**: replace the non-deterministic
     source (clock, UUID generator) with one the test controls. The
     expected value uses the same deterministic value. Strongest
     coverage — the exact value is checked.
   - **Capture and verify**: when injection isn't feasible, let the
     real source run. Capture the value from the actual result, verify
     it meets expectations (non-zero, changed from input, within valid
     range), then substitute it into the expected object for
     whole-object comparison. This checks that the value was produced
     correctly *and* that all other fields match.
   - **Zero both sides**: when neither injection nor meaningful
     verification is possible, zero the field on both actual and
     expected before comparison. Assert the field is populated
     separately. Weakest — a bug that produces the wrong value passes
     silently.
   - Can the non-deterministic source be passed as a parameter? If
     yes, inject it. If unclear, check whether the source is created
     inside code you own (inject) or inside a third-party dependency
     (capture or zero). If still unclear, present the tradeoff:
     injection checks the exact value, capture-and-verify checks
     validity, zeroing only checks presence.
   - The test should make the chosen approach explicit. A helper that
     captures, validates, and substitutes in one step prevents the
     "forgot to check it actually changed" failure mode.
3. Construct the expected value with the same builder that created the
   test input (Test Data Builders step 6). Apply only the overrides
   that represent the operation's intended effect — unchanged fields
   carry the builder's defaults.
   - When no builder exists, construct the expected value inline with
     all fields specified. If repeating every field across multiple
     tests creates noise, that's the signal to extract a builder (see
     Test Data Builders).

OUTCOMES:
- Every field is either fully checked or explicitly accounted for — no
  field is silently ignored.
- Non-deterministic values don't prevent whole-object comparison —
  they're controlled at their source or explicitly excluded.
- Deviations between expected and actual are visible whether they occur
  in intended changes or in fields the operation shouldn't have touched.

MISAPPLICATIONS:
- Whole-object assertion on a type with volatile metadata (database
  row versions, system-generated timestamps) without injecting,
  capturing, or zeroing those fields — the assertion is flaky, not
  thorough.
- Asserting on serialized representations (JSON string comparison)
  when the language provides structural comparison — field ordering
  and formatting differences create false failures.
SKIP WHEN: The output shares no structural relationship with the
input — the operation is a transformation between unrelated types, not
a mutation, and field-by-field assertion of the transformed properties
is clearer. Or when only 1-2 fields exist on the type — there's
nothing to silently miss.

---
<!-- Rationale below — read when creating protocols, reviewing, or
questioning the strategy. Not needed for routine application. -->

## Rationale

### Why Fail Early and Loud, not Highlight the Difference

Both principles are served by this technique, but FEAL is primary. The
motivation is that unchecked fields are silent failures — asserting on
2 fields when the object has 10 means 8 fields can silently corrupt
without any test noticing. That's the same failure mode as a swallowed
null: the bug exists, nothing told you.

Highlight the Difference is served secondarily through step 3: builders
make the expected value readable by showing only overrides. But Test
Data Builders already serves HTD as its primary strategy. Making WOA
also primary-HTD would create overlapping territory. With FEAL as
primary, the layering is clean: TDB provides the builder mechanism
(HTD), WOA provides the assertion technique that uses it (FEAL).

### The determinism hierarchy

The three approaches in step 2 form a hierarchy ordered by FEAL
coverage:

**Injection** checks the exact value. When you inject a fixed clock
that returns `2024-01-15T10:00:00Z`, the expected value contains that
exact timestamp. A bug that produces the wrong timestamp — off by one
hour, wrong timezone, stale cached value — fails the assertion.

**Capture-and-verify** checks validity plus structure. The real source
runs, so you can't predict the exact value in advance. But you verify
it's reasonable (non-zero, different from the input, within an expected
range) and then substitute it into the expected object. The whole-object
comparison still catches every other field. This is weaker than
injection — a bug that produces a plausible-but-wrong timestamp could
pass — but stronger than zeroing because you're still checking the value
has the right properties.

**Zeroing** checks only presence. A bug that produces the wrong
timestamp passes silently — you only verified non-zero. This is the
last resort for fields whose source is completely outside your control.

The escalation path in step 2 exists because the inject-vs-capture
boundary isn't always obvious. Code you own can almost always be
refactored to accept an injected source. Third-party code that
generates its own values (an SDK that timestamps its own requests)
genuinely can't be injected without wrapping the dependency. Capture
is the right middle ground — let the real source run, verify the
result, and continue with whole-object comparison.

A helper that combines capture, validate, and substitute into one
operation makes the capture-and-verify pattern mechanical. Without a
helper, these are three manual steps — and the validation step is the
one that gets forgotten. When it's forgotten, capture-and-verify
silently degrades to zeroing: the value is captured and substituted
but never actually checked. The helper prevents this by making the
validation inescapable.

### Structural over serialized comparison

Serialized comparison introduces false failures because serialized
formats and type systems draw different boundaries. Field ordering is
format-dependent (JSON objects are unordered by spec, strings are
ordered). Numeric representation varies (`1.0` vs `1`). Most
critically, serialized formats collapse or rearrange distinctions the
type system preserves — Go's zero value vs JSON's absent field,
TypeScript's `undefined` vs JSON's missing key, explicit `null` vs
omitted field. Structural comparison operates at the type level where
these distinctions are already resolved.

### Mutual reinforcement with Test Data Builders

WOA and TDB are mutually reinforcing but serve different principles:

- **TDB → WOA**: Builders make whole-object assertion practical.
  Without builders, the expected value requires specifying every field
  inline — correct but noisy. Builders let the expected value show
  only overrides, making the assertion both complete (FEAL) and
  readable (HTD).
- **WOA → TDB**: Whole-object assertion is often the trigger that
  justifies extracting a builder. When a test needs a full expected
  object and inline construction is getting noisy across multiple
  tests, that's the signal from step 3's sub-bullet. WOA creates the
  demand that TDB fulfills.

TDB step 6 ("use builders for both test input and expected values")
and WOA step 3 aren't redundant. TDB step 6 says builders *can*
construct expected values. WOA step 3 says *why you'd want to* and
what the overrides represent (the operation's intended effect, not
arbitrary test data).

### Cross-references

- **Test Data Builders**: Step 6 provides the builder mechanism for
  expected values. WOA provides the FEAL motivation and the assertion
  technique.
- **Parameterized Test Structure**: Each row in a
  parameterized test uses whole-object assertion — the expected value
  per row is a builder with case-specific overrides.
- **Isolated Test Execution**: ITE step 3 prescribes deterministic
  factories. WOA step 2 extends the same principle to assertion
  values — determinism isn't just for setup, it's for expectations
  too.

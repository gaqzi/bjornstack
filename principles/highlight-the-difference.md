# Highlight the Difference
When things are similar, structure them so the differences are instantly visible — the reader should never scan boilerplate to find what actually changed.
VIOLATIONS:
- Buried variations in repeated boilerplate — similar code blocks
  repeat shared structure so that the meaningful differences are
  invisible without line-by-line comparison.
  Examples:
  - Five test cases that each repeat 12 lines of setup, differing
    only in the 5th function call's 3rd argument and the expected
    result.
  - Three API endpoint handlers that each contain 40 lines of
    identical middleware setup, differing only in the route and the
    inner handler.

WHY: Buried differences get missed in review, misread during debugging, and accidentally erased during refactoring.

---
<!-- Rationale below — read when creating strategies, reviewing, or
questioning the principle. Not needed for routine application. -->

## Rationale

The human eye is good at spotting differences — but only when the differences
are visible. When you have to scan 15 lines of identical boilerplate to find
that argument 2 and argument 3 are swapped, and then figure out whether that
swap was intentional or a mistake, the structure has failed you.

### The core technique

Extract what's shared, expose what varies. This applies everywhere:

- **Tests**: Default builders and options patterns so each test case only shows
  what it overrides. Table-driven tests where the varying inputs are laid out
  in a scannable structure, each with a descriptive name.
- **API handlers**: Extract shared middleware into a wrapper, leaving each
  handler to declare only its route, permissions, and business logic.
- **Configuration**: A base config with environment-specific overrides, not
  three complete config files that are 95% identical.

### Table-driven tests as a strategy

Table tests are one of the strongest implementations of this principle. When
you have 3+ cases exercising the same behavior with different inputs, a table
structure lays out the variations in a scannable grid. Each case has a name
that describes what makes it unique. The shared test body runs identically for
every case. The differences — inputs, expected outputs, assertion strategies —
are the only things visible in each case.

For 1-2 cases, individual test functions are clearer because there isn't enough
repetition to benefit from extraction. The principle applies when similarity
exists — if things aren't similar, there's nothing to highlight.

### Default-with-overrides pattern

Builders and options patterns serve this principle by establishing a known
default and letting each usage show only what it changes. When you see
`defaultCalculator(withTaxRates(emptyRates))`, the override (`withTaxRates`)
is the entire signal. Everything else is the known default. Compare this to
constructing the full object every time — the signal drowns in noise.

### The review connection

Code review is where buried differences cause the most damage. A reviewer
scanning five similar test cases that each repeat everything will miss the one
meaningful change. When the shared parts are extracted and only the differences
are visible, the reviewer sees exactly what matters.

### Cross-references

- **Earned Abstraction** (complementary): HTD extracts shared setup so
  variations are visible — but local extraction (one consumer, easy to undo)
  is not shared abstraction (many consumers, expensive to undo). HTD governs
  local extraction; EA governs shared abstraction. They complement rather
  than conflict.
- **Many More Much Smaller Steps** (complementary): HTD says "make differences
  visible in code." MMMSS says "make differences visible in changes." A PR
  that separates structural from behavioral work is MMMSS applied through
  HTD's lens.

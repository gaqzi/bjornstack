# Intentionally Public
PRINCIPLE: Structure Is Intent

1. Default to unexported — new code starts without public access.
2. Promote to public only when a consumer outside the package has a concrete, current need.
3. Before exporting, evaluate the boundary: does this symbol belong in the package's contract, or is a caller reaching into an implementation detail?
4. When a caller needs an unexported detail, treat it as a design signal — restructure the boundary or introduce an internal package rather than promoting the detail to the public contract.
5. Shape the exports into a coherent surface — the public API should read as a description of what the package does, not a grab-bag of what callers happened to need.
6. When a consumer is removed or refactored, check whether exports can be demoted back to private.

OUTCOMES:
- The package's exported symbols, read as a list, describe its purpose.
- No exported symbol exists without a current external caller.
- Adding internal functionality does not change the public surface.

MISAPPLICATIONS:
- Minimality without coherence — making everything private and
  exporting piecemeal on demand, without shaping the surface. Five
  unrelated functions that happen to be needed, rather than an API
  that communicates what the package is for. This is step 2 without
  step 5.
SKIP WHEN: The package is a leaf with a single consumer that will always
need most of what's inside. Also during early prototyping when boundaries
are still being discovered — but revisit before the design stabilizes.

---
<!-- Rationale below — read when creating protocols, reviewing, or
questioning the strategy. Not needed for routine application. -->

## Rationale

### Exports are structural decisions

SII focuses on directories and packages — the macro-level organization. But
within a package, the exported symbols are the micro-level structure. They're
the boundary between "this is what I am" and "this is how I work." When you
export an implementation detail, you've made an internal structural decision
visible — and now callers depend on it.

### Tests reveal the surface

Your tests are your first consumer. If a test can exercise the package's
behavior entirely through its public API, the surface is probably right. If a
test needs to reach past the public boundary to set up state or verify
internals, that's a design signal — either the surface is too narrow or the
test is verifying implementation rather than behavior.

Languages vary in how they enforce this. Some support testing from outside
the package, making the public boundary explicit. Others place tests inside
the package by convention, where discipline replaces enforcement. Either way,
the question is the same: can a caller — including a test — use this package
without knowing its internals?

When external testing becomes genuinely painful, the escape hatch is an
internal sub-package or module: importable by your own code but not by
external consumers. This preserves the public boundary while giving tests
and sibling code access to what they need.

### The coherence requirement

Minimality alone isn't the goal. A package that exports `ParseHeader`,
`ValidateChecksum`, and `WriteAuditLog` because three different callers each
needed one function has a minimal surface — but it communicates nothing. The
exports should form a coherent story: "this package handles message
processing" not "this package has three unrelated things."

Step 5 exists because real-world export lists grow organically. Each
individual export was justified at the time. But the aggregate surface drifts
from coherent to accidental. Periodically reading your exports as a list —
would a newcomer understand what this package is for? — catches the drift.

### Cross-references

- **Public API Surface Testing**: PAST validates the surface IP shapes —
  is it sufficient for tests to exercise behavior through exports? IP asks
  "does this symbol belong in the contract?" from the design side; PAST
  asks the same question from the testing side.
- **Grow Don't Break**: GDB governs what happens after IP's export
  decision — once something is public, it can't be removed without a
  version boundary or tracked migration. IP decides the surface; GDB
  prevents it from shrinking.

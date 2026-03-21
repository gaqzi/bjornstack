# Public API Surface Testing
PRINCIPLE: Be Your Name

1. Position tests outside the package boundary — they interact through
   exported symbols only, the same way external consumers would.
2. When a test can't exercise behavior through the public surface,
   classify what it needs to reach:
   - The behavior belongs in the package's contract but isn't exported →
     the surface is too narrow. Widen it.
   - State setup with no public path → add a construction or
     configuration entry point.
   - Complex internal algorithm → extract to an internal sub-module with
     its own testable surface.
   - When unclear → catalog what the test reaches for, separate behavior
     from mechanism, present the classification for review.

OUTCOMES:
- Tests compile without importing unexported symbols — the boundary is
  enforced mechanically, not by convention.
- Tests depend on what the package declares (its exports), not how it
  works internally — renaming private functions or reorganizing internals
  doesn't break any test.
- When tests couldn't reach behavior through the public surface, the
  resolution was a design change — not a test-only export.
- Tests exercise the package's behavior without reaching past its
  exports — the surface is sufficient to validate what the package does.

MISAPPLICATION: Testing externally but routing around API gaps by
exporting internals solely for tests — `ExportedForTest` functions or
test-only flags that pollute the public surface. Conversely, refusing
the internal sub-module escape hatch when complex internals genuinely
need direct testing, leading to circuitous tests that exercise internals
through awkward public paths.
SKIP WHEN: The package is itself an internal sub-module — it exists
specifically to be directly testable by its parent's tests.

---
<!-- Rationale below — read when creating protocols, reviewing, or
questioning the strategy. Not needed for routine application. -->

## Rationale

### Why Be Your Name

The public surface is a claim: "this is what this package does." Tests
are the proof. When tests exercise all behavior through exported symbols,
they validate that the surface declares the package's behavior completely.
When a test must reach past the public surface, it reveals behavior that
the surface doesn't declare — the names are incomplete. A package whose
tests can't stay outside its boundary has a surface that doesn't say what
the package does. That's a BYN violation: lying by omission.

This is BYN's verification mechanism. The principle says names should
declare behavior. This strategy proves or disproves that claim at the
package level.

### Relationship to Unit Testing

Unit Testing (Compute or Coordinate) classifies code and determines how
to test each classification. This strategy determines where you stand
when testing — outside the boundary, through the public surface. The two
compose: classify the code (Unit Testing), then test it through the
public API (this strategy). For computation, the public surface is the
function signature — pass real values, check returns. For coordination,
the public surface includes the collaborator interfaces received through
construction — provide test doubles through the same path a real caller
would.

### Relationship to Intentionally Public

Intentionally Public shapes the surface — what to export and why. This
strategy validates the surface — is it sufficient? They create a feedback
loop: IP says "export only what's needed," this strategy says "if tests
can't exercise behavior through exports, the surface is incomplete."

The overlap is real but the entry points differ. An engineer applying IP
is reviewing export decisions. An engineer applying this strategy is
writing tests and hitting friction. IP steps 3-4 ask "does this symbol
belong in the contract?" from the design side. Step 2 here asks the same
question from the testing side — triggered by pain, not by review. When
the two disagree (a test needs something IP says shouldn't be exported),
that's the richest design signal in the system.

IP's outcome ("exported symbols describe the package's purpose") is about
surface coherence — the full export list reads well. This strategy's
outcome is about surface sufficiency — tests can validate behavior without
reaching past exports. A surface can be coherent but insufficient (clean
exports that don't cover all behavior) or sufficient but incoherent (tests
pass but the export list is a grab-bag). Both strategies are needed.

### The escape hatch

Step 2's internal sub-module branch isn't a compromise — it's the correct
design for genuinely complex internals. A package with a sophisticated
algorithm internally may need focused tests on that algorithm. Forcing
those tests through the public API makes them indirect and fragile. An
internal sub-module lets you test the algorithm directly while preserving
the parent package's public boundary.

The principle applies recursively: the internal sub-module is tested
through its own public API. The SKIP WHEN acknowledges this — when you're
inside the sub-module, the parent's boundary already provides the external
constraint.

### Cross-references

- **Unit Testing**: Provides the compute/coordinate classification that
  determines what the "public surface" concretely means for each kind of
  code. This strategy assumes classification is done.
- **Intentionally Public**: Shapes the surface this strategy tests
  through. The two strategies create a design feedback loop — see above.
- **Black Box Integration Testing**: Tests at the system boundary (HTTP,
  CLI). This strategy tests at the package boundary. Different scope,
  same posture — exercise through the public interface only.

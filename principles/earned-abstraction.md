# Earned Abstraction
Abstractions must be earned through repetition, not speculated from a single case.
VIOLATIONS:
- Mode flags revealing a premature abstraction — an abstraction takes
  a boolean or mode parameter to handle a second use case, revealing
  it was built from one case and extended rather than extracted from
  understanding.
- Extracting a shared helper from two mechanically similar cases that
  solve different domain problems — the similarity is coincidental,
  and when the domains diverge, the helper becomes a coupling point
  that resists change in both directions.
  Examples:
  - Two services both "send a notification" but one is transactional
    (must deliver) and the other is promotional (best-effort). A
    shared sender accrues flags for retry policy, delivery guarantees,
    and rate limiting as each caller's needs diverge.

WHY: Premature abstractions attract flags and modes because they don't understand their own boundaries — each new case warps the abstraction further from cohesion.

---
<!-- Rationale below — read when creating strategies, reviewing, or
questioning the principle. Not needed for routine application. -->

## Rationale

The rule of thumb is three: don't abstract until you've solved the same problem
at least three times. With one case you can't distinguish the pattern from the
accident — you don't know which parts are essential and which are incidental to
that specific situation. With two cases you start to see similarities, but you
might be overfitting to what those two happen to share. With three, the real
shape of the abstraction becomes visible.

### The boolean-mode failure path

When someone abstracts too early (typically after one case), the abstraction is
overfit. When the second case arrives, there are two options: refactor the
abstraction to genuinely understand both cases (good, but more work), or add a
boolean/flag to switch behavior (easy, and almost always what happens).

Once there's one flag, the door is open for a second, then a third. Now you
have a combinatorial mess hiding behind what looks like a clean interface. Each
new mode warps the abstraction further from cohesion, and testing becomes
painful because you have to cover the cross-product of modes.

### What it actually is when it has modes

An abstraction with mode flags is usually a shared engine that needs different
harnesses, or a shared harness that needs a switchable engine. Both call for a
strategy — a named collaborator that encapsulates the varying behavior. The
caller is named after the specific case it serves and coordinates the shared
part with the strategy. This is Compute or Coordinate applied to abstraction
design.

### Duplication is better than the wrong abstraction

Three similar-looking blocks of code feel like a problem, but they're a safer
problem than a premature abstraction. Duplication is obvious, local, and easy
to refactor later when you understand the pattern. A wrong abstraction is
subtle, viral (callers depend on it), and expensive to undo. When in doubt,
keep the duplication.

### What this is not

Earned Abstraction doesn't mean never abstract. It means the abstraction
should come from understanding, not from speculation. Once you've solved the
same problem three times and can clearly see what varies and what's stable,
that's earned — abstract with confidence. The principle targets the impulse to
abstract on the first or second encounter, before the pattern is actually
visible.

### Dependencies are not abstractions

Adopting a well-established library because it serves other principles (e.g.,
an assertion library for better diffs and whole-object comparisons, or a
battle-tested protocol library instead of a hand-rolled implementation) is a
tool choice, not a premature abstraction. EA governs abstractions you create —
your own interfaces, helpers, and generic frameworks — not dependencies you
adopt. The question for dependencies is whether they genuinely serve the
principles you live by, not whether you've seen three cases first. When a
proven library exists for a problem, the default should be to use it —
choosing to implement instead is the decision that needs justification.

### Testability seams are not premature abstractions

An interface defined to make a coordinator independently testable is earned by
the testing need — there's a concrete consumer (the test) that requires it.
This is not speculation from a single case; it's a response to a real
constraint. The language-specific question of where the interface is defined
(consumer-side vs provider-side) belongs in protocols.

### Automation is earned abstraction of manual processes

EA applies beyond code. A runbook is a manual process — concrete, specific,
understood through repetition. Automation is the abstraction of that process.
The same rule of three applies: don't automate a procedure you've only run
once. The first time you follow the runbook, you discover what it missed.
The second time, you learn what varies. The third time, you see the real
pattern and can automate with confidence. Automating after the first run
produces brittle scripts that handle the happy path of one specific incident
and break on the next.

This is two sides of the same coin: in code, EA prevents premature
interfaces and generic frameworks. In operations, EA prevents premature
automation. Both forms of premature abstraction share the same failure mode —
they encode assumptions from too few cases and warp under real variation.

### Cross-references

- **Compute or Coordinate** (upstream): premature abstractions produce mixed
  objects that both compute and coordinate because the abstraction doesn't
  understand its own role yet. EA's discipline keeps CoC's classification clean.
- **Consistent Beats Correct** (tension): sometimes the right call is to keep
  duplication and stay consistent rather than introduce an abstraction that
  might be wrong. Resolution: if the duplication is genuinely three cases deep
  and the pattern is visible, EA wins — abstract and update the pattern
  everywhere (per CBC's own yield rule).
- **Highlight the Difference** (complementary): HTD extracts shared setup so
  variations are visible. This looks like it conflicts with EA — is a test
  helper "premature"? No. Local extraction (one consumer, easy to change) is
  not shared abstraction (many consumers, expensive to undo). EA governs the
  latter; HTD governs the former.
- **Many More Much Smaller Steps** (complementary): shipping small steps is
  not abstracting. A walking skeleton is coordination wiring, not abstraction.
  MMMSS governs delivery; EA governs design. Ship concrete implementations
  first, earn the abstraction later.

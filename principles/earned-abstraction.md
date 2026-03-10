# Earned Abstraction
Abstractions must emerge from repeated concrete cases — only after solving the same problem multiple times can you distinguish the essential pattern from incidental similarity.
VIOLATION: An abstraction that takes a boolean or mode flag to handle a second use case, revealing it was built from one case and extended rather than extracted from understanding.
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

An abstraction with mode flags is usually a shared core that needs different
harnesses, or a shared harness that needs a switchable core. Both call for a
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

### Connection to other principles

Earned Abstraction is upstream of Compute or Coordinate — if you abstract too
early, you end up with mixed objects that both coordinate and compute because
the abstraction doesn't understand its own role yet. It also connects to
Consistent Beats Correct — sometimes the right call is to keep the duplication
and stay consistent with the codebase's patterns rather than introduce an
abstraction that might be wrong.

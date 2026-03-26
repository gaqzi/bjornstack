# Consistent Beats Correct
Follow established patterns even when a locally better approach exists — the ability to make assumptions across the codebase is worth more than any single optimization.
VIOLATIONS:
- Inconsistency that forces investigation — using a structurally
  different approach for equivalent cases, forcing the reader to
  determine whether the difference is meaningful or accidental.
  Examples:
  - A module that uses a different paradigm without wrapping it
    behind the codebase's established interface patterns, forcing
    callers to learn a second interaction style.
  - Three API endpoints in the same service where two use the shared
    middleware wrapper and one hand-rolls the same setup inline —
    the reader must figure out if the third endpoint has a reason
    to be different or if the author just didn't know about the
    wrapper.

WHY: Every deviation forces readers to determine whether the difference is meaningful or accidental, destroying the ability to navigate by assumption.

---
<!-- Rationale below — read when creating strategies, reviewing, or
questioning the principle. Not needed for routine application. -->

## Rationale

Consistency pays off most when someone joins a codebase and can navigate by
assumption — "I know how errors are handled here because I've seen it in every
other file." They might prefer different patterns, but the consistency means
they don't have to stop and figure out which style they're looking at. That
predictability is worth more than any local improvement.

### What this is NOT

This is not "we've always done it this way" as a defense against improvement.
It's not a reason to never change. When a pattern is actively harmful — when it
violates other principles like Fail Early and Loud or Be Your Name — the right
response is to fix it *everywhere*, consistently. The principle governs
structural and stylistic choices: which paradigm you use, how you organize
code, how you handle common operations. It does not protect patterns that
create hidden behavior or obscure intent.

### When CBC conflicts with other principles

If the established pattern silently swallows errors (FEAL violation), don't
perpetuate it — fix it everywhere. If the established naming convention is
vague (BYN violation), improve it everywhere. CBC yields to other principles
when the pattern itself is the problem. But you fix it *consistently* — don't
fix it in one file and leave the old pattern in twenty others.

### CBC in greenfield projects

In greenfield projects, CBC inverts: instead of following existing patterns,
you are establishing them. The first module isn't just a deliverable — it's a
template. This transforms the first task from feature work into pattern-setting
work, which requires deliberate review before the second module is built.
Nothing in the principle block flags this transformation, so it catches teams
off guard — they build task 1 casually and then discover everything must be
consistent with whatever they happened to build. The "Thin Vertical Slice"
strategy addresses this directly.

### The wrapping exception

You can use a different approach internally if you wrap it behind the
codebase's standard interface. A module that uses functional pipelines
internally but exposes the same interface patterns as everything else doesn't
force callers to learn a new style. The deviation is contained. The violation
is when the deviation leaks.

### AI tooling changes the equation

With AI-assisted refactoring, "it would take too long to change everywhere" is
less true than it used to be. CBC is still valuable — the consistency itself
has value — but the bar for "let's actually fix the pattern everywhere" is
lower when the tooling can help apply the change across the codebase.

### Earning an exception

See the Practicality Beats Purity principle. When you genuinely need to deviate
from an established pattern, the process is: convince yourself it's not just
convenience, convince at least one other person, and document the tradeoff. If
you find yourself earning exceptions frequently for the same pattern, the
pattern needs updating — consistently.

### Cross-references

- **Fail Early and Loud** (yields to FEAL): when the established pattern
  silently swallows errors, CBC defers — fix the pattern everywhere rather
  than perpetuating a FEAL violation.
- **Be Your Name** (yields to BYN): when the established naming convention
  is vague or misleading, CBC defers — improve the names everywhere rather
  than perpetuating a BYN violation.
- **Earned Abstraction** (tension): EA says abstract when you've seen three
  cases. CBC says follow established patterns. Resolution: if the duplication
  is genuinely three cases deep and the pattern is visible, EA wins —
  abstract and update everywhere (per CBC's own yield rule).
- **Many More Much Smaller Steps** (tension): if the established pattern is
  large releases, MMMSS says stop. CBC yields — the pattern itself is the
  problem.
- **Practicality Beats Purity** (complementary): PBP governs the exception
  process when CBC's pattern genuinely doesn't serve the situation. CBC
  provides the default; PBP provides the escape valve.

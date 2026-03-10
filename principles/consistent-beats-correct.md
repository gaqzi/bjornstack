## Consistent Beats Correct
Follow established patterns even when a locally better approach exists — the ability to make assumptions across the codebase is worth more than any single optimization.
VIOLATION: Using a different paradigm in one module without wrapping it behind the codebase's established interface patterns — forcing callers to learn a second interaction style.
VIOLATION: Mocking some collaborators with real implementations and others with test doubles in the same test because "this one is simple enough to use directly."
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

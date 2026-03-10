## Practicality Beats Purity
When following a principle costs more than violating it, break the principle deliberately — but only after convincing yourself and at least one other person, and documenting the tradeoff.
VIOLATION: Breaking a principle without documentation because "it was faster" or "it's just this once."
VIOLATION: Documenting a deviation that nobody else reviewed — self-approval isn't approval.
WHY: Undocumented deviations become precedent — the next person sees the exception and assumes it's the rule.

---
<!-- Rationale below — read when creating strategies, reviewing, or
questioning the principle. Not needed for routine application. -->

## Rationale

Principles exist to constrain decisions, but reality is messy. Sometimes a
shell script doesn't need the same level of engineering as a production
service. Sometimes the deadline is real and the tradeoff is genuine. Sometimes
the principle simply doesn't apply to a novel situation.

Practicality Beats Purity is the escape valve — but it's a deliberate,
documented escape valve, not a convenient excuse.

### The bar is high

This principle is not meant to be easy to invoke. The process is:

1. **Convince yourself** — and not just "it's faster this way." You need to
   articulate why the principle doesn't serve you here. What specific cost
   does following it impose? What specific benefit does violating it provide?
   If you can't answer both clearly, you haven't earned the exception.

2. **Convince at least one other person** — someone who understands the
   principle and can push back. If you can't convince them, either your case
   is weak or the principle is right. Both outcomes are useful.

3. **Document the tradeoff** — so the next person who encounters this code
   understands it's a deliberate exception, not ignorance or sloppiness. The
   documentation should explain why the principle doesn't apply here, not just
   that you chose to skip it.

### If you're invoking this often, the principle needs updating

Frequent exceptions to the same principle are a signal. Either the principle
is too strict, the codebase has a structural problem that makes the principle
impractical, or the team doesn't actually agree with the principle. All three
are worth addressing directly. Use Consistent Beats Correct: fix the pattern
everywhere or change the principle, don't accumulate exceptions.

### You can't PBP out of PBP

This is the one principle you cannot use Practicality Beats Purity to override.
If you skip the documentation and review process, you haven't earned an
exception — you've just broken a rule. The point of PBP is that deviations are
*deliberate and visible*. Skipping PBP's own process makes deviations invisible,
which is exactly what PBP exists to prevent.

### Spirit over letter

The hardest part of working with principles is teaching people that it's about
the spirit, not the letter. Someone who follows every principle to the letter
while missing the intent is more dangerous than someone who occasionally breaks
a rule for good reasons. PBP exists to make the spirit explicit: we care about
the outcomes these principles produce, not about mechanical compliance. When
mechanical compliance doesn't produce the outcome, adapt — deliberately,
visibly, with agreement.

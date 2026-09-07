# Practicality Beats Purity
When following a tenet costs more than violating it, break the tenet deliberately — but only after convincing yourself and at least one other person, and documenting the tradeoff.
VIOLATIONS:
- Undocumented deviation — breaking a tenet without documenting
  the tradeoff because "it was faster" or "it's just this once."
- Self-approved deviation — documenting the tradeoff but skipping
  peer review, so the exception was never stress-tested by someone
  who could push back.

WHY: Undocumented deviations become precedent — the next person sees the exception and assumes it's the rule.

---
<!-- Rationale below — read when creating strategies, reviewing, or
questioning the tenet. Not needed for routine application. -->

## Rationale

Tenets exist to constrain decisions, but reality is messy. Sometimes a
shell script doesn't need the same level of engineering as a production
service. Sometimes the deadline is real and the tradeoff is genuine. Sometimes
the tenet simply doesn't apply to a novel situation.

Practicality Beats Purity is the escape valve — but it's a deliberate,
documented escape valve, not a convenient excuse.

### The bar is high

This tenet is not meant to be easy to invoke. The process is:

1. **Convince yourself** — and not just "it's faster this way." You need to
   articulate why the tenet doesn't serve you here. What specific cost
   does following it impose? What specific benefit does violating it provide?
   If you can't answer both clearly, you haven't earned the exception.

2. **Convince at least one other person** — someone who understands the
   tenet and can push back. If you can't convince them, either your case
   is weak or the tenet is right. Both outcomes are useful.

3. **Document the tradeoff** — so the next person who encounters this code
   understands it's a deliberate exception, not ignorance or sloppiness. The
   documentation should explain why the tenet doesn't apply here, not just
   that you chose to skip it.

### If you're invoking this often, the tenet needs updating

Frequent exceptions to the same tenet are a signal. Either the tenet
is too strict, the codebase has a structural problem that makes the tenet
impractical, or the team doesn't actually agree with the tenet. All three
are worth addressing directly. Fix the pattern everywhere or change the
tenet, don't accumulate exceptions.

### You can't PBP out of PBP

This is the one tenet you cannot use Practicality Beats Purity to override.
If you skip the documentation and review process, you haven't earned an
exception — you've just broken a rule. The point of PBP is that deviations are
*deliberate and visible*. Skipping PBP's own process makes deviations invisible,
which is exactly what PBP exists to prevent.

### Spirit over letter

The hardest part of working with tenets is teaching people that it's about
the spirit, not the letter. Someone who follows every tenet to the letter
while missing the intent is more dangerous than someone who occasionally breaks
a rule for good reasons. PBP exists to make the spirit explicit: we care about
the outcomes these tenets produce, not about mechanical compliance. When
mechanical compliance doesn't produce the outcome, adapt — deliberately,
visibly, with agreement.

### Cross-references

- **Consistent Beats Correct** (complementary): CBC provides the default —
  follow established patterns. PBP provides the escape valve — when following
  the pattern costs more than breaking it. Together they form the tension
  management system: CBC says "stay consistent," PBP says "unless the cost is
  genuine and documented."

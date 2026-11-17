# Practicality Beats Purity
When following a tenet costs more than violating it, break the tenet deliberately — but only after convincing yourself and at least one other person, and documenting the tradeoff.

- Good: the exception states what following the tenet would cost and
  what breaking it gains, someone who could push back agreed, and the
  record sits where the next reader will meet it; such as a code comment
  naming the tenet and the reason, approved in review, or a decision
  record a teammate signed off before the work started.
- Good: a tenet that keeps costing more than it gives is dealt with
  once, with the same argument and agreement, instead of collecting
  exceptions; such as changing the tenet itself, or fixing the pattern
  everywhere so the exceptions are no longer needed.
- Bad: a comment that says "skipping tests here, deliberate" with no
  reason given.

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
   that you chose to skip it. A choice that holds beyond one place in
   the code, such as for a package or the whole project, goes in the
   project's conventions record, `.bjornstack/conventions.md`, once it
   is agreed.

### Robust in proportion to what a failure costs

Protection against a failure is built in proportion to what the
failure costs. Take the first of these that fits:

1. The project or feature says it cannot accept the failure, in its
   tenets or alongside its story, such as "a customer is never charged
   twice for one order". Prevent it, even when that costs a lot. The
   statement says what that takes to run, and which rare cases are
   left to be put right by hand, since a business can often handle a
   truly exceptional case that way. Setting the statement aside is an
   exception, held to "The bar is high".
2. Leaving it unguarded would break a tenet that does not itself
   accept the failure, such as sending an email before its event is
   stored. That is an exception, held to "The bar is high". A rare
   crash does not lower that bar.
3. Preventing it would cost far more than the failure, including
   putting it right by hand, counted at the volume the system runs.
   Accept it, and say so where the next reader will meet it. This is
   not an exception and needs no second person. It is usually a
   failure that needs several unlikely things to happen together.
4. Otherwise, guard against it.

How rare one case sounds is not the measure: at four million
transactions a day, a one-in-a-million case happens four times a day.

Design for Replay builds for the normal case and aims for no
duplicates: each email is recorded as sent, and a payment passes an
idempotency key. What is left is a user working around it, such as
paying again on a new order, or something highly unlikely, such as a
crash between sending an email and recording it. A double-confirmed
write on the store, so that a duplicate email can never go out, would
cost far more than a rare repeat, which is far from the end of the
world. A duplicate payment costs more, but "never" is generally out of
reach there too: the rare case is put right by hand, under rule 3 or
as a case a rule 1 statement names.

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

# Recorded Old Forms
TENET: Consistent Beats Correct

1. Keep one conventions record for the codebase, with an entry for
   each old form the code stays on deliberately while a better one
   exists: what the code uses, why, and what would trigger the move.
   For example: "serializer v1, not v2: v2 changes wire output; move
   when we do a full pass." If the codebase has no record yet, ask
   the owner where it should live before creating one.
2. When work meets an old form, take the first case that fits:
   1. The record has an entry for it: follow the entry, hold new code
      to it, and suggest no migration, in delivery and in review, even
      if the form is at odds with another tenet.
   2. There is no entry: keep using the old form unless it breaks
      another tenet, add the entry, naming any tenet the form breaks,
      and ask the owner once whether to keep it or move; for a form
      that breaks another tenet, suggest fixing it everywhere. A
      reviewer asks the author to add the entry.
3. In a periodic review of the codebase or system, go through the
   record and raise each entry whose trigger has fired, or where the
   better form is now worth migrating to in one go, with what the move
   changes. A migration moves every use and removes the entry.

OUTCOMES:
- Every old form the code stays on deliberately has an entry naming
  what, why and the trigger.
- Delivery reports and reviews of single changes suggest no migration
  for a form that has an entry.
- Each migration proposed covers every use of the old form, states
  what the move changes, and comes from the periodic review or from
  the owner's answer to a new entry.

MISAPPLICATIONS:
- Treating an entry as a to-do: an agent working on a feature
  migrates the package it touches because the record says a better
  form exists.

SKIP WHEN: The better form is adopted across the whole codebase in the
change that introduces it, so no old form remains to record.

---
<!-- Rationale below — read when creating protocols, reviewing, or
questioning the strategy. Not needed for routine application. -->

## Rationale

### Why an entry holds against another tenet

An entry the owner agreed is a documented, agreed exception in the
sense of Practicality Beats Purity. Raising it again on every change
reopens a settled decision; the periodic review in step 3 is where it
is reopened.

### Why migrations wait for the periodic review

A nudge toward migration on every change is noise, and it buries the
nudge that matters. Raised once, against the whole record, a
migration can be weighed and done in one go, which is what Consistent
Beats Correct asks for.

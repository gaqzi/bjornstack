# Tidy or Change
PRINCIPLE: Many More Much Smaller Steps

1. Start with the goal — what behavioral change is needed?
2. Read the code that will change. Identify structural obstacles to this
   specific goal — places where the current shape makes the behavioral
   change hard to write, review, or understand in a diff.
3. Plan the sequence: a tidy changeset for each structural obstacle,
   followed by a behavioral changeset for the actual change. Alternatively,
   change first when you won't know what tidying helps until the new
   behavior reveals the shape.
4. Execute each changeset separately and sequentially — commit one before
   starting the next.
5. In a structural changeset, confirm tests pass without modification — if
   a test needs updating, behavior changed.
6. In a behavioral changeset, limit structural changes to the minimum the
   new behavior requires — any structural diff beyond that should have been
   a separate tidy changeset.

OUTCOMES:
- Before coding starts, the work is decomposed into a sequence of
  structural and behavioral changesets.
- Each changeset is classifiable as purely structural or purely behavioral.
- Reviewers can evaluate structural changes without considering behavioral
  correctness, and vice versa.
- Rolling back a behavioral change does not undo a structural improvement,
  and vice versa.

MISAPPLICATION: A "structural" PR that sneaks in a behavioral fix "while
I'm in here," or a "behavioral" PR with extensive renaming that makes the
actual change invisible in the diff. Also: planning so many tidy steps
that the sequence becomes a refactoring project that delays the actual goal.
SKIP WHEN: The change is trivially small — a one-line behavioral fix that
needs no structural preparation and no structural cleanup. Splitting would
produce two changesets with less clarity than one.

---
<!-- Rationale below — read when creating guidelines, reviewing, or
questioning the strategy. Not needed for routine application. -->

## Rationale

### Planning before execution

The critical moment is step 2, not step 4. By the time you're committing,
the hard decision — what to separate and in what order — is already made.
The strategy front-loads that decision into a planning phase because both
agents and humans produce cleaner work when they know the sequence before
they start coding. An agent that plans "tidy X, then add Y" writes two
focused diffs. An agent that starts coding and tries to separate later
inevitably tangles structural and behavioral changes.

### Why structural-first is the default

Tidying first makes the behavioral diff smaller and easier to review — the
code is already in the shape the new behavior needs. The reviewer sees only
the new behavior, not the reorganization that enabled it. This is the common
case. Change-first is the exception: use it when the behavioral change is
exploratory and you genuinely don't know what structural shape would help
until you've written the new code. In that case, the behavioral change
reveals the tidying opportunities, and you tidy after.

### The tests-unchanged heuristic

Step 5 gives structural changesets a concrete verification: tests pass
without modification. This works because tests encode behavior. If a
structural change requires test updates, it changed something observable —
either intentionally (which makes it behavioral, not structural) or
accidentally (which is a bug). The exception: renames and moves that
propagate mechanically through test references. A renamed type updating
its test references is structural — the test logic didn't change, only
the names it uses. The signal is test *logic* changes (different
assertions, different setup, different cases), not mechanical reference
updates that mirror the structural change exactly.

### Connection to Flag Your Changes

Feature flags enable the tidy-first workflow for larger changes. A
structural changeset can introduce new domain types or reorganize modules
behind a flag that defaults to OFF — the code is wired but inert. This
lets the team build on the new structure immediately while the behavioral
activation comes in a later changeset. Without flags, structural changes
that introduce new code paths risk partial activation. With flags,
"structural" truly means "no behavior changes" because the flag guarantees
inertness.

### Avoiding the refactoring trap

The MISAPPLICATION warns against planning so many tidy steps that the
sequence becomes a refactoring project. The guard: each tidy step must
directly serve the behavioral goal. "This rename makes the pagination diff
clearer" is valid. "While I'm here, this other module could use cleanup" is
scope creep. The behavioral goal is the anchor — tidy steps earn their
place by making that specific goal easier to deliver.

### Lineage

Kent Beck's *Tidy First?* is the direct source. Beck frames the choice as
a personal, moment-to-moment decision: before each change, ask whether
tidying first would make the change easier. GeePaw Hill's MMMSS provides
the broader frame: the tidy/change split is one technique for achieving
many more much smaller steps. The strategy makes Beck's question into a
plannable sequence rather than a per-line judgment call.

### Cross-references

- **Flag Your Changes**: FYC strengthens the tidy-first workflow — a
  structural changeset can introduce new code behind a flag that defaults
  to OFF, ensuring "structural" truly means "no behavior changes." The
  behavioral activation comes in a later changeset.

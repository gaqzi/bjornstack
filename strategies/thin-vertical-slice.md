# Thin Vertical Slice
TENET: Many More Much Smaller Steps

1. **needs-slice-zero.** Decide whether the feature needs a slice 0:
   technical groundwork done before any business work starts. Ask
   whether the feature's path needs infrastructure, a runtime or a
   deploy path the codebase has never run, such as a new process, a
   message broker, a new kind of store or a scheduler. A new service
   or project counts: it is a deploy path the codebase has never run.
   When the path needs any of these, plan a slice 0 for what is new.
   A new implementation behind something already wired is ordinary
   new code: there is no slice 0, and the first story is slice 1, the
   feature's walking skeleton. Record the decision in the feature's
   design, and who made it.
   - Good: a slice 0 only for something the codebase has never run;
     such as the first cache server, a kind of store the codebase has
     not used before, or the first scheduled job.
   - Bad: a slice 0 for a new database table. The table is new; the
     database it lives in is already wired.
2. **slice-zero-wires-only.** Limit slice 0 to proving the new thing is
   wired end to end. It is done when it shows the new path working end
   to end, in a way someone can see; how it shows that is open. It
   does no business work: the work the feature exists for starts in
   slice 1.
   - Good: the new path carries something and nothing more; such as a
     message that is sent, received and logged by a worker that does
     nothing else with it, or a new project that builds, deploys and
     answers a health check.
   - Bad: since the message already reaches the worker, slice 0's
     worker also does the first part of the real job.
3. **one-slice-not-split.** Decide how the business work is cut into
   slices. A slice is one story that delivers one thing of value.
   Slice 0 (step 1) and a cut by layer (case 3) are the exceptions,
   each used only when its own condition holds. A vertical slice
   crosses every layer the feature touches; a horizontal slice is one
   layer. Ask of the whole feature, then again of each slice a case
   makes, and take the first case that fits:
   1. It has parts someone can use apart, such as kinds, cases or
      triggers: each part is its own vertical slice, the most wanted
      first.
   2. It is too large to review, and the user does it in several
      actions or it covers many of something: cut it along what the
      user does (ask, wait, receive) or by how much it covers (one
      tenant, then all).
      Each slice still crosses every layer and stops at a point the
      user can see, like a page saying it will reload when the result
      is ready.
   3. It is too large to review and no such cut is left: cut it by
      layer, behind a flag. Nothing reaches the user until the last
      of these slices lands.
   4. Otherwise it stays one slice; for the whole feature, that is
      slice 1.

   Too large to review depends on the work: about 500 changed lines
   for ordinary application code with its tests; about half that for
   code that handles money, security or concurrency; more for
   generated code or test data. When a slice mixes kinds, use the
   smallest; judge other kinds against these. Record the cut in the
   feature's design, and who made it. When the feature is split, mark
   each slice as slice 0, vertical or horizontal, and for each cut
   made because something was too large to review, say why.
   - Good: each slice crosses every layer and ends where the user sees
     something; such as refunds cut into full, partial and exchange,
     with full refunds first, or a slow report cut into asking for it
     and receiving it.
   - Bad: the CSV export of yesterday's orders split into an endpoint
     that returns an empty file and a later slice that fills it. It
     is one part and small enough to review, so it is one slice.
4. **slice-one-useful-sooner.** When step 3 splits the feature, make
   slice 1 the first thing someone can use: the most wanted part, or
   the first thing the user does in that part. It shows use, not just
   wiring, and stops at a point the user can see, even though it does
   less than was wanted.
   It lands sooner than the whole feature would, so you see what works
   before building the rest. When slice 1 is cut by layer, its
   layers are slice 1a, 1b and so on, the practical exception to one
   story per slice, and the last of them is the one that shows use.
   Later slices each add the next thing the user does, or the next part.
   - Good: slice 1 is usable and leaves the rest out; such as reports
     for three kinds of account where slice 1 covers one kind, or a
     report request that ends on a page saying it will reload when the
     report is built, before anything builds it.
   - Bad: slice 1 is only the storage for the feature, and nothing
     anyone can use. This is about the slice, not the changes inside
     it: landing the storage as its own change within a slice, or as
     a horizontal slice when step 3 cuts by layer, is still a valid
     small step.

OUTCOMES:
- A slice 0 exists only for a feature whose path needs infrastructure,
  a runtime or a deploy path the codebase has never run, and it
  contains no business work.
- The feature's design records whether it has a slice 0 and how it
  is cut, and who made each decision. A split marks each slice as
  slice 0, vertical or horizontal, and says why each cut made because
  something was too large to review was needed.
- Slice 0, when there is one, shows its new path working end to end in
  a way someone can see.
- A feature that one slice delivers lands as one slice.
- When a feature has more than one slice, slice 1 is usable by someone
  it was built for, stops at a point they can see, and slice 1, with
  any layers under it, lands before the rest of the feature.

MISAPPLICATIONS:
- A slice 0 in front of ordinary work. The feature follows paths the
  codebase already has, but a setup story comes first anyway, and it
  delivers nothing the next story couldn't have built for itself.
- A slice 0 that grows past wiring.
  Examples:
  - The first piece of business work rides along because the path is
    already there.
  - Every layer is set up in full, with routes, settings and helpers
    that nothing passes through yet.
- A feature that one slice delivers, split anyway. Each piece is too
  small to use, and the split only adds stories to review and land.
- A missing split. The request has parts someone could use apart, or
  one part too large to review, and slice 1 carries all of it, so
  nothing is seen working until all of it is done.
- A cut by layer where a cut by part, by what the user does or by
  coverage would do. Each slice is one layer, and nobody can use any
  of it until the last lands.
- A slice 1 cut so thin that nobody can use it: a part that only
  makes sense once the next slice lands, or a first thing the user does
  that ends where they see nothing.

SKIP WHEN: The change is not a feature someone will use, such as a
bug fix or a structural change. Tidy or Change covers how to sequence
a structural change.

---
<!-- Rationale below — read when creating protocols, reviewing, or
questioning the strategy. Not needed for routine application. -->

## Rationale

### Two concerns, two slices

A feature's first slice can be asked to do two different jobs. One is
groundwork: proving that new infrastructure, a new runtime or a new
deploy path, one the codebase has never run, is connected end to
end. The other is business work: doing a first useful part of
what the feature is for. Mixing the two makes the first slice too
large to check, or too thin to be useful. Slice 0 takes the first job
and slice 1 the second, and slice 0 exists only when there is
groundwork to do.

"Too large" for slice 0 means doing business work. For slice 1 it
means carrying parts someone could use apart, or more than a
reviewer can read as one change. "Too small" for slice 1 means
nothing anyone can use. A feature can fail by being split when it
should not be, or by not being split when it should; step 3 checks
both.

### Vertical first, by layer last

A cut by part, by what the user does or by coverage keeps every slice
something the user can see working, so each one is checked against what
was wanted. A cut by layer gives nobody anything until its last layer
lands, so it comes last, for a piece that cannot be made smaller any
other way. Too large is measured by what a reviewer can read with care.
Code that handles money, security or concurrency needs closer reading,
so less of it fits; generated code and test data need less, so more
fits. Code is cheap to produce in bulk, but a large change is rarely
good, and small steps keep the work from running ahead of what has
been checked.

### Serving Many More Much Smaller Steps

Each slice is a step that can be landed and reviewed on its own.
Slice 0 is the smallest thing that proves the new path works: wired
but inert, which the tenet's rationale counts as a valid small step.
Slice 1 is the walking skeleton that rationale names: the first
deployable step on the feature's path. It lands a useful part of the
feature before the rest exists, so the next slices are shaped by what
was learned from it. Splitting a feature that one
slice delivers adds steps without making any of them cheaper to
review or reverse, which is why step 3 keeps it whole.

### Serving Consistent Beats Correct

Slice 0 is the plumbing every later story builds on, and the first
code to use new infrastructure, a new runtime or a new deploy path is
the pattern the rest copy.
Consistent Beats Correct notes that in new work the first module sets
the pattern, so it needs deliberate review. Kept lean and apart from
business work, slice 0 is small enough to check that it points in the
right direction. A large slice 0 lets in habits nobody thought
through, and later stories build on them.

### Relationship to the Skeleton step of story definition

This strategy and the story-definition skill's Skeleton step both
start with a thin story that proves a path end to end, and add no
setup story when the path already exists. Slice 0 proves new
infrastructure, a runtime or a deploy path, and does no business
work, so it can ship but gives no user anything new. Slice 1 is the
feature's walking skeleton: the thinnest pass that proves the
feature's path, working end to end for the business side, fleshed
out by later slices when step 3 splits the feature. When step 3 cuts
by what the user does, slice 1 may be only the first thing the user
does in a part, such as asking for a report and seeing that it is
being built. With no slice 0, the first story is slice 1.

### Where the terms come from

Slice 0 matches the practice of "iteration zero". Limiting it to a
path that needs something the codebase has never run, and ending it
in a path visibly working, answers George Dinwiddie's criticism that
iteration zero produces no working software. Slice 1 matches
Cockburn's walking skeleton and the first row of Jeff Patton's story
map: the thinnest end-to-end slice of real function, fleshed out by
later slices when step 3 splits the feature. Hunt and Thomas's tracer
bullets sit between the two: thin code that does a little real work,
kept and grown.

### Cross-references

- **Tidy or Change**: when existing code must be reshaped before a
  slice can reach it, that reshaping is a structural change that lands
  before the slice.
- **Flag Your Changes**: a slice 0 or a partial slice 1 can ship
  wired but switched off, and be turned on when it is ready.
- **Earned Abstraction**: slice 0 is wiring, not abstraction. It
  builds only what its one path needs, and shared pieces wait until
  later slices show what repeats.

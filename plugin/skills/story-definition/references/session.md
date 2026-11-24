# The session, phases 2 to 5

Loaded from SKILL.md after the Goal exit test passes. Each phase has a
question and an exit test; do not move on until the exit test passes.
Phase 1, Goal, is in SKILL.md.

### 2. Verification

Decide how we'll know it works before deciding how to build it. The
technical verification is the minimum; business acceptance can be
deferred, but the entry point and the observation cannot.

- **Happy path:** the actor accomplished what the feature intends.
- **Unhappy path:** the actor tried but couldn't, given the feature's
  rules.

Name the entry point the test drives (HTTP endpoint, CLI command, page,
message consumer, or the database itself when the guarantee lives
there), what state it observes to judge the result, and what is stubbed
at the network boundary, which may be nothing.

**What the actor does with each output next.** At the happy path, list
each kind of output the feature gives its actor, one item at a time
(a part, a record, a number, a notice), and ask what the actor does
with it next. A need that shows only when the actor pictures using the
output comes up here, before any story is drafted. Each part on a
mechanic's parts list might be ordered, fitted or sent back; each of
those is a different story.

- Ask per kind of output, not per field or detail of it. Take the
  kind at the grain the actor handles it: each item they open or
  use, not the file, page or list that holds many. Asking only what
  they do with the holder leaves the item unasked.
- A kind that enters scope later in the session gets the same
  question when it enters, before the story that gives it is drafted.
- With the owner present, ask before the first story is drafted, in
  the words "what does the actor do with it next?" naming the actor
  and the output, and give your best guess as a pick. The answer is
  the owner's call.
- With the owner away, list it under "Open decisions for the user"
  with a pick, and draft the stories on the pick.
- Record the answer in the epic's verification, or the story's Notes
  when there is no epic.

**When a rule depends on the time,** decide how the tests get the
times it depends on before any mechanism is named, with
strategies/time-in-tests.md. Read it, then take its first step that
fits. Stubbing the clock is not a default and the
product carries no test-only time setting the owner did not choose.

- With the owner present, ask before the first story is drafted, one
  question, even when the file's first fit seems clear. Give the
  options the file allows for this rule, always including test data
  dated long before any run date and a time the tests control, and
  mark the one you would pick with the file's reason, citing
  strategies/time-in-tests.md. Do not say or imply that the tests
  cannot work without a time setting.
- With the owner away, settle it by the file's first fit and cite it,
  or list it under "Open decisions for the user" when what the test
  must show about time is not clear from the prompt.
- No flag, variable or setting that replaces the clock appears in a
  story, the design or the verification unless the entry naming the
  approach says it. Record the answer in the epic's verification, or
  the story's Notes when there is no epic.
- A scenario that pins the current time is proven where "now" is passed
  in, in a unit test. It is not a story's black-box line unless a
  controlled clock was the chosen approach; the black-box line uses
  data dated far from every boundary.

A feature boundary is
where a consumer-visible capability enters the system: two endpoints
serving one capability share a boundary, and so do every method and
action on it. One capability has a second boundary only when it is
reached through a second kind of entry point, such as an endpoint and
a message consumer.

Write one happy and one unhappy scenario per boundary at this level,
and no more: the unhappy one is the top failure in the ranking below.
The pair is the feature's definition of done, the tests to write
failing first, not a cap on what the stories may say. Each story expresses
the whole of its rule; a story scenario that already holds stays, and
its test passes from the start. The black-box budget is decided
separately, below.

To pick the unhappy path here, list the failures a consumer could hit
and rank by how hard they are to undo and who pays: data lost or
exposed, then wrong result, then degraded experience, then cosmetic.
Take the top one. For a "remember me" login:

  A failed login with the box ticked issues a 30-day session:
    exposure, a credential handed to someone who never authenticated
  An unticked login gets a 30-day session:
    wrong result, the user gets more than they asked for
  The cookie drops its Secure flag:
    degraded, no wrong outcome yet

Every other failure, however high it ranks, either becomes a scenario
of the story whose rule it shows, whose black-box line adds it when the
epic's pair cannot show it, or goes in the out-of-scope list, so it is
decided rather than forgotten. Out of scope is for a failure the user
or the request has ruled out; one the request did not settle and no story's rule
shows, while the user is away, is an open decision, as Before starting
in SKILL.md says. If the ranking is ambiguous, show the top two with
the reasoning, and the user's pick is the one unhappy scenario; while
the user is away, take the top one and list the choice as an open
decision.

Watch for error handling that is really a feature. "Return a clear error
when the fraud service is down" is the payment feature's unhappy path.
"Let payments under five dollars through when the fraud service is down"
adds a threshold and an alternative flow: it is its own story with its
own happy and unhappy path.

**Two budgets, kept apart.** The scenarios are the requirement, and
they are as expressive as the rules demand. The black-box test suite is
slow, so it is budgeted per feature: the epic's pair per boundary is
its floor, and a story adds a black-box scenario only when its rule
changes what the entry point does in a way that pair cannot show, and
prefers none. Rows of a table and cases that differ only in values
never add black-box tests. Everything else is proven in unit tests,
which the implementer writes whether or not the story names them. The
story's black-box line names the scenario or row it adds, or says
none, so it carries the whole requirement without implying the whole
requirement is integration-tested.

**A unit layer the logic can reach.** Those unit tests call the logic
on literal data, without the external tool the code drives (a
database, a CLI, a service). When the feature's logic is more than
glue and the planned language would make its unit tests slow or
awkward, as shell scripts whose rules are reachable only through the
real tool are, propose now, before any slicing, to write that logic in
the project's main language, and ask the user. Suggest Python instead
only when the main language is a bad fit, as for a project mostly in
shell. Logic that needs a unit test (parsing, escaping, validation,
decisions) is not glue and goes in that language; shell is for glue
that a black-box check covers. The epic names the language and
harness the unit tests run in, or says the feature is all glue; it
never records "no unit tests" for logic that needs them.

**Exit test:** someone could write the failing integration test for the
happy path from what is on the page, and the language and harness the
unit tests run in are named, unless the feature is all glue. That
failing test is the definition of done, and slice 1 owns
making it pass or the first step toward it.

### 3. Architecture

Settle the design questions below before any story is drafted, for a
feature that builds code, so the slices sit on a structure the owner
chose. With the owner present, you draft no story until every item
here is settled or answered; you never draft first and leave items
open. Scale each to the feature: for a small feature an answer is
one line, and the phase is short. Stories stay free of technical
detail; every answer goes in the epic's `--design`, under a heading
"Architecture". When the work is one story with no epic, the answers
go in that story's own `--design` under the same heading; "the epic's
design" below means the design of the work filed.

**Whether the phase runs** was decided after the Goal in SKILL.md
(Whether the architecture phase runs). When it was skipped, skip this
phase: the design records no architecture decision and no slice 0 or
split decision, and the exit test below does not apply.

Take each question in turn. What the codebase runs is a fact, read
from the code, or from the first prompt when there is no code to read.
Settle the question by the first of these that fits:

1. The first prompt or the code states the answer: record it with the
   prompt's words, quoted.
2. One rule entry decides this case without a judgment about the
   owner's business: record the answer with the entry as
   `<file>#<id>`. An entry that says to present options to a human,
   or whose answer depends on something only the owner knows, does not
   settle it.
3. Otherwise ask the owner, one question at a time, with the options
   you see and the one you would pick; record the answer as the
   owner's. While the owner is away, list it under "Open decisions
   for the user" with the stories it affects, as Before starting in
   SKILL.md says, and record no answer for it. If the owner hands the
   question back, see below.

Every recorded answer names where it came from: the rule entry as
`<file>#<id>`, the first prompt's words, the owner, or, for an item a
present owner handed back, "the session's pick, owner deferred". An
answer with no source is a guess.

An answer with no source is not recorded. Take these in order:

- An assumption is not a source.
- A rule entry is a source only for what its text says. Cite it for
  the decision it states, never for a consequence you drew from it.
- The first prompt's words are a source only when the words themselves
  state the answer. Words that merely mention a thing, such as a store
  the codebase uses, do not say where something else lives.
- An item is answered with its source, or open, never both: while the
  owner is present, do not write "open" on an item you then draft
  stories from. When part of it
  is settled and part is not, split it into two items.
- An entry that says how to name or draw a boundary, such as
  domain-first-packaging#identify-domains, tells you how to name a
  capability. It does not say which capabilities exist or which one a
  piece of the feature belongs to: only the prompt's words or the owner
  do.
- Where an answer names a part of the code, read that code. With none
  to read, the part is not known: ask, or while the owner is away list
  it as open.

While the owner is away, every item no source settles goes under
"Open decisions for the user", using that heading exactly. Each entry
holds the item, the pick you would make, its reason and the stories
that rest on it, including a "none" the prompt does not state (no
worker, queue or scheduler needed). In the design the item reads
"open, see Open decisions for the user" and holds no pick. A pick
written in the design is an answer with no source. A story may rest on
a pick only when that pick is in the list. Inside this phase that
heading is the only one: SKILL.md's "Assumptions made in the user's
absence" is for facts outside the phase's questions, and no answer
here rests on one.

While the owner is present, an item no source settles is asked before
the first story is drafted, one question at a time. Ask the questions
of this phase even when the owner has just answered the Goal
questions. Before drafting, show the owner in one message every answer
settled from a rule or the prompt, each with its source, so they can
correct it; this includes a planned slice 0. Then ask the rest, one
question at a time. Do not draft while any item is unasked.

An instruction at the Goal, such as "leave the code facts open" or
"draft the stories without it", does not defer these items. Each is
still asked, or settled from a rule or the prompt, before drafting.
"The session's pick, owner deferred" applies only to an item the owner
was asked and handed back.

When a present owner hands an item back, take these in order:

1. Settle it from the rule entry that decides it, and cite the entry.
2. Otherwise state your own pick with its reason, tell the owner in
   one line, and record it as "the session's pick, owner deferred".

Never leave the item open, and go on drafting. The owner is still
present: one deferral does not switch you to the away way of working.
An owner's "just draft it" hands back every item still open: take
these two steps for each item in turn, tell the owner the picks, then
draft.

When the owner hands back the zone and
utc-computation#utc-unless-one-zone-matters says one local zone
matters, the pick is one business zone kept as a setting the owner
fills in, with no default value, such as "the business zone, a setting
the owner fills in". Record it as "the session's pick, owner
deferred". Stories compute in UTC and convert at that one setting. It
names no place.

Never assume where the owner is. A zone, country, locale, currency or
a name that points to one is stated only when the prompt or the owner
gave it: in an answer, an example in a question, or a name or figure
in a scenario. Ask for the zone
without naming one, and write amounts and dates without a currency or
offset the owner did not give. A test input may carry an offset that
points at no place, as utc-computation asks for east and west of UTC;
it never stands for the owner's place.

| Question | Rule entries |
|----------|--------------|
| Which business capabilities does the system own, each named by a noun? | domain-first-packaging#identify-domains, domain-first-packaging#name-for-domain, domain-first-packaging#no-sibling-domain-imports (how the capabilities refer to one another), structure-is-intent#tree-shows-boundaries |
| Which steps decide on data, kept apart from the steps that call outside systems? | compute-or-coordinate#logic-apart-from-collaborators, testing__unit#collaborators-received-set-up |
| Which one part owns each piece of data that more than one part writes or reads? | boundary-communication#find-shared-data, boundary-communication#single-owner (tenet: no-shared-fate) |
| What happens if a run stops between acting on an input and recording that it did? | design-for-replay#act-only-after-stored, design-for-replay#outside-effect-once-per-event |
| Which clock and zone decides the date a time falls on? | utc-computation#utc-unless-one-zone-matters |

Read each entry in the rule file before citing it; the table says where
to look, not what the file says. When no id decides an item, cite the
rule file and its section, and tell the owner that the rule has no id
there. Add no id of your own. The files, by path from the plugin
root, each with its id marked as `**<id>.**`:

- `strategies/domain-first-packaging.md`
- `tenets/structure-is-intent.md`
- `tenets/compute-or-coordinate.md`
- `strategies/testing__unit.md`
- `strategies/boundary-communication.md`
- `tenets/no-shared-fate.md`
- `tenets/design-for-replay.md`
- `strategies/utc-computation.md`
- `strategies/thin-vertical-slice.md`

If a rule file cannot be read, tell the owner and ask the item. A rule
file's own limits apply: if the file says the rule does not cover the
case, ask.

The replay question scales to the feature, as design-for-replay's
"Small systems too" section does: a program that runs alone needs the
answer at its own size, not a broker or a framework. Name what is
recorded and where, and what a second run does.

The clock question names a zone only when the rule says a zone
matters; the design says once which zone and why, from the prompt or
the owner, never from a guess at where the owner is.

**The first-slice decisions.** Then settle two decisions with
strategies/thin-vertical-slice.md, in the same three ways:

- `thin-vertical-slice#needs-slice-zero`: does the path need
  infrastructure, a runtime or a deploy path the codebase has never
  run? If so, plan a slice 0 for what is new; if not, there is none.
- `thin-vertical-slice#one-slice-not-split`: how is the feature cut?
  Ask of the whole feature, then again of each slice a cut makes. Try
  these in order and take the first that fits:
  1. It has parts someone can use apart, such as kinds, cases or
     triggers: each part the prompt names is its own vertical slice,
     the most wanted first. A part is never dropped, and a cut by rule
     is not a cut by part.
  2. It is too large to review, and the user does it in several
     actions or it covers many of something: cut it by what the user
     does (ask, wait, receive) first, or by how much it covers. When
     one part is too large, the cut and its size reason are for that
     part, not for the whole feature.
  3. It is too large to review and no such cut is left: cut it by
     layer, behind a flag.
  4. Otherwise it stays one slice.

Record in the design whether there is a slice 0, how the feature is
cut, who made each decision (the rule entry as `<file>#<id>`, the
first prompt's words, the owner, or the session's pick, owner
deferred), and, when the feature is split,
every slice marked slice 0, vertical or horizontal; no slice goes
unmarked. For every cut made
because something was too large to review (cases 2 and 3), record why
the uncut piece was too large: its estimated changed lines against
the limit for its kind in thin-vertical-slice#one-slice-not-split
(for example, "about 600 changed lines uncut, against about 500").
Naming only the limit is not a reason, and a cut of that kind with no
such reason is incomplete. A slice is never cut by rule: a rule is not
a part, an action or an amount of coverage. A feature that stays one
slice has no marks and no size reason: nothing is cut.
While the owner is away, an unsettled one of these two goes under
"Open decisions for the user" like the rest.

**When the owner decides against a thin-vertical-slice step**, they may.
Tell them in that message which step the decision breaks, by
`<file>#<id>` (for example, "this decision breaks
thin-vertical-slice#needs-slice-zero"). Record the decision as the
owner's, the step it breaks, and the owner's reason in their words;
tenets/practicality-beats-purity.md asks for the tradeoff to be
documented. When they gave no reason, ask for one in a single line,
without suggesting an answer. A
design with no such decision names no step as broken.

**Exit test:** when the phase ran, the epic's design holds an answer,
with its source, or
an open decision for each of the five questions and the two
first-slice decisions, and no answer is without a source (the
rule entry, the first prompt's words, the owner, or the session's pick,
owner deferred).

### 4. Skeleton

The first story is slice 0 when phase 3 planned one, and slice 1, the
walking skeleton, otherwise. When phase 3 was skipped there is no
slice 0, and the first story is slice 1. Each story says in its text
which slice it is: "Slice 0", or "Slice 1, the walking skeleton".
When the owner declined a slice 0 that phase 3 planned (see "When the
owner decides against a thin-vertical-slice step"), no story says it
is slice 0; the first story is slice 1, and what slice 0 would have
wired is built in the first story that needs it.

**Slice 0** (thin-vertical-slice#needs-slice-zero,
thin-vertical-slice#slice-zero-wires-only) proves the new
infrastructure, runtime or deploy path and nothing else. It is the
exception to "one thing of value": it is written as a technical
outcome, for the people who run the system, and it does no business
work. Its scenarios show the new path working end to end in a way
someone can see: a message the app sends is received by a worker that
only logs it, or a new project that builds, deploys and answers a
health check. A scenario that does a first piece of the feature's real
job does not belong in it; that is slice 1.

**Slice 1** is the feature's walking skeleton: the thinnest path
through every layer the feature will touch, demonstrable end to end.
It shows use, not just wiring (thin-vertical-slice#slice-one-useful-sooner):
someone can do something with it, and it stops at a point the user can
see, even though it does less than was wanted. Which thing it shows
follows phase 3's cut: with parts someone can use apart, it is the
most wanted part; with a cut by what the user does, it may be only the
first thing the user does in that part, such as asking for a report
and seeing a page saying it is being built. When slice 1 is cut by
layer, its layers are slices 1a, 1b and so on, and the last of them
shows use. A flag is how a slice ships safely, not what it does:
behind the flag it still crosses every layer.

  Not a skeleton:  Service foundation, routing, auth middleware, test
                   harness; every ledger route returns 501
  Skeleton:        Record a ledger entry: POST one entry, get 201 and
                   the stored row back, through real Postgres
  Skeleton:        A sales report takes a minute to build: ask for
                   it and see a page saying it will reload when the
                   report is ready

The first is a horizontal layer with nothing to demonstrate. The
others cross every layer, someone can use them, and the harness gets
built because this one scenario needs it.

Slice 1 proves the wiring of the feature's own path, which is the one
thing unit tests cannot prove, and it is the template later stories
copy. So it carries only what its one scenario needs, built to the
standard you want everywhere. Scaffolding that no scenario exercises
is not thin, it is speculative; the next story will show which parts
of the pattern need adjusting, and that is cheaper than guessing.

A layer is a tier the path the scenario drives crosses, such as the
entry point, the logic and the storage, or a command, the script it
runs and the file it writes; it is not a file the feature will ship.
Slice 1 builds the part of each layer its scenario needs. Every
other mechanism, file or deliverable lands with the story whose rule
needs it, and a step the repo's conventions ask of every change is
listed in no story.

Agents put later tests wherever slice 1 put its own, so unless
the feature is all glue, slice 1's tests run in both layers, the
black-box check and the unit tests. It builds whichever harness is
missing and uses the one that exists, and it carries the first thing
someone can use, such as one kind's report with its rows; the
implementer's empty-input unit test covers the empty case in the unit
harness. No rule is
ported or built in slice 1 to give the tooling something to
test.

In an existing system where the path is already wired, slice 1 is the
first thing someone can use, through the existing path, its
acceptance written as its end state. Don't invent a scaffolding story
for wiring that exists. When existing code has to be extracted before
the new path can reach it, that is a structural story that lands
before slice 1; with slice 0, it is one of two cases where slice 1 is
not story one.

**Exit test:** slice 0, when there is one, has a scenario that shows
the new path working end to end and none that does business work.
Slice 1 has at least one scenario that crosses every layer and shows
use and stops at a point the user can see, and it could ship alone.

### 5. Slices

Every later story is one slice of phase 3's cut, on top of the
skeleton; when phase 3 was skipped there is no cut, and the slices
follow from the rules below alone. Order them so
each is demonstrable on top of what came before, retiring the biggest
unknown first and otherwise in the order the actor would notice.

Each story is either structural (reorganising code that exists, no
behaviour change) or behavioural (new or changed behaviour), never
both. When a behaviour needs structural work first, that is a separate
story that lands before it and leaves every existing test passing
unchanged. The reviewer of a mixed change cannot tell which
differences are intentional. A capability the story assumes, which
the system lacks and no story in the set provides, is not structural
work; it is a gap raised to the user, as The story in SKILL.md says.

**What makes a story: one rule.** Phase 3's slice is one story and is
never split by rule. Only a slice too large to review by the sizes in
thin-vertical-slice#one-slice-not-split, which count changed lines, is
cut again, by phase 3's order, with its size reason. A rule is a
business decision the system enforces: a threshold, a permission, an
ordering guarantee, an alternative flow. A story's scenarios show each
rule from both sides, so a happy path and the failure of the same rule
belong together, even when the failure looks like error handling.

Instances of a rule are not rules. "A submission must be well-formed"
is one rule, and the email format, the required fields, and the ticked
checkbox are its instances, written as rows of one table in one story.
A check earns its own story when it needs a mechanism of its own, an
external lookup, its own state or a different actor, and that
mechanism has a failure the actor sees. Its own handler or module is
not one. The test is the same as
for scenarios: instances differ in values, rules differ in shape. One
story per validator is the horizontal split this skill exists to
prevent.

Conventional responses are not rules: not-found, malformed input, and
the framework's default validation sit in the story whose path they
guard, as one line each, unless the user has asked for designed
behaviour there.

**Size: one valuable commit.** A story lands as one commit that a
reviewer can read as one thing: the black-box scenario, the wiring, and
the unit tests underneath, all in service of the one rule. The layers
are driven out separately while building, but they are reviewed
together, because a human understands "refuse deletes of ledger
entries" as one change and not as three. The commit subject is derived
from the story title, in code terms; commit-style owns its shape.

How large a slice may be depends on the work
(thin-vertical-slice#one-slice-not-split), counted in changed lines:
about 500 for ordinary application code with its tests; about half
that for code that handles money, security or concurrency; more for
generated code or test data; and the smallest of these when a slice
mixes kinds. A slice over its size is cut again by phase 3's order,
with its size reason. A much smaller one that is not demonstrable
alone is a scenario of another story. Structural stories are their
own commits, which is what keeps them reviewable as pure moves.

Each story's one rule gives the actor a capability the system did not
have, testable on its own. That is the unit of growth: the skeleton
is the first capability, and every later story is the next one the
actor would notice. Slice by how the capability grows, not by how the
code is laid out; a handler, a file, a middleware or a module is how
the code is laid out. Scenarios are enumerated from the actions the
actor takes on the system, each in a state where the capability has
already been used and one where it has not, and what is observed
after each; an action that only observes is the Then of the others,
and the When where no other action precedes it; a combination that
repeats another scenario or shows nothing is dropped. The scenarios
that show one rule are one story. Where the code changes to make a
scenario pass is the implementer's finding, not a story.

  Cut on code:     Story: Pin a note (the pin handler sets pinned_at)
                   Story: List pinned notes first (first task: check
                     whether the list already sorts by pinned_at; if it
                     does, add the scenario as a test and close)
                   Story: Unpin a note (the unpin handler clears
                     pinned_at)
  Cut on actions:  Story: Keep a note at the top of my list while it
                     is pinned
                   Scenario: a note the owner pins is listed first
                   Scenario: a list with nothing pinned keeps its order
                   Scenario: a note the owner unpins returns to its
                     place

Taking it apart: the three stories are cut where the code changes,
the pin handler, the list, the unpin handler, which is how the code
is laid out. The new capability is pinning. The actions the actor
takes on the system are pin, unpin and view the list. Viewing only
observes, so it is the Then of pin and unpin, and the When where no
other action precedes it, with nothing pinned. Enumerated with and
without a pinned note: pin then view; view with nothing pinned; unpin
then view. Pin with a note already pinned and view with a pinned note
each repeat pin then view, and unpin with nothing pinned shows
nothing, so all three are dropped. The three that remain show one
rule, a pinned note is listed first, so they are one story. "Check
whether the list already sorts" asks what the system does today; the
story describes the end state, as The story in SKILL.md says, so its
Then says the pinned note is listed first whether or not the list
sorts today, and the implementer reads the code to find what is left
to build. The check is settled in the session, as Before starting in
SKILL.md says, not filed as a story.

Signs a story may be too big, and what they mean. Each is a prompt to
check the slice's size against the sizes in
thin-vertical-slice#one-slice-not-split; none is a reason to cut by
rule:

- The title needs an "and" whose halves could each ship and be checked
  on their own: two rules.
- You could not pause after it and hand the next story to someone
  else: it is not a real boundary.
- The Given sets up more than three things that differ from the
  skeleton's state: the reader can no longer hold the setup in their
  head, and the implementer will get one of them wrong.
- The scenarios introduce a new threshold, fallback, or alternative
  flow under the name of error handling: a second rule.
- More than about five scenarios: either a second rule has crept in, or
  instances of one rule are written as separate scenarios when they
  should be rows of one outline.

The counts are smells, not limits. A cohesive story one over stays; a
story that trips two of these splits.

Merge two stories when neither could be demonstrated without the other.

Gherkin's verbosity is a feature. When a scenario gets long because of
setup, trim the story. When it is long because the steps are imperative
("click", "type", "then click"), rewrite them declaratively.

**Parallel work is a consequence, never a goal.** Stories are sliced
by capability; where two capabilities happen to be independent, their
stories can run concurrently, and the output says so. Never split a
story, or arrange the code, to make more lanes: a poor slice costs
more than a serial one. A `Depends on` line records a real dependency:
a story that needs another's schema, contract, or wiring, or that
edits the same function or path. Two stories with independent rules
that both change the write path are serial, because two agents
rewriting one function is a merge nobody asked for. Anything parallel
agents would collide on is decided once in the epic and referenced
from the stories: migration numbering, constraint and index names and
who creates them, the error shape and which error wins when several
apply, file ownership.

**Exit test:** each story passes the handoff checklist.


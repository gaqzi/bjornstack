# The session, phases 2 to 4

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
at the network boundary, which may be nothing. A feature boundary is
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
failing test is the definition of done, and the skeleton story owns
making it pass or the first step toward it.

### 3. Skeleton

The first story is the walking skeleton: the thinnest path through every
layer the feature will touch, demonstrable end to end. It is
deliberately underwhelming. A real endpoint that stores one record and
returns it, a form that submits one field and is ignored, a scheduled
task that sends an empty email. A flag is how a skeleton ships safely,
not what it does: behind the flag it still crosses every layer.

  Not a skeleton:  Service foundation, routing, auth middleware, test
                   harness; every ledger route returns 501
  Skeleton:        Record a ledger entry: POST one entry, get 201 and
                   the stored row back, through real Postgres

The first is a horizontal layer with nothing to demonstrate. The second
crosses every layer, and the harness gets built because this one
scenario needs it.

The skeleton proves the wiring, which is the one thing unit tests cannot
prove, and it is the template later stories copy. So it carries only
what its one scenario needs, built to the standard you want everywhere.
Scaffolding that no scenario exercises is not thin, it is speculative;
the second story will show which parts of the pattern need adjusting,
and that is cheaper than guessing.

A layer is a tier the path the scenario drives crosses, such as the
entry point, the logic and the storage, or a command, the script it
runs and the file it writes; it is not a file the feature will ship.
The skeleton builds the part of each layer its scenario needs. Every
other mechanism, file or deliverable lands with the story whose rule
needs it, and a step the repo's conventions ask of every change is
listed in no story.

Agents put later tests wherever the skeleton put its own, so unless
the feature is all glue, the skeleton's tests run in both layers, the
black-box check and the unit tests. It builds whichever harness is
missing and uses the one that exists, and it still carries only the
empty case, such as a report with no rows, which the implementer's
empty-input unit test exercises in the unit harness. No rule is
ported or built in the skeleton to give the tooling something to
test.

In an existing system where the path is already wired, the skeleton
is the smallest new behaviour through the existing path, its
acceptance written as its end state. Don't invent a scaffolding story
for wiring that exists. When existing code has to be extracted before
the new path can reach it, that is a structural story that lands
before the skeleton; it is the one case where the skeleton is not
story one.

**Exit test:** the skeleton story has at least one scenario that
crosses every layer, and it could ship alone. Its rule is "the path
works", so a second scenario showing the path refusing is fine; a
second rule is not.

### 4. Slices

Every later story adds one rule on top of the skeleton. Order them so
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

**What makes a story: one rule.** A rule is a business decision the
system enforces: a threshold, a permission, an ordering guarantee, an
alternative flow. A story holds one rule and the scenarios that show it
from both sides, so a happy path and the failure of the same rule belong
together. A second rule is a second story, even when it looks like error
handling of the first.

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

A commit of around five hundred changed lines is the usual ceiling,
depending on the language and how much of it is test data. Much larger
means the rule is too big; much smaller, and not demonstrable alone,
means it is a scenario of another story. Structural stories are their
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

Signs a story is too big, and what they mean:

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


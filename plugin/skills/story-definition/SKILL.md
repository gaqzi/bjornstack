---
name: story-definition
description: "Turns a feature idea into thin, independently testable stories with acceptance criteria that an agent can implement without coming back with questions. Load whenever the user wants to define, scope, or break down a feature or epic, write user stories, acceptance criteria, Given/When/Then or Gherkin scenarios, slice work into increments, decide what the first deliverable or walking skeleton should be, or prepare work for agents to churn through. Also load when the beads design pattern reaches its breakdown step, or when a bead's acceptance field needs writing. Not for implementing a story, writing or planning tests, splitting a PR into commits, or scoping an experiment or spike."
disable-model-invocation: true
argument-hint: "[feature idea, epic id, or blank]"
---

# Story definition

A story is done when an agent can pick it up and finish it with only the
story, the epic, and the codebase. Every question the implementer would
have to ask is a defect in the story, and the point of this session is
to find those questions now, while the person who can answer them is in
the room. The only questions allowed to survive are decisions the user
has not made, and those are written down as open, not guessed.

Gherkin is used here for its shape, not its tooling. No step
definitions, no runner: a scenario is a readable spec that the
implementer transcribes into an integration test.

## Before starting

**Ask for intent, look up facts.** The user holds the mental model of
what the feature is for; extracting it is faster than building your own
and iterating on the delta. The codebase holds the facts: entry points,
existing patterns, what is already wired. Read the code before asking
anything the code can answer. An agent that asks the user which endpoint
to drive when the router is one grep away has wasted the user's time.

A question the code can answer is settled in this session, never
filed as a story: read the code for what shapes the story (entry
points, nouns, wiring), not to remove Then lines that already hold.
When the user is present, say what you are checking, so they can
answer it or stop you. When the code does not settle it and the user
is away, it is an assumption under the heading below, and the story
is written as if it holds. A question that needs a proof of concept
to settle is a spike; this skill does not write spikes, so name it
and stop.

**Starting from an epic or bead:** read its description, design, and
acceptance first. Ask only about the gaps.

**When the user cannot answer** (they are away, or the session is
non-interactive): sort each question by what would answer it. A fact
the code does not settle but the user's setup or docs would is
recorded with the assumption you made under a heading "Assumptions
made in the user's absence". What the system should do in a case the
request did not cover, such as an upload in a file format the request
never named, is a decision the user has not made: write it as a
question under a heading "Open decisions for the user", not as an
assumption and not only as an out-of-scope line, which would decide
it. Each entry says which stories it affects; continue. Stop only
when an assumption or an open decision would change the feature's
goal, not merely its shape, when a story assumes a capability no
story provides, as The story says, or when the question is a spike,
as above.

**Short path.** For a bug, or filling one acceptance field, skip to
[The story](#the-story) and the handoff checklist. A single story that
builds code is not short: phase 3, Architecture, in
`references/session.md`, runs before it is drafted, even when nothing
needs slicing. Work that builds no code skips phase 3, as
"Whether the architecture phase runs" below says. The other phases are for a feature that needs slicing.

## The session

Five phases, each with a question and an exit test. Don't move on until
the exit test passes: every later phase builds on the one before, and
the usual failure of breakdown sessions is slicing before the goal and
the verification are pinned, then finding the slices don't add up.
Goal is below. Verification, Architecture, Skeleton, and Slices are in
`references/session.md`; read that file when the Goal exit test
passes, before asking anything about verification or slicing.

### 1. Goal

Ask what the feature lets someone do that they cannot do today, who
that someone is, and why they want it. Write the answer as a story
sentence:

> As a <role>, I need <capability>, so that <outcome>.

The role is a real actor, not "the user". The outcome is what they get,
not what the system does. Each clause is one phrase with no list in it.
Ask why the actor wants this until the answer is a single reason; that
is the outcome. If two reasons remain, it is two sentences: keep either
one here and the other becomes a second feature. The capability is what
gives them the reason kept. Each other thing the draft mentioned is one
of two kinds: a check on that capability (a field written, a place it is
shown, an input refused), which goes in the acceptance; or something the
actor would still want without this capability, which is a second
feature. A sentence that carries the checks reads as a paragraph.

  Not a sentence:  As a human ending a session, I need a pick in the
                   close dialog to land in the log as the outcome, my
                   words if I gave any, and where they came from, so
                   that the log reads as what happened and what I said,
                   nothing repeated and nothing Claude wrote.
  Sentence:        As a human ending a session, I need my words kept
                   verbatim, so that whoever later asks why can read
                   them.

Asking why: the log should read as what I said because someone will
later ask why. The capability that gives that is the words kept
verbatim. The source and the no-repeat rule are checks on it. The pick
landing as the outcome is wanted even when no words were given, so it
is a second feature, and the slices phase gives it its own story.
Keeping "what happened" instead, with the pick as the capability and
the words as the second feature, would have been as valid.

Then write what is explicitly out of scope. Agents fill silence with
assumptions, and an unstated boundary is where they wander. Three or
four lines of "not this" prevent more questions than any amount of
"this".

An out-of-scope line must not settle a question the architecture
phase asks (phase 3), such as whether the system changes anything in
a system it does not own, or what marks an input as handled. Such a
question waits for phase 3, where it is answered from the prompt or a
rule, asked of the owner, or listed under "Open decisions for the
user". Do not propose a line that says the system does not do it, and
do not offer one as "strike or keep". Lines that settle no such
question are written and offered as before.

**Exit test:** the user can say, in one sentence, what is true after the
feature ships that is not true today.

### Whether the architecture phase runs

Decide this right after the Goal exit test, before any question of
phase 2 or of the architecture phase (phase 3). Work builds code when
it changes anything a program reads: source, configuration,
infrastructure definitions, or text a program reads. Take the first of
these that fits:

1. Any part of the work builds code: phase 3 runs.
2. The work plainly changes nothing a program reads, such as a guide,
   a plan for writing, or a change to how people work: phase 3 is
   skipped. Say so to the owner in one line, exactly:
   "Skipping the architecture phase: this builds no code."
   Then go on.
3. It is unclear whether the work changes anything a program reads,
   such as rewording text a program might send. With the owner
   present, ask that as the next question, before any question of
   phase 2 or 3: "Does this work change anything a program reads?"
   Then take 1 or 2 by the answer. While the owner is away, decide it
   yourself, list it under "Open decisions for the user" as whether
   the work changes anything a program reads, with your call, and take
   1 or 2 by that call, saying the skip line when the call is that the
   work builds no code. This open decision never stops the session,
   whatever else does: go on by your call.

Now read `references/session.md` for phases 2 to 5. The rest of this
file is the story shape, the handoff checklist, and filing, which the
phases refer to.

## The story

Write each story in this shape. Leave out fields the story doesn't
need; don't fill them with "N/A".

```
Title: <what the actor gains, one line>

As a <role>, I need <capability>, so that <outcome>.

Out of scope: <what this story deliberately does not do>

Acceptance:
  <scenarios, a checklist, or scenarios with a line or two of checks>

Constraints: <a requirement neither a test nor a thing to observe
  proves, so a reviewer checks it, if any>

Depends on: <story that must land first, if any>

Notes: <a reminder, a pointer, or the verification mechanism and run
  count when there is no epic, if any>
```

The mechanism the verification needs and the run count go in the epic's
verification, or in Notes when the story has no epic. Any other drafted
line is sorted by who would catch it missing. A test proves it:
acceptance; a line that restates what a scenario's steps already say
is cut. A thing to deliver, a README section or a docstring, is proven
by observing it, so it is acceptance too, a checklist item written as
the fact that is observed. Neither a test nor a thing to
observe proves it, and a reviewer checks it: a constraint. The
cross-functional requirements, concurrency, performance, migration of
existing data, compatibility, permissions, where a thing is stored, are
usually constraints; one that a test of this story proves is acceptance.
None of these, because the implementer would find it anyway: a note when
it saves a search, a pointer into the code or a reminder of a step, or
nothing when the story already names the file or step it would point to.
Each constraint and each note is one sentence.

  As drafted:  Acceptance:
               Scenario: a third visitor permit is refused
                 Given resident R with two active visitor permits
                 When R issues a visitor permit for "KLM456"
                 Then the response is refused with reason "resident
                   already has two active visitor permits"
                 And no event is appended to the audit log

               Black-box: the third-permit refusal.

               Notes:
               - A refused request appends nothing to the audit log.
               - README Permits section: describe the two-permit
                 limit.
               - The count of active permits and the insert run in
                 one database transaction, so two requests at once
                 cannot both take the last slot.
               - The audit log's append is in app/audit.py.
               - The black-box scenario runs through the replay tool
                 under tests/replays, as one recorded session with
                 its expected audit log.
  Sorted:      Acceptance:
               (the scenario, unchanged)
               - The README's Permits section says a resident holds
                 at most two active visitor permits

               Black-box: the third-permit refusal.

               Constraints:
               - The count of active permits and the insert run in
                 one database transaction, so two requests at once
                 cannot both take the last slot.

               Notes:
               - The audit log's append is in app/audit.py.
               - The black-box scenario runs through the replay tool
                 under tests/replays, as one recorded session with
                 its expected audit log.

Taking it apart: this story has no epic, so the fifth note, the
mechanism the verification needs, stays in Notes. The first note
restates the scenario's last And, so it is cut. The second names a
thing to deliver, the README section, so it is acceptance, a
checklist item written as the fact that is observed. The third is a
requirement no test of this story proves, the scenario has one request
and a test sending two at once passes or fails by timing, and no thing
to observe proves it either; a reviewer reading the code checks that
the count and the insert cannot interleave, so it is a constraint, one
sentence. The fourth is something the implementer would find anyway,
where the audit log is appended; it is a pointer into the code that
saves a search, so it stays a note.

The title names the capability from the actor's side, not the
mechanism from the code's. It is the line someone scans in a story
tracker months later, so it should say why the behaviour exists. One
line that fits the list without wrapping; no fixed length. Verbs like
"refuse", "keep", and "tell" face the actor; "implement" and "add"
face the code and belong in the commit subject.

  Story:  Refuse a contact submission we cannot reply to
  Commit: Validate contact form email and address

An "and" in a title is a signal to stop and ask, not a ban: could
each half ship and be checked without the other? If both could, they
are two rules and two stories. This sorts titles of stories you
draft; it never splits a slice that phase 3's cut made. If one half is only seen through the
other, or both halves name one reason from two sides, it is one
behaviour and the "and" stays.

  Two rules:  Pin a note and share it with a colleague
  Split:      Keep a note at the top of my list while it is pinned
              Share a note with a colleague
  One rule:   Pin a note and see it first in my list

Taking it apart: the first title has an "and", so ask of each half
whether it could ship and be checked without the other. Pinning could,
checked by the pinned note coming first in the list, with nothing
shared; sharing could, checked by the colleague reading the note, with
nothing pinned. Both could, so they are two rules and two stories,
each titled by what its half gains. The last title has an "and" too,
so ask the same. Pinning could not be checked without the second
half: a pin is only seen through the note coming first, and seeing a
note first shows nothing without a pin. The first half is only seen
through the other, so it is one behaviour and the "and" stays. It is the same
rule as the first Split title, and either title will do.

The sentence follows the method in Goal: ask why until one reason
remains, name the capability that gives it, put the checks in the
acceptance. Something the actor would want without this capability is
a second story.

A story describes the end state of the behaviour its one rule
governs, as its actor's actions exercise it, not the difference from
today. In an existing system some of the story's Then lines already
hold; they stay, because the story is the requirement and the
implementer reads the code to find what is left to build. What those
actions do not touch is outside the story even when the implementer
would find it missing: a capability the story assumes, which the
system lacks and no story in the set provides, is a gap. Raise it to
the user as a decision; in their absence it is the assumption that
changes the goal, so stop, as Before starting says.

A structural story has no actor outcome: it reorganises code that
exists, with no behaviour change. Replace the sentence with one line
saying what it reorganises and which behavioural story needs it. A
missing capability is not structural work; it is a gap, as above.

### Scenarios or checklist

Use scenarios when the outcome depends on the setup, or when there is
more than one actor or system state the reader must hold in their head.
Use a flat checklist when there is one actor, the precondition is the
skeleton's default state, and the outcome is a list of observable facts.
Mixing is fine: a story with two scenarios and one checked fact is
normal.

The switch signal: a checklist item that starts to read "if X then Y,
but if Z then W" has become two scenarios. Write them as scenarios. A
bug fix with a trigger condition gets one scenario; a bug fix in the
default state gets a checklist.

A scenario says what an actor does through the entry point and what
is then observed, a response or the state the verification names,
with concrete values. How the test is built stays out of it: the
layer it runs in, a fake or fixture, how many runs must pass, the name
of a test, an eval, or a function other than the entry point. Each is
replaced by what it stands for, or moved out as a test decision. A
fake or fixture stands for an action or a state, and the scenario says
that in the domain's terms: "it is 23:59", not "the clock is faked".
The mechanism that provides it and the run count go in the epic's
verification, or the story's Notes when there is no epic; the layer
goes in the one black-box line at the end of the acceptance; a name
goes nowhere, because the implementer names tests and functions. A
checklist item is held to the same rule: it states a fact that is
observed, not a test that passes.

  Not a scenario:  Scenario: a bare pick of Failed is answered in chat
                     (black-box: eval close-dialog-bare-failed)
                   Given a recorded transcript where the close dialog
                     was answered G1: Failed, no note
                   And the human's next message is "the venue fell
                     through and nothing else fits the dates"
                   When Claude records the goal
                   Then the log has GoalFailed{goal: G1, source: chat,
                     reason: "the venue fell through and nothing else
                     fits the dates"}
                   Guardrail: 5 of 5 runs.
  Scenario:        Scenario: a bare pick of Failed is answered in chat
                   Given a session with open goal G1
                   And the human answered the close dialog with Failed
                     and no note
                   When the human writes "the venue fell through and
                     nothing else fits the dates"
                   Then the log has GoalFailed{goal: G1, source: chat,
                     reason: "the venue fell through and nothing else
                     fits the dates"}

                   Black-box: the bare pick of Failed.

Taking it apart: "black-box" is the layer and "eval
close-dialog-bare-failed" the name of a test, so both leave the title;
the layer goes to the black-box line, the name nowhere. "A recorded
transcript where the close dialog was answered" is a fixture that
stands in for the human answering the dialog, so it becomes that
action, the human answered the close dialog with Failed and no note.
Replaying a recorded transcript is the mechanism, so it goes to the
epic's verification. "5 of 5 runs" is how many runs must pass, so it
goes to the epic's verification. "Claude records the goal" is the
system's step, not something the actor does, so it cannot be the When;
the actor's action is writing the message, so the message moves from
the And to the When. The transcript also carried the open goal G1, a
state, so it becomes a Given in the domain's terms: a session with
open goal G1. Left are the state, one action, and the one thing
observed.

One step, one thing. A handle (G, D1, T5) marks a thing; what follows
a handle without a new handle of its own is that thing's attributes,
including a handle the step refers back to, G in "D1 open under G".
An actor's name, Claude or the human, is not a handle. A Given
introduces one thing, with the attributes it is created with; a When
is one action; a Then observes one thing, an event with the fields
checked on it, a response field, or a state, an absence included. A
step with a second new
handle, a second action or a second observation is that many steps,
each after the first an `And` on its own line, so the reader sees
where every fact enters. A thing no later step names or checks is
cut, because it is setup the implementer must build with nothing to
check it against. When a story has two or more scenarios and they
open with the same Given steps, write those steps once under
`Background:` above the scenarios; a scenario that needs one of those
steps different or absent takes that step out of the Background, back
into every scenario's own Givens.

  Crowded:   Given a session with goal G, decision D1 open under G with
               criteria C1 to C4, and thread T5 "Best Greek pick is 2h
               by bus from the airport. OK?" open under G, asked by
               Claude
             When the human writes "T5: no, two hours with the kids is
               a no. Keep transfers under 30 min."
             Then ThreadResolved{thread: T5} is appended and
               CriterionAdded{on: D1, origin: T5} with a text holding
               "30", and no DecisionMade is appended
  One each:  Given a session with goal G
             And decision D1 open under G
             And thread T5 "Best Greek pick is 2h by bus from the
               airport. OK?" open under G, asked by Claude
             When the human writes "T5: no, two hours with the kids
               is a no. Keep transfers under 30 min."
             Then ThreadResolved{thread: T5} is appended
             And CriterionAdded{on: D1, origin: T5} is appended with a
               text holding "30"
             And no DecisionMade is appended

Taking it apart: the Crowded Given introduces the new handles G, D1,
C1 to C4 and T5, so it is that many things, one step each. No later
step names or checks C1 to C4, so the criteria are cut. D1's step
names G, the Then names D1, and the When and the Then name T5, so
those three stay, each with the attributes it is created with: T5's
question, the G it refers back to and its asker stay on T5's line.
The Then observes three things, two events appended and one not, so
it is three steps, each carrying the verb they shared. The story has
one scenario, so there is no Background.

Quote texts, bare the handles. A text is something someone wrote: a
message, a thread's question, a criterion's wording, a field's
contents. A text is written in double quotes, exactly as it is, and
spelled the same in every step that carries it; so is a fragment of a
text a step checks, "30" above. A number or a pick from a fixed set
(120.00, Failed, unchecked) has one spelling and stays bare; a number
inside someone's words is part of the text. A handle such as G, D1 or
T5 stays bare, and its text may follow it in quotes. A Then that
checks for a text an earlier step wrote, in a Given, the When or a
column an earlier step reads, carries that text in quotes, not a
description of it and not its handle. A Then that checks for no such
text either writes the words it checks for, as the outline's messages
below do, or describes the text and leaves the words to the
implementer. In an Examples
table the quotes sit in the cell or around the placeholder in the
step, either will do, never both.

  Inferred:  Given a session with goal G
             And decision D1 open under G with criteria C1 Europe
               and C2 sea ≥ 18°C
             When the human writes "D1: the water has to be warm"
             Then Claude's last message names the criterion this
               serves
  Verbatim:  Given a session with goal G
             And decision D1 open under G
             And criterion C2 "sea ≥ 18°C" on D1
             When the human writes "D1: the water has to be warm"
             Then Claude's last message names "sea ≥ 18°C" as the
               criterion this serves

Taking it apart: the Then checks that Claude names the criterion
warm water serves, and that criterion is C2, so the Then checks for
a text the Given wrote, C2's wording. It carries that text in quotes,
spelled as the Given spells it, rather than only describing it as
"the criterion this serves" or only naming C2. The criteria's
wordings are texts, so the Given quotes them too. By the rule above,
D1, C1 and C2 are one step each, and C1, which no later step names or
checks, is cut. C2 and D1 are handles and stay bare. The human's
message was already quoted.



When one rule has many instances (validation rules, thresholds, a
calculation over cases), write a Scenario Outline with an Examples
table: one row per instance, every row a requirement. The outline
counts as one scenario however long the table is. Say in one line,
the last line of the acceptance, which rows or scenarios run through
the black-box layer, or that none do. It comes after every scenario
and every checklist item, as in the sorted example under The story,
and outside the gherkin fence when there is one.
A story adds one only when the epic's black-box pair cannot show its
rule, and prefers none; a story with no epic carries that pair
itself, one scenario per side of its rule. The rest are pinned in
unit tests of the function that holds the rule; the story names
neither the function nor the tests. The story
keeps the whole requirement visible, and the test suite stays
proportionate. Don't push the table down into the epic or
a comment: a rule the user can't see in the story is a rule the user
can't correct.

A column that a Then step reads holds the value the reader checks,
written out in every row, even when the same value sits in a column
an earlier step reads: the cell says `"no venue fits"`, not `reason`.
A field name is a fine cell when the name is what is checked, as
`<field>` is below; it is a defect when it stands in for the value,
because that is a check the implementer has to invent.

A table is for instances that differ only in values. When cases differ
in shape, a different Given, a different kind of Then, write them out
as separate scenarios: three scenarios that each read as a sentence are
more expressive than one outline whose columns strain to hold them. A
story with two or three written-out scenarios on each side of its rule
is normal, not a smell.

**Outline example** (one rule, three instances, no black-box row:
the epic's unhappy scenario already submits an invalid form):

```
Scenario Outline: an invalid field is refused with its reason
  Given the contact form filled in validly
  And <field> is <value>
  When the visitor submits
  Then the form is shown again with "<message>" against <field>
  And no message is sent

  Examples:
    | field   | value           | message                     |
    | email   | "bjorn.example" | must contain @              |
    | address | "Oslo, Norway"  | must be in Sweden           |
    | robot   | unchecked       | confirm you are not a robot |
```

followed, outside the fence, by the acceptance's last line,
`Black-box: none.`

**Scenario example:**

```
Scenario: a recorded ledger entry cannot be removed
  Given a ledger with one posted entry of 120.00 to account 4000
  When the accountant requests its deletion
  Then the entry is still present
  And a reversal entry of -120.00 is appended referencing it
```

**Checklist example** (the story's default state is a ledger with one
entry):

```
Acceptance:
  - GET /ledger/{id} returns 200 with the entry's amount, account, and recorded_at
  - The response is byte-identical on repeated calls
  - An unknown id returns 404 with an empty body
```

## Handoff checklist

Run this per story before filing, then once across the set. For each
item, the fix is to put the answer in the story, move the decision to
the epic, or split the story. Never leave it for the implementer to
guess.

Per story:

- What would an agent have to ask the user to implement this? Answer
  it, or record it as an open decision for the user.
- Does the story, the skeleton included, build only what its one rule
  needs? Each mechanism, file or deliverable it builds is needed for
  that rule's scenarios to pass, or is a fact its checklist observes
  about that rule, like the README section stating the permit limit.
  A part another rule needs goes to that rule's story, whatever
  acceptance line could be written for it here; a step the repo's
  conventions ask of every change, a design record or a manifest, is
  listed in no story.
- Is every noun in the scenarios defined in the story, the epic, or the
  codebase? Check the codebase, don't assume.
- Does the story say which entry point to drive and what to observe?
- Does any scenario or checklist item say how the test is built (a
  layer tag, a fake, a run count, a test name) instead of what the
  actor does and what is then observed? The black-box line at the end
  of the acceptance is the one place a layer belongs.
- Does any step hold a second new handle, action or observation, or
  set up a thing no later step names or checks?
- Does any Then describe, or name by its handle, a text an earlier
  step wrote?
- Could it be implemented in a way that passes its acceptance but is
  not what the user wants? Read each scenario as an adversary looking
  for the laziest passing implementation. If one exists, the acceptance
  is too loose. The usual leaks: an assertion of the form "is not X",
  which anything else satisfies, so state the expected value; a rule
  left to a model's judgment where a model drives the system, which
  passes every scenario and can be talked out of the rule, so a
  constraint says that code decides it on the value the model
  extracted; and a story wholly true today or once another story
  lands, which has
  nothing of its own to build; its lines belong in the story whose
  rule they show.
- Does every rule about time, limits, or retries have a scenario at
  its edge? Just inside and just outside the window, the first run
  with no history, the attempt after the last retry. Without the edge
  the implementer picks one and the user discovers it in production.
- When a failure is handled, does the story say which failures: what
  counts as transient and is retried, what is permanent and is not?
- Does the story cover concurrency, permissions, performance,
  migration of existing data, compatibility, and where a thing is
  stored, where they apply, in Acceptance when a test proves it and in
  Constraints when none does? These hide behind a well-defined entry
  point.
- Does any constraint state what a test of this story or a thing to
  observe proves, or any note other than the verification mechanism
  and run count state a requirement? The first is acceptance; the
  second is a constraint, or acceptance when a test of this story or a
  thing to observe proves it.
- If the verification needs a mechanism (a controllable clock, expiring
  a key, a captured outbound message), does the epic, or the story's
  Notes when there is no epic, say which one? "Fake the clock" is not
  an instruction when the expiry lives in Redis. When a rule depends
  on the time, is the approach to time decided first, citing
  strategies/time-in-tests.md, before a clock mechanism is named?
- Does the verification ask for an eval, a model run against a prompt
  or skill an agent loads? Does it name the scenario or checklist item
  the eval proves, one whose behaviour no script check could catch?
  That item's Then steps or fact are what the eval asserts; the
  prompt it runs goes with the mechanism and run count. With no such
  item, drop the eval, tell the user in one line, and let a script
  check prove what it would have.
- Does it depend on a story that is not yet written?
- Does it mix structural and behavioural change?

Across the set:

- Do any two stories disagree on a shared contract: an error shape, an
  id format, a field name? Move the contract to the epic.
- Does any story's scenario contradict the epic's design or
  verification section? The epic wins, so fix the story or change the
  epic deliberately.
- Does the dependency graph say what can run in parallel, and has
  every shared resource the parallel stories touch been settled in the
  epic?

Before showing the stories, load workflow:feedback and run it over this
session. Its counts line for story-definition goes in the message that
shows them.

Then show the stories to the user before filing. They are the ones who
will see what the session missed.

## Filing

When stories are stored as beads, load the beads-workflow skill and
follow its create checklist. The mapping is:

- The feature's story sentence and out-of-scope lines go in the epic's
  `--description`, followed by its assumptions and open decisions
  under their headings; a story with no epic carries them in its own.
- The verification decisions from phase 2 (entry point, observed state,
  stubs, the feature-level happy and unhappy scenarios) go in the
  epic's `--acceptance`. That is the evaluation protocol, which
  beads-workflow places in acceptance, not design.
- When the Architecture phase ran, its answers, each with its source,
  and its open decisions, under a heading "Architecture", with shared
  contracts, the language and harness the unit tests run in
  (or that the feature is all glue), and anything parallel agents
  would collide on go in the epic's `--design`; for a lone story with
  no epic, they go in that story's own `--design`. No list of unit
  tests goes anywhere: the implementer writes them for every rule
  whether or not a story names them.
- Each story's sentence and out-of-scope lines go in `--description`,
  with its notes at the end of it. Its scenarios or checklist go in
  `--acceptance`, its constraints in `--design`, which beads-workflow
  defines as how the thing is built, and each story takes
  `--parent <epic>`. Stories don't repeat the epic; the parent link is
  the one hop back.
- Scenarios, in the epic's acceptance and in a story's, go inside one
  fenced ```gherkin block holding the Background, the scenarios and
  any Examples table. The other verification decisions, checklist
  items and the black-box line stay outside it as plain lines, the
  black-box line last. `bd
  show` renders the field as markdown and drops the indentation of
  plain lines; the fence keeps it. A field holding backticks is
  passed through a quoted heredoc, with the terminator on its own
  line:

  ```
  bd create "<title>" --acceptance "$(cat <<'EOF'
  <the acceptance>
  EOF
  )"
  ```
- `Depends on` becomes a `blocks` dependency. No dependency, no edge.
- Once filed, any line of the epic or a story names a story by its
  bead id, never by its place in the list ("story 3"), because a
  place changes when stories are reordered and an id does not. While
  drafting, a number may stand in: renumber every reference whenever
  drafts are reordered, and once every story has its id, replace each
  number with the id of the story it stands for. `bd update` replaces
  a whole field, so resend the whole field, through the heredoc above
  when it holds backticks.

When the session cannot file the stories itself, it gives the stories
and the exact commands in its message, or in the stories file. It
never writes a script or any other file than the story and design
output.

Without beads, the same shape goes in one file the user names, epic
section first, stories after, with the dependency summary at the end.
A story there names another by its title.

## Relation to test design

A scenario is an integration test at lower resolution: Given is the
state with its overrides, When is the driver, and the Then steps are
the comparisons on what that one action produced. The implementer
loads the test-design skill, transcribes
the black-box scenarios and rows into that layer, and turns each
Examples table into a table test of the pure function that holds the
rule. Unit tests are written for every rule whether or not the story
names them; a story lists none. A row proven in a solitary test is
not re-proven in the black-box layer. The skeleton story is the
invariant test at system scale, and every later story is an override on
it. If a scenario cannot be expressed as one state, one action and
the observations that follow from it, the story is asking for two
things.

## Install / Update (`/story-definition install`)

When the user runs `/story-definition install` or
`/story-definition update`, read `references/install.md` and follow it.
It manages the `## STORY DEFINITION` section of the project's CLAUDE.md.

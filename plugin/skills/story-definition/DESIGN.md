# story-definition: design record

For humans developing this skill. Not referenced from SKILL.md, so
agents never load it. It is the current expected state of the skill:
what it
is for, the rules in force and why, how it is judged, what the runs
taught. History is in git.

## Description (what and why)

A facilitated session that takes a feature idea to a set of stories that
a group of coding agents can implement without coming back with
questions, unless something genuinely cannot be done while meeting the
criteria.

The problem it solves: the design bead pattern in beads-workflow names a
"breakdown" step that produces implementation beads with acceptance
criteria, but says nothing about how to do that well. Without guidance,
agents either write vague acceptance ("works correctly") or produce
ceremony on three-line tasks, and the implementing agents come back with
questions that the person who could have answered them has already
forgotten the context for.

Goals, in priority order:

1. Stories are question-free at handoff. The session absorbs the
   questions; the implementers don't ask them.
2. Stories are thin enough to be demonstrable one at a time, in an order
   where each builds on the previous. Walking skeleton first.
3. Verification is decided before design. At minimum technical (which
   entry point, what is observed); business acceptance may be deferred.
4. Gherkin is used where it earns its place and not elsewhere.

Non-goals:

- Implementing stories. That is the implementer's job with test-design.
- Project management: estimates, priorities beyond ordering, sprints.
- Replacing beads-workflow. This skill produces content; that one files
  it.

## Design (how)

### Decisions

**Separate skill, not a section in beads-workflow.** Beads-workflow
loads on every `bd` command and every bead ID; story-writing guidance is
irrelevant to most of that traffic. The content is also a method that
applies regardless of where the stories are stored. Beads-workflow
points here from its `--acceptance` field note and from step 4 of the
design bead pattern; this skill points back in "Filing".

**Name: story-definition.** "Feature" is the input, stories are the
output, and the skill's job is producing stories. The user prefers
"story" even though the term is less common now.

**Five phases with exit tests: Goal, Verification, Architecture, Skeleton, Slices.**
Each phase has one question and one exit test, because the failure mode
of breakdown sessions is sliding into slicing before the goal and the
verification are pinned, then discovering the slices don't add up.
Verification before skeleton follows the Outside-In loop: the failing
outer test defines done, so it has to be nameable before the first
slice is chosen.

**The handoff checklist runs workflow:feedback before the stories are
shown.** The author asked for the session's pushbacks to be recorded
without remembering to ask, and the handoff is where story-definition's
session ends. A step before "Then show the stories" loads the feedback
skill, and its counts line for story-definition goes in the message
that shows the stories, so the author sees how much correction the
skill is waiting on, even at zero.

**Ask for intent, look up facts.** The user holds the mental model;
the codebase holds the facts. An earlier "ask before proposing" made
agents ask the user for things the router was one grep away from
answering. Where the user is absent, a fact question gets an
assumption under its own heading; what the system should do in a
case the request did not cover is an open decision under a heading
of its own, never only an out-of-scope line, which would decide it;
out of scope is for a failure the user or the request ruled out. Both file in the epic's
description. The session stops only when an assumption or an open
decision would change the goal, or a story assumes a capability no
story provides.
Forced by refund-escalation runs that put a request with no amount,
or in another currency, out of scope or under assumptions.

**The story sentence is one reason, one capability, no list.** Ask
why until one reason remains; the capability is what gives it; each
other thing in the draft is a check (in the acceptance) or a second
feature. Forced by a live run whose sentence listed every field
written and had three "and"s in the outcome. The pair in the skill is
that sentence and its repair.

**Gherkin versus checklist is a decision rule, not a vibe.** Scenarios
when there is more than one actor or system state to hold, or when the
outcome depends on the setup. Checklist when one actor, default
precondition, flat list of observable facts. The switch signal is a
checklist item that starts to say "if X then Y, but if Z then W". The
user's own observation drove this: Gherkin's verbosity is useful as a
signal that a story is too big, so the response to a long scenario is to
slice, not to trim words.

**A story is one rule.** A story holds one business rule and the
scenarios that show it from both sides; conventional responses (404,
malformed input) are not rules; instances of a rule (each validator)
are rows of one table, and a check earns its own story only when it
needs its own mechanism. An earlier split trigger, "a new Given that
changes the Then is a second story", was also the Gherkin trigger, so
every Gherkin story had to split: Haiku wrote five stories for a 30-day
cookie, Opus ten for the ledger. A later reading of "a rule is a
threshold, a permission..." as "each validator is a rule" split the
contact form into seven; the rule-versus-instance paragraph answers it.

**Every story is checked for one rule and a thin slice, the skeleton
included.** A handoff item asks whether each mechanism, file or
deliverable a story builds is needed by its one rule: for the rule's
scenarios to pass, or as a fact the checklist observes about the
rule. The test is the rule, not whether an acceptance line exists,
because any part can be given a checklist line. A part another rule
needs goes to that rule's story; a step the repo asks of every change
(design record, manifest) is listed nowhere. The skeleton's "every
layer" means the tiers its scenario's path crosses, not the files the
feature ships. Forced by a skeleton story that bundled every file of
a plugin feature and a second rule's scenario.

**A story describes the end state, not the delta.** A story says what
holds after it lands for the behaviour its one rule governs, as its
actor's actions exercise it; Then lines that already hold stay, and
the implementer reads the code for what is left to build. A
capability the story assumes, which the system lacks and no story in
the set provides, is a gap raised to the user, because it changes
the goal; a question the code can answer is settled in the session,
never filed as a story; a question that needs a proof of concept is a spike,
which the skill names and stops on. Forced by the eval loop on the
remember-me prompt, where both texts split one rule into three
stories along handler seams (login, logout, cookie middleware) and
wrote two of them "first task: check whether this already holds; if
so, add the scenario as a test and close"; the eval forbids a
codebase, so the lookup became a story and "look up facts" had
nowhere to send it. Beck's "make the change easy, then make the easy
change" is the implementer's commit order, which the skill already
requires, not a reason to split a story.

**Scenarios are enumerated from the actor's actions.** They come
from the actions the actor takes on the system, each in a state where
the capability has been used and one where it has not, and what is
observed after each; an observing action is the Then of the others;
repeats and empty combinations drop; the scenarios that show one rule
are one story. A handler, a file or a middleware is how the code is
laid out, and where the code changes is the implementer's finding.
Same evidence as above. The
pair sits in session.md Slices, in a notes-list domain, because every
run that split had loaded that file and the login domain belongs to
an eval. The guard against the end-state rule making stories too
coarse is one rule per story and the five-scenario smell; the contact
form's three-story bar shows if it slips.

**Slicing rules are borrowed, not invented.** Each traces to a
bjornstack source (see Sources), so the skill doesn't drift from the
tenets the rest of the workflow is built on. The additions without a
source are the one-rule-per-story reading above, the end-state rule,
and the story format, Gherkin, and agent-readiness material, which
bjornstack does not cover.

**Scenarios are the integration-test list, nothing more.** This is what
keeps Gherkin short. Validation, calculation, and edge-case tables are
unit tests the implementer writes; test-design owns that layer. The
cross-link to test-design is explicit: Given is the state with
overrides, When the driver, Then the one comparison; the skeleton is the
invariant test at system scale.

**A scenario says what the actor does and what is observed; test
mechanics stay out.** Layers, fakes, run counts, and test or function
names are replaced by what they stand for or moved to the black-box
line, the epic's verification, or Notes. A live run put layer tags on
titles, "5 of 5 runs" lines, and a replay fixture in a Given; the skill
said what a scenario includes but not what it leaves out, and the
outline example's trailer named where unit tests go, which agents
copied and extended.

**Outline cells hold the value the reader checks.** A column a Then
step reads is written out in every row, even when the same value sits
in an earlier column; a field name is a cell only when the name is
what is checked. A live run wrote `reason` where the row's text
belonged.

**One step, one thing.** A handle marks a thing; a Given introduces
one thing with the attributes it is created with, a When one action,
a Then one observation, and anything further is an `And` of its own.
A thing no later step names or checks is cut. A Background holds the
Given steps every scenario of a multi-scenario story opens with. The
user's own stories had paragraph-long Givens listing every node in
the session and Thens joining three events with "and"; the pair is
one of them. Six drafts failed review: a lexical split test (commas,
"with", "and") breaks the file's own examples, and "attributes a
later step reads" cuts structural attributes such as a parent. The
split is on new handles and the cut on whole things, which every
existing example satisfies.

**Quote texts, bare the handles.** A text someone wrote (a message, a
question, a criterion's wording) is in double quotes, verbatim and
spelled the same in every step; numbers and fixed picks stay bare; a
handle stays bare with its text after it in quotes. A Then that
checks for a text an earlier step wrote carries it in quotes, not a
description or its handle; a Then that checks for no such text
writes the words or describes the text. The user marks up stories
this way by hand and had drafts where the criteria's texts had to be
inferred. Seven drafts failed review: "a value a later step reads
back" did not cover a quoted thread question nobody reads back, and
"a text the system composes" also covered the outline's fixed error
messages. The line that held is whether an earlier step wrote the
text.

**Constraints are a field of their own.** The mechanism and run count
go in the epic's verification, or in Notes when there is no epic;
every other drafted line is sorted by who would catch it missing. A
test proves it, acceptance, and a thing to deliver (README section,
docstring) is proven by observing it, so it is a checklist item
written as the observed fact. Neither a test nor a thing to observe
proves it and a reviewer checks it, a constraint: the cross-functional
requirements (concurrency, performance, migration, compatibility,
permissions, where a thing is stored) are usually constraints, and one
a test of the story proves is acceptance. The implementer would find
it anyway, a note when it saves a search, or nothing. Nine runs of the
parking-permit prompt on three models filled Notes with requirements
no scenario proved: the transaction behind the concurrency guarantee,
the refusal shape, where a counter lives, which mailer to reuse. A
Notes-only rule (a note earns its line when neither acceptance, epic
nor codebase gives it and a wrong guess would pass and be sent back)
passed review but left those requirements with no home. Constraints
file in the story bead's `--design`, notes at the end of its
`--description`; reviewer-spec treats an unmet constraint as a `must`
finding and dispatch checks constraints as it checks notes.

**Two budgets: expression and black-box tests.** The scenarios are the
requirement, as expressive as the rules demand; a rule with many
instances is a Scenario Outline with an Examples table, every row a
requirement. The black-box budget is per feature: the epic's pair per
boundary is the floor, and a story adds a black-box scenario only when
its rule changes what the entry point does in a way that pair cannot
show, preferring none. Every other row is pinned in unit tests, which
the implementer writes whether or not the story names them; stories
list none (decision wf-gck). Tables stay in the story, never pushed
into the epic, so the user can see and correct every rule. An earlier
draft carried "one happy and one unhappy per boundary" from the test
strategy into the spec, which capped what a story could say; the
later one-per-side-per-story allowance grew a feature's black-box
check past two minutes. The epic holds exactly one happy and one
unhappy scenario per boundary, the unhappy one the top-ranked
failure. Boundaries are counted by capability: every endpoint, method
and action on one capability shares its boundary, and a second kind
of entry point (an endpoint and a message consumer) is a second one.
Every other failure is a scenario of the story whose rule it shows,
or out of scope. Forced by a ledger run that, with stories told
to prefer no black-box scenario, moved two more failures into the
epic and counted record, read and change attempts as three
boundaries.

**The verification phase checks the unit layer exists.** When the
feature's logic is more than glue and the planned language would make
its unit tests slow or awkward, the session proposes writing that
logic in the project's main language, suggesting Python only when
the main language is a bad fit (a project mostly in shell), and asks
the user before slicing; test-design and the implementer apply the
same rule.
Logic that needs a unit test is not glue; shell is for glue a
black-box check covers. The epic names the language and harness the
unit tests run in, or that the feature is all glue. Forced by
an epic that recorded "rule list for unit tests: none" for sh and jq
scripts driving a real CLI, so every row of every story landed in a
black-box check that took 125 to 188 s, 92% of it inside the CLI.

**The skeleton's tests run in both layers.** The skeleton builds
whichever of the black-box check and the unit harness is missing and
carries only the empty case. The outline example shows no black-box
row, because agents copy examples over prose. Agents put later
tests where the skeleton put its own; a skeleton that built only the
black-box check sent every later row there, and a drafter told to
build the tooling also ported every rule into the skeleton.

**Scenarios filed in beads are fenced.** `bd show` renders the
acceptance field as markdown and drops the indentation of plain
lines, so Gherkin read back from a bead lost its structure; a
```gherkin fence keeps it, and checklist items and the black-box line
render fine outside it. The black-box line is the last line of the
acceptance, after every checklist item and outside the fence; two
visitor-permits runs put it inside the fence with the scenarios and
the README and docstring items after it, so the outline paragraph
and Filing both say it comes last, and the outline example shows the
line outside its fence. The field is passed through a quoted heredoc
because `--acceptance` takes only a string and the shell runs the
fence's backticks inside double quotes. Beads-workflow carries the
same instruction at its `--acceptance` field note.

**An eval names the behaviour only it can prove.** A verification
that asks for an eval names the scenario or checklist item it proves,
one no script check could catch; that item's Then steps are the
eval's assertions, so they live once, in the acceptance, and the
prompt goes with the mechanism and run count. Without such an item
the eval is dropped and a script check proves the rest, because a
model run costs far more than a shell check (decision wf-gck).
Forced by a story that asked for "shell check and eval" and defined
no eval.

**Filed stories name each other by bead id.** The epic and its
stories refer to a story by its bead id, never by its place in the
list; draft numbers are renumbered on every reorder and replaced with
ids once every story is filed. Without beads, a story is named by its
title. Forced by an epic whose stories said "story 3" and "stories 1,
2, 7 and 6" in a numbering that no longer matched after reordering.

**Verification goes in the epic's acceptance, contracts in its design.**
Beads-workflow says an evaluation protocol is acceptance even when it
reads like a plan, so the entry point, observed state, and feature-level
scenarios belong there. Shared contracts and anything parallel agents
would collide on go in design.

**Story title and commit subject are different lines.** The commit
subject names the change to the code; the story title names what the
actor gains and is the line scanned in a tracker later. Squeezing the
title to 50 characters pushed toward code-shaped titles. The pair is
in the skill because agents copy examples over prose.

**An "and" in a title is a signal, not a ban.** It asks whether each
half could ship and be checked on its own; if both could, they are two
rules and two stories. If one half is only seen through the other, or
both name one reason from two sides, the "and" stays. The user's
cases: "a secure and private system" is one reason, not leaking
private information, seen from two sides; a skeleton that records an
entry and reads it back is one behaviour, because reading it back is
the only way the actor sees the write. The pair uses pinned notes, not
the ledger, so the ledger eval's skeleton title is not handed over.

**A rule a model could decide is decided by code.** Where a model
drives the system, the adversary item in the handoff checklist names
the rule left to the model's judgment as a leak, because it passes
every scenario and the customer can talk the model out of it; a
constraint says code decides it on the value the model extracted.
Forced by a refund-escalation run that lost this constraint once
stories stopped listing unit tests, the line through which earlier
runs had reached "the function that holds the rule".

**Size is one valuable commit.** A story lands as one commit holding
its black-box scenario, wiring, and unit tests, reviewable as one
thing, around five hundred changed lines depending on language.
Scenario counts stay as smells for expression; commit size is the size
rule.

**Parallel work is a consequence, never a goal.** Stories are sliced by
how a capability grows; parallelism is whatever independence falls
out, and stories that edit the same function are serial. The rule
exists because the same-code serialisation rule has an inverse
incentive: a run once invented "one validator file per rule" to make
validation stories parallel, which yielded one story per validator.

**Examples are added on evidence, as contrast pairs, lifted from
runs.** Agents copy examples over prose; the checklist example once
overrode its own rule, which proved it. So an example earns its place
only where runs showed the anti-pattern: the skeleton (the 501
foundation), the title (code-shaped by default), the sentence (a
paragraph), outlines versus written-out scenarios, test mechanics in
scenarios. Prefer a pair that shows the wrong thing beside the right
thing, taken from an actual run. Don't add examples to parts that
worked without one; every example is read on every load.

**The handoff checklist is the actual deliverable.** Everything before
it is how you get a story that passes it. The one question the session
is allowed to leave open is a decision the user hasn't made, and then
the session stops rather than guessing. Its items come from handoff
passes: a story wholly true once another lands (cut on a seam, so
its lines belong there; verifying today's behaviour is never a task
inside a story), "is not X" assertions, time and retry rules with no edge scenario, transient
versus permanent failures unnamed, a mechanism named but not specified
("fake the clock" against a Redis TTL), a story contradicting the epic,
parallel stories editing one function, test mechanics in scenarios.

**The core is the short path; the long path loads on demand.**
SKILL.md holds what every run needs: Before starting, Numbered threads,
Goal, Whether the architecture phase runs, the story shape, scenarios,
the handoff checklist, filing, and the relation to test design.
Verification, Architecture, Skeleton, and Slices live in
`references/session.md`, read when the Goal exit test passes, and the
install procedure in `references/install.md`. Goal stays in the core because the short
path applies its sentence method, and the two derivations stay with
their rules because reviews reject a contrast pair without one.
Forced by SKILL.md reaching 576 lines, over skill-creator's 500-line
ceiling; every real run so far took the short path, so the phases
were the text least often needed. The risk is a section not loaded
being a rule not applied, so the eval loop checks the long-path
transcripts read the reference, not only the outputs.

**Sources are named, not copied.** Say-it-once applied to the skill:
the rationale keeps living in bjornstack, the skill carries the one-line
rule and the attribution.

### Alternatives considered

- A section inside beads-workflow. Rejected: trigger mismatch and
  content kind mismatch (checklists for a tool versus a method).
- Mandatory Gherkin for all acceptance. Rejected: produces ceremony on
  bug fixes and structural stories; the user wants Gherkin only where
  interactions with setup exist.
- INVEST as the slicing checklist. Not adopted as a list; its
  properties are covered by the slicing rules and the handoff checklist,
  and bjornstack's "pause and hand off" test is a sharper independence
  criterion than "I" in INVEST.
- Referencing bjornstack files by path. Rejected: the skill is
  installed on machines that don't have bjornstack checked out.

### Sources

From /Users/ba/workspace/bjornstack:

- tenets/many-more-much-smaller-steps.md: "and" in the commit message;
  structural or behavioural, never both; skeleton, then behaviour, then
  polish; a feature inert behind a flag is a valid step.
- strategies/testing__outside-in-loop.md: happy/unhappy path
  definitions; the failing test defines done; error handling that adds
  thresholds or alternative flows is a separate feature.
- strategies/testing__black-box-integration.md: feature boundary is
  what consumers see; one happy and one unhappy per boundary; blast
  radius ranking.
- strategies/tidy-or-change.md: structural changesets land first and
  leave tests passing unchanged.
- .claude/skills/strategy-editor/SKILL.md: "could you pause between
  steps and hand off to someone else?"; collapse steps that would be
  done simultaneously.
- docs/WORKFLOW.md: design is "facilitate, ask", implementation is
  "execute, follow"; ask before proposing.
- Bead bs-y2f (unwritten Thin Vertical Slice strategy): first slice is
  the template; don't over-engineer it on that account.

bjornstack has no material on story format, Gherkin, or agent-readiness
checklists. Those parts of the skill are original.

Platform facts, checked on bd 1.3.1: `bd show` renders description,
design, acceptance and notes as markdown, so plain lines lose leading
spaces and fenced blocks keep them; `--acceptance` has no file or
stdin form (only `--body-file` and `--design-file` do), so a value
holding backticks goes through a quoted heredoc.

## Acceptance (how we judge it)

The skill works if, for a realistic feature prompt:

1. The output names the entry point driven and the state observed, not
   just "it works".
2. The first story is demonstrable end to end and thinner than any
   later story.
3. No story title bundles two behaviours that could each ship and be
   checked on their own; no story mixes structural and behavioural
   change.
4. Gherkin appears only on stories with setup or branching outcomes;
   small stories get a checklist.
5. A second, independent agent given one story and the epic context
   lists zero questions it would need to ask the user, or only
   questions that are genuinely the user's decision.
6. Where the user is unavailable, every assumption made is listed under
   its own heading rather than silently baked in.

Method: the skill-creator eval loop over the six prompts in
evals/evals.json (greenfield Go/Postgres ledger; scheduled CSV export
on a Django app; a "remember me" login option; a Rails contact form
with validation and a rate limit; a refund-escalation rule for a
support bot, whose prompt baits the scenarios with a test harness and
run counts; a visitor-permit limit on a FastAPI app, whose prompt
baits Notes with deliverables, a replay tool and a concurrency
requirement), each run with and without the
skill across models and effort levels. Then a handoff pass: a fresh
agent reads each produced story as the implementer and classifies
every question it would ask as CODEBASE, STORY, or USER; STORY-class
questions are the skill's defects. The workspace lives in the session
scratchpad, not in this repo, because the plugin's skills directory is
scanned on load.

Grading: the assertions an eval lists under `script_graded` are form
rules (story count, an assumptions heading, where a
harness, a requirement or a deliverable sits, the black-box line's
place) and are graded by `evals/grade.py` on the saved story; the
rest need reading for meaning and go to a sonnet grader. The script recognises stories by "Title:" lines or "Story <n>:"
headings and exits 2 when it finds none, so an unparsed output is
never graded as a pass. Changing how an assertion is graded does not
change the assertion, so it does not call for a whole-skill run.

Last measured result, at d8a1680 against the skill text at 502a18e,
one Sonnet medium run per prompt per text, the evals.json at d8a1680
for both: assertions 31/39 with the new text against 33/39 with
502a18e's. Per eval, new against old:

- ledger-greenfield 6/8 against 8/8. The new text titled the skeleton
  "Record a financial event and read it back" and put three unhappy
  scenarios in the epic instead of one.
- scheduled-export 7/8 on both. Neither run wrote the once-per-week
  guard; 502a18e's dropped it as an assumption.
- remember-me 3/5 on both. Both split the rule into two stories, the
  second for the thirty-day expiry, and put logout out of scope, so
  no scenario logs out.
- contact-form-validation 7/7 against 5/7. The old text named the
  email row in the validation story's black-box line and put lines
  after the black-box line in two stories.
- refund-escalation 4/6 against 5/6. The new run did not say the 500
  SEK comparison is code against the extracted amount, and recorded
  the missing amount and other currencies as an assumption, not an
  open decision; the old run named unit tests in the acceptance. The
  new run read only SKILL.md, taking the short path for one story.
- visitor-permits 4/5 against 5/5. The new run put the README and
  docstring checklist items after the black-box line.

The earlier handoff-pass numbers (STORY-class questions ledger 14
without the skill, 3 with; export 28 and 10; remember-me 10 and 6)
were measured at c7e53bd and have not been rerun.

Defect-fix check, not a whole-skill result: one Sonnet medium run each
of ledger-greenfield, refund-escalation and visitor-permits on the text
of bead wf-sp3 (the "and" signal, the one pair per boundary counted by
capability, open decisions, code-decided rules, the black-box line
last), graded by the script and a sonnet grader: 9/9, 6/6 and 5/5. The
ledger epic held one happy and one unhappy scenario; no ledger title
held an "and", so the new title row was not exercised on one.

## Lessons

- Evals that last regressed, all on Sonnet at medium effort:
  ledger-greenfield broke the no-"and" title rule on the skeleton and
  the one-unhappy-path rule in the epic; refund-escalation, on the
  short path for one story, left the threshold comparison unstated as
  code and recorded open decisions as assumptions; visitor-permits
  put checklist items after the black-box line. Contact-form-
  validation (eval 3) on Sonnet at high effort once split validation
  into seven stories; its three-story result is the bar that shows if
  the end-state rule makes stories too coarse.
- Eval prompts must come from a domain no example in the skill uses,
  or agents copy the example verbatim. Domains in use: contact form,
  scheduled export, remember-me, ledger, session close dialog, refund
  escalation, pinned notes, parking permits.
- A rule that ships with a contrast pair must derive the good example
  from the bad one in the rule's own words. Drafts that only described
  the good sentence ("narrow to one reason", "everything else is a
  check") failed review several times in a row.
- Don't retry, test mechanics rule: tying the Then to the entry point
  (Thens observe state, as Verification and the ledger example say); a
  fixture rule covering only actions (fake clocks and stubbed services
  stand for state); banning function names outright (a library or CLI
  entry point is a function); giving the mechanism or run count a home
  only in the epic (the short path has none); a trailer that says
  "this scenario" (invites a tag under each one; name the scenario).
- Don't retry, step rule: splitting steps on commas, "with" or "and"
  (the good examples contain all three inside one thing); keeping
  only attributes a later step reads (cuts a node's parent and
  text); a Background rule without the two-scenario condition (a
  one-scenario story moves its whole Given up); "a second handle"
  without "new" (D1 open under G holds two).
- Don't retry, quoting rule: "a value the actor enters or a later
  step reads back" (misses a Given's text nobody reads back);
  "when any way would be wrong, quote it" (invites quoting a
  paraphrase); "a text the system composes" as the describe case
  (the outline's error messages are composed and quoted); a
  derivation that cuts the unread criterion first and quotes what is
  left (the cut presupposes the fixed Then).
- Don't retry, end-state rule: "a capability the system lacks" as
  the gap (every later story assumes what the skeleton provides;
  the gap excludes what any story in the set provides); the end
  state of "the behaviour the actions exercise" without tying it to
  the rule (invites Then lines for existing list behaviour); "with
  and without the new option" (option is undefined, and "without"
  reads as today's system; say a state where the capability has
  been used and one where it has not); an enumeration rule that does
  not say the observing action is the Then of the others and the
  When where nothing precedes it, or that repeats drop (three actions
  times two states is six, and the pair shows three); "its own
  failure mode" in the mechanism list (licenses splitting error
  handling); a spike sentence that says stop without the absence
  paragraph saying so too; "seam" (no other sentence uses it); "a
  task in the session" (task is a beads issue type; say settled in
  the session, never filed as a story).
- Don't retry, constraints rule: "a changed description" as a
  deliverable example (collides with a tool's or model's description);
  "one line each" (read as a printed line); a derivation that cites a
  scenario the pair does not show (the concurrency outcome); a "first
  task: check whether..." note (a question the code answers is a task,
  per Before starting); the mechanism sentence after the sorting
  sentences (it passes the constraint test first); "a reviewer checks
  it and no test proves it" without the thing-to-observe carve-out
  (fits every deliverable); the black-box line anywhere but last; a
  "this scenario" black-box trailer.
- Don't retry, title rule: "no 'and'" as a ban or a word check (it
  fails a skeleton whose write is seen only by reading it back); a
  pair from an eval's domain (it hands the eval its answer).
- Don't retry, verification pair: "one per boundary" without counting
  boundaries by capability (a run counted each action as a boundary);
  "not a cap" without "and no more" for the epic (read as no cap on
  the epic either); "one capability may have several" boundaries
  beside the capability count (two counts at once); an example of
  record, read and refused change (the ledger eval's shape).
- Don't retry, absence rule: "a case the rule cannot read" as the
  open-decision example (the refund eval's answer); "a fact the code
  would settle" as an assumption (Before starting settles those by
  reading). Possible leak to watch: the code-decides leak in the
  handoff checklist is general but close to a refund-escalation
  assertion.
- Don't retry, title derivation: checking a half "on its own" without
  saying "without the other" (the pin half of both titles is checked
  through the list).
- Untested by a run, review only: the thin-slice and eval handoff
  items, the bead-id rule in Filing, the unit-layer language check
  and the two-layer skeleton harness. Their defects showed over a
  multi-turn session, which no single stored prompt reproduces.
- Effort level matters less than the rule text: Opus at low effort
  once produced the best breakdown by ignoring the rule that made
  Haiku over-slice. A bad outcome across models is the text, not the
  model.

## Open questions

- Spikes. A spike's deliverable is the answers that unblock the
  remaining stories, a different acceptance shape from everything in
  this skill, and the description already excludes them. The
  lookup-story pattern showed that without a named place for big
  questions, models invent stories for small ones. Decide whether a
  spike is this skill's or a sibling's; do not define it until a real
  need appears.
- Should the skill ask the user to pick the unhappy path from the top
  two blast-radius candidates every time, or only when ranking is
  ambiguous? Currently only when ambiguous.
- Whether to add a worked example of a full session (goal to filed
  stories) as a reference file. Deferred until evals show whether
  agents need it.
- Whether the "more than about five scenarios" threshold is right, or
  whether the Given-size rule alone suffices. Two agents kept a
  cohesive six-scenario story and said so, which is the intended
  reading.
- The evals forbid reading a codebase, which inflates STORY defects
  from invented names. The next full loop should run against a real
  small repo.
- Visitor permits on Sonnet, text at 05c816f (502a18e's rules):
  - One requested story split in two, one per rule: "The request
    asked for one story. ... Under 'one story, one rule' they are two
    stories, 1 and 2." No visitor-permits assertion checks the count.
    A fix decides whether an explicit one-story request overrides the
    one-rule-per-story split, or the split stands and the output says
    so, as this run did.
- Watch: agents reporting lane counts as if they were a score; and
  runs writing "pinned in unit tests" in Notes or the black-box line.
  If the second grows into named tests, cut that sentence from the
  outline paragraph.

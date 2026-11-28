# Story definition results

Score tables for the story-definition evals: one section per run, each
naming the date, arm, spec, skill commit, grader commit or "hand", and
key commit, then each rubric item's verdict and its outcome by the
spec's key, the number of questions put to the owner, and a count of
the briefkasten runs the architecture phase has been changed after.
Both arms of one spec are graded on the same grader commit. Transcripts
stay untracked under tmp/evals/.

## Baseline, owner away, 2026-11-23 — reference only, no pass bar

- Arm: bjornstack:story-definition as on main before the architecture
  phase (bs-f3o.7.19). The skill at this commit has no architecture
  phase.
- Spec: briefkasten, owner away.
- Skill and key commit: 39c3c1f.
- Grader: hand.
- Model: claude-opus-5-5.
- Cost: $1.25.
- Transcript: `tmp/evals/runs/2026-11-23-baseline-away/transcript.jsonl`
  (untracked, under tmp/evals; kept in the worktree
  agent-a94dc42c0adcc7d8f). The design is `workdir/STORIES.md` beside
  it; line numbers below point there.
- Questions put to the owner: 0.
- Briefkasten runs the phase has been changed after: 0.
- Discarded: an earlier run, `tmp/evals/runs/2026-11-20-baseline-away`,
  was denied reading the skill's `references/session.md`. Its scores,
  for comparison: domain-first-packaging missed, compute-or-coordinate
  missed, boundary-communication wrong, design-for-replay wrong,
  utc-computation wrong.

The session read `references/session.md`; its only denials were Bash
calls. No rule entry is cited anywhere in the design.

| Item | Mark | Verdict | Outcome |
|---|---|---|---|
| domain-first-packaging | rule | missed | missed |
| compute-or-coordinate | rule | missed | missed |
| boundary-communication | rule | answered-for-you | wrong |
| design-for-replay | rule + owner | answered-for-you | wrong |
| utc-computation | rule | answered-for-you | wrong |

### domain-first-packaging: missed

No list of capabilities and no package split. The design says only
"Go in one module" (STORIES.md:136) and that "A mailbox's output
directory is computed in one function" (STORIES.md:167). Neither
answers which capabilities the system owns.

### compute-or-coordinate: missed

The design says unit tests run "on pure functions, which take the time
as an argument" (STORIES.md:136-137; also STORIES.md:109). It names no
step as one of those pure functions, and does not say that any step is
kept apart from the Fastmail calls and file writes. Scorer's call: the
key's answer names the steps (what goes into an entry, which entries
are older than a week, which archive each moves to, how archives
link); a test style that assumes pure functions exist names none of
them, so it is no answer to "which steps". The reviewer read it as an
uncited answer (answered-for-you, wrong); see Review.

### boundary-communication: answered-for-you, wrong

The design decides how shared data is written without asking or citing
a rule, under "Shared rules that parallel or later stories would
otherwise collide on" (STORIES.md:163-172):

- "Saves, refreshes and prunes run one at a time within the process"
  (STORIES.md:166): every command writes the feed files, serialised.
- "The state file is JSON …, keyed by JMAP mailbox id. Story 1 creates
  it with `checked`; later stories add fields" (STORIES.md:169-170):
  save and refresh both write it, and no one part owns it.

That is not the key's single owner, and no source is named either way.

### design-for-replay: answered-for-you, wrong

Rule part: answered-for-you. The design states what happens after a
stop, with no rule cited:

- new mail is "matched by Fastmail email id, so each email is published
  once" (A8, STORIES.md:39-41);
- "A folder is recorded as saved only after its initial-archive.xml has
  been written" (STORIES.md:274-275);
- "A folder's last-check marker moves forward only after its feed.xml
  has been written" (STORIES.md:400-403);
- the archive is written first, so a crash "leaves an entry in both
  files, never in neither" (STORIES.md:467-468).

No decision is stored as an event before acting, and no
acknowledgement follows the feed write. The losses are not named. Open
decisions 1, 2 and 8 (STORIES.md:60-65, 79-82) ask about read mail,
mail moved in late, and which unhappy path to verify; none names mail
that expires, is deleted or is read elsewhere.

Owner part: answered-for-you. The agent decided the acknowledgement
itself, against the owner's pick of marking mail read: "Changing
anything in Fastmail, marking mail read included; the service only
reads" is out of scope (STORIES.md:9-10). The last-check marker and
email-id matching stand in; the key says a cursor or the service's own
copy does not settle the item.

Combined, by the key: the worst failing part is wrong.

### utc-computation: answered-for-you, wrong

"The archive is named for the ISO week the prune runs in, in UTC"
(A7, STORIES.md:36-38); tests compute archive names "from the run's
UTC date" (STORIES.md:102-104); "Older than 1 week" is 7×24 hours (A6,
STORIES.md:34-35). A7 quotes the first prompt ("feed.xml always points
to the current week") for which week, but the prompt says nothing of a
zone. Scorer's call: the quote is the source for the week, not the
zone, so the zone answer names no source and is answered-for-you.

### Live interview

No item's verdict needs a live interview: with the owner away, an item
listed under "Open decisions for the user" scores raised, and none of
the five is listed there. An owner-away run cannot show a late verdict,
a re-asked question, or whether an owner's answer reaches the design;
those wait for the live run in bs-f3o.7.15.

### Review

An independent reviewer re-scored compute-or-coordinate,
boundary-communication and design-for-replay from STORIES.md without
these verdicts. It agreed on boundary-communication and
design-for-replay. On compute-or-coordinate it scored answered-for-you
(wrong) and named the same doubt. Settled as missed: the key's answer
is a list of steps, and the design names none.

### Summary

- applied 0, answered-for-you 3, raised 0, late 0, missed 2.
- Outcomes: right 0, wrong 3, asked needlessly 0, late 0, missed 2.
- Same verdicts as the discarded run. With session.md read, the design
  has more open decisions (eight against six) and ordering
  constraints for a crash, but still cites no rule.
- Most telling misses:
  - The acknowledgement: the agent put marking mail read out of scope
    itself, the opposite of the owner's pick, and stood up its own
    last-check marker and email-id matching instead.
  - Shared files: every command writes the feed files and the state
    file, serialised in one process, where the rule asks for one owner.
    - BA: serialised could mean it was handled by one owner, who called both places. this is how I understood the publisher package to work, to be responsible for driving both changes, even if they were both small modules themselves that were collaborated upon in one place.
  - Crash ordering: the design orders writes with care (archive before
    feed, marker after feed) yet ties none of it to a rule, so the
    replay item still scores wrong.

## Live, 2026-11-23

- Date: 2026-11-23 (22:28 to 23:12 UTC; past midnight the owner's
  local date was 2026-11-24).
- Arm: bjornstack:story-definition with the architecture phase, from
  the plugin frozen at 84cffac, loaded with --restricted on the
  owner's normal login (bs-f3o.7.15, comment of 2026-11-23).
- Spec: briefkasten, owner answering live.
- Skill commit: 84cffac.
- Grader: hand.
- Key commit: 39c3c1f.
- Model: claude-opus-5-5.
- Transcript: `~/workspace/bjornstack-evals/runs/briefkasten-live-84cffac/transcript.jsonl`
  (untracked). `L<n>` is a line of that file. The design is the drafts
  in L189, amended in L202.

| Item | Mark | Verdict | Outcome | Baseline | Evidence |
|---|---|---|---|---|---|
| domain-first-packaging | rule | raised | asked needlessly | missed | L116: "**First open question: which capabilities does the system own?** ... Does this split match how you think about it?"; owner accepts at L127/L131. |
| compute-or-coordinate | rule | applied (check) | right | missed | L116 table row "Logic kept apart from I/O": the pure steps listed, cited compute-or-coordinate#logic-apart-from-collaborators. |
| boundary-communication | rule | applied (check) | right | wrong | L137: "**Who owns which shared data** (boundary-communication#single-owner ...)", table naming `mail`, `feed`, `publication`. |
| design-for-replay | rule + owner | answered-for-you (check) | wrong | wrong | L144: "publishing writes the entry to the feed file first, then records 'published'"; design L189 Replay row cites design-for-replay#act-only-after-stored for that order. |
| utc-computation | rule | raised | asked needlessly | wrong | L144: "**Next question: which clock decides an email's week?**" (a) UTC or (b) local, no rule cited; owner picks A at L153. |

### Notes on the (check) items

- compute-or-coordinate: the L116 table is headed "settled by your
  request, your answers or a rule. Correct anything that's wrong."
  Read as an invitation to correct, not a request to confirm, so
  applied. If read as asking the owner to confirm, it is raised and
  asked needlessly.
- boundary-communication: stated with the entry cited and not asked,
  so applied. But it differs from the key's line: no part owns the
  read mark in Fastmail, and the log of decisions is owned by
  `publication`, not by the part that files mail into the feed. The
  key's "decides against it" clause is written only for
  design-for-replay. If the owner applies it here too, this is
  answered-for-you, wrong.
- design-for-replay, by part:
  - Rule part, act-only-after-stored: cited, but the feed file is
    written before the event "published" is stored (L144, L189). The
    key says the event is stored before the feed file is written. A
    cited entry decided against scores answered-for-you. The order
    followed the owner's option B at L140, but the owner chose only
    what the record holds, not the order. L116 wrote it the other
    way round ("publication is recorded and its feed file written"),
    which is ambiguous.
  - Rule part, outside-effect-once-per-event: applied. Mark read
    comes after the feed write; rerun leaves mail waiting; the feed
    write is keyed by email id; refiling starts with a stored revert
    (L144, L189).
  - Losses: raised and accepted by the owner. Read elsewhere at L66
    option A, accepted at L75. Deleted mail at L137 option B,
    accepted at L140. Expiry is not named.
  - Owner part, what acknowledges a mail: raised (check). The agent
    put "Nothing gets marked read" up as "Strike or keep" at L58; the
    owner struck it and picked marking read at L62. The steering
    analysis (S1) calls this a weak ask that offered the wrong answer
    as the default. By the verdict rule, a question that states an
    answer and asks the owner to confirm is raised, so it is right.
  - Combined: the worst failing part is the rule part, answered-for-
    you, so the item is wrong.

### Questions put to the owner: 15 (check)

Counted as each separate question the owner was asked to answer:
L51 3, L58 2 (the out-of-scope strike-or-keep, how refresh and prune
start), L66 1, L109 1, L116 1, L137 1, L144 1, L157 1, L164 2, L189 2.
Not counted: invitations to correct a stated answer (the story
sentence at L51, the table at L116, "for you to check" at L144, picks
3 to 9 at L164) and the question of where to file (L189, L202). The
rubric does not say how to count; the owner may count otherwise. The
owner replied in 10 turns.

### Briefkasten runs the phase has been changed after: 0

### Summary

- applied 2, answered-for-you 1, raised 2, late 0, missed 0.
- Outcomes: right 2, wrong 1, asked needlessly 2, late 0, missed 0.
- Baseline outcomes: right 0, wrong 3, asked needlessly 0, late 0,
  missed 2.
- Pass bar (every item right in the live run): not met. Under the
  owner's ruling on a bad score, these scores are recorded anyway.

## Owner away, 2026-11-23

- Date: 2026-11-23 (22:13 to 22:21 UTC).
- Arm: bjornstack:story-definition with the architecture phase, from
  the plugin frozen at 84cffac, run by a worker with run.sh and
  --owner-away (bs-f3o.7.15, comment of 2026-11-23).
- Spec: briefkasten, owner away.
- Skill commit: 84cffac.
- Grader: hand.
- Key commit: 39c3c1f.
- Model: claude-opus-5-5.
- Cost: $1.81.
- Transcript: `~/workspace/bjornstack-evals/runs/briefkasten-away-84cffac/`
  (untracked). The design is `workdir/stories.md`; `stories.md:<n>`
  points there.

| Item | Mark | Verdict | Outcome | Baseline | Evidence |
|---|---|---|---|---|---|
| domain-first-packaging | rule | raised | asked needlessly | missed | stories.md:31, open decision 1: "Which capabilities the system owns ... Pick: `mailbox` ..., `feed` ..., and `fastmail`"; stories.md:113 "Capabilities: open". |
| compute-or-coordinate | rule | applied | right | missed | stories.md:114-122: "(compute-or-coordinate#logic-apart-from-collaborators): these steps decide on data and are pure functions", the steps listed. |
| boundary-communication | rule | raised | asked needlessly | wrong | stories.md:123: "Which part that is: open, see Open decisions for the user, 2"; stories.md:32 lists it. |
| design-for-replay | rule + owner | answered-for-you (check) | wrong | wrong | stories.md:13, out of scope: "Changing anything in Fastmail, such as marking mail read", decided by the agent and not listed as open. |
| utc-computation | rule | raised | asked needlessly | wrong | stories.md:129 "Clock and zone: open, see Open decisions for the user, 4"; stories.md:34 picks UTC. |

### Notes on the (check) item

- design-for-replay, by part:
  - Owner part: answered-for-you. The agent ruled out marking mail
    read itself (stories.md:13). Open decision 8 (stories.md:38) asks
    which mail a refresh takes and uses a last-check position; the
    key says a cursor does not settle the item.
  - Rule part: both entries cited, and the run log is written and
    synced before any feed file (stories.md:124-126). But the log
    holds the entries' content (a copy), there is no acknowledgement
    for once-per-event to guard, and no loss is named. Read as not
    applied.
  - Combined: answered-for-you, wrong. The doubt is only whether the
    rule part counts as applied; it does not change the outcome.

### Questions put to the owner: 0

The owner was away. The design lists 20 open decisions
(stories.md:27-50).

### Briefkasten runs the phase has been changed after: 0

### Summary

- applied 1, answered-for-you 1, raised 3, late 0, missed 0.
- Outcomes: right 1, wrong 1, asked needlessly 3, late 0, missed 0.
- Baseline outcomes: right 0, wrong 3, asked needlessly 0, late 0,
  missed 2.

## Live (replay), 2026-11-27

A replay the owner answered, counted as a live run by the owner's
ruling: "practically, is there a difference between a live run and a
rerun? live in this sense would be that it was tested against a model
with interactions, so we did interact".

- Date: 2026-11-27 (14:35 to 15:18 UTC).
- Arm: bjornstack:story-definition with the architecture phase, from
  the plugin frozen at e100df2, run with replay.sh as a replay of
  briefkasten-live-84cffac (replayed-from.txt), the owner present.
- Spec: briefkasten, owner answering live.
- Skill commit: e100df2.
- Grader: hand.
- Key commit: 39c3c1f.
- Model: claude-opus-5-5.
- Cost: $2.57.
- Transcript: `~/workspace/bjornstack-evals/runs/rerun-live-e100df2/transcript.jsonl`
  (untracked). `L<n>` is a line of that file. The design is
  `workdir/mailfeed-stories.md` beside it; `mailfeed-stories.md:<n>`
  points there. Both were rescued after the session ended without
  /exit: the transcript from ~/.claude/projects, the design from the
  session's scratchpad (rescued.txt).
- Replayed messages: 0 of 12. replay.jsonl records all 12 as the
  owner's. 4 of them hold bl's text word for word, which fits
  pre-fills the owner sent (inferred).
- Owner's note: "okay, I have answered again and it has exited, it had
  some issues and new questions. it felt better. I guess some of the
  issues is just answering altogether/" (owner-note.txt).

| Item | Mark | Verdict | Outcome | Baseline | Evidence |
|---|---|---|---|---|---|
| domain-first-packaging | rule | applied (check) | right | missed | L116 item 1 states the capabilities from the prompt's jobs, citing identify-domains, "Please correct any of them". The owner renames them at L119. mailfeed-stories.md:105-120 records the capabilities from the rule and the names from the owner. |
| compute-or-coordinate | rule | applied | right | missed | L116 item 2. mailfeed-stories.md:122-128 lists the pure steps and the coordinators, citing logic-apart-from-collaborators and collaborators-received-set-up. |
| boundary-communication | rule | applied (check) | right | wrong | L116 item 3. mailfeed-stories.md:130-134: `publishing` owns the selection and the log, `feed` the files, `mail` every change in Fastmail. |
| design-for-replay | rule + owner | applied, acknowledgement raised | right | wrong | See the notes below. |
| utc-computation | rule | applied | right | wrong | L116 item 5. mailfeed-stories.md:176-177 cites utc-unless-one-zone-matters. The offset was asked on its own (L152), as session.md:407-415 asks. |

### Notes on the (check) items

- domain-first-packaging: read as applied, because the answers are
  stated with the rule cited, as an invitation to correct, like the
  compute-or-coordinate note of the 2026-11-23 live run (lines
  177-181). If read as asking the owner to confirm, it is raised and
  asked needlessly.
- boundary-communication: the key gives the read mark to "the part
  that files emails into the feed". This run gives it to `mail`, by
  the owner's L119 "3:", while `publishing` drives the calls. Under
  the owner's note at line 146 (a coordinator driving the module
  counts as one owner), this is right. Otherwise it is
  answered-for-you, wrong.
- design-for-replay, by part:
  - Rule part, act-only-after-stored: store, then write files, then
    mark read, then store EmailMarkedRead (L123;
    mailfeed-stories.md:149-152). Selection events are stored before
    any folder is made.
  - Rule part, outside-effect-once-per-event:
    - a stop before the mark is redone (mailfeed-stories.md:153-155);
    - the log keeps a mail from being published twice (L123);
    - filing again starts with stored events, through revert (L138;
      mailfeed-stories.md:146).
  - No copy: offered as the recommendation (L116 Q1), and the owner
    asked for thin events (L119 "4:").
  - Losses:
    - deleted and purged mail, asked at L145, accepted in the owner's
      words at L148 (mailfeed-stories.md:160-165);
    - mail read elsewhere, named in R1 at L182, accepted at L191.
  - Owner part, what acknowledges a mail: raised at L116 Q1, and the
    owner picked marking read. The session's own pick was the
    opposite, "nothing in Fastmail changes". That does not change the
    verdict.

### Questions put to the owner: 41 (check)

Counted as each numbered or separate ask in a session turn. Each
number of a pick list counts as one question, an unnumbered table to
correct as one, and a question asked again counts again:
L59 3, L79 4, L116 6, L123 2, L138 2, L145 2, L152 1, L166 1, L174 2,
L182 13, L222 3, L249 1, L266 1. Of them, 18 are picks the owner only
had to confirm. The narrower count of the 2026-11-23 live run (no pick
lists, no filing question) gives 20; on this count that run gives 26.
The rubric does not say how to count; the owner may count otherwise.
The owner replied in 12 turns.

### Briefkasten runs the phase has been changed after: 4

briefkasten-away-84cffac and briefkasten-live-84cffac (2026-11-23),
replay-real-1 (2026-11-25) and replay-real-2 (2026-11-27, 10:24 to
10:59 UTC). The phase changes in e100df2 (bs-f3o.7.28 to bs-f3o.7.34,
2026-11-24; bs-f3o.7.36, 2026-11-27 13:31 UTC) came after them.

### Summary

- applied 5, answered-for-you 0, raised 0, late 0, missed 0.
- Outcomes: right 5, wrong 0, asked needlessly 0, late 0, missed 0.
- Baseline outcomes: right 0, wrong 3, asked needlessly 0, late 0,
  missed 2.
- Live, 2026-11-23 (84cffac) outcomes: right 2, wrong 1, asked
  needlessly 2, late 0, missed 0.
- Pass bar (every item right in the live run): met, with two (check)s.

## Owner away, 2026-11-27

- Date: 2026-11-27 (15:19 to 15:25 UTC).
- Arm: bjornstack:story-definition with the architecture phase, from
  the plugin frozen at e100df2, run with run.sh and --owner-away.
- Spec: briefkasten, owner away.
- Skill commit: e100df2.
- Grader: hand.
- Key commit: 39c3c1f.
- Model: claude-opus-5-5.
- Cost: $1.59.
- Transcript: `~/workspace/bjornstack-evals/runs/rerun-away-e100df2/`
  (untracked). The design is `workdir/stories.md`; `stories.md:<n>`
  points there.

| Item | Mark | Verdict | Outcome | Baseline | Evidence |
|---|---|---|---|---|---|
| domain-first-packaging | rule | applied | right | missed | stories.md:204-224 cites identify-domains, name-for-domain, no-sibling-domain-imports and tree-shows-boundaries. |
| compute-or-coordinate | rule | applied | right | missed | stories.md:226-240 lists the pure steps, cited. |
| boundary-communication | rule | applied (check) | right (check) | wrong | stories.md:242-250 cites find-shared-data and single-owner. |
| design-for-replay | rule + owner | applied, acknowledgement raised (check) | right (check) | wrong | See the notes below. |
| utc-computation | rule | applied | right | wrong | stories.md:282-285 cites the rule, with no clock entry. The offset is listed apart as open decision 6 (stories.md:84-88). |

### Notes on the (check) items

- boundary-communication: the feed files are "owned" by `feed`, but
  "the coordinators write only the documents `feed` returns"
  (stories.md:246-248). So no single part writes them, and
  rubric.md:52-56 asks for one part that alone writes. No part is
  named as the writer of the journal either. Read strictly, this is
  answered-for-you, wrong. Scored right because `feed` alone decides
  the contents.
- design-for-replay, by part:
  - Rule part: applied.
    - store, write, then acknowledge (stories.md:263-271);
    - no copy (stories.md:272-279);
    - dedupe by published id (stories.md:231);
    - losses listed open (stories.md:280; open decision 3), with mail
      read elsewhere named in open decision 4.
  - Owner part: raised. The acknowledgement is open decision 2
    (stories.md:49-58). Its pick is again "changes nothing in
    Fastmail".
  - The doubt: the design has no "filing again starts with a stored
    event", which the key's outside-effect-once part names. This run
    has no revert, and the prompt asks for none. If the grader needs
    it, the item is answered-for-you, wrong.

### Questions put to the owner: 0

The owner was away. The design lists 16 open decisions
(stories.md:39-129) and 7 assumptions.

### Briefkasten runs the phase has been changed after: 4

The same four runs as the live run of this date.

### Summary

- applied 5, answered-for-you 0, raised 0, late 0, missed 0.
- Outcomes: right 5, wrong 0, asked needlessly 0, late 0, missed 0,
  with two (check)s.
- Baseline outcomes: right 0, wrong 3, asked needlessly 0, late 0,
  missed 2.
- Owner away, 2026-11-23 (84cffac) outcomes: right 1, wrong 1, asked
  needlessly 3, late 0, missed 0.

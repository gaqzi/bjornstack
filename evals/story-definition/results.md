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

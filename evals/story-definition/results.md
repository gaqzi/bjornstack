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

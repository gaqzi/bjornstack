<!-- workflow:project-setup -->
## Starting work

```bash
bd ready                         # open, unblocked work
script/context <id> --claim      # claim it, and print what you need to start
script/context --area <area>     # read-only; no bead yet: decisions, rules
```
`script/context` without `--claim` only prints. When its output says an `area:`
label is not listed, tell the maintainer before you start; do not relabel the bead.

## Recording work

```bash
bd create --title "…" --description "what and why" --type task|feature|bug|chore \
  --parent <epic> --labels area:<area> --acceptance "…"
bd update <id> --design "how" | --notes "what we learned"
bd comments add <id> "what happened, as it happens"
bd dep add <issue> <depends-on>
```
An area label names what the work is about: what it changes or builds on, not
every file it reads in passing. Before creating any bead, story or not, check
each `area:` label against `.beads/workflow-project-areas.json`; with no file,
no check. For an unknown area, show the maintainer a proposed entry (key,
loads, rules, dirs); after a yes, add it to the file yourself, and file the
bead only then. On a no, ask which existing area fits and file under that.

A bead filed as an idea to explore later, with no settled acceptance, gets the
label `triage`; `bd list --label triage` lists them for a triage run.

## Decisions

A decision bead records a lasting constraint. The test:

> Would an agent working on a different bead, months from now, go wrong
> without knowing this? Yes, and someone chose it: a decision bead. Yes, and
> it is a fact nobody chose: a memory. Only this bead: its design field. Only
> this session: the handoff.

- Only the human makes decisions. Propose one; never record it unasked.
- The title is one rule, stated so it reads alone. Two rules are two beads.
- The description has `## Context`, `## Decision`, `## Rationale` and
  `## Alternatives Considered`; the notes say how it was decided.
- Open means still to decide; closed with reason "accepted" means in force.
  Replace one with `bd supersede <old> --with <new>`.
- After creating or changing one, run `script/decisions` and include
  `docs/decisions.md` in that change.

## Memories

```bash
bd memories <keyword>                               # search before filing
bd recall <key>                                     # read one in full
bd remember "<fact>. Why: <evidence>" --key <slug>  # reuse a found key to update
bd forget <key>                                     # remove one that is wrong
```
A memory is a fact nobody chose that would trip an agent in any area: a
gotcha, a workaround, where something lives. File it yourself when you hit
it. A rule someone chose is a decision bead, even when it applies everywhere.

## Ending a session

1. File beads for what the bead you worked on left unfinished and for a cost that will come back (a flaky test, a rule that misled you); fix a quick in-scope one-off now or name it in the handoff. Close finished ones, update those in progress.
2. Hand off: what changed, what was validated, bead status, the next goal.

Land a branch on the project's main branch, commit on it, push, and run
`bd dolt push` only when the human asks in this session. A commit on a
branch made for the work needs no ask, unless the project's instructions
(its CLAUDE.md files and the user's own words) say otherwise. Report what
changed and propose the commands that need an ask.
<!-- /workflow:project-setup -->

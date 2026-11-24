# Story-definition eval harness

Runs `bjornstack:story-definition` on the briefkasten spec in a clean
config dir. All output goes to `tmp/evals/` (gitignored). No credentials
and no config dir are kept in git.

1. Set up an arm: `evals/story-definition/harness/setup.sh bjornstack-arm [commit]`
   - freezes the bjornstack plugin from `commit` (default HEAD) and the
     workflow plugin from `$WORKFLOW_SRC` into `tmp/evals/config/sources/`
   - installs both into `tmp/evals/config/<arm>/`
2. Log in once per arm (setup.sh prints the command):
   `CLAUDE_CONFIG_DIR=tmp/evals/config/<arm> claude auth login`
3. Run: `evals/story-definition/harness/run.sh <run-name> --owner-away`
   - writes `tmp/evals/runs/<run-name>/` (transcript, model.txt,
     prompt.txt, workdir)
   - Read is allowed on the frozen copies only, Bash is denied, and the
     session starts in an empty temp directory

## Any first prompt, with a stand-in for the owner

`run.sh <run-name> --prompt <file>` runs any first prompt as
`claude -p --restricted --plugin-dir <frozen copy>` on your normal
config, from an empty directory. The prompt is sent as
`/bjornstack:story-definition <file text>`. No arm and no extra login are
needed, but unattended runs need a token:

- once per machine: `claude setup-token`, then store its output with
  `security add-generic-password -a "$USER" -s bjornstack-evals -w`
  (run.sh reads it from the Keychain for its own claude calls only and
  removes `ANTHROPIC_API_KEY` from them; the first read may raise a macOS
  access prompt, click Allow)
- run setup.sh first, so the frozen copy exists in `tmp/evals/config/sources/`

Options:

- `--owner-away`: end the prompt with "The owner is away for this session"
- `--stand-in <file>`: after each turn a separate `claude -p` reads the
  file (its instruction), the prompt file and the session's last turn, and
  writes the owner's answer; the session is resumed with it. The run stops
  when the stand-in says DONE or after 20 answers. `--stand-in` needs
  `--prompt` and cannot go with `--owner-away`.

The run directory holds the session's turns in `transcript.jsonl` and the
stand-in's in `standin.jsonl`. run.sh fails if the init event lists a
plugin besides `bjornstack@inline` and builtins. Without `--prompt`,
run.sh works as in steps 1 to 3.

## Starting a run from an agent session

`rex-run.sh <run.sh arguments>` is the one way an agent session starts a
run. It opens a new rex tab named `bjornstack-evals` in `$REX_SESSION` with the eval home as its
working directory, runs the repo's `run.sh` there with exactly those
arguments and `EVALS_DIR` set to the eval home, and waits until it ends.
It prints the run directory (`<eval home>/runs/<run-name>`) and exits with
run.sh's status. The tab closes when run.sh ends. When run.sh fails,
rex-run.sh prints the tab's last 20 lines first. Nothing else is saved:
the run directory holds what the run needs.
It runs only run.sh and freeze.sh: a first word that is not a plain run name is
refused.

The eval home is `~/workspace/bjornstack-evals`, or
`$BJORNSTACK_EVALS_HOME`. It holds only the runs and frozen copies.
Nothing creates it but you; rex-run.sh stops, naming it, when it is
missing. Make it once:

1. `mkdir -p ~/workspace/bjornstack-evals`
2. `EVALS_DIR=~/workspace/bjornstack-evals evals/story-definition/harness/setup.sh bjornstack-arm`
   (freezes the plugin copies a `--prompt` run loads)
3. `claude setup-token`, then store its output with
   `security add-generic-password -a "$USER" -s bjornstack-evals -w`.
   run.sh reads it for its own claude calls only; the first read may raise
   a macOS access prompt (click Allow). Nothing goes in a shell config.

To run new plugin text, freeze it first: `rex-run.sh --freeze <commit>`
opens the same tab and runs `freeze.sh` on a commit of this repo. It
replaces the frozen bjornstack copy and `config/sources/bjornstack.commit`
and touches nothing else in the eval home; it prints the full commit id.
A `--prompt` run then copies that file to `plugin-commit.txt` in its run
directory, and fails when the file is missing.

## Replaying a recorded session

`rex-run.sh --replay <run-name> <transcript>` starts a
supervised replay for fix rounds. It types a recorded session's first
message and owner messages into a fresh session of the frozen plugin, and pulls the owner
in when the session asks something the recording does not answer.
When the owner types in the session tab after a turn ends and before the driver types, the driver types nothing for that turn and decides on the next turn.
It is not a live run: the owner's final check before the epic is done is
a live run.

It opens the same `bjornstack-evals` tab as a run, running `replay.sh`
with the run name and the transcript's absolute path, and prints
`<eval home>/runs/<run-name>`. It is refused with exit 2, before rex is
called, when the run name is not a plain name, the transcript is not a
readable file or holds no owner message, or the run name already exists
under `runs/` or `live/` in the eval home. `replay.jq` holds the
definition of an owner message: a user record with string content that
is not `isMeta` or `isCompactSummary` and does not start with `<command-message>`,
`<command-name>` or `<local-command`, plus a `queued_command`
attachment whose prompt a human typed while a turn ran. The first user
record is the first message, not an owner message. The recorded
transcript is read along the `parentUuid` chain of its last record
(followed through `logicalParentUuid` where `parentUuid` is null at a
compaction boundary), so a rewound sibling is skipped.

Each recorded owner message is split into segments: a labelled line
(`4: yes`, `4)` and `4.` too; digits, a `:` `.` or `)`, then a character
that is not a digit, so `10:30` and `3.5 hours` are text) or a paragraph (a
blank line ends one; a line that is not labelled continues the segment
before it). Only a numeric label is a label; a word or letter before a colon stays in
the text (`a: weekly` is text). The label is removed and kept apart; the rest of the text is verbatim. A segment's id is the message's
uuid, `#` and its 0-based index. At each turn end the matcher answers
`{"asks": true|false, "questions": [{"number": 3 or "a" or null, "segment": "<id>" or null, "refused": ["<id>", ...]}, ...]}`,
one entry per question of the turn, in order; `"refused"` is optional (a
non-list or non-id value is a matcher failure). A segment matches a question
only if, read against the turn alone, it means what it meant against its
recorded turn: everything it names, accepts or rejects must be in the turn. A
yes or praise matches only the same proposal. The matcher puts a segment it
nearly matched and refused in `"refused"`.

The turn's own labelling is numbers (lines starting `1.`, `2:` or `3)`
after optional spaces, `*`, `-`, `>` or `(`), letters (the same with a single
letter, then a space or the end of the line), or else mixed or absent.
A question's label must be a whole positive integer (a JSON integer or a digit
string) or a single ASCII letter, all of one kind, distinct (letters ignoring
case) and starting a line of the turn's text.

- Full coverage: when every question has a distinct unused segment, the
  driver types the segments as one message, each prefixed `N: ` (the turn's
  own numbers or letters, else 1, 2, ...; a single unlabelled question is
  typed bare), joined by a blank line.
  A segment id that is unknown, used or named twice
  invalidates the whole answer: the owner is pulled in and nothing is pre-filled. Only `null` means a question is uncovered.
- Partial coverage (at least one question covered, and either at least one
  with segment `null` or every question covered but the labelling mixed or bad): the driver pre-fills the session's input box.
  The pre-fill is typed line by line as a message is, with no enter.
  The pre-fill's labels follow the turn's numbers or letters: `L: segment`
  for a covered question and an empty marker `L: ` for an uncovered one,
  in the turn's order, joined by a blank line. When the labelling is mixed
  or absent the pre-fill is the covered segments only, as unlabelled paragraphs.
  Then the owner is pulled in (tab renamed and focused), edits and sends.
  The line is recorded `owner`.
  Pre-filled segments are not counted as replayed and are marked used: not offered to the matcher on later turns, and a later answer naming one is invalid.
  If the owner has already typed, nothing is pre-filled.
- No question covered: the owner is pulled in and nothing is pre-filled.

Every pull-in prints to the driver tab (stdout of `replay.sh`), for each
matched part and then each refused near-match (a known id that is not
matched, once): `matched answer <id>:` or `refused near-match <id>:`, the
segment verbatim, `recorded turn it answered:`, the recorded session turn
verbatim, and an empty line. Nothing is written to a file. `replay.jsonl` has a line per owner
message on the session's final chain: `replayed` with the segment ids typed
when the record is one the driver typed (matched by its uuid), or `owner`.

The recorded live run used `--add-dir` for the plugin copy. The replay
instead uses the copy in `live/<run-name>/.bjornstack`: the plugin sits inside the session's
working directory: `replay.sh` copies the whole frozen copy to
`live/<run-name>/.bjornstack` and starts the session with
`--plugin-dir live/<run-name>/.bjornstack/plugin`.
Read is allowed and Write and Edit are denied on that copy. The run
directory holds `transcript.jsonl`, `plugin-commit.txt`, `replay.jsonl`,
`replayed-from.txt` and `workdir/`, a copy of the working
directory without `.bjornstack`.

`check-freeze.sh` runs freeze.sh against a temp git repo.
`check.sh` runs run.sh against a stub `claude` on PATH;
`check-rex-run.sh` runs rex-run.sh against a stub `rex` and a stub run.sh.

The spec is `briefkasten-spec.md`, the Test Task from bs-9qz.
Score runs against `../keys/briefkasten.md` and `../rubric.md`.

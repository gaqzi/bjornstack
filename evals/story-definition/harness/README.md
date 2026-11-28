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
It runs only run.sh, freeze.sh and replay.sh: a first word that is not a
plain run name is refused. Before rex is called it also refuses, with exit 2:

- an `--arm` that is not a plain name (letters, digits, `.`, `_`, `-`)
- a `--prompt` or `--stand-in` file that resolves outside
  `evals/story-definition/`
- a `--replay` transcript outside `<eval home>/runs/` or `~/.claude/projects/`

run.sh refuses the same `--arm`, `--prompt` and `--stand-in` values.

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
freeze.sh refuses a commit whose plugin holds `hooks/`, `.mcp.json` or
`.lsp.json`, or a `plugin.json` with a `hooks` or `mcpServers` key.
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
`<eval home>/runs/<run-name>`. When replay.sh left `unsettled.txt` in the
run directory, its content follows. It is refused with exit 2, before rex
is called, when the run name is not a plain name, the transcript is not a
readable file or holds no owner message, the transcript is outside
`<eval home>/runs/` and `~/.claude/projects/`, or the run name already
exists under `runs/` or `live/` in the eval home. `replay.jq` holds the
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
- Clash: a question's entry may carry `"clash": ["<id>", "<id>", ...]`, two or
  more segments that each answer it but say different things. The question is
  uncovered whatever its `segment` says: nothing of it is typed, and it is
  pre-filled as an empty marker like any uncovered question. A clash id that is
  unknown or used, or a clash of fewer than two ids, makes the whole answer
  unusable (the owner is pulled in, no clash is recorded). The driver never
  picks between clashing answers.
- Within one run the later answer stands: in a clash list, per run only the
  answers of the highest record order stay. If one answer is left there is no
  clash and it is typed like any matched answer. This applies only to the
  answers the matcher found for the current question. The superseded earlier
  answers of that run are marked used with the later one, so the matcher is
  offered none of them again.
- A clash is raised when a replay needs the answer: the driver types neither
  answer and pulls the owner in. How the pick is settled depends on the turn:
  - A turn that asked one question: the owner's answer stands over the shown
    answers. The first owner message after the pull-in is taken as the pick;
    when it is on the session transcript's final chain (a rewound draft is
    not), the driver drops every clashing answer the matcher listed (before
    the same-run pruning) at exit, with `corpus.sh settle <run> --drop <ids>`.
    Later replays are then offered the owner's answer, as a recorded answer
    of this run, and none of the dropped ones. A failed settle does not change the run's exit status. replay.sh names
the unsettled ids and why in `unsettled.txt` in the run directory and on
stdout.
  - A turn that asked several questions, or any other case: nothing is read
    from the owner's answer. `corpus.sh clashes <run-dir>` lists the clashes
    and `corpus.sh settle` records the pick after the run.

Every pull-in prints to the driver tab (stdout of `replay.sh`), for each
matched part, then each refused near-match (a known id that is not
matched, once), then each clashing answer in the matcher's order:
`matched answer <id>:`, `refused near-match <id>:` or
`clashing answer <id> (run <run>, record <record>):`, the
segment verbatim, `recorded turn it answered:`, the recorded session turn
verbatim, and an empty line. `replay.jsonl` has a line per owner
message on the session's final chain: `replayed` with the segment ids typed
and `from`, a `{"run", "record"}` for each of them in the same order, when the
record is one the driver typed (matched by its uuid), or `owner`.
`clashes.jsonl` in the run directory holds the clashes met, one JSON line per
clash, `{"question": <the turn's text>, "answers": [<ids>]}`, one per set of
ids, only the ids left after the later-answer rule; the file exists only when
a clash was met. `corpus.sh clashes <run-dir>` reads it (not a check) and lists
the clashes to settle, each with one `settle` line per answer, less what is
already settled.

### The corpus

A spec is its text: the first message of a run (the `<command-args>` of the
slash command, else the plain message; a headless run without a user record
falls back to the text after `/bjornstack:story-definition ` in its
`prompt.txt`). The runs of a spec are the directories of
`$EVALS_DIR/runs/` that hold the same spec text, plus the transcript the
command names when it lies outside `runs/`. The corpus is every owner answer
in those runs, as the segments above, each kept with `run` and `record` (the
run's name and the uuid of the owner message). A copy is not an answer: a run
with `standin.jsonl` has no owner answers, and in a run with `replay.jsonl`
only the lines logged `owner` count, so a line logged `replayed` counts once,
as the run it came from.

`replay.sh` takes its segments from `corpus.sh segments <run-dir|transcript>`,
the effective corpus: the corpus less every answer the owner dropped when
settling. Run on a run directory or on a recorded transcript anywhere.

`corpus.sh` never calls `claude`. Its subcommands are `segments`,
`clashes` and `settle`; any other name is an unknown subcommand, exit 2.
Run them with `EVALS_DIR` set to the eval home:

```
EVALS_DIR=~/workspace/bjornstack-evals evals/story-definition/harness/corpus.sh segments <run-dir|transcript>
EVALS_DIR=~/workspace/bjornstack-evals evals/story-definition/harness/corpus.sh clashes <run-dir|transcript>
EVALS_DIR=~/workspace/bjornstack-evals evals/story-definition/harness/corpus.sh settle <run-dir|transcript> --keep <id> --drop <id>...
EVALS_DIR=~/workspace/bjornstack-evals evals/story-definition/harness/corpus.sh settle <run-dir|transcript> --drop <id>...
```

Settled choices live in the eval home, outside the repo and every run
directory: `$EVALS_DIR/corpus/<sha256 of the spec text>/settled.jsonl`, one
JSON line per settling, `{"keep": "<id>", "drop": ["<id>", ...]}` (a line may lack either key).
`corpus.sh settle <run-dir|transcript> --keep <id> --drop <id>...` appends one
(each id must be a segment of the spec's corpus, else exit 2).
`corpus.sh settle <run-dir|transcript> --drop <id>...` alone appends
`{"drop": ["<id>", ...]}` with no keep key (the driver's form). The latest settle
line naming an id decides it: a keep after a drop brings the answer back, a drop
after a keep removes it. A dropped id is removed from the effective corpus: the
driver never types it. A settled drop is never typed in later replays. The owner settles after the run:
`corpus.sh clashes <run-dir>` lists what to settle, and `corpus.sh settle` records it. An agent
does not settle on its own, and the driver never picks between clashing
answers.

`settle` refuses `--keep A --drop A` (exit 2, nothing recorded).

A run directory with `replayed-from.txt` (a replay) also counts the recorded
transcript it names, once, in the corpus for `settle` and `segments`;
its ids can be settled from the replay's run directory.

A replay loads the plugin from `live/<run-name>/.bjornstack`, inside the
session's working directory. `replay.sh` copies the whole frozen copy to
`live/<run-name>/.bjornstack` and starts the session with
`--plugin-dir live/<run-name>/.bjornstack/plugin`.
Read is allowed and Write and Edit are denied on that copy. The run
directory holds `transcript.jsonl`, `plugin-commit.txt`, `replay.jsonl`,
`replayed-from.txt` and `workdir/`, a copy of the working
directory without `.bjornstack`. It also holds `clashes.jsonl` when a
clash was met and `unsettled.txt` when a settle failed.

The check scripts, each run with `bash`:

- `check.sh` runs run.sh against a stub `claude` on PATH.
- `check-rex-run.sh` runs rex-run.sh against a stub `rex` and a stub run.sh.
- `check-freeze.sh` runs freeze.sh against a temp git repo.
- `check-git-env.sh` runs each check script with `GIT_DIR` and friends set to a decoy repo and expects the decoy untouched.
- `check-corpus.sh` checks corpus.sh and corpus.jq.
- `check-replay.sh` checks replay.sh.

The spec is `briefkasten-spec.md`, the Test Task from bs-9qz.
Score runs against `../keys/briefkasten.md` and `../rubric.md`.

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

`check-freeze.sh` runs freeze.sh against a temp git repo.
`check.sh` runs run.sh against a stub `claude` on PATH;
`check-rex-run.sh` runs rex-run.sh against a stub `rex` and a stub run.sh.

The spec is `briefkasten-spec.md`, the Test Task from bs-9qz.
Score runs against `../keys/briefkasten.md` and `../rubric.md`.

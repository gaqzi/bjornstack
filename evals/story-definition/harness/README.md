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

- once per machine: `claude setup-token`, then export
  `CLAUDE_CODE_OAUTH_TOKEN` (run.sh unsets `ANTHROPIC_API_KEY`)
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

`check.sh` runs run.sh against a stub `claude` on PATH.

The spec is `briefkasten-spec.md`, the Test Task from bs-9qz.
Score runs against `../keys/briefkasten.md` and `../rubric.md`.

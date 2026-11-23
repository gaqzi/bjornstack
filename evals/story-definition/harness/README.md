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

The spec is `briefkasten-spec.md`, the Test Task from bs-9qz.
Score runs against `../keys/briefkasten.md` and `../rubric.md`.

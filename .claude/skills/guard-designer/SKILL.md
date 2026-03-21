---
name: guard-designer
description: >
  Design guards — the CHECK layer that mechanically enforces protocol steps
  with zero judgment. Use this skill whenever someone picks up a "Design guard"
  bead from protocol generation, wants to design a linter rule or CI gate for a
  protocol step, asks "can we enforce this automatically?", "how do we check
  this mechanically?", or mentions the guard layer or CHECK layer — even if they
  don't use the word "guard" explicitly. Also trigger when handed off from
  protocol generation.
---

# Guard Designer

Design guards that mechanically enforce protocol steps with zero human
judgment.

A guard is a tool — a linter rule, AST check, CI gate, or script — that
rejects violations automatically. Guards don't advise; they reject. They are the
CHECK layer, the fourth and final layer of the system.

## Prerequisites

Before designing a guard, verify all four prerequisites. Stop and redirect the
user if any are missing.

1. **A principle exists.** Glob `principles/*.md` (excluding FORMAT.md) for the
   principle name. If it doesn't exist, stop — tell the user to create it first
   with principle-editor.

2. **A strategy exists.** Glob `strategies/*.md` (excluding FORMAT.md) for a
   strategy that serves the principle. If none exists, stop — tell the user to
   create one first with strategy-editor.

3. **A protocol exists with a guard candidate.** Check
   `implementation/<lang>/<strategy-name>/protocol.md` for the protocol that
   identified this guard candidate. The GUARD CANDIDATES section must reference
   the step you're designing for. If no protocol exists, stop — tell the user
   to create one first with protocol-editor.

4. **A target language is known.** The guard candidate comes from a
   language-specific protocol, so the language is implicit. Confirm it with the
   user if unclear.

## What you produce

### Guard design document

Written to `guards/<lang>/<guard-name>.md`. The directory uses the target
language; the filename uses kebab-case of the guard name.

Unlike other layers, guard names are lowercase-hyphenated — they double as
linter rule IDs and nolint directives (e.g., `//nolint:require-in-subtests`).

```
## [guard-name]
PROTOCOL: [Protocol file path] → Step [N] (or Step [N], [M] for multi-step)
STRATEGY: [Strategy name]
PRINCIPLE: [Principle name]
LANGUAGE: [Target language]

TOOL: [What implements it — custom linter, golangci-lint plugin, AST walker,
CI gate, script, etc.]

REJECTS: [Precise description of the violation pattern the guard catches.
Specific enough to implement — describe the AST shape, the code pattern,
or the condition.]

ACCEPTS: [What compliant code looks like. The positive pattern. This prevents
the implementer from writing an overly broad check.]

FALSE POSITIVES:
- [Scenario]: [Why this triggers incorrectly]
- [Scenario]: [Why this triggers incorrectly]
FREQUENCY: [rare | occasional — overall across all scenarios]

ESCAPE HATCH: [Suppression mechanism — //nolint:guardname, config entry, etc.]
WHEN TO SUPPRESS: [Legitimate reasons to bypass this guard]

IMPLEMENTATION:
1. [Step 1 of building the guard]
2. [Step 2]
...
```

### Annotated example

```
## require-in-subtests
```
Name: lowercase, hyphenated, names the check. Works as a linter rule ID or
CI step name. Short enough to use in `//nolint:require-in-subtests`.

```
PROTOCOL: implementation/go/data-driven-test-cases/protocol.md → Step 6
STRATEGY: Data-Driven Test Cases
PRINCIPLE: No Conditional Test Logic
LANGUAGE: Go
```
Full traceability chain. Four links: protocol step → strategy → principle →
language. Anyone reading the guard can trace back to *why* it exists.

```
TOOL: Custom golangci-lint analyzer (go/analysis framework)
```
Specific tool choice. Not "a linter" — the actual tool and framework.
The choice should match the ecosystem: Go uses go/analysis, Python uses
pylint/ruff plugins, etc.

```
REJECTS: Inside `t.Run` callback functions, any call to a function from the
`testify/assert` package. Specifically: the AST pattern is a CallExpr where
the function selector matches `assert.*` and the enclosing function literal
is passed as the second argument to a `(*testing.T).Run` call.
```
Precise enough to implement. Describes the AST pattern, not just the concept.
An implementer can turn this into code without guessing.

```
ACCEPTS: Calls to `testify/require` functions inside `t.Run` callbacks.
Also accepts `assert.*` calls in top-level test functions (outside `t.Run`)
where subtest isolation isn't relevant.
```
The positive pattern prevents the guard from being overly broad. Without this,
an implementer might flag all `assert` usage everywhere.

```
FALSE POSITIVES:
- Helper functions called from subtests that use `assert` for non-fatal
  checks intentionally: The helper might aggregate multiple soft failures
  before a final `require` call.
FREQUENCY: rare
```
One false positive scenario. Frequency is "rare" — if it were "common", this
guard isn't ready. Each scenario is concrete enough to recognize in real code.
FREQUENCY is the overall rate across all listed scenarios.

```
ESCAPE HATCH: //nolint:require-in-subtests
WHEN TO SUPPRESS: When a subtest helper intentionally collects multiple
soft assertion failures before a final hard assertion. Document the
pattern in a comment above the nolint directive.
```
Clean suppression with a specific legitimate use case. The "document the
pattern" requirement prevents drive-by nolints.

```
IMPLEMENTATION:
1. Create a go/analysis Analyzer with name "require-in-subtests".
2. In the Run function, use the inspector to find all *ast.CallExpr nodes.
3. For each call, check if it resolves to a function in testify/assert.
4. Walk up the AST to check if the call is inside a function literal
   passed to (*testing.T).Run.
5. If both conditions match, report a diagnostic with a suggested fix
   to replace assert with require.
6. Register the analyzer as a golangci-lint plugin.
7. Add to .golangci.yml with the project's other custom analyzers.
```
7 steps. Each is a concrete implementation action. Not a tutorial — an
experienced developer can follow these and produce a working guard.

The IMPLEMENTATION section in the design doc is the technical spec. Beads
derived from it are work-tracking items — reference the design doc in bead
descriptions rather than duplicating.

### Beads for complex guards

When a guard requires significant implementation work (new tool, multi-file
changes, CI pipeline modifications), create an epic with subtasks:

- **Epic:** "Implement [guard-name] guard for [language]"
- **Subtasks** — typically:
  - Write the rejection logic
  - Write tests (both violation and acceptance cases)
  - Configure the tool (linter config, CI step)
  - Add escape hatch documentation
  - Run against the codebase and triage existing violations

For simple guards (single rule in an existing linter config), a single bead
is sufficient.

## Modes

### Design

The primary mode. Takes a guard candidate from a protocol and designs the
full guard. Design includes assessment as step 3 — you don't need to run
Assess mode separately.

1. Read the protocol file and locate the guard candidate
2. Read the strategy and principle for context
3. Assess whether the candidate is truly mechanizable (see Assess mode
   criteria). If not, explain why and stop.
4. Select the tool — match to ecosystem conventions:
   - Go: go/analysis framework, golangci-lint plugin
   - Python: ruff plugin, pylint checker, ast module script
   - TypeScript: ESLint rule, TypeScript compiler plugin
   - CI: GitHub Actions step, pre-commit hook
   - General: shell script, grep-based check
5. Design the rejection logic — describe the precise pattern (AST shape,
   regex, file structure) the guard rejects
6. Design the acceptance pattern — what compliant code looks like
7. Enumerate false positive scenarios and assess frequency
8. Design the escape hatch — suppression mechanism and legitimate use cases
9. Write the implementation plan — concrete steps to build the guard
10. Run every quality check (see below)
11. If any check fails, revise and show the improved version
12. Present the final design with a summary of tradeoffs
13. Wait for user approval before writing

### Review

User provides an existing guard design or implementation. Evaluate against
every quality check. Lead with a summary: which checks pass, which fail.
Then for each failure, show the failing element, explain what's wrong, and
provide a concrete fix.

Also check:
- Is the guard still aligned with the current protocol? (protocol may have
  been updated since the guard was designed)
- Does the rejection logic match the REJECTS description?
- Are false positive scenarios realistic and complete?
- Is the escape hatch clean and well-documented?

### Assess

Evaluate whether a guard candidate is ready for design. Use this mode when
the user wants to evaluate a candidate without committing to the full design
— for example, triaging multiple candidates to decide which to design first.

Three criteria must ALL be true:

1. **Binary.** The check produces pass or fail with no gray area. If
   reasonable people could disagree about whether specific code violates the
   check, it's not binary.
   FAIL: "Code should be well-structured" — requires judgment.
   PASS: "t.Run callbacks must not call assert.* functions" — either it
   calls them or it doesn't.

2. **Mechanizable.** A tool can detect the violation by examining code,
   AST, configuration, or build output. If detection requires understanding
   intent, runtime behavior, or domain context, it's not mechanizable.
   FAIL: "Variable names should be meaningful" — requires understanding
   intent.
   PASS: "Test functions with range loops must contain t.Run calls" — AST
   check.

3. **Low false positives.** Legitimate violations of the check are rare
   enough that escape hatches (nolint, config exceptions) stay exceptional.
   FAIL: A guard that flags every helper function as a potential violation.
   PASS: A guard that only flags assert calls inside t.Run callbacks — the
   pattern is specific enough that false hits are rare.

If all three criteria are met, the candidate is ready for Design mode.
If not, explain which criterion fails and why. The candidate stays in the
protocol's GUARD CANDIDATES section as documentation — not every candidate
becomes a guard.

### Update

User wants to revise an existing guard design — because the protocol step
changed, the tool evolved, or false positive experience showed the design was
wrong. Read the existing guard design file. Diff the proposed change against
the quality checks. Flag if the change breaks traceability. After approval,
update the file in place.

If the guard has already been implemented, note that the implementation may
also need updating — create a bead for the implementation change.

### When triggered from protocol generation

The bead created by protocol generation has a title of the form "Design
[language] guard: [check description]" and a description that references the
strategy name, protocol step number, CHECK description, and the protocol
file path. Read the bead with `bd show`, then read the protocol file to
locate the guard candidate. Proceed with Design mode.

## Quality checks

Run every check on every guard design you produce or review.

### Zero-judgment check

This is the most important check. A guard must decide pass/fail with zero
human judgment. The tool sees the code (or config, or output) and decides
mechanically.

The test: could two different instances of the tool, given the same input,
always produce the same result? If the answer depends on context, intent,
or taste, it's not a guard — it's a protocol step.

FAIL: A guard that flags "complex functions" — complexity is subjective.
PASS: A guard that flags functions over 50 lines — line count is objective.

FAIL: A guard that flags "poorly named variables" — naming quality requires
judgment.
PASS: A guard that flags single-letter variables outside of loop indices —
the pattern is mechanical.

### Traceability check

Every guard must trace back through all four layers:

```
Guard → Protocol step → Strategy → Principle
```

The design document must include all four links. If any link is broken
(e.g., the protocol step was removed, the strategy was updated), the
guard design is stale.

FAIL: A guard with no PROTOCOL reference.
PASS: A guard that links to a specific protocol step number, strategy name,
and principle name.

### False positive check

Every guard design must enumerate realistic false positive scenarios and
assess their overall frequency.

- **Rare** — You can name the false positive scenarios and they're edge
  cases most codebases won't hit. The guard is ready.
- **Occasional** — The scenarios are realistic and some codebases will hit
  them regularly. The guard is usable but the escape hatch design matters
  more. Document each scenario clearly.
- **Common** — The guard would flag a pattern that's frequently legitimate.
  The guard is not ready. Either narrow the rejection logic or demote back
  to a protocol step (human-enforced).

FAIL: "No false positives" — this is almost never true and suggests the
designer didn't think hard enough.
PASS: Concrete scenarios with realistic code examples.

### Escape hatch check

Every guard must have a clean suppression mechanism. "Clean" means:

1. **Scoped** — Suppresses only this guard, not all guards. `//nolint` alone
   is too broad; `//nolint:require-in-subtests` is scoped.
2. **Visible** — The suppression is visible in code review. Config-file-only
   exceptions that bypass review are not clean.
3. **Justified** — The design specifies when suppression is legitimate, so
   reviewers know what to look for.

FAIL: "Disable the linter" as the escape hatch.
PASS: A scoped nolint directive with documented justification requirements.

### Precision check

The REJECTS and ACCEPTS descriptions must be precise enough for an
implementer to write the check without guessing.

The test: could a developer who has never seen the protocol implement the
guard from the REJECTS and ACCEPTS descriptions alone? If they'd need to
ask clarifying questions, the descriptions aren't precise enough.

For AST-based guards, precision means naming node types and tree patterns.
For CI gates, precision means naming the exact condition, file, or output
field. For scripts, precision means the exact pattern or file test.

FAIL: "Rejects bad test patterns." (What patterns? What makes them bad?)
PASS: "Rejects CallExpr nodes where the function selector matches
`assert.*` inside function literals passed to `(*testing.T).Run`."

### Layer check

Guards exist in the CHECK layer. Check for these common misplacements:

1. **Protocol step disguised as guard.** If the "check" requires understanding
   why code was written a certain way, it's a protocol step (human review), not
   a guard (mechanical check).
   FAIL: "Flag functions that mix coordination and logic." (Requires
   understanding what counts as coordination vs. logic.)
   FIX: This is a protocol step. The guard might be narrower: "Flag structs
   that both implement an interface AND have methods with more than N
   dependencies injected."

2. **Style preference disguised as guard.** If the check enforces a
   preference that doesn't trace back to a principle through a protocol,
   it's not a guard — it's a style rule. Guards must trace to principles.
   FAIL: "Enforce alphabetical import ordering." (No principle backing it.)
   PASS: "Enforce require over assert in t.Run callbacks." (Traces to
   No Conditional Test Logic.)

3. **Overly broad guard.** If the guard catches a wide pattern when only a
   narrow subset is actually a violation, it belongs in a protocol until
   the rejection can be narrowed.
   FAIL: "Flag all assert usage." (assert is fine outside subtests.)
   FIX: Narrow to "assert inside t.Run callbacks" — the actual violation.

## After approval

Once the user approves the guard design, complete these steps in order.

### 1. Verify the traceability chain

Confirm all four files exist:
- `principles/<principle-name>.md`
- `strategies/<strategy-name>.md`
- `implementation/<lang>/<strategy-name>/protocol.md`

If any are missing, stop and tell the user.

### 2. Uniqueness check

Glob `guards/<lang>/*.md`. For each existing guard, compare against the
new one:

- **Name collision** — Same or nearly identical name. Resolve before writing.
- **Overlap** — Different name but checks the same thing or a superset.
  Show both to the user and ask: merge, differentiate, or abort?
- **Complementary** — Different guards for different steps of the same
  protocol. This is fine and expected.

### 3. Create the guards directory

Create `guards/<lang>/` if it doesn't exist.

### 4. Write the guard design document

Write the guard design to `guards/<lang>/<guard-name>.md`.

### 5. Close the originating bead

If this design was triggered by a "Design guard" bead from
protocol generation, close it with `bd close <id>`. If there is no
originating bead (e.g., the user requested the design directly), skip
this step.

### 6. Create implementation beads

For simple guards (single linter rule in existing config):
- Create one bead: "Implement [guard-name] guard for [language]"
  with type `task`, priority `3`. Description includes the full
  traceability chain and references the design doc path.

For complex guards (new tool, multi-file, CI changes):
- Create an epic: "Implement [guard-name] guard for [language]"
- Create subtasks:
  - "Write [guard-name] rejection logic" — the analyzer/rule code
  - "Write [guard-name] tests" — violation and acceptance test cases
  - "Configure [guard-name] in [tool]" — linter config, CI step
  - "Triage existing [guard-name] violations" — run against codebase,
    fix or suppress existing violations
- Link subtasks to the epic with dependencies

### 7. Update WORKFLOW.md if needed

If this is the first guard for a language, add a guards section to
`docs/WORKFLOW.md` describing where guards live and how they're configured.

### 8. Offer next steps

- **Implement now?** If the guard is simple enough, offer to implement it
  in the current session.
- **More guards?** If the protocol has other guard candidates, offer to
  design the next one.
- **Different language?** If the same protocol step has guards in other
  languages, offer to design those too.

## Edge cases

- **Guard candidate fails the assess.** Not every guard candidate becomes a
  guard. If assessment shows the check requires judgment, isn't mechanizable,
  or has too many false positives, the candidate stays in the protocol's
  GUARD CANDIDATES section as documentation. Don't force it into a guard.

- **Upper layer needs refinement.** During guard design, you may discover
  the protocol step is too vague to produce a precise REJECTS description,
  the strategy step is too abstract, or the principle is too broad to
  mechanize. Don't force a vague guard. Instead: create a bead for the
  appropriate editor describing what needs refinement. Add the new bead as a
  blocker on the current guard design bead (`bd dep add <guard-bead>
  <refinement-bead>`). Update the guard design bead's notes with what you
  learned — specifically, what's vague and what precision is needed. The
  guard design bead stays open but blocked until the upper layer is refined.

- **Guard already exists in tooling.** Before designing a custom guard,
  check whether the target ecosystem already provides a built-in rule that
  does exactly this. For example, golangci-lint has hundreds of built-in
  analyzers, ruff has hundreds of rules, ESLint has extensive plugin
  ecosystems. If an existing rule matches, the guard design document
  describes the configuration rather than a custom implementation. The TOOL
  field names the existing rule, and the IMPLEMENTATION section describes
  how to enable and configure it.

- **Multiple tools could work.** When several tools could implement the
  guard (e.g., golangci-lint vs. standalone binary vs. CI script), present
  the tradeoffs:
  - **Linter plugin** — Best for code-level checks. Runs in editor, fast
    feedback. More work to set up.
  - **CI gate** — Best for cross-file or build-output checks. Runs only in
    CI. Less work to set up.
  - **Pre-commit hook** — Best for file-level checks. Runs before commit.
    Medium setup.
  Default to the tool that provides the fastest feedback loop unless
  there's a reason not to.

- **Multi-step guard candidate.** A single mechanical check may enforce
  two or more related protocol steps. Use comma-separated step references:
  `PROTOCOL: ... → Step 4, 6`. Design the guard holistically — the REJECTS
  and ACCEPTS should cover the combined scope. Don't create two nearly
  identical guard designs when one check handles both.

- **Existing violations in the codebase.** When a guard is designed for
  code that already exists, there will likely be existing violations.
  The implementation plan should include a triage step: run the guard,
  categorize violations (fix vs. suppress), and handle them before
  enabling the guard as a blocking check.

- **Guard becomes obsolete.** When a protocol step changes or is removed,
  the guard may no longer apply. The guard design document should be updated
  or archived. Don't leave stale guards checking for patterns that are no
  longer part of the protocols.

- **Cross-language guards.** Some checks are conceptually the same across
  languages but implemented differently. Design each language's guard
  independently — they share a strategy but their rejection logic, tools,
  and false positive profiles are different. Don't try to create a
  "universal" guard.

- **User wants to batch-design guards.** When designing guards for multiple
  candidates from the same protocol, work through them one at a time.
  Each guard has its own false positive profile and tool considerations.
  Present them individually for review.

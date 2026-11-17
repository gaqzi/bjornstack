# Go

This file records bjornstack's opinionated take on Go. It is not a Go
style guide. Where it says nothing, follow the standard Go conventions
(go-conventions). What it holds is what we add to those conventions or
do differently, each with its reason, how our strategies are done in
Go, and the Go behaviour that breaks our rules when it is missed. The
Go protocols are generated from it.

Each rule starts with its id in bold; other rules refer to it by that
id. "Differs:" says where we depart on purpose from a source, and why.
"Source:" says where the rule's wording comes from, using the keys
listed under [Sources](#sources). "Rows:" lists the rows of the
decision tables in `languages/go/decisions/` that the rule takes in,
by table key, including rows of other sources that only agree with it.
Strategies and tenets are named by their titles and live in
`strategies/` and `tenets/`.

Three terms recur. A coordinator is a unit whose work is calling its
collaborators and checking what they return (Unit Testing). The edge
is the unit that talks to an outside system, such as a database,
another service or the file system, and turns that system's errors
into our own. `test/a` is the one package that holds the builders and
shared doubles every test imports (Test Data Builders).

The sections:

- Tooling: tools, libraries and Go versions.
- Pattern mappings: how a strategy, or a choice of ours that a
  strategy leaves open, is done in Go.
- Go pitfalls: Go behaviour that quietly breaks one of our rules.
- Go style: style choices of ours for Go that map to no strategy.
- For the protocols: material the protocols turn into steps.

## Tooling

**go-conventions.** Follow the standard Go conventions, as Effective
Go, the Go Wiki's Code Review Comments and Test Comments, and the
Google Go style guide state them, wherever this file says nothing.
This file lists only what we add or change, so that our departures are
not buried under rules every Go programmer already follows. The Uber
Go style guide is not one of the standard conventions: an Uber rule
applies only where a rule here cites it (U), as chan-size and enum-start
do. Outside testing, this file picks no third-party package, and a
package a standard source picks, such as the Google guide's
`subcommands` for command-line tools, is the project's choice, not
ours.
Source: owner ruling 2026-11-16; owner rulings 2026-11-17 (Q3,
packages); EG; CRC; TC; G, D and BP.
Rows: none of its own; it stands for every row the tables drop as
standard Go conventions.

**go-version.** Use only the language features and standard library
of the Go version in `go.mod`'s `go` directive, or older. From Go 1.27
`go test` runs the `stdversion` check; when it fails, raise the
directive or stop using the newer API, never silence the check.
Source: JB `README.md:11-12`; T `SKILL.md:298-300`; RN27.
Rows: E 67; G 34.

**tool-finish.** A change is done when `gofmt -l .` prints nothing,
`go vet ./...` is clean and `go test ./... -count=1` passes, with no
existing test weakened to get there. CI also runs the tests with
`go test -race ./...`.
Source: P0 slice 2 brief, "Finish criteria"; T `SKILL.md:60`, `:419`.
Rows: A 78; B 33; C1 10, 11; D 1; F 1, 61, 64, 69; G 13, 154, 175.

**tool-guards.** These checks are candidates for the guard layer, not
part of tool-finish:
- golangci-lint, configured in a `.golangci.yml` at the module root,
  with at least errcheck, forcetypeassert, nilerr, govet, staticcheck,
  thelper, paralleltest, testifylint, revive and goimports. Reuse
  golangci-lint's linters where they exist, and write our own so that
  they could later go into golangci-lint.
- `go.uber.org/goleak` in every package whose code starts goroutines,
  as `goleak.VerifyTestMain(m)` or `defer goleak.VerifyNone(t)`:
  `-race` does not find a goroutine that never exits.
- The go fix guard (bs-1y3): new code uses the forms `go fix`'s
  modernize analyzers write, with the `atomictypes` analyzer left out
  (old-forms).

Source: owner rulings S-4 and S-5; U "Linting", "Lint Runners", "Don't
fire-and-forget goroutines"; T `SKILL.md:56`, `:181-213`, `:396`; CRC
"Imports"; JB `guidelines.json`.
Rows: B 51; D 51, 115, 116; E 5, 11, 13, 14, 15, 21, 26, 27, 30, 32,
34, 39, 47, 54, 60, 61, 63; G 9, 49, 64, 114, 144, 200, 239.

**tool-coverage.** Plain `-cover` measures a package through its own
tests only. Code that only tests in other packages exercise, black-box
tests among them, needs `-coverpkg=./...`, or it shows as uncovered.
A coverage run of parallel tests without `-race` passes
`-covermode=atomic`.
Source: T `references/coverage.md:35-43`.
Differs: T also asks for `-covermode=atomic` with `-race`, which
already sets it.
Rows: G 37, 38.

**test-require.** Assert with testify's `require`. Use `assert` only
when a test deliberately collects failures that are independent of
each other. We chose `require` because `require.Equal` compares with
`reflect.DeepEqual`, which catches a time-zone mismatch that go-cmp's
`cmp.Diff` hides (test-time).
Source: owner comments 2026-09-08 09:04 and 2026-11-03 09:09; TD
`conventions.md` rule 3.
Differs: Test Comments and the Google guide advise against assertion
libraries and compare with go-cmp; the Phase 0 briefs used `cmp.Diff`.
Rows: A 39, 57, 90; C1 135; C2 118.

**test-protobuf.** Compare protobuf messages with
`cmp.Diff(want, got, protocmp.Transform())`, because `require.Equal`
misreports on messages. The failure message labels the sides,
`(-want +got)`, and starts the diff on a new line. Nothing else uses
go-cmp, and production code never imports it: it may panic on a
comparison it considers invalid.
Source: owner comments 2026-09-08 09:58 and 2026-11-03 09:09; TC
"Print Diffs"; D:3359-3363, D:3421-3445.
Rows: A 43, 57; B 10, 24, 25; C1 136, 139, 146.

**tool-bb-infra.** Black-box tests start the service's own
infrastructure for real, with testcontainers-go or docker-compose
(bb-infra).
Source: bs-6nd.
Rows: A 7; G 40.

**new-stdlib.** In a module whose `go` directive is 1.27 or later, new
code uses `encoding/json/v2`, and generates and parses UUIDs with the
standard library's `uuid` package, which generates UUIDv7. A package
already on `encoding/json` (v1) stays on it (old-forms).
Source: owner comment 2026-11-03 09:09; RN27; owner rulings 2026-11-16
and S-8.
Rows: A 60a; E 2, 8; F 67, 68.

**test-artifacts.** A file a test writes for a person to inspect after
the run goes in `t.ArtifactDir()` (Go 1.26), not an ad-hoc path or the
repository.
Source: RN26; T `SKILL.md:279-296`.
Rows: F 62; G 33.

## Pattern mappings

### Packages and layout

**pkg-naming.** Name a package with a short lower-case noun for the
domain it owns (Domain-First Packaging). Exports extend the package
name instead of repeating it: `mail.Message`, not `mail.Mail`.
Source: bs-01o.
Rows: A 1, 4; B 67; C1 17, 36; C2 2, 23; D 65; F 6.

**pkg-internal.** A module's supporting packages start under
`internal/`; a package moves out only when a consumer outside the
module has a concrete, current need (Intentionally Public steps 1-2).
There is no `pkg/` for code that might be useful elsewhere one day. A
library puts its public packages at the module root. When a caller or
a test needs an unexported detail, reshape the boundary or move the
detail into an `internal/` sub-package; never export it for the test.
Source: bs-01o; bs-8bi; ML "Package or command with supporting
packages", "Server project"; PL `SKILL.md:80`, `:114-115`,
`references/directory-layouts.md:72-96`.
Differs: PL allows `pkg/` for code useful to other modules.
Rows: A 2, 14, 16; C1 89; F 47, 50, 51; G 128, 129, 130.

**layout-cmd.** Each binary's `package main` lives in `cmd/<name>/`,
also when the module has only one binary. When a tool is created, ask
the owner whether it will have several binaries and whether to add the
folder; a root `main.go` is allowed as a local exception, recorded in
`.bjornstack/conventions.md`. `main` parses flags and configuration,
builds the collaborators (coord-inject) and calls a function such as
`run` that returns an error; no business logic lives in `cmd/`. Only
code in `main` calls `os.Exit` or `log.Fatal`, in two places: when `run`
returns an error, `main` prints a message saying how to fix the problem
and exits non-zero, without a stack trace; and after a server's panic
middleware tells `main` to stop, `main` drains the server and exits with
status 2 (fail-loud), whatever the drain returns. A panic keeps its
stack trace. A subcommand needs no package of its own, and a binary that
wraps a library is one more client of it.
Source: owner ruling S-7; PL `SKILL.md:80`,
`references/directory-layouts.md:98-150`; ML "Multiple commands"; U
"Exit in Main", "Exit Once"; BP "Program initialization", "Complex
command-line interfaces".
Differs: Go's module layout guide puts a single binary's `main.go` at
the module root; we default to `cmd/<name>/`.
Rows: C2 58, 105; D 47, 48; F 48, 49; G 126, 127, 132, 133.

**test-pkg.** Tests are in `package foo_test` and reach the package
only through its exports; no test file declares `package foo`, not
even `export_test.go` (Public API Surface Testing step 1). An
`internal/` sub-package is the way to test an algorithm directly.
Source: bs-8bi; owner comment 2026-09-08 09:04; P0 slice 5 and 6
briefs; TD `conventions.md` rule 1; owner ruling 2026-11-16.
Differs: TD also allows testing unexported code "as a noted deliberate
choice"; Public API Surface Testing has no such exit.
Rows: A 13, 41, 63, 88; C1 165; G 8, 18, 146.

### Interfaces

**iface-consumer.** An interface belongs to the package that uses it
and lists only the methods that package calls. It is declared when a
consumer first needs it: outside-in, that is the coordinator test that
first needs the collaborator (Outside-In Development Loop step 2). A
coordinator's direct collaborator always gets one, as an interface or
a function type, because its tests replace it with a double (Unit
Testing steps 3.2-3.3). Past three methods, look for smaller
interfaces that compose. The implementing package returns a concrete
type, so it can add methods without breaking anyone (iface-grow). It
exports an interface instead only when the interface is the product,
a protocol many implementations follow such as `io.Writer`; when the
function picks one of several concrete types at run time; or to break
an import cycle, which more often means the packages are split wrongly
(Domain-First Packaging step 5). No interface is declared because
something is called a service or a repository, and none on the
implementing side only for mocking. A generated RPC client is used
directly by the edge unit that calls the service (test-http); code
above the edge depends on our own interface in domain types.
Source: CRC "Interfaces"; D:2347-2373; BP "Avoid unnecessary
interfaces", "Interface ownership and visibility", "Designing
effective interfaces"; EG "Generality"; SI `SKILL.md:28-110`.
Differs: the Google guide starts from the concrete type and advises
against interfaces over RPC clients for testing; outside-in, the
coordinator test declares the interface before an implementation
exists. SI caps interfaces at three methods; past three is a cue here,
not a limit.
Rows: B 57, 58, 59; C1 87, 91, 92; C2 144, 145, 148, 149, 150, 151,
152, 153, 154, 155, 156, 157, 158, 159; F 23; G 11, 156, 157, 158,
159.

### Context

**ctx-per-call.** `context.Context` is the first parameter of each call
that needs it and is never stored in a struct. It is the one value a
coordinator hands on to its collaborators (the exception to Unit
Testing step 3.2). The one place a ctx may sit in a struct is a value
built inside a call only to fit that call's data to an interface whose
signature cannot take a ctx, such as an `io.Reader` that stops reading
when the call is cancelled. That value holds the call's own ctx and
never outlives the call (Unit Testing, Rationale, "Signatures that say
what they work on").
Source: owner comments 2026-10-19 16:32 and 2026-10-21 06:36; owner
ruling 2026-11-16; owner ruling R-4; CRC "Contexts"; D:2907-2912; CS.
Differs: CRC, the Google guide and CS allow a stored ctx for any
method that must match an outside interface, and CS where duplicating
an API is impractical; a ctx stored when a value is set up is the
set-up value Unit Testing step 3.2 forbids.
Rows: A 46; B 35, 37; C1 112, 116; C2 98; F 33; G 92, 93, 94.

**ctx-scope.** ctx carries cancellation and the per-goroutine settings
the whole program needs, such as the logger and the trace ID. It does
not carry data because it is easy to reach: data in ctx is almost
never right, not never. One accepted case is the authenticated
principal: auth
middleware puts it in the request's ctx, the handler reads it and
passes it down as input, and code below the handler reads it from ctx
only for a finer-grained check than the middleware made, so that it
does not authenticate again. Each ctx value has an unexported key
type and exported functions to set and get it; callers never
type-assert `ctx.Value` themselves. The logger lives in ctx only: code
takes it with a getter such as `logctx.From(ctx)`, which returns a
logger that discards everything when ctx carries none, never
`slog.Default()`. Tests put their own logger in ctx.
Source: owner comment 2026-10-21 06:36; owner ruling 2026-11-16; owner
ruling S-1; CX `SKILL.md:37`, `references/values-tracing.md:7-38`.
Differs: the sources put the user or tenant in ctx for any code to
read.
Rows: A 47; G 100, 101, 102, 103, 110, 231, 246, 247, 248.

**ctx-sources.** Code takes ctx from its caller. Where no caller hands
one over, an HTTP handler uses `r.Context()`, a test `t.Context()`, a
command run by a CLI library the context the library passes it, and
`main`, `init` and `TestMain` `context.Background()`. Work that must
outlive the request gets `context.WithoutCancel(ctx)`, which keeps the
logger and trace ID, plus a timeout of its own. `context.TODO()` marks a
ctx the caller does not pass yet and is replaced before the change
ships. Any other `context.Background()` is raised in review.
Source: CRC "Contexts"; D:2878-2932; CX `SKILL.md:35-49`,
`references/cancellation.md:163-186`; BP "Complex command-line
interfaces".
Differs: CRC allows `context.Background()` wherever there is a good
reason; CX lets tests call it and gives detached work no timeout.
Rows: B 36; C1 114, 119; C2 104; G 97, 98, 99, 105, 240, 252, 253.

**ctx-retrofit.** When an exported function gains a ctx (Grow Don't
Break):
- Callers you don't control: add `XxxContext(ctx, ...)` beside it,
  keep the old function working by calling the new one with
  `context.Background()`, and mark the old one deprecated (steps 3
  and 5).
- Every caller is yours: add the new form, move every caller to it,
  then remove the old one (step 4).

Skip this, and change the signature in place, when the function has no
callers outside its own package, or in early prototyping before any
consumer depends on it.
Source: CS "Exception to the rule".
Differs: CS says nothing about deprecating the old function or about
callers that are all yours.
Rows: F 34.

### Errors

**err-identity.** When a caller handles a failure differently from
others (Failure Identity step 1), give the failure an identity Go can
compare. With no values the caller reads, it is a package-level
sentinel, `var ErrNotFound = errors.New("not found")`. With values, it
is an error type whose fields hold them, named `...Error`, which the
caller reads with `errors.As` (step 2). A function returns it as
`error`, never as `*NotFoundError`: a nil pointer of that type stored
in an `error` is not nil, so the caller's `err != nil` is true. A
failure no caller handles
differently gets neither: `errors.New` or `fmt.Errorf` inline. An
exported identity is part of the package's contract: document it with
the operation that returns it, and change it as Grow Don't Break
changes any contract. An identity matched only inside the package
stays unexported.
Source: ER "Errors and package APIs"; BP "Error structure"; U "Error
Types", "Error Naming"; EH `references/error-creation.md:62-138`; TC
"Test Error Semantics".
Differs: ER lets a sentinel stand for any condition, and EH keeps
sentinels for "expected conditions"; here an identity that carries
values is a type, and the test is whether a caller handles the
failure differently, not whether a test wants to tell it apart.
Rows: B 32; C1 53; C2 33, 36, 77; D 23, 24, 25, 32, 33; F 43; G 80,
183, 223.

**err-wrap-where.** Wrap the error returned by a call to another
unit's public function, naming the action that failed and the values
the error does not already carry: `load settings for %s: %w`. Leave
out words like "failed to", "couldn't" or "unable to". Return a
private helper's error unwrapped, so one unit's own steps add no
noise. `%w` goes at the end, so the text reads newest to oldest; a
sentinel that names the failure's category goes first instead,
`"%w: bad header: %v"`. The verb follows err-wrap-verb.
Source: owner ruling 2026-11-16; BP "Adding information to errors",
"Placement of %w in errors"; EH `references/error-creation.md:42-60`.
Differs: BP leaves an error unannotated where a wrap would add
nothing; we always wrap at a unit's boundary.
Rows: A 121; C2 38, 39, 40, 41, 49, 50; D 26, 27, 30; G 70, 71, 224,
228.

**err-test-identity.** A test checks which failure came back with
`require.ErrorIs` or `require.ErrorAs`, never by comparing
`err.Error()` or the whole error with `require.Equal`, which stops
matching once the error is wrapped. It checks that the message names
the facts it must, such as the parameter name, with
`require.ErrorContains`, never its full wording (Failure Identity step
6). An identity's data may be compared whole with `require.Equal`,
leaving out any text meant for a person. A failure with no identity is
checked with `require.Error` and the facts its message must name, or
`require.Error` alone when the test set up no such fact.
Source: TC "Test Error Semantics"; TF `SKILL.md:188`.
Differs: TC permits a check on the message; Failure Identity step 6
requires it.
Rows: B 29, 30; G 62.

### Validation

**scrub-boundary.** Wire types, with their `json` tags, live in the
boundary adapter. A scrub function there turns a wire value into a
domain value. Domain types carry no wire tags, and a domain package's
API takes domain types only (Scrub on Entry steps 5-6).
Source: bs-8jx.
Rows: A 20, 21.

**scrub-validate.** Check each acted-on field of the input struct, and
the relationships between its fields, with validation tags (from a
library or our own) or with plain Go. Either way, a rejection lists
every violation in the record with its field, value and constraint.
Validation tags go on the input struct; domain types carry no input
tags. In Go the boundary checks include a nil pointer in the external
data, an integer that must fit a narrower type (the conversion wraps
silently), and a zero that will be a divisor (integer division by
zero panics). Code past the boundary does not check them again.
Source: bs-8jx; owner ruling 2026-11-04; SF `references/nil-safety.md`,
`SKILL.md:115-156`.
Differs: SF checks before every narrowing conversion and every
division; Scrub on Entry rules out checking scrubbed values again.
Rows: A 17, 18; G 91, 192, 195, 201, 202.

**scrub-collect.** Inside a layer, a record's violations may be
collected with `errors.Join`, each one built with `errors.New` or a
`fmt.Errorf` holding at most one `%w` (err-wrap-verb); so may any
rejection whose members are plain messages nobody compares. At the
boundary, or anywhere a caller branches on the result, return one error
type for each distinct thing the caller acts on, such as one rejection
per record that holds its violations as data, gathered in one rejection
for the whole input that also carries the counts Scrub on Entry step 4
asks for: errors found, records checked, records shown, and whether
checking stopped early. A Join of sentinels handed to a caller that
branches on it lets one cause decide for all the others
(err-join-match); several `%w` in one `fmt.Errorf` do the same. Across
many records, the cap and what the rejection reports follow Scrub on
Entry step 4; the cap falls between records, so a record's violations
are never split. Tests take the rejection out with `require.ErrorAs` and
compare its data, all of a record's violations, in one `require.Equal`,
not one `ErrorIs` per cause. Collecting is for violations only: an
operational failure returns at once, alone, without the violations found
so far (Scrub on Entry step 4), and the end user sees only a general
message (its Rationale). Related operations where only the first failure
matters may run under an error group. Closing several resources at the
end of work is the one place operational failures are joined: try
every one, wrap each error with the resource it came from, and join
them, since an unclosed resource leaks whatever the others did.
Source: bs-8jx; owner comment 2026-09-08 09:58; P0 slice 2 brief;
owner rulings 2026-11-04 and 2026-11-16; EG "If"; BP "Error handling";
EH `references/error-wrapping.md:103-115`.
Differs: the Phase 0 briefs used `errors.Join` everywhere, including
results a caller branches on.
Rows: A 19, 45, 68; C2 32; F 13; G 76, 78.

### Time

**clock-inject.** No code under test calls `time.Now()`, `time.Since`
or `time.Until`; it receives a clock. The clock has two parts:
- `Now()` returns the current instant in UTC (UTC Computation step 2).
  A deadline that is stored or sent to another process is such an
  instant.
- A separate way to measure elapsed time and in-process timeouts: a
  start mark of its own type, such as `m := clk.Start()`, and
  `clk.Since(m)` for the time passed. The mark carries the monotonic
  reading `time.Now()` takes, which is never converted with `.UTC()`,
  `.In()` or `.Local()`, since converting removes it (UTC Computation,
  Rationale, the Go entry among the language quirks). Because the mark
  is not a `time.Time`, a `Now()` result cannot be passed as one.

Elapsed time is never the difference of two `Now()` results, and an
in-process timeout is never computed from `Now()`, as in
`clk.Now().After(deadline)`: it is a duration measured from a mark, or a
ctx deadline. Only the clock implementation calls `time.Now()`. Tests
pass a fixed clock whose instant and elapsed time they set. Timers,
tickers and ctx deadlines (`context.WithTimeout`, `time.NewTicker`,
`time.Tick`, `time.After`) run on the real clock: code under test either
takes its ticks from the injected clock or uses them directly, and then
its test runs under `testing/synctest` (`synctest.Test`, Go 1.25), with
`httptest.NewTestServer` for any server it needs. Where neither works,
assert that the result's time field was set, copy it into `want`,
then compare the
whole value. Randomness follows the same order: inject its source, and
where it is drawn inside `crypto/rand` or another crypto package,
`cryptotest.SetGlobalRandom` controls it for the test. No test waits
with `time.Sleep`.
Source: P0 slice 4-7 briefs; owner comment 2026-11-03 09:09; TD
`conventions.md` rule 6; owner ruling 2026-11-16; bs-luj (option D,
2026-11-17); JB `guidelines.json` `time_since`, `time_until`,
`time_tick_gc`; RN25; RN26; RN27; T `SKILL.md:219-255`.
Differs: TD has no synctest step. JB recommends `time.Since` and
`time.Until` everywhere; code under test never reads the real clock.
Rows: A 59, 74, 93; E 25, 65, 66; F 60, 63, 65; G 24, 25, 47, 48, 238.

**time-external.** Hold an instant in a `time.Time` and a period in a
`time.Duration`, never a bare integer whose unit the reader must
guess. Exchange them with outside systems as `time.Time` and
`time.Duration` where the format supports them. Code that reads an
instant converts it to UTC where it enters (UTC Computation step 2);
code that only passes it on leaves it as it is. A value UTC
Computation step 1 keeps local, such as a reminder every day at 09:00,
is stored and sent as local date and time plus the IANA zone name, and
computed in that zone, never as a bare `time.Time`, whose RFC 3339
form carries an offset but no zone name. Where a format cannot carry a
`time.Duration`, use an integer with the unit in the field name,
`IntervalMillis`; where it cannot carry a `time.Time`, write RFC 3339
in UTC.
Source: U "Use `"time"` to handle time", "Use `time.Time` and
`time.Duration` with external systems"; CU `go-defensive/SKILL.md:29`.
Differs: Uber writes RFC 3339 in any offset, does not convert on
entry, and sends every time as `time.Time` where the format allows.
Rows: D 16, 17, 19, 20, 21; G 256.

### Wire formats

**wire-tags.** Every exported field of a struct marshalled to JSON,
YAML or another format that names fields by tag carries a tag with its
name, so the wire form, a contract with other systems (Boundary
Communication step 3), stays fixed when the Go field is renamed. Such
types live in the boundary adapter (scrub-boundary). `omitzero` marks
a field whose Go zero value means "absent"; `omitempty` stays where
JSON's empty value is meant, mostly empty strings, slices and maps;
where zero and absent mean different things and neither fits, use a
pointer.
Source: U "Use field tags in marshaled structs"; SI `SKILL.md:243-254`;
JB `guidelines.json` `json_omitzero`.
Rows: D 49; E 17, 18; G 172, 173, 174.

### Unit tests and coordinators

**test-names.** Name the outer test `Test<Type>_<Method>`. Name each
`t.Run` case as a sentence stating the situation and the outcome.
`go test` shows spaces as underscores; keep `/`, which splits a `-run`
filter, and non-printing characters out of case names.
Source: TD `conventions.md` rule 2; P0 slice 2 brief; TC "Choose
Human-Readable Subtest Names"; D:3523-3550.
Differs: the Google guide asks for short case names without spaces.
Rows: A 67, 89; B 2, 15, 16; C1 153, 154, 161; D 70; G 3, 21.

**test-table.** A table test is a slice of cases run with `t.Run`.
Each case names its fields and sets every one, zero values included,
and carries the assertion functions that differ between cases. For a
`(value, error)` result those are `assertError` and `assertResult`, and
the body calls both for every case. The body has no conditionals. A
table carries no setup or mock-expectation functions: cases that need
different setup are separate tests (Parameterized Test Structure step
1).
Source: P0 slice 2 brief; TD `conventions.md` "Error plus state";
owner ruling 2026-11-16; BP "Use field names in struct literals";
U "Avoid Unnecessary Complexity in Table Tests"; D:1536-1583.
Differs: Parameterized Test Structure step 3 prefers expected-value
fields where the assertion can be written as values; we keep an
assertion function per case because it allows custom logic, keeps
changes cheap and shared assertion functions read better (bs-6q6
proposes this for the strategy). The Google guide lets a case leave
zero fields out; Uber counts any function in a table as confusing.
Rows: A 64, 65, 83, 86; B 6, 20; C1 68, 132, 135, 160; C2 119, 126; D
96, 97, 98, 107, 108, 110.

**test-helper.** `t.Helper()` is the first line of every function that
calls `t.Fatal`, `t.Error`, `require.*` or `assert.*`. A setup helper
fails the test itself with `require` rather than returning an error;
its message says which step failed and why, `setup: write asset pak0:
...`; and it registers its teardown with `t.Cleanup`, not `defer`. A
helper in which nothing can fail the test takes no `*testing.T`.
Source: TD `conventions.md` rule 4; BP "Error handling in test
helpers"; D:2177-2221; CU `go-testing/SKILL.md:107-122`.
Differs: the Google guide's helpers call `t.Fatal`; ours use `require`.
Rows: A 91; B 21; C1 85, 162; C2 107, 120, 121, 122, 123, 124; G 221,
260.

**test-messages.** An assertion message says what was expected, and
for which call and inputs: `expected Total(order-42) to include tax`,
not "should". Where the test calls the code under test more than once,
the message says which call failed. Large or opaque inputs are
described by the case name instead, or logged with `t.Log`. `require`
supplies the got and expected values.
Source: TD `conventions.md` rule 5; TC "Identify the Function",
"Identify the Input"; CRC "Useful Test Failures"; D:3373-3384.
Rows: A 92; B 3, 13, 14, 82, 83; C1 140, 142.

**test-whole-value.** Compare the whole value with
`require.Equal(t, want, got, "expected ...")`, building `want` with the
same builder as the input. A struct literal for a type that has a
builder is a smell: add the missing `With*` method. A field
`require.Equal` cannot compare exactly, such as a func field or a
computed float, is handled as Whole-Object Assertion step 2 does:
check it on its own (a float with `require.InDelta`), copy it into
`want`, then compare the whole. Output whose exact bytes another
package controls, such as `json.Marshal`'s, is decoded and compared as
a value, never as a string; a golden file in `testdata/` is only for
output with no structure Go can decode, such as HTML or SQL text.
Source: TD `conventions.md` rule 7, `builders.md`; P0 slice 2 brief;
TC "Compare Full Structures", "Compare Stable Results"; D:3210-3220;
SF evals 23.4, 31.5; ES `go-test-quality/SKILL.md:137`.
Differs: TC tweaks `cmp` with `cmpopts` for such fields; ES lists JSON
among golden-file outputs.
Rows: A 66, 82, 94, 118; B 4, 5, 7; C1 130, 133; G 194, 235.

**test-sut-options.** Build the code under test with an options
function in the test file, `defaultCalculator(withTaxRates(x))`, where
a full builder would be more than the type needs.
Source: bs-bq9; TD `conventions.md` "Options function".
Rows: A 33, 80.

**test-ctx.** A test derives its ctx from `t.Context()`, which is
cancelled when the test ends and before its cleanup runs; a benchmark
from `b.Context()`. A test whose code could hang adds
`context.WithTimeout`, so a hang fails that test instead of the whole
run. To show code honours cancellation, cancel its ctx and check
`errors.Is(err, context.Canceled)`. A test that needs its own logger
adds it to a ctx derived from `t.Context()` (ctx-scope). A handler
test builds its request with `httptest.NewRequestWithContext`.
Source: RN23; RN24; ES `go-context/SKILL.md:206-209`; owner ruling
2026-11-16.
Rows: F 54, 55; G 249, 250.

**test-isolation.** Tests and subtests call `t.Parallel()` wherever
they can (Isolated Test Execution). Each black-box test works under
its own identity: a fresh user, tenant or key prefix. Data on shared
infrastructure is scoped by that identity, never reset or reseeded
between tests. Only a test that changes process-wide state stays
serial: one that calls `t.Setenv` or `t.Chdir`, or changes a package
variable, which it restores with `t.Cleanup`. Code under test takes the
directory it works in as a parameter, and a black-box test sets
`exec.Cmd.Dir`, so `t.Chdir` is left for code whose contract is to
read the working directory; no test calls `os.Chdir`. A test calls the
setup it needs, so `go test -run X` pays only for X: test files have
no `init` and no package-level setup outside `TestMain`, and
`TestMain` only starts shared infrastructure (bb-infra). `sync.Once`
may share setup that is expensive, used by only some tests, needs no
teardown, takes no ctx, and is only read.
Source: bs-6nd; RN24; BP "Keep setup code scoped to specific tests",
"When to use a custom TestMain entrypoint"; T `SKILL.md:302-326`; ES
`go-test-quality/SKILL.md:158-160`.
Differs: T and ES let a test with shared mutable state opt out of
`t.Parallel`; BP has each test reset what it wrote to a database;
RN24 puts no limit on `t.Chdir`.
Rows: A 10; C2 127, 128, 129, 130, 131; F 56; G 7, 237.

**test-fuzz.** A function that parses or checks untrusted input gets a
fuzz test, seeded with `f.Add`, that asserts properties of the result,
beside its table test of known cases.
Source: T `SKILL.md:328-346`; ES `go-test-quality/SKILL.md:138`.
Rows: G 35.

**test-eventually.** A black-box test waits for an asynchronous
outcome with `require.Eventually`, or `require.EventuallyWithT`
asserting on its `*assert.CollectT` when the outcome needs more than
one check. Code whose result depends on time uses clock-inject
instead.
Source: TD `conventions.md`; TF `SKILL.md:119-131`.
Differs: TD lists `require.Eventually` as the general retrying
comparison.
Rows: A 85; G 53, 243.

**coord-inject.** A coordinator receives its collaborators through its
constructor, fully set up; the constructor sets every field. Its tests
replace every direct collaborator with a double, and never a
collaborator's own dependencies.
Source: P0 slice 2 brief; TD `mocks.md` rule 1.
Rows: A 69, 102; C2 139; D 42; G 171.

**coord-doubles.** A single-method dependency is a function type, and
its double is an inline function. A `testify/mock` double calls
`.Test(t)` before use, so an unexpected call fails instead of
panicking, and is checked with `m.AssertExpectations(t)`, which alone
catches an expected call that never happened. A call expected a fixed
number of times says so with `.Once()` or `.Times(n)`; successive
results, such as a failure then a success, chain one `.Once()` each.
An argument is matched against a whole expected value; `mock.MatchedBy`
only for Whole-Object Assertion step 2's fallbacks, never to check a
few chosen fields. A ctx argument may be matched with `mock.Anything`.
When setting up many doubles hides what a test checks, build them with
a builder in the test file whose `Build(t)` calls `.Test(t)` on each.
Source: TD `mocks.md` "Mock style", `conventions.md`; TF
`references/mock.md:3-82`, evals 4-6.
Differs: TF eval 5 matches only a log entry's level and message.
Rows: A 84, 108, 109, 110; G 44, 45, 54, 55, 56, 57, 58.

**doubles-home.** A test double stays in the test file that uses it. A
stateful double, one whose later results depend on earlier calls, moves
under `test/a` once a second test file in its interface's domain, or a
test outside that domain, needs it, and only after it passes that
interface's compliance suite; before writing one, look there and in
other test files first (Test Data Builders step 2). A package
`<pkg>test` holds only that package's compliance suite and helpers
published for tests outside this module, not doubles. No production
package exports a test double, or an interface whose only use is
substitution in tests.
Source: D:2360-2363; BP "Creating test helper packages", "Avoid
unnecessary interfaces".
Differs: the Google guide puts doubles in a package such as
`footest` or `spannertest`.
Rows: C1 90; C2 11, 146, 147.

**coord-count.** A coordinator with N collaborators that can fail has
about N+1 tests. Past four collaborators, look for a domain concept
that combines some of them.
Source: TD `mocks.md` rules 2-3.
Differs: TD says about 2N tests and at most three or four
collaborators; Unit Testing steps 3.1 and 3.4 say N+1 and set no
ceiling.
Rows: A 103, 104.

**coord-logic.** A conditional in a coordinator beyond
`if err != nil`, or a transform that needs test cases of its own,
signals computation: extract it, typically as a function-type
collaborator. A method called on an argument counts only if it needs
test cases of its own. A unit whose job is handling a failure, such as
mapping it to a status, retrying it or recovering from one failure the
callee's contract names, may branch on the failure's identity (Unit
Testing steps 3.4-3.5, Failure Identity step 3). An error from work
the task does not strictly need, such as emitting a metric, may be
logged while the work carries on.
Source: TD `mocks.md` smells 1-2; owner ruling 2026-11-16; U "Handle
Errors Once".
Differs: TD makes `if err != nil` the only allowed conditional; Uber
recovers from a named failure inline, wherever it is received.
Rows: A 105, 106; D 35, 36.

**coord-globals.** Diagnostic logging and metrics are not
collaborators (Unit Testing step 3.2). Metrics may be package-level
globals. The logger is not a global: it lives in ctx (ctx-scope).
Audit records are behaviour the work requires, so they come from an
injected collaborator. Any other global state a coordinator reads,
flag variables included, is a hidden collaborator: other packages take
their configuration as arguments, and only `package main` defines
flags, except in Google's extremely rare case of a library flag named
for its package, which needs a stated reason.
Source: TD `mocks.md` smell 3; owner ruling 2026-11-16; owner ruling
S-11; D:2779-2787; BP "Global state".
Differs: TD allows logging as a global; the Google guide makes no
exception for metrics.
Rows: A 107; C1 109; C2 138, 140, 141, 142.

**func-options.** Optional settings are variadic options with sane
defaults, `New(addr, WithTimeout(5*time.Second))`, so a caller passes
only what differs. There are no option structs: a struct that only
carries one function's arguments is the one-call wrapper Unit Testing
rules out, and a value that names a domain concept is passed as that
type. ctx is never an option, and collaborators are not options: they
arrive set up through the constructor (coord-inject); options are for
settings that mostly keep their default. An option takes its value as
a parameter, `WithFailFast(enable bool)`, not `EnableFailFast()`;
options apply in order and the last wins. Implement them as an
`Option` interface with an unexported `apply(*options)` method, so
options can be compared in tests. Where other packages are meant to
define options, the settings struct and the method that changes it are
exported instead, since an unexported method keeps them out.
Source: owner ruling S-3; BP "Option structure", "Variadic options";
U "Functional Options".
Differs: BP prefers an option struct in several cases; Uber does not
consider options defined in other packages.
Rows: C2 96, 97, 99, 100, 101, 102; D 113, 114.

**generics.** A type parameter is an abstraction: Earned Abstraction
decides whether it is earned, so with one type, or fewer than three
cases, write the code for the types at hand. Never use generics to
build domain-specific languages or error-handling frameworks. Where
generic code is earned, use a type parameter rather than `any` when
the caller knows the type. On Go 1.27, a generic helper whose
operation belongs to one type becomes a generic method on it.
Source: D:2397-2420; SI `SKILL.md:138-148`; JB `guidelines.json`
`generic_methods`.
Differs: the Google guide also warns against generic assertion
libraries; testify is our choice (test-require).
Rows: C1 94, 96, 97; E 1; G 161, 180.

**zero-value.** A type with no invariant to establish, such as a
buffer or a struct guarding state with a mutex, works as its zero
value, initialising its maps lazily where needed. A domain type is
built from validated data (Scrub on Entry step 6), and a type that
needs collaborators or settings by its constructor (coord-inject);
neither needs a usable zero value.
Source: EG "Allocation with `new`"; SI `SKILL.md:112-136`.
Differs: EG gives the advice for every type.
Rows: F 19; G 160, 196, 197.

**fail-loud.** Return an error for any failure a caller can expect;
library code never ends the program, and only code in `main` exits
(layout-cmd). Panic only for a broken invariant that leaves state
unrecoverable, with a message naming the invariant; for misuse that
tests and review should catch, such as a `Must` helper used at
initialisation; or as `panic("unreachable")`. Outside the two cases
below, nothing recovers a panic, so a panic ends the process. A panic
in a goroutine a handler starts is outside them: no middleware catches
it, and it ends the process at once, without draining. Take the first
case that fits:

- A package that panics internally to unwind, as a parser can,
  recovers its own error type at its exported functions, returns it as
  an error, and re-panics anything else.
- A server's outermost HTTP middleware, or its unary and stream gRPC
  interceptors, recover a handler's panic to stop the server cleanly.
  The middleware re-panics `http.ErrAbortHandler` unchanged, since
  `net/http` and `httputil.ReverseProxy` panic with it on purpose to
  abort a response. For any other panic it writes the panic and its
  stack trace, synchronously, to the log or stderr, and signals `main`
  to stop without blocking, once however many handlers panic, by
  closing a channel under a `sync.Once` or cancelling a ctx; it never
  calls `Shutdown` itself, which would wait on its own request. Then
  it answers that request 500, or that call `codes.Internal`; when the
  HTTP response has already started, it panics with
  `http.ErrAbortHandler` instead, so the client sees a dropped
  connection rather than a truncated body that looks complete. On the
  signal, `main` stops the server in this order:
  1. If the server has a readiness check, fail it, and give the load
     balancer time to notice, out of the shutdown deadline.
  2. Call `http.Server.Shutdown` with the server's usual shutdown
     deadline and wait for it to return, not for `ListenAndServe`,
     which returns as soon as shutdown starts. Hijacked connections,
     such as websockets, need a close hook registered with
     `RegisterOnShutdown`. For gRPC, call `GracefulStop` in a
     goroutine and `Stop` when the deadline passes, since
     `GracefulStop` has no deadline of its own.
  3. If the deadline passes, close the server, `Close` or `Stop`.
  4. Exit with status 2, as an unrecovered panic does, also when the
     drain timed out (layout-cmd).

  Draining keeps one bug from failing the other requests in flight, and
  exiting makes the bug fail the deployment and trigger a rollback.
  Without the middleware, `net/http` recovers the panic, logs it and
  keeps serving, so a bug on a rarely used path fails one request at a
  time and is easy to miss, and grpc-go does not recover it, so the
  process ends at once with every request in flight. This is preferred,
  not required: a server that must keep serving through a handler's
  panic records that as a local exception in
  `.bjornstack/conventions.md`.

A test fails through `require`, not `panic`;
builders-a's panic for a state not written yet is the exception,
since `Build()` takes no `*testing.T`.
Source: coordinator call 2026-11-16; owner rulings 2026-11-17 (Q2,
drain); EG "Panic", "Recover"; CRC "Don't Panic"; D:2127-2141; BP
"Program checks and panics", "When to panic"; U "Don't Panic"; EH
`references/error-handling.md:50-97`.
Differs: EG keeps running where a problem can be masked; the Google
guide ends the program on a broken invariant with glog's `log.Fatal`,
and we have no glog, slog has no Fatal, and `os.Exit` skips
`t.Cleanup`; EH recovers a panic in a handler to answer 500 and keeps
serving, and we drain and exit instead.
Rows: B 45; C1 82, 83; C2 59, 60, 61, 62, 63, 64, 65, 67; D 38, 39,
40; F 31, 32; G 81, 82, 257, 258.

**doc-comments.** Every exported name has a doc comment saying what it
does, takes and returns and how it fails (Say It Once step 1),
including the error identities a caller may branch on: the sentinel,
or the type and whether it comes as a pointer, which decides the
`errors.As` target. A type that is not safe for concurrent use says so
once, on the type; cleanup a caller owes, such as closing
`resp.Body`, is documented. An unexported name gets a comment only for
what its code cannot say, the why (Say It Once step 3). Builder
methods in `test/a` have none (builders-a). New code does not document
the obvious, such as that cancelling ctx interrupts the call, or
"format is the format"; existing caller documentation that does stays.
Source: CRC "Doc Comments"; D:557-633; BP "Parameters and
configuration", "Contexts", "Concurrency", "Cleanup", "Errors"; owner
rulings 2026-11-16 and S-12.
Differs: CRC and the Google guide also comment non-trivial unexported
code and builder methods; BP would delete documentation that restates
the obvious.
Rows: B 34, 44; C1 38, 40; C2 68, 69, 70, 71, 72, 73, 74, 75, 76, 78;
D 29.

### Test data builders

**builders-a.** Shared builders live in package `test/a`, one file per
type. The constructor applies the common states, so `a.Review().Build()`
is valid as it stands. Each customisable field gets a `With*` method,
and `Modify(fns ...func(*T))` covers one-off changes. `Build()` takes no
`*testing.T` and returns a value, not a pointer, so each build is
independent. A builder that needs another domain object uses that
object's builder. Builder methods have no doc comments. A state not
written yet panics with its name instead of guessing.
Source: bs-bq9; TD `builders.md`.
Rows: A 27, 28, 29, 30, 81, 111, 114, 115, 116, 119; G 234.

**builders-states.** Recurring multi-field states are methods named for
the domain state, such as `Persisted()` or `Expired()`. What is not the
happy path is declared as named edge-case variants, plus one method
returning every edge case as name and fresh builder (Test Data
Builders steps 5-6).
Source: bs-bq9; TD `builders.md` "Concern methods"; owner ruling
2026-11-04.
Differs: TD names states `IsSaved()` and `IsValid()`; the `Is` prefix
reads like a check, not a setup step. TD's `IsInvalid()` returns a
zeroed value instead of named edge cases.
Rows: A 32, 112.

**builders-ids.** Each builder sets its own static UUID. A random id is
used only as a test's scope identity on shared infrastructure, never
as a field default. On shared infrastructure, a test overrides ids and
other unique fields, such as emails and slugs, with values derived
from its scope identity (Isolated Test Execution step 3).
Source: bs-bq9; TD `builders.md` "Static UUIDs"; owner ruling
2026-11-16.
Differs: TD offers a random `a.UUID()` without limiting its use.
Rows: A 31, 117.

### Compliance suites

**compliance-suite.** When an interface has two implementations, or one
plus a stateful test double, write one exported
`<Interface>Test(t *testing.T, factory func(t *testing.T) I)` in an
ordinary file of the test-only package `<pkg>test`, such as
`storagetest` for package `storage`, so
implementations in other packages can import it. It takes no ctx:
each scenario uses its own `t.Context()` (test-ctx). It groups `t.Run`
by operation, then by scenario, and calls the factory with the
scenario's `t` for a fresh instance in every scenario, so the factory
can register its cleanup with `t.Cleanup` (Compliance Test Suites step
5). Each implementation wires its factory in a thin test. Scenarios
cover success, the contract's errors, returned values not sharing
stored state, and every edge case the builders declare for types the
interface takes or returns. A `slog.Handler` we write is checked with
`testing/slogtest`, the standard library's suite for that interface.
Source: TD `compliance-tests.md`, `conventions.md` "Interface
compliance"; owner ruling 2026-11-16; RN21.
Differs: TD puts the suite in a `_test.go` file, which other packages
cannot import; its factory takes no `t`, so it cannot clean up; it
requires two real implementations; and its scenarios have no
edge-case iteration or returned-copy check.
Rows: A 95, 96, 97, 98, 99, 100, 101; C2 112; F 52.

### Black-box tests

**bb-package.** Black-box tests live in their own package, one file per
feature, and import no production package. They run the built binary
or call the running server, and parse what comes back with local
structs, as a consumer would. A helper runs the binary with a
subcommand and prints its output when it fails.
Source: bs-6nd; P0 slice 3 and 5 briefs.
Rows: A 11, 62, 75.

**bb-setup.** A black-box test sets up state through the public
interface. It may instead write the bytes the system reads only when
that file format is a documented interface that the system's consumers
write. No test-only flag such as `--now`, and production code never
branches on `testing.Testing()`.
Source: P0 slice 7 brief; owner ruling 2026-11-16; RN21.
Differs: the Phase 0 brief allowed writing the published bytes
whenever they are the real interface.
Rows: A 76; F 53.

**bb-infra.** Shared infrastructure (tool-bb-infra) starts once per
test package, in `TestMain` or a testify suite's `SetupSuite`, and
stops in its teardown. It may be cleared once before the run, never
between tests, and `SetupSuite` creates no state tests change. A
testify suite is used only for this; its assertions go through
`s.Require()`, since `s.Equal` and the like behave like `assert`, and
each suite has its launcher, `suite.Run(t, new(XxxSuite))`.
Source: T `references/integration-testing.md:97-161`; TF
`SKILL.md:141-191`.
Differs: T truncates and reseeds between tests and waits a fixed five
seconds; TF uses suites for any shared setup.
Rows: G 41, 59, 60, 61.

**test-http.** Black-box tests call the server with an `http.Client` at
its real address, and services across the boundary are stubbed with
`httptest.Server`. A handler's own test is a coordinator test: it calls
`ServeHTTP` with `httptest.NewRequest` and `httptest.NewRecorder`, with
doubles for the handler's collaborators. The unit that calls another
service is tested through the production client and the real
transport against a test server, preferably one the service's authors
provide, never a hand-written imitation of the client (Contract
Testing step 2.2); coordinators above it get doubles of it.
Source: bs-6nd; T `references/http-testing.md:3`, eval 11; BP "Use
real transports".
Differs: T's eval rejects `httptest.NewServer` for handler tests
outright; black-box tests need the real server.
Rows: A 8, 9; C2 115, 116; G 23.

### Flags

**flag-test.** A helper runs one test body with the flag off and on,
each with its own assertions: the off run proves nothing changed, the
on run proves the new behaviour (Flag Your Changes step 3).
Source: bs-9sn.
Rows: A 22.

### Old forms

**old-forms.** Go's deliberate old forms follow Recorded Old Forms, with
`.bjornstack/conventions.md` as the record (docs/WORKFLOW.md, "Project
records"): an entry names what the code uses, why, and the trigger to
move. New code follows the entry wherever it applies, including new
packages it covers; with no entry, Recorded Old Forms step 2.2 decides,
including asking the owner once. The Go cases:
- `encoding/json` (v1) beside v2 (new-stdlib). Swapping the import can
  compile and still change the wire: v2 rejects invalid UTF-8 and
  duplicate object names, and encodes nil slices and maps as `[]` and
  `{}`, so sibling endpoints on different versions answer differently.
  A migration starts from `jsonv1.DefaultOptionsV1()`, adds tests of
  the encoded output and of the input still accepted, then removes the
  compatibility options one deliberate change at a time.
- Untyped `sync/atomic` functions beside typed atomics such as
  `atomic.Int64` and `atomic.Pointer[T]`, which new code uses: with
  the functions, one plain read of the value is a race. Replacing a
  raw field changes its type's layout and size, and `atomic.Value`
  treats nil and types differently from `atomic.Pointer[T]`, so a type
  migrates as one deliberate change. The go fix guard leaves out the
  `atomictypes` analyzer, which rewrites existing types.
- Benchmarks looping over `b.N` beside `for b.Loop()`, which new
  benchmarks use (modern-traps).

A migration moves every use of the old form and removes the entry
(Recorded Old Forms step 3). It changes behaviour, so it is a change of
its own, never mixed into feature work (Tidy or Change).
Source: owner rulings 2026-11-16 and R-2; JB `guidelines.json`
`json_v2`, `atomic_types`, `SKILL.md:50-52`; U "Use go.uber.org/atomic";
RN24; RN26; T `references/benchmarks.md:48-50`.
Differs: JB has new code follow the modern form even where nearby code
uses the old one, which is Consistent Beats Correct's Bad case; Uber
uses `go.uber.org/atomic`.
Rows: D 41; E 3, 4, 58, 59, 69; F 57, 58; G 30.

## Go pitfalls

**iface-grow.** Adding a method to an exported interface breaks every
type outside the package that implements it: the type no longer
satisfies the interface until it adds the method. Under Grow Don't
Break that is a breaking change, however additive it looks. Take the
first case that fits:
- The interface is in an `internal/` package, or in a module no one
  outside imports, so every implementer is yours: add the method, update
  every implementer in the same change, and let the compiler find
  them (Grow Don't Break step 4).
- Others implement it: grow the contract with a new interface beside
  the old one, which may embed it; consumers that need the new method
  ask for the new interface or check for it with a type assertion,
  and the old one keeps working, marked deprecated once the new one
  replaces it (steps 3 and 5).

A package that returns concrete types
(iface-consumer) adds methods to them without breaking anyone.
Embedding has the same trap: an exported struct that embeds a type
takes that type's methods into its contract, so embed only where every
exported method of the inner type belongs on the outer one, and never
embed a `sync.Mutex`.
Source: owner ruling R-5; CRC "Interfaces"; CU
`go-interfaces/SKILL.md:102-105`; U "Avoid Embedding Types
in Public Structs", "Embedding in Structs"; SI `SKILL.md:181-221`.
Rows: D 10, 43, 81, 82; G 170, 233.

**test-time.** `require.Equal` compares a `time.Time`'s location and
monotonic reading as well as its instant: the same instant in another
zone, or a value straight from `time.Now()`, is not equal. Builder
defaults and expected values are built with
`time.Date(..., time.UTC)` or from the injected clock. The inputs of a
UTC Computation step 5 test come from a zone east of UTC and one west
of it.
Source: owner comments 2026-09-08 09:58 and 2026-11-03 09:09; R
`exp_test.go`; TD `builders.md` "Concern methods".
Differs: TD builds times with `time.Parse`.
Rows: A 44, 57, 113.

**time-add.** `t.AddDate(0, 0, 1)` moves to the same clock time on the
next calendar day; `t.Add(24 * time.Hour)` moves exactly 24 hours.
Choose by intent. `AddDate` counts days in the value's own zone, so
convert into the computation's zone first (UTC Computation step 3).
Source: U "Use `time.Duration` for periods of time".
Differs: Uber does not mention the zone.
Rows: D 18.

**err-wrap-verb.** `%w` and `%v` differ by one character, and `%w`
passes the cause's identity on; `go vet` does not catch the
difference. A second `%w` passes on both. At the edge, where an
outside system's error is translated into our own identity, use `%v`.
Everywhere above the edge, wrap with a single `%w`. Two kinds of error
are always wrapped with `%w`, even at the edge, because they are the
caller's own and the caller may need to recognise them:
`context.Canceled` and `context.DeadlineExceeded`, and an error from a
collaborator the caller supplied, such as an `io.Reader` passed in.
`%v` leaves only a string, so a caller that needs the detail gets our
own error type, never a match on the text (Failure Identity steps
1-3).
Source: owner comment 2026-10-29 14:58; owner rulings 2026-11-16 and
S-2; ER "Whether to Wrap".
Rows: A 48; C2 35, 45, 46; D 28; F 39, 40; G 73, 229.

**err-unwrap.** An `Unwrap` method on an identity type passes the
cause's identity on, as `%w` does. So an error type that carries a
cause implements `Unwrap` only above the edge; at the edge it keeps
the outside message in `Error()` and has no `Unwrap`, except that ctx
errors stay reachable (err-wrap-verb).
Source: owner comment 2026-10-29 14:58; EH
`references/error-creation.md:140-157`.
Differs: EH implements `Unwrap` on every wrapping type.
Rows: A 49; G 90, 244.

**err-join-match.** `errors.Is` and `errors.As` match any member of an
`errors.Join`, so a caller can check a combined failure for one cause
(scrub-collect).
Source: owner comment 2026-10-29 14:58.
Rows: A 50; G 77.

**err-as-pointer.** `errors.As` into a value type silently misses an
error returned as a pointer.
Source: owner comment 2026-10-29 14:58; ER "Examining errors with Is
and As".
Rows: A 51; F 38.

**err-is-fresh-pointer.** `errors.Is(err, &T{})` compares pointers and
matches only if `T` defines an `Is` method. Check a typed failure with
`errors.As` into a pointer target, in tests `require.ErrorAs`.
Source: TD `conventions.md` "Error plus state" example.
Differs: the TD example uses `require.ErrorIs` with a fresh pointer.
Rows: A 87.

**err-timeout-ctx.** `net.Error.Timeout()` is also true when the
caller's own context hit its deadline: retry only when `ctx.Err()` is
nil. In a handler, a failed call with
`errors.Is(r.Context().Err(), context.Canceled)` means the client is
gone, so write nothing; when the handler's own deadline fired, the
client is still waiting, so answer 503 or 504.
Source: owner comment 2026-10-29 14:58; CX
`references/http-services.md:17-24`.
Differs: CX writes nothing whenever `ctx.Err()` is set.
Rows: A 52; G 109.

**err-equate-errors.** `cmpopts.EquateErrors` compares with
`errors.Is`, so a wrapped error equals a bare one.
Source: owner comment 2026-10-29 14:58.
Rows: A 53.

**err-compare.** Because err-wrap-where wraps every error that crosses
a unit, `err == ErrX`, a type assertion or a type switch on an error
stops matching as soon as a callee wraps. Compare with
`errors.Is(err, ErrX)` for a sentinel and `errors.As`, or
`errors.AsType[T]` from Go 1.26, for a type. `errors.Unwrap` returns
nil for an error that wraps several, from `errors.Join` or several
`%w`, so don't inspect a chain with it. A function documented to
return an error wrapping a sentinel never returns the bare sentinel,
so its callers cannot come to rely on `==`.
Source: ER "Examining errors with Is and As", "Errors and package
APIs"; BP "Error structure", "Adding information to errors"; JB
`guidelines.json` `errors_is`; EH `references/error-wrapping.md:50-80`.
Differs: BP allows `==` where a function returns sentinels unwrapped.
Rows: C2 34, 44; E 64; F 30, 36, 37, 44; G 74, 75, 169.

**err-check.** Check every returned error. Discard one with `_` only
where it cannot fail, with a comment saying why:
`n, _ := b.Write(p) // bytes.Buffer.Write never fails`. A bare
`defer f.Close()` discards Close's error, which for a file that was
written can be the only report that the write failed: use it only for
a file that was only read, and close a written file explicitly on the
success path or in a deferred function that returns the error.
Source: EG "Defer", "The blank identifier"; CRC "Handle Errors";
D:1142-1163; EH `SKILL.md:40`; SF eval 27.5.
Differs: EG's example defers `f.Close()` whether or not the file was
written; CRC and EH never allow `_`.
Rows: B 49; C1 57, 58; D 13; F 17, 24; G 66, 211, 226.

**nil-slice-want.** `require.Equal` tells a nil slice from an empty
one. No API makes its callers tell them apart: callers test
`len(s) == 0`, and a function returns `nil` for an empty result unless
its contract, such as a JSON field that must encode as `[]`, needs a
non-nil one. A test's `want` matches the nil-ness the code returns; a
nil/empty mismatch is a bug in the test, not behaviour to pin.
Source: D:1682-1739; CRC "Declaring Empty Slices"; U "nil is a valid
slice".
Rows: B 42, 43; C1 71; D 84, 85, 86, 87, 88.

**share-backing.** A slice or map shares its backing data with every
copy of it, and `append` writes into the existing array when it has
room. A function that keeps one it received sees the caller's later
changes, and one that returns one it holds lets the caller change its
state, outside any lock that guards it. An exported function that
returns a slice or map the type keeps returns a copy (`slices.Clone`,
`maps.Clone`) unless its documentation says not to modify it, and one
that keeps a caller's slice or map stores a copy; this is what
compliance-suite's returned-copy scenario checks.
Source: U "Copy Slices and Maps at Boundaries"; SF `SKILL.md:95-107`,
`:188-208`; CU `go-defensive/SKILL.md:25-65`.
Rows: D 11, 12; G 186, 188, 189, 190, 259.

**t-context-cleanup.** `t.Context()` is cancelled before the test's
`t.Cleanup` functions run. Cleanup that needs a context, such as a
compliance-suite factory's, uses `context.WithoutCancel(ctx)`.
Source: JB `guidelines.json` `testing_t_context`; D:2920-2923.
Rows: C1 118; E 16.

**testify-traps.** testify takes `(expected, actual)`, and
`ErrorIs(err, target)`; swapped, the diff reads backwards. Inside
`t.Run`, assert with the subtest's `t`: an `assert.New` or
`require.New` built from the parent's `t` reports a subtest's failure
against the parent, and the failing subtest prints PASS. `require.*`,
`t.Fatal` and `t.FailNow` work only on the test's own goroutine: a
goroutine the test starts sends its result on a channel, the test
asserts after receiving it, and code that runs elsewhere, such as an
`httptest` handler or a double the code calls, reports with `t.Error`.
Source: TF `SKILL.md:108`, `:189`; T `SKILL.md:145-171`; BP "Don't
call t.Fatal from separate goroutines"; CU `go-testing/SKILL.md:82-83`;
U "Don't Panic".
Rows: C2 125; G 22, 52, 219, 241.

**modern-traps.** Some modern forms (modern-forms) behave differently
from the code they replace:
- `cmp.Or` evaluates every argument, so not where a later one is
  costly or has side effects, or where `0` or `false` is a valid
  answer.
- `slices.SortFunc` is not stable: code that used `sort.SliceStable`
  moves to `slices.SortStableFunc`.
- `slices.Compact` removes only consecutive duplicates; sort or group
  equal values first to remove all.
- With `b.Loop()`, `b.N` holds the count only after the loop ends, so
  a benchmark that sizes its fixtures from `b.N` is restructured, not
  converted line by line.
- In `for _, v := range s`, `&v` points at that iteration's copy; take
  `&s[i]` for the element.

Source: JB `guidelines.json` `cmp_or`, `slices_sort_func`,
`slices_compact`, `testing_b_loop`, `loopvar_capture`.
Rows: E 19, 20, 28, 29, 38, 43.

## Go style

**modern-forms.** New code uses the current standard-library form over
a hand-written equivalent, as the go fix guard does for the forms it
covers (tool-guards). The ones it does not cover: `strings.CutLast`
and `bytes.CutLast` over `LastIndex` and slicing; `URL.Clone` and
`Values.Clone` over field-by-field copies; `clear`, `slices.Index`,
`slices.IndexFunc`, `slices.Reverse`, `slices.Compact`, `slices.Clip`,
`slices.Clone`, `bytes.Clone`, `maps.Clone`, `maps.DeleteFunc`, and
`slices.Max` and `slices.Min` on a non-empty slice; `slices.SortFunc`
with `cmp.Compare` over `sort.Slice`; ranging over a map directly,
`slices.Collect` only where a slice is needed and `slices.Sorted` where
it must be sorted; `fmt.Appendf` to append formatted text;
`strings.Clone` for a small string kept from a large one;
`sync.OnceFunc` and `sync.OnceValue` over `sync.Once` with a wrapper;
`context.AfterFunc` over a goroutine that only waits on `ctx.Done()`;
the `Cause` variants of `context.WithCancel`, `WithTimeout` and
`WithDeadline` where `ctx.Err()` is too coarse for a caller; `cmp.Or`
for a fallback chain; `for b.Loop()` in new benchmarks; and
method-aware `ServeMux` patterns, `"GET /orders/{id}"`, with
`r.PathValue`. See modern-traps.
Source: JB `guidelines.json`; RN24; RN26; CX
`references/cancellation.md:146-161`; ES `go-context/SKILL.md:213-219`;
SF `SKILL.md:222-238`.
Differs: JB rewrites a plain map range into `maps.Keys`; SF uses
`sync.Once` for lazy initialisation.
Rows: E 7, 10, 22, 23, 24, 29, 31, 33, 35, 36, 37, 40, 41, 42, 44, 45,
46, 48, 49, 50, 51, 52, 53, 56, 57, 62; G 108, 198, 251.

**goroutines.** Code that starts a goroutine has a way to wait for it
to exit, a `sync.WaitGroup` for several or a `done` channel the
goroutine closes for one, and a predictable end or a signal that stops
it. A package that needs a background goroutine starts it only when
the caller creates the object that owns it, and that object has a
method such as `Close` that stops the goroutine and waits for it.
Source: U "Don't fire-and-forget goroutines", "Wait for goroutines to
exit", "No goroutines in `init()`"; CRC "Goroutine Lifetimes";
D:2243-2297.
Differs: CRC and the Google guide accept documenting when a goroutine
exits; we require a way to wait, which goleak can then check.
Rows: B 48; C1 86; D 50, 52, 53.

**log-style.** Log with `log/slog` through the logger in ctx
(ctx-scope), never `fmt.Println` or `log.Printf`. A log message is a
fixed string; IDs, paths and counts go in attributes, and an error
goes under an `err` attribute. An error's own message still names its
values (Failure Identity step 5). Handle an error once: the unit that
handles it logs it, and a unit that returns it does not also log it.
A server logs each request through middleware, with its method, path,
status and duration as attributes.
Source: EH `SKILL.md:46-54`, `references/error-handling.md:12-48`; U
"Error Wrapping"; BP "Logging errors".
Differs: EH prefers static log messages with a "sometimes" exit.
Rows: C2 51, 52, 53, 54; D 31, 34; G 79, 83, 85, 88.

**chan-size.** A channel is unbuffered or has a buffer of one. Any
other size carries a comment saying how the size was chosen, what
keeps the channel from filling under load, and what its writers do
when it is full. A large buffer hides backpressure: writers run ahead
until it fills, and the stall then shows up under load, far from its
cause (Fail Early and Loud).
Source: owner ruling 2026-11-17 (Q3); U "Channel Size is One or None".
Differs: U asks only for scrutiny of other sizes; we require the
comment.
Rows: D 14.

**enum-start.** An `iota` enum starts at one, `Add Operation = iota +
1`, so an unset value is not a valid member and is caught (Fail Early
and Loud). Start at zero only where the zero value is the right
default.
Source: owner ruling 2026-11-17 (Q3); U "Start Enums at One"; CU
`go-defensive/SKILL.md:30`.
Differs: the standard sources start `iota` at zero in their examples
and set no rule.
Rows: D 15; G 254.

**flag-names.** Command-line flag names are kebab-case,
`--max-retries`.
Source: owner ruling S-10.
Differs: the Google guide names flags in snake_case.
Rows: C1 108.

**no-dot-import.** No file uses `import .`, test files included: the
package qualifier shows where a name comes from (Be Your Name).
Source: EG "Package names"; CRC "Import Dot".
Differs: EG and CRC allow it in a test that would otherwise create an
import cycle.
Rows: B 53; F 7.

## For the protocols

**proto-packages.** No package named for a technical role (utils,
helpers, common, models, types). Sibling domain packages never import
each other; a coordinating package or a shared interface sits between
them.
Source: bs-01o; P0 slice 2 brief.
Rows: A 3, 5, 71; B 68; C1 19; C2 22; D 68; G 134.

**proto-bb-budget.** One happy and one unhappy black-box test per
feature boundary. It is a budget, not a cap: a third test must show
that no unit test could catch what it checks. The unhappy test covers
the failure with the largest blast radius a consumer could hit: data
loss, then wrong result, then degraded experience, then cosmetic.
Source: bs-6nd; owner ruling 2026-11-16.
Rows: A 12.

**proto-flag-expiry.** A rollout flag carries a dated expiry marker in
the code that tooling can find and escalate when the date passes.
Source: bs-9sn.
Rows: A 24.

**proto-tidy.** Classify each changeset as structural or behavioural,
commit structural ones first, and split pull requests along that line.
A structural changeset passes `go test ./...` with no test file changed
beyond renames that follow the code.
Source: bs-jo0.
Rows: A 34, 35, 36, 37.

## Sources

Table keys, for "Rows:" (all in `languages/go/decisions/`): A
`bjornstack.md`, B `go-wiki.md`, C1 `google-guide-decisions.md`, C2
`google-best-practices.md`, D `uber.md`, E `jetbrains-modern.md`, F
`go-team-docs.md`, G `community-skills.md`. Each table pins its
sources in full; the pins below are the short form.

Source keys, for "Source:":

| Key | Source | Pin |
|---|---|---|
| owner comment, owner ruling | Comments on bs-f3o.2 by date and time; rulings S-1 to S-13 and R-1 to R-5 are in its comments "Owner rulings from go-decisions (2026-11-17)" and "Owner rulings, round 2 (2026-11-17)"; the rulings of 2026-11-04 are recorded on bs-f3o.2.1 and in `bjornstack.md`, "Owner rulings"; rulings Q2 and Q3 of 2026-11-17 are in a comment on bs-f3o.2.9 | read 2026-11-17 |
| bs-01o, bs-6nd, bs-8bi, bs-8jx, bs-9sn, bs-bq9, bs-jo0 | Superseded Go guideline beads, description | closed 2026-03-21, read 2026-11-03 |
| bs-luj | Bead comment, 2026-11-17 11:46 | read 2026-11-17 |
| P0 | Phase 0 implementer briefs | briefkasten `b4bc5df`, read 2026-11-03 |
| TD | workflow test-design Go references | plugin 1.16.0, read 2026-11-03 |
| R | `tmp/research/bs-f3o.2/exp_test.go` | read 2026-11-03 |
| EG | Effective Go, go.dev/doc/effective_go | read 2026-11-16 |
| CS | "Contexts and structs", go.dev/blog/context-and-structs | posted 2021-02-24, read 2026-11-16 |
| ER | "Working with Errors in Go 1.13", go.dev/blog/go1.13-errors | posted 2019-10-17, read 2026-11-16 |
| ML | "Organizing a Go module", go.dev/doc/modules/layout | read 2026-11-16 |
| RN21-RN27 | Go 1.21 to 1.27 release notes, go.dev/doc/go1.NN | read 2026-11-16 |
| TC, CRC | Go Wiki Test Comments and Code Review Comments | `go.googlesource.com/wiki` `fe2268bb04c9`, read 2026-11-16 |
| G, D, BP | Google Go style guide: `go/guide.md`, `go/decisions.md` (cited D:line), `go/best-practices.md` | `github.com/google/styleguide` `a9c5f82b1981`, read 2026-11-16 |
| U | Uber Go Style Guide, `style.md` | `github.com/uber-go/guide` `1d60a91aa5e8`, read 2026-11-16 |
| JB | JetBrains go-modern-guidelines | `github.com/JetBrains/go-modern-guidelines` `155dc7c`, read 2026-11-16 |
| T, TF, EH, CX, PL, SI, SF | samber/cc-skills-golang skills: golang-testing, -stretchr-testify, -error-handling, -context, -project-layout, -structs-interfaces, -safety | `github.com/samber/cc-skills-golang` `d68d80a`, read 2026-11-16 |
| CU | cxuu/golang-skills | `github.com/cxuu/golang-skills` `91f0c2e`, read 2026-11-16 |
| ES | eduardo-sl/go-agent-skills | `github.com/eduardo-sl/go-agent-skills` `e25b517`, read 2026-11-16 |

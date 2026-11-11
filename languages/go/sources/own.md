# Go sources A: our own material

Decision table for bs-f3o.2.1. It reviews the Go material bjornstack
already holds and decides, item by item, what goes into
`languages/go.md`. Later source tables (bs-f3o.2.2 to bs-f3o.2.8) mark
a rule "already ours" against the ids below.

Read 2026-11-03. Strategy text was judged at bjornstack commit
`e31ec16`, which includes the Scrub on Entry record cap (`4c0125e`,
`e31ec16`) and the Unit Testing transform rule (`3109d37`).

## Sources and pins

| Key | Source | Pin |
|---|---|---|
| bs-01o, bs-6nd, bs-8bi, bs-8jx, bs-9sn, bs-bq9, bs-jo0 | Superseded Go guideline beads, description field | Closed 2026-03-21; no comments |
| O-0908a, O-0908b | bs-f3o.2 comments | 2026-09-08 09:04, 2026-09-08 09:58 |
| O-1019, O-1021 | bs-f3o.2 comments | 2026-10-19 16:32, 2026-10-21 06:36 |
| O-1029a, O-1029b | bs-f3o.2 comments | 2026-10-29 14:58, 2026-10-29 17:31 |
| O-1103a, O-1103b | bs-f3o.2 comments | 2026-11-03 08:45, 2026-11-03 09:09 |
| P0 | Phase 0 implementer briefs, first user turn of each subagent: slice 2 `agent-a4e4a813f09ea8762`, slice 3 `agent-a0e611cff0e066e21`, slice 4 `agent-aab46041c0a48a71b`, slice 5 `agent-a3b72e195dfdec755`, slice 6 `agent-a04f9908297c42ead`, slice 7 `agent-a8d58bb75b68de066`; RFC extracts `agent-a4a1b3d29ccd46981`, `agent-adf0f5a58e9cc9a90` | `~/workspace/briefkasten--2026-09-07` commit `b4bc5df`, `implementation-transcript.tbz` (sha256 `fb65827c811e`), `transcript/subagents/` |
| TD | test-design Go references, `skills/test-design/references/go/` | workflow plugin 1.16.0 (plugin cache, not a git checkout): `conventions.md` sha256 `929148350cb2`, `builders.md` `bdd5ee101e22`, `mocks.md` `92bf76dc7396`, `compliance-tests.md` `f72d69bf855d` |
| R | `tmp/research/bs-f3o.2/` | `exp_test.go` (require vs cmp.Diff experiment), `fixexp/` (go fix experiment); no written notes |

## Decision table

"Lands in" names the go.md section: Tooling, Pattern mappings, Go
pitfalls, or For the protocols (material bs-y5h turns into protocol
steps).

| # | Source | Item | Decision | Reason | Rule id | Lands in |
|---|---|---|---|---|---|---|
| <a id="row-1"></a>1 | bs-01o | Package naming conventions | keep | Go spelling of Domain-First Packaging steps 1-2 and 4 | [pkg-naming](#rule-pkg-naming) | Pattern mappings |
| <a id="row-2"></a>2 | bs-01o | `internal/` usage patterns | keep | Go's mechanism for Intentionally Public step 4 and Public API Surface Testing step 2 | [pkg-internal](#rule-pkg-internal) | Pattern mappings |
| <a id="row-3"></a>3 | bs-01o | Banned package names (utils, helpers, common) | keep | bs-f3o.2 acceptance assigns it to For the protocols | [proto-packages](#rule-proto-packages) | For the protocols |
| <a id="row-4"></a>4 | bs-01o | Smurf-naming avoidance | keep | Domain-First Packaging step 4; Go's qualified names make the echo visible | [pkg-naming](#rule-pkg-naming) | Pattern mappings |
| <a id="row-5"></a>5 | bs-01o | Dependency direction enforcement | keep | bs-f3o.2 acceptance assigns it to For the protocols | [proto-packages](#rule-proto-packages) | For the protocols |
| <a id="row-6"></a>6 | bs-01o | Guard candidates: lint banned names, exports echoing the package, external types in domain signatures | drop | Guards are their own layer (bs-ws1), not language configuration | [dropped](#drop-6) | — |
| <a id="row-7"></a>7 | bs-6nd | Test infrastructure: testcontainers or docker-compose | keep | Named in bs-f3o.2 acceptance; Black Box Integration step 2 needs the service's own infrastructure running for real | [tool-bb-infra](#rule-tool-bb-infra) | Tooling |
| <a id="row-8"></a>8 | bs-6nd | HTTP test client patterns | keep | Named in bs-f3o.2 acceptance; Go spelling of Black Box Integration step 1 | [bb-http](#rule-bb-http) | Pattern mappings |
| <a id="row-9"></a>9 | bs-6nd | External service stubbing | adapt | The bead names no mechanism; `httptest.Server` is the stdlib form of step 2's stub across the service boundary | [bb-http](#rule-bb-http) | Pattern mappings |
| <a id="row-10"></a>10 | bs-6nd | Data scoping for parallel execution | keep | Black Box Integration step 3 and Isolated Test Execution; in Go this is `t.Parallel` plus a per-test identity | [bb-parallel](#rule-bb-parallel) | Pattern mappings |
| <a id="row-11"></a>11 | bs-6nd | Test file organization by feature | keep | Black Box Integration step 4 | [bb-package](#rule-bb-package) | Pattern mappings |
| <a id="row-12"></a>12 | bs-6nd | Happy/unhappy path budget | keep | bs-f3o.2 acceptance assigns it to For the protocols | [proto-bb-budget](#rule-proto-bb-budget) | For the protocols |
| <a id="row-13"></a>13 | bs-8bi | Default to `_test` packages | keep | Public API Surface Testing step 1; named in bs-f3o.2 acceptance | [test-pkg](#rule-test-pkg) | Pattern mappings |
| <a id="row-14"></a>14 | bs-8bi | `internal/` packages over exporting details | keep | Intentionally Public step 4 | [pkg-internal](#rule-pkg-internal) | Pattern mappings |
| <a id="row-15"></a>15 | bs-8bi | Smurf naming handled under BYN (bs-n5q) | drop | Pointer, not a rule; row 4 covers the naming rule | [dropped](#drop-15) | — |
| <a id="row-16"></a>16 | bs-8bi | Make step 4 (design signal, restructure) concrete for Go | adapt | Concrete form is the three exits in Public API Surface Testing step 2, spelled with Go's package tools | [pkg-internal](#rule-pkg-internal) | Pattern mappings |
| <a id="row-17"></a>17 | bs-8jx | Struct validation: tags vs custom validators | adapt | Owner ruled 2026-11-04: tags (library or hand-made) or plain Go are all allowed on the input struct, provided the rejection meets Scrub on Entry step 4; no source argued against tags | [scrub-validate](#rule-scrub-validate) | Pattern mappings |
| <a id="row-18"></a>18 | bs-8jx | Cross-field validation patterns | keep | Scrub on Entry step 3 includes relationships between fields | [scrub-validate](#rule-scrub-validate) | Pattern mappings |
| <a id="row-19"></a>19 | bs-8jx | Collecting errors into a multi-error response | adapt | Must follow the current Scrub on Entry step 4 (full record, cap between records, counts in the rejection) and Failure Identity step 4 and its "combined failure checked for one cause" misapplication (`failure-identity.md:95-96`), which forbids a caller branching on one member, not Join itself (owner, 2026-11-04) | [scrub-collect](#rule-scrub-collect) | Pattern mappings |
| <a id="row-20"></a>20 | bs-8jx | Request struct to domain struct conversion | keep | Scrub on Entry steps 5-6; Domain-First Packaging step 6 | [scrub-boundary](#rule-scrub-boundary) | Pattern mappings |
| <a id="row-21"></a>21 | bs-8jx | Where validation lives in the package structure | keep | Scrub on Entry rationale "Relationship to Domain-First Packaging" | [scrub-boundary](#rule-scrub-boundary) | Pattern mappings |
| <a id="row-22"></a>22 | bs-9sn | Flag test helper (run the same test with the flag on and off) | keep | Flag Your Changes step 3; named in bs-f3o.2 acceptance | [flag-test](#rule-flag-test) | Pattern mappings |
| <a id="row-23"></a>23 | bs-9sn | Flag naming convention format | drop | Flag Your Changes step 2 already says it and nothing about it is Go-specific | [dropped](#drop-23) | — |
| <a id="row-24"></a>24 | bs-9sn | Code-level expiry marker format (remembrall-style) | keep | bs-f3o.2 acceptance assigns it to For the protocols | [proto-flag-expiry](#rule-proto-flag-expiry) | For the protocols |
| <a id="row-25"></a>25 | bs-9sn | Mechanical flag removal tooling | drop | No such tool exists; it is a guard or tooling project, not configuration | [dropped](#drop-25) | — |
| <a id="row-26"></a>26 | bs-9sn | Flag config file schema | drop | Lives in the flag system's config (Flag Your Changes step 2), not in Go code | [dropped](#drop-26) | — |
| <a id="row-27"></a>27 | bs-bq9 | `test/a/` package | keep | Test Data Builders step 2's single entry point | [builders-a](#rule-builders-a) | Pattern mappings |
| <a id="row-28"></a>28 | bs-bq9 | `With*` modifier naming | keep | Test Data Builders step 4 | [builders-a](#rule-builders-a) | Pattern mappings |
| <a id="row-29"></a>29 | bs-bq9 | `Build()` returns a value, not a pointer | keep | Each build is independent state (Test Data Builders step 1) | [builders-a](#rule-builders-a) | Pattern mappings |
| <a id="row-30"></a>30 | bs-bq9 | `Modify()` escape hatch | keep | Test Data Builders step 4's mutation mechanism | [builders-a](#rule-builders-a) | Pattern mappings |
| <a id="row-31"></a>31 | bs-bq9 | Static UUIDs for reproducibility | keep | Isolated Test Execution step 3 (deterministic data) | [builders-ids](#rule-builders-ids) | Pattern mappings |
| <a id="row-32"></a>32 | bs-bq9 | Concern method naming `Persisted()`, `Invalid()` | adapt | Test Data Builders steps 5-6 split these: `Persisted` is a state method, `Invalid` becomes named edge cases; owner ruled 2026-11-04 for `Persisted()`, no `Is` prefix (row 120) | [builders-states](#rule-builders-states) | Pattern mappings |
| <a id="row-33"></a>33 | bs-bq9 | SUT options pattern as lighter alternative | keep | Same pattern as TD's options function | [test-sut-options](#rule-test-sut-options) | Pattern mappings |
| <a id="row-34"></a>34 | bs-jo0 | Classify structural vs behavioural changes in Go | keep | bs-f3o.2 acceptance assigns it to For the protocols | [proto-tidy](#rule-proto-tidy) | For the protocols |
| <a id="row-35"></a>35 | bs-jo0 | Commit sequencing practices | keep | Tidy or Change steps 3-4; protocol material | [proto-tidy](#rule-proto-tidy) | For the protocols |
| <a id="row-36"></a>36 | bs-jo0 | Verify structural purity via test stability | keep | Tidy or Change step 5, spelled for Go | [proto-tidy](#rule-proto-tidy) | For the protocols |
| <a id="row-37"></a>37 | bs-jo0 | Patterns for splitting Go PRs | keep | bs-f3o.2 acceptance assigns it to For the protocols | [proto-tidy](#rule-proto-tidy) | For the protocols |
| <a id="row-38"></a>38 | bs-jo0 | Guard: CI flags PRs mixing structural and behavioural diffs | drop | Guard layer (bs-ws1) | [dropped](#drop-38) | — |
| <a id="row-39"></a>39 | O-0908a | Assertion library: testify `require.*` over `assert.*` | keep | Owner preference, confirmed by O-1103b | [test-require](#rule-test-require) | Tooling |
| <a id="row-40"></a>40 | O-0908a | Granularity: code longer and less broken down than wanted | drop | Tested and refuted on bs-iyx (median function body 12-15 lines); the real problem, parameter width, is now Unit Testing steps 2.1 and 3.2 | [dropped](#drop-40) | — |
| <a id="row-41"></a>41 | O-0908a | `package foo_test` is settled by Public API Surface Testing step 1 | keep | go.md only names the Go spelling and points at the strategy | [test-pkg](#rule-test-pkg) | Pattern mappings |
| <a id="row-42"></a>42 | O-0908a | Method note: harvest the Phase 0 briefs | drop | Pointer to a source; its content is rows 61-79 | [dropped](#drop-42) | — |
| <a id="row-43"></a>43 | O-0908b | Do not reserve a role for `cmp.Diff` without reading testify's source | adapt | Settled by O-1103b and R: `require.Equal` everywhere, `cmp.Diff` only for protobuf messages | [test-protobuf](#rule-test-protobuf) | Tooling |
| <a id="row-44"></a>44 | O-0908b | `require.Equal` compares `time.Time` fields, not the instant | keep | Confirmed by R; it is why O-1103b chose require, so go.md states it as a pitfall | [test-time](#rule-test-time) | Go pitfalls |
| <a id="row-45"></a>45 | O-0908b | `require` stops at the first failure, weakening loops over `errors.Join` causes | adapt | Answer is one comparison over all causes, not a loop of `ErrorIs`; also follows Failure Identity step 6 | [scrub-collect](#rule-scrub-collect) | Pattern mappings |
| <a id="row-46"></a>46 | O-1019 | `context.Context` passed per call, not stored, as the exception to Unit Testing 3.2 | keep | Owner decision; Unit Testing 3.2 at `e31ec16` still says a coordinator never hands on a set-up value | [ctx-per-call](#rule-ctx-per-call) | Pattern mappings |
| <a id="row-47"></a>47 | O-1021 | ctx is a narrowly scoped global: cancellation and program-wide per-goroutine settings only | keep | Owner decision; matches Unit Testing 3.2's logging/metrics exception | [ctx-scope](#rule-ctx-scope) | Pattern mappings |
| <a id="row-48"></a>48 | O-1029a | `%w` vs `%v`, and a second `%w`, leak a cause's identity | keep | Go form of Failure Identity step 3 | [err-wrap-verb](#rule-err-wrap-verb) | Go pitfalls |
| <a id="row-49"></a>49 | O-1029a | An `Unwrap` method on an identity type leaks the cause | keep | Same | [err-unwrap](#rule-err-unwrap) | Go pitfalls |
| <a id="row-50"></a>50 | O-1029a | `errors.Is`/`As` match any member of `errors.Join` | keep | Go form of Failure Identity's "combined failure checked for one cause" | [err-join-match](#rule-err-join-match) | Go pitfalls |
| <a id="row-51"></a>51 | O-1029a | `errors.As` into a value type misses a pointer error | keep | Owner-recorded trap | [err-as-pointer](#rule-err-as-pointer) | Go pitfalls |
| <a id="row-52"></a>52 | O-1029a | `net.Error.Timeout()` is true for the caller's own deadline | keep | Owner-recorded trap | [err-timeout-ctx](#rule-err-timeout-ctx) | Go pitfalls |
| <a id="row-53"></a>53 | O-1029a | `cmpopts.EquateErrors` compares with `errors.Is` | keep | Owner-recorded trap; matters for protobuf tests (row 43) | [err-equate-errors](#rule-err-equate-errors) | Go pitfalls |
| <a id="row-54"></a>54 | O-1029b | Search for existing Go skills first, then include or mine them | drop | Process step, done 2026-11-03 (O-1103b); the mining happens in bs-f3o.2.6 and bs-f3o.2.8 | [dropped](#drop-54) | — |
| <a id="row-55"></a>55 | O-1103a | Writing waits for bs-z6h | drop | Sequencing; bs-z6h landed in `4c0125e` and `e31ec16`, and row 19 follows it | [dropped](#drop-55) | — |
| <a id="row-56"></a>56 | O-1103b | Sources: no official Go skill; install none | drop | Decides which source tables exist, not a go.md rule | [dropped](#drop-56) | — |
| <a id="row-57"></a>57 | O-1103b | Assertions: require; test times via `time.Date` in UTC or the injected clock; protobuf via `cmp.Diff` + `protocmp.Transform` | keep | Owner decision | [test-require](#rule-test-require), [test-time](#rule-test-time), [test-protobuf](#rule-test-protobuf) | Tooling, Go pitfalls |
| <a id="row-58"></a>58 | O-1103b | Rejected assertion libraries and why | drop | Rationale for row 57; stays on the bead | [dropped](#drop-58) | — |
| <a id="row-59"></a>59 | O-1103b | Clock: injected by default, `testing/synctest` allowed where injecting is awkward | keep | Owner decision; Whole-Object Assertion step 2's first choice | [clock-inject](#rule-clock-inject) | Pattern mappings |
| <a id="row-60"></a>60 | O-1103b | Format `languages/<lang>.md`; citation format | drop | Govern docs/WORKFLOW.md (bs-f3o.2) and this file, not Go code | [dropped](#drop-60) | — |
| <a id="row-60a"></a>60a | O-1103b | `encoding/json/v2` and a stdlib uuid for new code on Go 1.27 | adapt | Owner said yes pending a release-notes check, which is outside this bead's pinned sources; carried as conditional until bs-f3o.2.7 checks it | [new-stdlib](#rule-new-stdlib) | Tooling |
| <a id="row-61"></a>61 | P0 | Outside-in order: black-box test first, then coordinator, then computation | drop | Outside-In Development Loop says it for every language | [dropped](#drop-61) | — |
| <a id="row-62"></a>62 | P0 | Black-box test imports no production package; parses output with its own local structs | keep | Black Box Integration step 1, spelled for Go | [bb-package](#rule-bb-package) | Pattern mappings |
| <a id="row-63"></a>63 | P0 | Tests live outside the package; no test files in the package itself; unexported code reached through the public surface | keep | Public API Surface Testing step 1 | [test-pkg](#rule-test-pkg) | Pattern mappings |
| <a id="row-64"></a>64 | P0 | Table tests carry an assertion function per case; no conditionals in a test body | keep | Parameterized Test Structure steps 3-4 | [test-table](#rule-test-table) | Pattern mappings |
| <a id="row-65"></a>65 | P0 | Every field present in every table case | keep | Parameterized Test Structure step 2 | [test-table](#rule-test-table) | Pattern mappings |
| <a id="row-66"></a>66 | P0 | Whole-object assertions with `cmp.Diff` | adapt | Owner chose `require.Equal` (O-1103b); `cmp.Diff` hides a time-zone mismatch | [test-whole-value](#rule-test-whole-value) | Pattern mappings |
| <a id="row-67"></a>67 | P0 | Case names read as specifications | keep | Parameterized Test Structure step 2 | [test-names](#rule-test-names) | Pattern mappings |
| <a id="row-68"></a>68 | P0 | Errors name the offending value; collect every violation with `errors.Join` | adapt | Naming values is Failure Identity step 5; Join stays fine inside a layer; where a caller branches, rows 19 and 50 apply | [scrub-collect](#rule-scrub-collect) | Pattern mappings |
| <a id="row-69"></a>69 | P0 | Coordinators receive collaborators; tests replace all of them | keep | Unit Testing steps 3.2-3.3 | [coord-inject](#rule-coord-inject) | Pattern mappings |
| <a id="row-70"></a>70 | P0 | Comments explain why, not what | drop | Language-neutral; bs-cbr's strategy owns where reasoning lives, and bs-iyx found the run over-commented | [dropped](#drop-70) | — |
| <a id="row-71"></a>71 | P0 | No utils/helpers/common packages | keep | Same rule as row 3 | [proto-packages](#rule-proto-packages) | For the protocols |
| <a id="row-72"></a>72 | P0 | No new dependencies beyond go.mod | drop | A fence for that run; it is what kept testify out | [dropped](#drop-72) | — |
| <a id="row-73"></a>73 | P0 | Do not extract a shared atomic-write helper at two cases | drop | Earned Abstraction's rule, applied to one codebase; nothing Go-specific | [dropped](#drop-73) | — |
| <a id="row-74"></a>74 | P0 | No `time.Now()` inside a package; the clock is a parameter | keep | Whole-Object Assertion step 2; UTC Computation step 2 | [clock-inject](#rule-clock-inject) | Pattern mappings |
| <a id="row-75"></a>75 | P0 | A black-box helper runs the binary with a subcommand and reports its output on failure | keep | Go form of Black Box Integration step 1 for a CLI | [bb-package](#rule-bb-package) | Pattern mappings |
| <a id="row-76"></a>76 | P0 | Black-box setup may write the published bytes directly; no test-only flags such as `--now` | keep | Public API Surface Testing misapplication "test-only flags"; the bytes are the real interface | [bb-setup](#rule-bb-setup) | Pattern mappings |
| <a id="row-77"></a>77 | P0 | Browser-driving black-box tests must not call `t.Parallel` | drop | A workaround found in one harness: running browser tests concurrently stalled navigations under the race detector, and a browser per test made it worse, so the cause was concurrency, not sharing (`bbtest/main_test.go:177-186` at `b4bc5df`); Black Box Integration step 3 still asks for parallel-safe tests | [dropped](#drop-77) | — |
| <a id="row-78"></a>78 | P0 | Finish criteria: `gofmt -l .` empty, `go vet ./...` clean, `go test ./... -count=1` passes, existing tests not weakened | keep | Mechanical, Go-specific | [tool-finish](#rule-tool-finish) | Tooling |
| <a id="row-79"></a>79 | P0 | RFC extract briefs and slice designs (atomic writes, versioned JSON) | drop | Design of one application, not Go conventions | [dropped](#drop-79) | — |
| <a id="row-80"></a>80 | TD conventions | Options function for overrides | keep | Test Data Builders "SKIP WHEN" small types; Highlight the Difference | [test-sut-options](#rule-test-sut-options) | Pattern mappings |
| <a id="row-81"></a>81 | TD conventions | Fluent builder in `test/a`; scenario as builder method | keep | Same as rows 27-30 | [builders-a](#rule-builders-a) | Pattern mappings |
| <a id="row-82"></a>82 | TD conventions | Whole-state comparison `require.Equal(t, want, got, "expected ...")` | keep | Owner decision O-1103b | [test-whole-value](#rule-test-whole-value) | Pattern mappings |
| <a id="row-83"></a>83 | TD conventions | Table: slice of cases, `t.Run`, strategy functions in the struct | keep | Same as row 64 | [test-table](#rule-test-table) | Pattern mappings |
| <a id="row-84"></a>84 | TD conventions | Mock: `testify/mock` with `.Test(t)`, or a function type | keep | Test Data Builders step 2: a double is often a single function | [coord-doubles](#rule-coord-doubles) | Pattern mappings |
| <a id="row-85"></a>85 | TD conventions | Retrying comparison `require.Eventually` | adapt | Fine for waiting on an asynchronous outcome in a black-box test; time-dependent logic uses the clock rule instead | [test-eventually](#rule-test-eventually) | Pattern mappings |
| <a id="row-86"></a>86 | TD conventions | Error plus state: two assertion functions, both always called | keep | Parameterized Test Structure step 3 for Go's `(value, error)` | [test-table](#rule-test-table) | Pattern mappings |
| <a id="row-87"></a>87 | TD conventions | Example `require.ErrorIs(t, err, &cart.UnknownTaxRate{})` | adapt | `errors.Is` against a fresh pointer matches only if the type defines `Is`; a typed failure is checked with `ErrorAs` | [err-is-fresh-pointer](#rule-err-is-fresh-pointer) | Go pitfalls |
| <a id="row-88"></a>88 | TD conventions | Rule 1: `package foo_test`; unexported code tested in `internal/`, or "as a noted deliberate choice" | adapt | Public API Surface Testing has no deliberate-choice exit: tests compile without unexported symbols | [test-pkg](#rule-test-pkg) | Pattern mappings |
| <a id="row-89"></a>89 | TD conventions | Rule 2: `Test<Type>_<Method>`; subtests as sentences | keep | Parameterized Test Structure step 2 | [test-names](#rule-test-names) | Pattern mappings |
| <a id="row-90"></a>90 | TD conventions | Rule 3: `require.*` over `assert.*`; `assert` only for deliberately independent failures | keep | Owner decision | [test-require](#rule-test-require) | Tooling |
| <a id="row-91"></a>91 | TD conventions | Rule 4: `t.Helper()` first in every assertion helper | keep | Named in bs-f3o.2 acceptance | [test-helper](#rule-test-helper) | Pattern mappings |
| <a id="row-92"></a>92 | TD conventions | Rule 5: messages say "expected X to Y" | keep | Assertion messages, not failure messages; no conflict with Failure Identity step 6 | [test-messages](#rule-test-messages) | Pattern mappings |
| <a id="row-93"></a>93 | TD conventions | Rule 6: inject a clock or id source; else assert the field changed, copy it over, compare whole | adapt | Add `testing/synctest` as the allowed second choice (O-1103b); the copy-over is Whole-Object Assertion's capture-and-verify | [clock-inject](#rule-clock-inject) | Pattern mappings |
| <a id="row-94"></a>94 | TD conventions | Rule 7: raw struct literal where a builder exists is a smell | keep | Test Data Builders step 7 | [test-whole-value](#rule-test-whole-value) | Pattern mappings |
| <a id="row-95"></a>95 | TD conventions | Interface compliance: exported suite taking a factory | adapt | See rows 96-101 | [compliance-suite](#rule-compliance-suite) | Pattern mappings |
| <a id="row-96"></a>96 | TD compliance | Exported `<Interface>Test(t, ctx, factory)`; `t.Run` by operation then scenario | keep | Compliance Test Suites steps 2-3 | [compliance-suite](#rule-compliance-suite) | Pattern mappings |
| <a id="row-97"></a>97 | TD compliance | Place the suite in a `_test.go` file in the interface's package | adapt | An implementation in another package cannot import a `_test.go` file, so the suite lives in an ordinary file of a test-only package | [compliance-suite](#rule-compliance-suite) | Pattern mappings |
| <a id="row-98"></a>98 | TD compliance | Each implementation wires its factory in a thin test | keep | Compliance Test Suites step 5 | [compliance-suite](#rule-compliance-suite) | Pattern mappings |
| <a id="row-99"></a>99 | TD compliance | Factory per test case, not a shared instance | keep | Compliance Test Suites step 2 | [compliance-suite](#rule-compliance-suite) | Pattern mappings |
| <a id="row-100"></a>100 | TD compliance | Standard CRUD scenarios table | adapt | Add step 3's returned-copy check and step 4's iteration over every declared edge case | [compliance-suite](#rule-compliance-suite) | Pattern mappings |
| <a id="row-101"></a>101 | TD compliance | Use only with two or more implementations | adapt | Compliance Test Suites step 1 also counts one stateful test double | [compliance-suite](#rule-compliance-suite) | Pattern mappings |
| <a id="row-102"></a>102 | TD mocks | Rule 1: mock direct collaborators, not transitive ones | keep | Unit Testing step 3.1 and its misapplication | [coord-inject](#rule-coord-inject) | Pattern mappings |
| <a id="row-103"></a>103 | TD mocks | Rule 2: about 2 tests per collaborator (2N) | adapt | Unit Testing step 3.4 at `e31ec16` says N+1 | [coord-count](#rule-coord-count) | Pattern mappings |
| <a id="row-104"></a>104 | TD mocks | Rule 3: at most 3-4 collaborators | adapt | Unit Testing step 3.1 prompts a look past four and has no ceiling | [coord-count](#rule-coord-count) | Pattern mappings |
| <a id="row-105"></a>105 | TD mocks | Smell 1: the only `if` in a coordinator is `if err != nil` | adapt | Unit Testing step 3.5 (`3109d37`) also extracts a transform that needs test cases of its own | [coord-logic](#rule-coord-logic) | Pattern mappings |
| <a id="row-106"></a>106 | TD mocks | Smell 2: calling methods on a passed-in object is a hidden collaborator | adapt | Under `3109d37` the test is whether the method needs its own cases; the example's `time.Now()` breaks clock-inject and UTC Computation step 2 | [coord-logic](#rule-coord-logic) | Pattern mappings |
| <a id="row-107"></a>107 | TD mocks | Smell 3: globals only for logging and metrics | adapt | Unit Testing step 3.2 limits it to diagnostic logging and metrics, not audit records; ctx carries the rest (O-1021) | [coord-globals](#rule-coord-globals) | Pattern mappings |
| <a id="row-108"></a>108 | TD mocks | Function types for single-method dependencies | keep | Test Data Builders step 2 | [coord-doubles](#rule-coord-doubles) | Pattern mappings |
| <a id="row-109"></a>109 | TD mocks | `mock.Test(t)` on every testify mock | keep | Unexpected calls fail instead of panicking | [coord-doubles](#rule-coord-doubles) | Pattern mappings |
| <a id="row-110"></a>110 | TD mocks | Builder for complex mock setups, `Build(t)` | keep | Highlight the Difference; the builder stays in the test file (Test Data Builders step 2) | [coord-doubles](#rule-coord-doubles) | Pattern mappings |
| <a id="row-111"></a>111 | TD builders | Constructor applies the common states; `a.X().Build()` is usable | keep | Test Data Builders step 1 | [builders-a](#rule-builders-a) | Pattern mappings |
| <a id="row-112"></a>112 | TD builders | Concern methods `IsValid`, `IsSaved`, `IsNotSaved`, `IsInvalid` (zeroed) | adapt | `IsInvalid` as a zeroed value is not a declared edge case (Test Data Builders step 6); the `Is` prefix reads like a check, not a setup step, so states are named `Persisted()` (owner, 2026-11-04) | [builders-states](#rule-builders-states) | Pattern mappings |
| <a id="row-113"></a>113 | TD builders | `IsSaved` builds times with `time.Parse(time.RFC3339, "...Z")` | adapt | O-1103b: `time.Date(..., time.UTC)` | [test-time](#rule-test-time) | Go pitfalls |
| <a id="row-114"></a>114 | TD builders | Panicking stubs for concerns not written yet | keep | Fails loudly instead of guessing a default | [builders-a](#rule-builders-a) | Pattern mappings |
| <a id="row-115"></a>115 | TD builders | No doc comments on builder methods | keep | Names carry the meaning | [builders-a](#rule-builders-a) | Pattern mappings |
| <a id="row-116"></a>116 | TD builders | Nested builders compose; parent takes built children | keep | Test Data Builders step 3 | [builders-a](#rule-builders-a) | Pattern mappings |
| <a id="row-117"></a>117 | TD builders | Static UUID per builder; `a.UUID()` returns a random v7 | adapt | Random only for a test's scope identity (Isolated Test Execution steps 1 and 3), never a field default | [builders-ids](#rule-builders-ids) | Pattern mappings |
| <a id="row-118"></a>118 | TD builders | Raw struct literal smell; add the missing `With*` | keep | Same as row 94 | [test-whole-value](#rule-test-whole-value) | Pattern mappings |
| <a id="row-119"></a>119 | TD builders | Steps to create a new builder in `test/a/<entity>.go` | keep | Mechanical checklist for builders-a | [builders-a](#rule-builders-a) | Pattern mappings |
| <a id="row-120"></a>120 | TD builders | Follow-up: TD's `builders.md` still names states `IsValid`, `IsSaved`, `IsNotSaved`, `IsInvalid` | drop | Not a go.md rule; records that TD disagrees with builders-states after the 2026-11-04 ruling. TD is not edited here; aligning it is a follow-up for the workflow plugin | [dropped](#drop-120) | — |

## Rules

Each rule below is the wording go.md takes. Source lines cite the rows
above; strategy citations are at bjornstack `e31ec16`.

### Tooling

<a id="rule-tool-finish"></a>**tool-finish.** A change is done when `gofmt -l .` prints nothing,
`go vet ./...` is clean and `go test ./... -count=1` passes, with no
existing test weakened to get there.
Source: P0 slice 2 brief, "Finish criteria", `b4bc5df`, read 2026-11-03.
↩ row [78](#row-78)

<a id="rule-tool-bb-infra"></a>**tool-bb-infra.** Black-box tests start the service's own
infrastructure for real with testcontainers-go or docker-compose.
Source: bs-6nd description (closed 2026-03-21), read 2026-11-03.
↩ row [7](#row-7)

<a id="rule-test-require"></a>**test-require.** Assert with testify's `require`. Use `assert` only
when a test deliberately collects failures that are independent of
each other.
Source: bs-f3o.2 comments 2026-09-08 09:04 and 2026-11-03 09:09, read
2026-11-03; TD `conventions.md` rule 3 (sha256 `929148350cb2`), read
2026-11-03.
Differs: the Phase 0 briefs asked for `cmp.Diff`; we chose `require`
because `require.Equal` catches a time-zone mismatch that `cmp.Diff`
hides.
↩ rows [39](#row-39), [57](#row-57), [90](#row-90)

<a id="rule-test-protobuf"></a>**test-protobuf.** Compare protobuf messages with
`cmp.Diff(want, got, protocmp.Transform())`, because `require.Equal`
misreports on messages. Nothing else gets a `cmp.Diff` role.
Source: bs-f3o.2 comments 2026-09-08 09:58 and 2026-11-03 09:09, read
2026-11-03.
↩ rows [43](#row-43), [57](#row-57)

<a id="rule-new-stdlib"></a>**new-stdlib.** New code on Go 1.27 uses `encoding/json/v2` and the
standard library's uuid package, once the Go 1.27 release notes
confirm both.
Source: bs-f3o.2 comment 2026-11-03 09:09, read 2026-11-03.
Differs: conditional until bs-f3o.2.7 checks the release notes; this
bead could not look them up.
↩ row [60a](#row-60a)

### Pattern mappings

<a id="rule-pkg-naming"></a>**pkg-naming.** Name a package with a short lower-case noun for the
domain it owns. Exports extend the package name instead of repeating
it: `mail.Message`, not `mail.Mail`.
Source: bs-01o description (closed 2026-03-21), read 2026-11-03.
↩ rows [1](#row-1), [4](#row-4)

<a id="rule-pkg-internal"></a>**pkg-internal.** When a caller or a test needs an unexported detail,
reshape the boundary or move the detail into an `internal/`
sub-package that your own code and tests can import. Never export it
for the test.
Source: bs-01o and bs-8bi descriptions (closed 2026-03-21), read
2026-11-03.
↩ rows [2](#row-2), [14](#row-14), [16](#row-16)

<a id="rule-test-pkg"></a>**test-pkg.** Tests are in `package foo_test` and reach the package
only through its exports; the package has no test files of its own.
An `internal/` sub-package is the way to test an algorithm directly.
Source: bs-8bi description (closed 2026-03-21); bs-f3o.2 comment
2026-09-08 09:04; P0 slice 5 and 6 briefs, `b4bc5df`; TD
`conventions.md` rule 1; all read 2026-11-03.
Differs: TD rule 1 also allows testing unexported code "as a noted
deliberate choice"; Public API Surface Testing allows no such exit.
↩ rows [13](#row-13), [41](#row-41), [63](#row-63), [88](#row-88)

<a id="rule-test-names"></a>**test-names.** Name the outer test `Test<Type>_<Method>`. Name each
`t.Run` case as a sentence stating the situation and the outcome.
Source: TD `conventions.md` rule 2; P0 slice 2 brief; read 2026-11-03.
↩ rows [67](#row-67), [89](#row-89)

<a id="rule-test-table"></a>**test-table.** A table test is a slice of cases run with `t.Run`.
Every case sets every field, and carries the assertion functions that
differ between cases; for a `(value, error)` result that is
`assertError` and `assertResult`, and the body calls both for every
case. The body has no conditionals.
Source: P0 slice 2 brief; TD `conventions.md` "Error plus state"; read
2026-11-03.
↩ rows [64](#row-64), [65](#row-65), [83](#row-83), [86](#row-86)

<a id="rule-test-helper"></a>**test-helper.** `t.Helper()` is the first line of every function that
calls `t.Fatal`, `t.Error`, `require.*` or `assert.*`.
Source: TD `conventions.md` rule 4, read 2026-11-03.
↩ row [91](#row-91)

<a id="rule-test-messages"></a>**test-messages.** Assertion messages say what was expected:
"expected the total to include tax", not "should".
Source: TD `conventions.md` rule 5, read 2026-11-03.
↩ row [92](#row-92)

<a id="rule-test-whole-value"></a>**test-whole-value.** Compare the whole value with
`require.Equal(t, want, got, "expected ...")`, building `want` with
the same builder as the input. A struct literal for a type that has a
builder is a smell: add the missing `With*` method.
Source: TD `conventions.md` mapping and rule 7, `builders.md` (sha256
`bdd5ee101e22`); P0 slice 2 brief; read 2026-11-03.
Differs: P0 used `cmp.Diff` (see test-require).
↩ rows [66](#row-66), [82](#row-82), [94](#row-94), [118](#row-118)

<a id="rule-test-sut-options"></a>**test-sut-options.** Build the code under test with an options
function in the test file: `defaultCalculator(withTaxRates(x))`. Use
it where a full builder would be more than the type needs.
Source: bs-bq9 description (closed 2026-03-21); TD `conventions.md`
"Options function"; read 2026-11-03.
↩ rows [33](#row-33), [80](#row-80)

<a id="rule-clock-inject"></a>**clock-inject.** No package calls `time.Now()`; it receives a clock.
Tests pass a fixed clock. Where injecting one is awkward, use
`testing/synctest`. Where neither works, assert the field changed,
copy it into `want`, then compare the whole value.
Source: P0 slice 4-7 briefs; bs-f3o.2 comment 2026-11-03 09:09; TD
`conventions.md` rule 6; read 2026-11-03.
Differs: TD rule 6 has no `synctest` step.
↩ rows [59](#row-59), [74](#row-74), [93](#row-93)

<a id="rule-test-eventually"></a>**test-eventually.** `require.Eventually` waits for an asynchronous
outcome in a black-box test. Code whose result depends on time uses
clock-inject instead.
Source: TD `conventions.md` mapping, read 2026-11-03.
Differs: TD lists it as the general retrying comparison.
↩ row [85](#row-85)

<a id="rule-builders-a"></a>**builders-a.** Shared builders live in package `test/a`, one file per
type. The constructor applies the common states so `a.Review().Build()`
is valid as it stands. Each customizable field gets a `With*` method;
`Modify(fns ...func(*T))` covers one-off changes. `Build()` takes no
`*testing.T` and returns a value. A builder that needs another domain
object uses that object's builder. Builder methods have no doc
comments. A state not written yet panics with its name instead of
guessing.
Source: bs-bq9 description (closed 2026-03-21); TD `builders.md`; read
2026-11-03.
↩ rows [27](#row-27), [28](#row-28), [29](#row-29), [30](#row-30), [81](#row-81), [111](#row-111), [114](#row-114), [115](#row-115), [116](#row-116), [119](#row-119)

<a id="rule-builders-states"></a>**builders-states.** Recurring multi-field states are methods named
for the domain state, such as `Persisted()` or `Expired()`. What is
not the happy path is declared as named edge-case variants, plus one
method returning every edge case as name and fresh builder.
Source: bs-bq9 description (closed 2026-03-21); TD `builders.md`
"Concern methods"; read 2026-11-03; owner ruling relayed 2026-11-04.
Differs: TD names states `IsSaved()` and `IsValid()`; we drop the `Is`
prefix because it reads like a check, not a setup step. TD's
`IsInvalid()` returns a zeroed value; Test Data Builders step 6 asks
for named edge cases instead.
↩ rows [32](#row-32), [112](#row-112)

<a id="rule-builders-ids"></a>**builders-ids.** Each builder sets its own static UUID. A random id
is used only as a test's scope identity on shared infrastructure,
never as a field default.
Source: bs-bq9 description (closed 2026-03-21); TD `builders.md`
"Static UUIDs"; read 2026-11-03.
Differs: TD offers a random `a.UUID()` without limiting its use.
↩ rows [31](#row-31), [117](#row-117)

<a id="rule-coord-inject"></a>**coord-inject.** A coordinator receives its collaborators through its
constructor, fully set up. Its tests replace every direct collaborator
with a double and never a collaborator's own dependencies.
Source: P0 slice 2 brief; TD `mocks.md` rule 1 (sha256
`92bf76dc7396`); read 2026-11-03.
↩ rows [69](#row-69), [102](#row-102)

<a id="rule-coord-doubles"></a>**coord-doubles.** A single-method dependency is a function type, and
its double is an inline function. A `testify/mock` double calls
`.Test(t)` before use. When setting up many doubles hides what a test
checks, build them with a builder in the test file whose `Build(t)`
calls `.Test(t)` on each.
Source: TD `mocks.md` "Mock style", `conventions.md` mapping; read
2026-11-03.
↩ rows [84](#row-84), [108](#row-108), [109](#row-109), [110](#row-110)

<a id="rule-coord-count"></a>**coord-count.** A coordinator with N collaborators that can fail has
about N+1 tests. Past four collaborators, look for a domain concept
that combines some of them.
Source: TD `mocks.md` rules 2-3, read 2026-11-03.
Differs: TD says about 2N tests and a maximum of three or four
collaborators; Unit Testing steps 3.1 and 3.4 say N+1 and give no
ceiling.
↩ rows [103](#row-103), [104](#row-104)

<a id="rule-coord-logic"></a>**coord-logic.** The only conditional in a coordinator is
`if err != nil`. A conditional, or a transform that needs test cases
of its own, including a method called on an argument, is computation:
extract it, typically as a function-type collaborator.
Source: TD `mocks.md` smells 1-2, read 2026-11-03.
Differs: TD names only conditionals and methods on arguments; Unit
Testing step 3.5 (`3109d37`) adds transforms that need their own
cases, and a short transform that needs none stays inline.
↩ rows [105](#row-105), [106](#row-106)

<a id="rule-coord-globals"></a>**coord-globals.** A coordinator may use diagnostic logging and
metrics as package-level globals. Everything else, audit records
included, is an injected collaborator.
Source: TD `mocks.md` smell 3, read 2026-11-03.
Differs: TD says "logging and metrics"; Unit Testing step 3.2 limits
it to diagnostic logging.
↩ row [107](#row-107)

<a id="rule-ctx-per-call"></a>**ctx-per-call.** `context.Context` is the first parameter of each
call and is never stored in a struct. This is the one exception to
Unit Testing step 3.2: a coordinator hands ctx on to its
collaborators.
Source: bs-f3o.2 comment 2026-10-19 16:32, read 2026-11-03.
↩ row [46](#row-46)

<a id="rule-ctx-scope"></a>**ctx-scope.** ctx carries cancellation and per-goroutine settings the
whole program needs, such as the logger and trace ID. It does not
carry data structures because ctx is easy to reach.
Source: bs-f3o.2 comment 2026-10-21 06:36, read 2026-11-03.
↩ row [47](#row-47)

<a id="rule-compliance-suite"></a>**compliance-suite.** When an interface has two implementations, or
one plus a stateful test double, write one exported
`<Interface>Test(t *testing.T, ctx context.Context, factory func() I)`
in an ordinary file of a test-only package (such as `storagetest`), so
implementations in other packages can import it. It groups `t.Run` by
operation, then by scenario, and calls the factory for a fresh
instance in every scenario. Each implementation wires its factory in a
thin test. Scenarios cover success, the contract's errors, returned
values not sharing stored state, and every edge case the builders
declare for types the interface takes or returns.
Source: TD `compliance-tests.md` (sha256 `f72d69bf855d`) and
`conventions.md` "Interface compliance", read 2026-11-03.
Differs: TD puts the suite in a `_test.go` file, which other packages
cannot import; it requires two real implementations; and its scenario
table has no edge-case iteration or returned-copy check.
↩ rows [95](#row-95), [96](#row-96), [97](#row-97), [98](#row-98), [99](#row-99), [100](#row-100), [101](#row-101)

<a id="rule-bb-package"></a>**bb-package.** Black-box tests live in their own package, one file
per feature, and import no production package. They run the built
binary or call the running server, and parse what comes back with
local structs, as a consumer would. A helper runs the binary with a
subcommand and prints its output when it fails.
Source: bs-6nd description (closed 2026-03-21); P0 slice 3 and 5
briefs, `b4bc5df`; read 2026-11-03.
↩ rows [11](#row-11), [62](#row-62), [75](#row-75)

<a id="rule-bb-setup"></a>**bb-setup.** A black-box test sets up state through the public
interface, or by writing the published bytes the system reads. No
test-only flag such as `--now`.
Source: P0 slice 7 brief, `b4bc5df`, read 2026-11-03.
↩ row [76](#row-76)

<a id="rule-bb-http"></a>**bb-http.** Black-box tests call the server with an `http.Client` at
its real address. Services across the boundary are stubbed with
`httptest.Server`.
Source: bs-6nd description (closed 2026-03-21), read 2026-11-03.
↩ rows [8](#row-8), [9](#row-9)

<a id="rule-bb-parallel"></a>**bb-parallel.** Each black-box test calls `t.Parallel()` and works
under its own identity: a fresh user, tenant or key prefix.
Source: bs-6nd description (closed 2026-03-21), read 2026-11-03.
↩ row [10](#row-10)

<a id="rule-scrub-boundary"></a>**scrub-boundary.** Wire types with `json` tags live in the boundary
adapter. A scrub function there turns a wire value into a domain
value; domain types carry no wire tags, and the domain package's API
takes domain types only.
Source: bs-8jx description (closed 2026-03-21), read 2026-11-03.
↩ rows [20](#row-20), [21](#row-21)

<a id="rule-scrub-validate"></a>**scrub-validate.** Check each acted-on field of the input struct, and
the relationships between its fields, with validation tags (from a
library or our own) or with plain Go. Either way, a rejection lists
every violation in the record with its field, value and constraint.
Validation tags go on the input struct; domain types carry no input
tags.
Source: bs-8jx description (closed 2026-03-21), read 2026-11-03; owner
ruling relayed 2026-11-04.
↩ rows [17](#row-17), [18](#row-18)

<a id="rule-scrub-collect"></a>**scrub-collect.** Inside a layer, `errors.Join` or `fmt.Errorf` with
`%w` may collect a record's violations, and so may any rejection
whose members are plain messages that nobody compares. At the
boundary, or anywhere a caller branches on the result, return one
error type for each distinct thing the caller acts on, such as one
rejection per record holding its violations as data. A Join of
sentinels handed to a caller that branches on it lets one cause decide
for all the others (err-join-match); `%w` does the same. Across many
records, the cap falls between records, never inside one, and the
rejection states how many errors it found after checking how many
records, and how many it shows. Tests compare all of a record's
violations in one `require.Equal`, not one `ErrorIs` per cause.
Source: bs-8jx description (closed 2026-03-21); bs-f3o.2 comment
2026-09-08 09:58; P0 slice 2 brief; read 2026-11-03; owner ruling
relayed 2026-11-04.
Differs: P0 used `errors.Join` everywhere, including results a caller
branches on.
↩ rows [19](#row-19), [45](#row-45), [68](#row-68)

<a id="rule-flag-test"></a>**flag-test.** A helper runs one test body with the flag off and on,
each with its own assertions: the off run proves nothing changed, the
on run proves the new behavior.
Source: bs-9sn description (closed 2026-03-21), read 2026-11-03.
↩ row [22](#row-22)

### Go pitfalls

<a id="rule-test-time"></a>**test-time.** `require.Equal` compares a `time.Time`'s location and
monotonic reading as well as its instant: the same instant in another
zone, or a `time.Now()` value, is not equal. Builder defaults and
expected values are built with `time.Date(..., time.UTC)` or from the
injected clock. The inputs of a UTC Computation step 5 test come from
a zone east of UTC and one west of it.
Source: bs-f3o.2 comments 2026-09-08 09:58 and 2026-11-03 09:09, R
`exp_test.go`; TD `builders.md` "Concern methods"; read 2026-11-03.
Differs: TD builds times with `time.Parse`; owner decision is
`time.Date`.
↩ rows [44](#row-44), [57](#row-57), [113](#row-113)

<a id="rule-err-wrap-verb"></a>**err-wrap-verb.** `%w` and `%v` differ by one character, and `%w`
passes the cause's identity on; `go vet` does not catch it. A second
`%w` passes on both. Where a failure enters from outside, use `%v`.
Source: bs-f3o.2 comment 2026-10-29 14:58, read 2026-11-03.
↩ row [48](#row-48)

<a id="rule-err-unwrap"></a>**err-unwrap.** An `Unwrap` method on an identity type passes the
cause's identity on as well.
Source: bs-f3o.2 comment 2026-10-29 14:58, read 2026-11-03.
↩ row [49](#row-49)

<a id="rule-err-join-match"></a>**err-join-match.** `errors.Is` and `errors.As` match any member of an
`errors.Join`, so a caller can check a combined failure for one cause.
Source: bs-f3o.2 comment 2026-10-29 14:58, read 2026-11-03.
↩ row [50](#row-50)

<a id="rule-err-as-pointer"></a>**err-as-pointer.** `errors.As` into a value type silently misses an
error returned as a pointer.
Source: bs-f3o.2 comment 2026-10-29 14:58, read 2026-11-03.
↩ row [51](#row-51)

<a id="rule-err-is-fresh-pointer"></a>**err-is-fresh-pointer.** `errors.Is(err, &T{})` compares pointers and
matches only if `T` defines `Is`. Check a typed failure with
`require.ErrorAs` into a pointer target.
Source: TD `conventions.md` "Error plus state" example, read
2026-11-03.
Differs: the TD example uses `require.ErrorIs` with a fresh pointer.
↩ row [87](#row-87)

<a id="rule-err-timeout-ctx"></a>**err-timeout-ctx.** `net.Error.Timeout()` is also true when the
caller's own context hit its deadline. Retry only when `ctx.Err()` is
nil.
Source: bs-f3o.2 comment 2026-10-29 14:58, read 2026-11-03.
↩ row [52](#row-52)

<a id="rule-err-equate-errors"></a>**err-equate-errors.** `cmpopts.EquateErrors` compares with
`errors.Is`, so a wrapped error equals a bare one.
Source: bs-f3o.2 comment 2026-10-29 14:58, read 2026-11-03.
↩ row [53](#row-53)

### For the protocols

<a id="rule-proto-packages"></a>**proto-packages.** No package named for a technical role (utils,
helpers, common, models, types). Sibling domain packages never import
each other; a coordinating package or a shared interface sits between
them.
Source: bs-01o description (closed 2026-03-21); P0 slice 2 brief; read
2026-11-03.
↩ rows [3](#row-3), [5](#row-5), [71](#row-71)

<a id="rule-proto-bb-budget"></a>**proto-bb-budget.** One happy and one unhappy black-box test per
feature boundary.
Source: bs-6nd description (closed 2026-03-21), read 2026-11-03.
↩ row [12](#row-12)

<a id="rule-proto-flag-expiry"></a>**proto-flag-expiry.** A rollout flag carries a dated expiry marker in
the code that tooling can find and escalate when the date passes.
Source: bs-9sn description (closed 2026-03-21), read 2026-11-03.
↩ row [24](#row-24)

<a id="rule-proto-tidy"></a>**proto-tidy.** Classify each changeset as structural or behavioural,
commit structural ones first, and split pull requests along that line.
A structural changeset passes `go test ./...` with no test file
changed beyond renames that follow the code.
Source: bs-jo0 description (closed 2026-03-21), read 2026-11-03.
↩ rows [34](#row-34), [35](#row-35), [36](#row-36), [37](#row-37)

## Dropped

One section per drop row: what the source said, what it would have
meant in practice, and why it was dropped.

### <a id="drop-6"></a>Row 6: Guard candidates for packaging

Source: bs-01o description: "Guard candidates: lint for banned package names, lint for exported type names that match package name, lint for external types in domain signatures."

In practice: Three linters run in CI: one failing on a package named `utils` or `helpers`, one failing on `feed.Feed`-style exports, and one failing when a domain package's signature names a third-party type.

Dropped because: Guards are their own layer (bs-ws1), not language configuration.

↩ row [6](#row-6)

### <a id="drop-15"></a>Row 15: Smurf naming handled under BYN

Source: bs-8bi description: "Smurf naming avoidance is handled separately under BYN (bs-n5q)."

In practice: A note telling the Intentionally Public guideline not to cover names like `cart.CartItem`, because another bead owned that. It asked for nothing to be written.

Dropped because: Pointer, not a rule; row 4 covers the naming rule.

↩ row [15](#row-15)

### <a id="drop-23"></a>Row 23: Flag naming convention format

Source: bs-9sn description lists "naming convention format" among the guideline's concerns.

In practice: A fixed form for flag names in Go code, such as how words are joined. Flag Your Changes step 2 already says the name describes what `true` activates and keeps lifecycle out of the name.

Dropped because: Flag Your Changes step 2 already says it and nothing about it is Go-specific.

↩ row [23](#row-23)

### <a id="drop-25"></a>Row 25: Mechanical flag removal tooling

Source: bs-9sn description lists "mechanical flag removal tooling".

In practice: A tool that deletes a retired flag's OFF path from production code and tests automatically, so the removal changeset in Flag Your Changes step 5 is mechanical.

Dropped because: No such tool exists; it is a guard or tooling project, not configuration.

↩ row [25](#row-25)

### <a id="drop-26"></a>Row 26: Flag config file schema

Source: bs-9sn description lists "flag config file schema for lifecycle tracking".

In practice: A defined file format for flag entries carrying state (active, deprecated, retired) and retirement metadata (when, why, owner), as Flag Your Changes step 2 describes.

Dropped because: Lives in the flag system's config (Flag Your Changes step 2), not in Go code.

↩ row [26](#row-26)

### <a id="drop-38"></a>Row 38: Guard for mixed structural and behavioural PRs

Source: bs-jo0 description: "Guard candidates: CI check that flags PRs mixing structural and behavioral diffs."

In practice: A CI job that inspects a pull request and fails or warns when one changeset both restructures code and changes behaviour.

Dropped because: Guard layer (bs-ws1).

↩ row [38](#row-38)

### <a id="drop-40"></a>Row 40: Granularity of generated code

Source: bs-f3o.2 comment 2026-09-08 09:04, point 2: the owner's read of the Phase 0 result was "a lot of the code is longer and less broken down than I would've liked", with the caveat that it may be Go convention, to be tested before it became a rule.

In practice: It would have become a rule pushing for shorter functions or more decomposition. bs-iyx then measured the code: median function body 12-15 lines, p90 36, and what read as long was comment volume and parameter width.

Dropped because: Tested and refuted on bs-iyx (median function body 12-15 lines); the real problem, parameter width, is now Unit Testing steps 2.1 and 3.2.

↩ row [40](#row-40)

### <a id="drop-42"></a>Row 42: Method note: harvest the Phase 0 briefs

Source: bs-f3o.2 comment 2026-09-08 09:04, "Method note": the run's per-slice briefs hold a Go-flavoured convention list and are "a first draft of this bead's content"; harvest them from the run's subagent logs.

In practice: An instruction on where to find material, not a rule for Go code.

Dropped because: Pointer to a source; its content is rows 61-79.

↩ row [42](#row-42)

### <a id="drop-54"></a>Row 54: Search for existing Go skills first

Source: bs-f3o.2 comment 2026-10-29 17:31: "first run a thorough search for existing Go skills from reputable sources. Then decide whether to include any of them as they are, or mine them for rules and traps".

In practice: A research step before writing go.md. It was carried out on 2026-11-03.

Dropped because: Process step, done 2026-11-03 (O-1103b); the mining happens in bs-f3o.2.6 and bs-f3o.2.8.

↩ row [54](#row-54)

### <a id="drop-55"></a>Row 55: Writing waits for bs-z6h

Source: bs-f3o.2 comment 2026-11-03 08:45: "Writing waits for bs-z6h (go.md's 'collecting multiple errors' must follow its rule); bs-z6h is now a blocker."

In practice: An ordering constraint on the work: do not write the multiple-errors rule before Scrub on Entry's cap rule lands.

Dropped because: Sequencing; bs-z6h landed in `4c0125e` and `e31ec16`, and row 19 follows it.

↩ row [55](#row-55)

### <a id="drop-56"></a>Row 56: Sources: no official Go skill; install none

Source: bs-f3o.2 comment 2026-11-03 09:09, first bullet: "no official Go skill exists. Take rules from community skills (samber/cc-skills-golang, cxuu/golang-skills) and JetBrains go-modern-guidelines; install none."

In practice: Decides which outside sources get their own decision table (bs-f3o.2.6, bs-f3o.2.8) and that no skill is installed as it stands.

Dropped because: Decides which source tables exist, not a go.md rule.

↩ row [56](#row-56)

### <a id="drop-58"></a>Row 58: Rejected assertion libraries

Source: bs-f3o.2 comment 2026-11-03 09:09, "Rejected" bullet: shoenig/test, gotest.tools and quicktest (all go-cmp based, so no time-zone strictness); matryer/is (dormant, no diff); alecthomas/assert (compares printed form); rolling our own (needs a diff printer).

In practice: Why testify `require` won. go.md states the choice (test-require); the comparison is history.

Dropped because: Rationale for row 57; stays on the bead.

↩ row [58](#row-58)

### <a id="drop-60"></a>Row 60: Format and citation format

Source: bs-f3o.2 comment 2026-11-03 09:09, "Format" and citation bullets: the configuration lives at `languages/<lang>.md`, docs/WORKFLOW.md:236 and :260 change in the same edit, and each go.md rule has an id, own wording, a pinned Source line and "Differs:" where we diverge.

In practice: Where the file lives and how its rules are cited. This table follows the citation format; neither is a rule about Go code.

Dropped because: Govern docs/WORKFLOW.md (bs-f3o.2) and this file, not Go code.

↩ row [60](#row-60)

### <a id="drop-61"></a>Row 61: Outside-in order

Source: P0 slice 2 brief (`agent-a4e4a813f09ea8762`), "Non-negotiable conventions": "Write the black box test in `bbtest/` FIRST and watch it fail, then the coordinator tests, then the computation. Do not write the implementation first." Repeated in slices 3-7.

In practice: The order in which tests are written for each slice, which the Outside-In Development Loop strategy already sets for every language.

Dropped because: Outside-In Development Loop says it for every language.

↩ row [61](#row-61)

### <a id="drop-70"></a>Row 70: Comments explain why, not what

Source: P0 slice 2 brief (`agent-a4e4a813f09ea8762`), "Non-negotiable conventions": "Comments explain why, not what. Match the voice of the existing doc comments: they justify decisions a reader would otherwise question."

In practice: Doc comments that justify decisions. In that run it produced 878 comment lines of 4008 production lines, much of it restating the design record (bs-iyx).

Dropped because: Language-neutral; bs-cbr's strategy owns where reasoning lives, and bs-iyx found the run over-commented.

↩ row [70](#row-70)

### <a id="drop-72"></a>Row 72: No new dependencies

Source: P0 slice 2 brief (`agent-a4e4a813f09ea8762`): "No new dependencies beyond what `go.mod` already has." Repeated in slices 3-7.

In practice: Implementers could not add a module. go.mod held only go-cmp and playwright-go, so testify could not be added (bs-iyx).

Dropped because: A fence for that run; it is what kept testify out.

↩ row [72](#row-72)

### <a id="drop-73"></a>Row 73: Do not extract a shared atomic-write helper

Source: P0 slice 3 brief (`agent-a0e611cff0e066e21`): "Do NOT extract a shared atomic-write helper between `watchlist` and `feed`. Two cases is not enough to earn an abstraction — the duplication is deliberate. Copy it." Repeated in slices 4-7.

In practice: The `watchlist` and `feed` packages each kept their own temp-file-and-rename code.

Dropped because: Earned Abstraction's rule, applied to one codebase; nothing Go-specific.

↩ row [73](#row-73)

### <a id="drop-77"></a>Row 77: Browser-driving black-box tests must not call t.Parallel

Source: P0 slice 7 brief (`agent-a8d58bb75b68de066`): "Black box tests that drive a browser must not call `t.Parallel` — see the comment on `visit` in `bbtest/main_test.go`. A test that only runs commands may."

In practice: The comment it cites (briefkasten--2026-09-07 `bbtest/main_test.go:177-186`, `b4bc5df`) says driving the Playwright browser from several tests at once stalled a navigation for thirty seconds under the race detector, and a browser per test made it worse; running those tests one at a time cost about 0.7 s.

Dropped because: A workaround found in one harness: running browser tests concurrently stalled navigations under the race detector, and a browser per test made it worse, so the cause was concurrency, not sharing (`bbtest/main_test.go:177-186` at `b4bc5df`); Black Box Integration step 3 still asks for parallel-safe tests.

↩ row [77](#row-77)

### <a id="drop-79"></a>Row 79: RFC extract briefs and slice designs

Source: P0 RFC briefs `agent-a4a1b3d29ccd46981` ("Fetch and read RFC 5005 ... Quote the specification") and `agent-adf0f5a58e9cc9a90` ("Fetch and read RFC 8620 ... and RFC 8621 ... quote the spec's own examples character for character"); slice 2 brief: "The file is written atomically: write a temp file in the same directory, then rename" and "The JSON carries a format version field. Reading a file with an unrecognised version must fail loudly".

In practice: Research tasks and design decisions for the briefkasten application: what the feed and JMAP wire formats are, and how its files are written and versioned.

Dropped because: Design of one application, not Go conventions.

↩ row [79](#row-79)

### <a id="drop-120"></a>Row 120: test-design still uses Is… state names

Source: TD `builders.md:36-42` (sha256 `bdd5ee101e22`): concern methods "Name them as adjectives or state descriptions", listing `IsValid()`, `IsSaved()`, `IsNotSaved()`, `IsInvalid()`.

In practice: Builders following test-design read `a.Review().IsValid().IsSaved()`, which go.md's builders-states now names `Persisted()`. The row exists to record the mismatch for a later edit of test-design.

Dropped because: Not a go.md rule; records that TD disagrees with builders-states after the 2026-11-04 ruling. TD is not edited here; aligning it is a follow-up for the workflow plugin.

↩ row [120](#row-120)

## Owner rulings

All four questions this table raised were decided by the owner on
2026-11-04 and are applied above.

1. **Validation: struct tags or plain Go (row 17).** Tags from a
   library, hand-made tags or plain Go are all allowed on the input
   struct, provided a rejection lists every violation in the record
   with its field, value and constraint. Domain types carry no input
   tags. Applied in scrub-validate.
2. **Builder state method names (rows 32, 112, 120).** `Persisted()`,
   no `Is` prefix, because an `Is…` name reads like a check, not a
   setup step. Applied in builders-states; TD's mismatch is row 120.
3. **Test times in UTC vs UTC Computation step 5 (rows 44, 57).** Split
   by role: builder defaults and expected values use UTC; step 5's
   inputs come from zones east and west of UTC. Applied in test-time.
4. **Shape of a record's rejection (rows 19, 45, 68).** Join or `%w` is
   fine inside a layer and for plain messages nobody compares. At the
   boundary, or where a caller branches, return one error type per
   distinct thing the caller acts on. Applied in scrub-collect.

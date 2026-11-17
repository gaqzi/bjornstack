# Go sources G: community skills

Decision table for bs-f3o.2.8. It reviews community Go skills for
agents and decides, item by item, what goes into `languages/go.md`. Our
own table is [bjornstack.md](bjornstack.md); a rule it already holds
reads "already ours" here, with its row there.

Read 2026-11-16. Strategy text was judged at bjornstack commit
`67b1213`. No skill was installed (bs-f3o.2 comment 2026-11-03 09:09).

## Sources and pins

| Key | Source | Pin |
|---|---|---|
| T | `skills/golang-testing/` (SKILL.md, references/, evals/evals.json) | https://github.com/samber/cc-skills-golang commit `d68d80aec298e1b74b37c2a472c002b5217248b3`, read 2026-11-16 |
| TF | `skills/golang-stretchr-testify/` | same repository and commit |
| EH | `skills/golang-error-handling/` | same repository and commit |
| CX | `skills/golang-context/` | same repository and commit |
| PL | `skills/golang-project-layout/` | same repository and commit |
| SI | `skills/golang-structs-interfaces/` | same repository and commit |
| SF | `skills/golang-safety/` | same repository and commit |
| CU | `skills/go-testing`, `go-error-handling`, `go-context`, `go-interfaces`, `go-defensive` (SKILL.md only) | https://github.com/cxuu/golang-skills commit `91f0c2eef559a3168f9d3c38f5f99936d472b508`, read 2026-11-16 |
| ES | `skills/(testing)/go-test-quality`, `(code-quality)/go-error-handling`, `(code-quality)/go-context` (SKILL.md only, the sections cited) | https://github.com/eduardo-sl/go-agent-skills commit `e25b517bbd0c11db35f75a83a14f18848c1abdb0`, read 2026-11-16 |

Coverage:
- Fully reviewed: the seven samber skills above, each with its
  SKILL.md, every file under references/, and evals/evals.json.
  Assets (a Makefile and a .gitignore template) were read as what
  rows 142-143 name, not line by line.
- Spot-checked: cxuu and eduardo-sl, only the skills covering the
  same topics, and only to find rules that add to or contradict a
  samber row. cxuu `go-defensive` gives rows 254-259 and bears on
  rows 81-82 and 188-189. Nothing else in either repository was
  read.

Evals: the bead puts the evals in scope without saying what they
contribute. Each eval is a prompt, a trap and assertions. An
assertion that restates a rule of the skill's text is cited in that
row's Source and gives no row of its own. An assertion that states a
rule the text does not, or contradicts the text, gets its own row.
Assertions about the prompt's own task (such as "uses
`binary.BigEndian.PutUint16` as specified") give none.

Source cells cite `file:line` inside the keyed skill directory.

## Decision table

"Section" names the go.md section: Tooling, Pattern mappings, Go
pitfalls, or For the protocols. "Check" says how a keep or adapt rule
is enforced: "tool" when a check the pinned source itself names
enforces it, "guard candidate" when the rule is mechanical but no
check is named, "judgment" when a person or an agent has to decide.
An "already ours" row takes the Section and Check of its bjornstack.md
row. Drop rows have "-".

| # | Source | Item | Decision | Reason | Rule id | Section | Check |
|---|---|---|---|---|---|---|---|
| <a id="row-1"></a>1 | T `SKILL.md:26-37` | Modes (write, review, audit, debug), thinking mode, sub-agent fan-out for audits | drop | Instructions for running an agent, not Go rules | [dropped](#drop-1) | — | - |
| <a id="row-2"></a>2 | T `SKILL.md:34`, `:41-43` | Scaffold table tests with `gotests` | drop | A generator, not a rule; the table's shape is test-table | [dropped](#drop-2) | — | - |
| <a id="row-3"></a>3 | T `SKILL.md:51`, `:103`; eval 3.3 | Every table case has a `name` passed to `t.Run` | already ours | bjornstack.md row 89 (test-names), with row 83 (test-table) | [test-names](bjornstack.md#rule-test-names) | Pattern mappings | guard candidate |
| <a id="row-4"></a>4 | T `SKILL.md:52`, `:360-384`; eval 2 | Integration tests behind `//go:build integration`; `testing.Short()` is no substitute | drop | tool-bb-infra starts the infrastructure inside the tests, so a tag buys nothing and hides black-box tests from `go test ./...` and gopls | [dropped](#drop-4) | — | - |
| <a id="row-5"></a>5 | T `references/coverage.md:44` | Tagged integration tests are invisible to coverage unless the tag is passed | drop | Same as row 4 | [dropped](#drop-4) | — | - |
| <a id="row-6"></a>6 | T `SKILL.md:53`; eval 14.3, 14.5 | Tests do not depend on execution order | drop | Isolated Test Execution's outcomes say it for every language | [dropped](#drop-6) | — | - |
| <a id="row-7"></a>7 | T `SKILL.md:54`, `:302-326`; eval 3.1-3.2 | Independent tests and subtests call `t.Parallel()` | adapt | Go's mechanism for Isolated Test Execution step 4; only process-wide state keeps a test serial, and a test that would collide gets its data scoped (bb-parallel) | [test-parallel](#rule-test-parallel) | Pattern mappings | tool: paralleltest (named by T `SKILL.md:396`) |
| <a id="row-8"></a>8 | T `SKILL.md:55`; evals 6, 7 | Assert observable behaviour through the public API; `package foo_test` | already ours | bjornstack.md row 63 (test-pkg) | [test-pkg](bjornstack.md#rule-test-pkg) | Pattern mappings | guard candidate |
| <a id="row-9"></a>9 | T `SKILL.md:56`, `:181-213`; eval 1 | Packages with goroutines check for leaks with goleak in `TestMain` | keep | Mechanical, Go-specific; `-race` does not find a goroutine that never exits | [test-goleak](#rule-test-goleak) | Tooling | guard candidate |
| <a id="row-10"></a>10 | T `SKILL.md:57` | Use testify as helpers, not a replacement for `testing` | drop | testify's API already forces `*testing.T`; test-require settles the assertion choice | [dropped](#drop-10) | — | - |
| <a id="row-11"></a>11 | T `SKILL.md:58`, `:388-392`; eval 5 | Mock interfaces, not concrete types; define the interface where it is consumed | keep | Go spelling of Unit Testing step 3.3 and Test Data Builders step 2 | [iface-consumer](#rule-iface-consumer) | Pattern mappings | judgment |
| <a id="row-12"></a>12 | T `SKILL.md:59`, `:175` | Unit tests under 1 ms, isolated, deterministic | drop | No strategy sets a time budget; isolation and determinism are Unit Testing's and Isolated Test Execution's | [dropped](#drop-12) | — | - |
| <a id="row-13"></a>13 | T `SKILL.md:60`, `:419`; eval 14.2 | Run tests with the race detector in CI | keep | Mechanical, Go-specific | [tool-race](#rule-tool-race) | Tooling | tool: `go test -race` (named by T `SKILL.md:60`, `:419`) |
| <a id="row-14"></a>14 | T `SKILL.md:61`, `:348-352`; `references/examples.md:3`; eval 8 | Example functions as executable documentation | adapt | Go's form of documentation that `go test` checks; limited to packages other modules import, since an `internal/` package has no outside reader | [test-examples](#rule-test-examples) | Pattern mappings | judgment |
| <a id="row-15"></a>15 | T `references/examples.md:21-30` | An example's suffix after the second underscore starts lower-case | keep | Otherwise godoc detaches the example from its symbol | [test-examples](#rule-test-examples) | Pattern mappings | guard candidate |
| <a id="row-16"></a>16 | T `references/examples.md:34-36`; eval 8.3 | Examples carry `// Output:`; one without it is compiled, not run; none for live dependencies | keep | Same rule; the source allows no output where the example needs a live dependency (T `references/examples.md:36`) | [test-examples](#rule-test-examples) | Pattern mappings | guard candidate |
| <a id="row-17"></a>17 | T `references/examples.md:35` | `// Unordered output:` for map iteration and concurrent producers | keep | Same rule | [test-examples](#rule-test-examples) | Pattern mappings | judgment |
| <a id="row-18"></a>18 | T `references/examples.md:40` | Examples live in `package foo_test` | already ours | bjornstack.md row 63 (test-pkg): no test file declares `package foo` | [test-pkg](bjornstack.md#rule-test-pkg) | Pattern mappings | guard candidate |
| <a id="row-19"></a>19 | T `SKILL.md:62`, `:77-87` | Test file named after the source file; a split file's name still derives from it | adapt | Keep for package tests; black-box tests are one file per feature (bb-package) | [test-file-name](#rule-test-file-name) | Pattern mappings | guard candidate |
| <a id="row-20"></a>20 | T `SKILL.md:63`, `:89` | Test functions in the order of the functions they test | keep | A convention that lets a reader find a test by position | [test-file-name](#rule-test-file-name) | Pattern mappings | judgment |
| <a id="row-21"></a>21 | T `SKILL.md:91-99` | Names `TestX`, `TestType_Method`, `BenchmarkX`, `ExampleX`, `FuzzX` | already ours | bjornstack.md row 89 (test-names); the other prefixes are what `go test` requires | [test-names](bjornstack.md#rule-test-names) | Pattern mappings | guard candidate |
| <a id="row-22"></a>22 | T `SKILL.md:145-171` | Never reuse an `assert.New`/`require.New` built from the parent `t` inside `t.Run` | keep | Go pitfall: the failing subtest reports PASS | [test-subtest-t](#rule-test-subtest-t) | Go pitfalls | guard candidate |
| <a id="row-23"></a>23 | T `SKILL.md:177-179`; `references/http-testing.md:3`; eval 11 | Handler tests use `httptest.NewRecorder`, not a running server | adapt | Right for a handler's own (coordinator) test; black-box tests still call the running server (bb-http) | [test-handler-recorder](#rule-test-handler-recorder) | Pattern mappings | judgment |
| <a id="row-24"></a>24 | T `SKILL.md:215-224` | `testing/synctest` instead of real time for concurrent time-based code | already ours | bjornstack.md row 59 (clock-inject): an injected clock first, `synctest` where injecting is awkward | [clock-inject](bjornstack.md#rule-clock-inject) | Pattern mappings | guard candidate |
| <a id="row-25"></a>25 | T `SKILL.md:255` | Use `synctest.Test`, not the Go 1.24 experimental `synctest.Run` | keep | Mechanical API choice | [test-synctest-api](#rule-test-synctest-api) | Go pitfalls | guard candidate |
| <a id="row-26"></a>26 | T `SKILL.md:263-265` | Go 1.27 `synctest.Sleep` and `httptest.NewTestServer` | drop | Describes APIs and sets no rule beyond row 25; Go 1.27 facts are bs-f3o.2.7's to check | [dropped](#drop-26) | — | - |
| <a id="row-27"></a>27 | T `SKILL.md:267-269`; `references/helpers.md:3-41` | Timeout helper whose goroutine panics with the caller's location | drop | A panic in a goroutine ends the whole test binary; row 249's context timeout fails only the hung test | [dropped](#drop-27) | — | - |
| <a id="row-28"></a>28 | T `SKILL.md:273`; `references/benchmarks.md:5-28` | One sub-benchmark (`b.Run`) per variant | keep | Each variant gets its own name for `benchstat` | [bench-shape](#rule-bench-shape) | Pattern mappings | judgment |
| <a id="row-29"></a>29 | T `references/benchmarks.md:30-46`; eval 13.2 | Vary input size through sub-benchmarks | keep | Same rule | [bench-shape](#rule-bench-shape) | Pattern mappings | judgment |
| <a id="row-30"></a>30 | T `SKILL.md:273`; `references/benchmarks.md:48-50`; eval 13.3 | `for b.Loop()` on Go 1.24+, not a `b.N` loop; legacy `b.N` only for Go <1.24 or existing code kept on purpose | keep | Go pitfall: `b.N` loops can report impossible results; the source's exit matches the owner's migration ruling | [bench-loop](#rule-bench-loop) | Go pitfalls | guard candidate |
| <a id="row-31"></a>31 | T eval 13.1, `references/benchmarks.md:37`; ES `go-test-quality/SKILL.md:193` | Benchmarks report allocations (`b.ReportAllocs()`) | keep | Allocations are half of what a benchmark reports; `-benchmem` does the same from the command line | [bench-shape](#rule-bench-shape) | Pattern mappings | judgment |
| <a id="row-32"></a>32 | T eval 13.5-13.6 | Keep the result alive with a sink; setup outside the timed loop or `b.ResetTimer` | drop | `b.Loop` does both (T `references/benchmarks.md:50`) | [dropped](#drop-32) | — | - |
| <a id="row-33"></a>33 | T `SKILL.md:279-296` | Go 1.26: files a test keeps go in `t.ArtifactDir()` | keep | Mechanical, Go-specific | [test-artifacts](#rule-test-artifacts) | Tooling | judgment |
| <a id="row-34"></a>34 | T `SKILL.md:298-300` | Go 1.27: a `stdversion` failure means bump the `go` directive or stop using the API, never silence it | adapt | Kept conditional until bs-f3o.2.7 checks the Go 1.27 release notes, as bjornstack.md row 60a | [tool-stdversion](#rule-tool-stdversion) | Tooling | tool: `stdversion` vet check (named by T `SKILL.md:300`) |
| <a id="row-35"></a>35 | T `SKILL.md:328-346`; eval 9; ES `go-test-quality/SKILL.md:138` | Fuzz functions that take untrusted input, seeded with `f.Add`, asserting properties | keep | Finds inputs no table case thought of | [test-fuzz](#rule-test-fuzz) | Pattern mappings | judgment |
| <a id="row-36"></a>36 | T `SKILL.md:354-358`; `references/coverage.md:3`, `:46` | Coverage is a gap finder, not a target | drop | Language-neutral advice; its home is bs-1ep | [dropped](#drop-36) | — | - |
| <a id="row-37"></a>37 | T `references/coverage.md:43` | Coverage is per package unless `-coverpkg` is passed | keep | Go pitfall; tests in another package, black-box tests included, report nothing for the package without it | [tool-coverage](#rule-tool-coverage) | Tooling | guard candidate |
| <a id="row-38"></a>38 | T `references/coverage.md:35-39` | `-covermode=atomic` with `-race` or `t.Parallel()` | adapt | `-race` already makes `atomic` the default; only a parallel run without `-race` needs the flag | [tool-coverage](#rule-tool-coverage) | Tooling | guard candidate |
| <a id="row-39"></a>39 | T `references/coverage.md:45` | Exclude generated code before setting a coverage threshold | drop | No coverage threshold exists in the stack | [dropped](#drop-39) | — | - |
| <a id="row-40"></a>40 | T `references/integration-testing.md:11-41` | docker-compose fixture for the service's own infrastructure | already ours | bjornstack.md row 7 (tool-bb-infra) | [tool-bb-infra](bjornstack.md#rule-tool-bb-infra) | Tooling | judgment |
| <a id="row-41"></a>41 | T `references/integration-testing.md:97-126`, `:159-161`; eval 12.1-12.2, 12.4, 12.6 | testify suite: `SetupSuite` starts infrastructure, `TearDownSuite` stops it | adapt | Starting shared infrastructure once is fine; Isolated Test Execution step 2 forbids suite setup that creates state tests change | [bb-infra-lifecycle](#rule-bb-infra-lifecycle) | Pattern mappings | judgment |
| <a id="row-42"></a>42 | T `references/integration-testing.md:64-78`, `:128-139`; eval 12.3 | Truncate and reseed shared data before each test | drop | Isolated Test Execution steps 2 and 4: per-test factories, no clearing between tests | [dropped](#drop-42) | — | - |
| <a id="row-43"></a>43 | T `references/integration-testing.md:164-195` | Embedded SQL fixtures loaded by an exported `SetupDB` in the production package | drop | Shared seed data (row 42) and a test-only export (Public API Surface Testing misapplication) | [dropped](#drop-43) | — | - |
| <a id="row-44"></a>44 | T `references/mocking.md:10-73` | testify/mock doubles verified with `AssertExpectations` | keep | Same rule as row 54 | [mock-expectations](#rule-mock-expectations) | Pattern mappings | guard candidate |
| <a id="row-45"></a>45 | T `references/mocking.md:75-141` | Organize mocks alongside the code they mock | already ours | bjornstack.md row 110 (coord-doubles): a double stays in the consumer's test file (Test Data Builders step 2), as T's own example does (`references/mocking.md:94-96`) | [coord-doubles](bjornstack.md#rule-coord-doubles) | Pattern mappings | judgment |
| <a id="row-46"></a>46 | T `references/mocking.md:143-177` | Package-level fixture variables; `NewUser` with `uuid.New()` and `time.Now()` | drop | Contradicts builders-a, builders-ids, clock-inject and Isolated Test Execution steps 2-3 | [dropped](#drop-46) | — | - |
| <a id="row-47"></a>47 | T `references/mocking.md:179-213`; eval 4.1-4.3 | Time-dependent code takes a clock; tests use a fake one (clockwork) | already ours | bjornstack.md row 74 (clock-inject); it names no clock library | [clock-inject](bjornstack.md#rule-clock-inject) | Pattern mappings | guard candidate |
| <a id="row-48"></a>48 | T eval 4.4; `references/mocking.md:181`; `SKILL.md:219-223` | No real `time.Sleep` in test code | keep | Mechanical; ES row 238 says the same | [test-no-sleep](#rule-test-no-sleep) | Pattern mappings | guard candidate |
| <a id="row-49"></a>49 | T `SKILL.md:394-396` | Enforce test practices with `thelper`, `paralleltest`, `testifylint` | keep | Mechanical, Go-specific | [tool-lint](#rule-tool-lint) | Tooling | tool: golangci-lint linters (named by T `SKILL.md:396`) |
| <a id="row-50"></a>50 | TF `SKILL.md:44-49`, `:68`, `:190`; eval 1.1-1.4 | `require` for preconditions, `assert` for verifications | drop | Contradicts test-require (bjornstack.md row 39), the owner's choice | [dropped](#drop-50) | — | - |
| <a id="row-51"></a>51 | TF `SKILL.md:51-66`; eval 2 | `assert.New(t)` / `require.New(t)`, named `is` and `must` | drop | test-whole-value uses the package functions, `require.Equal(t, ...)`; one form for all tests | [dropped](#drop-51) | — | - |
| <a id="row-52"></a>52 | TF `SKILL.md:108`, `:189`; eval 1.5, 3.4 | Argument order `(expected, actual)`; `ErrorIs(err, target)` | keep | Go pitfall: a swapped order prints a backwards diff | [test-arg-order](#rule-test-arg-order) | Go pitfalls | tool: testifylint (named by TF `SKILL.md:196`) |
| <a id="row-53"></a>53 | TF `SKILL.md:119-131`; eval 10 | `EventuallyWithT` with `*assert.CollectT` when the awaited outcome needs several checks | keep | Extends test-eventually (bjornstack.md row 85) without changing where it applies | [test-eventually-witht](#rule-test-eventually-witht) | Pattern mappings | guard candidate |
| <a id="row-54"></a>54 | TF `SKILL.md:135`, `:187`; `references/mock.md:3`; eval 4.3, 5.5, 6.4 | Always verify a testify mock with `AssertExpectations(t)` | keep | `.Test(t)` (coord-doubles) catches unexpected calls, not missing ones | [mock-expectations](#rule-mock-expectations) | Pattern mappings | guard candidate |
| <a id="row-55"></a>55 | TF eval 4.4 | `.Once()` or `.Times(n)` to pin how often a call happens | keep | Eval-only rule; an unpinned count lets a duplicate call pass | [mock-calls](#rule-mock-calls) | Pattern mappings | judgment |
| <a id="row-56"></a>56 | TF eval 4.5 | `mock.Anything` for a context argument | adapt | Only eval 4.5 names ctx, and only as an example of an argument that needs no specific matching | [mock-ctx-anything](#rule-mock-ctx-anything) | Pattern mappings | judgment |
| <a id="row-57"></a>57 | TF `SKILL.md:137`; `references/mock.md:55-58`; eval 5.1-5.3 | `mock.MatchedBy` checking a few fields because a timestamp varies | adapt | Whole-Object Assertion steps 1-2: inject the source and match the whole value; a predicate only for step 2's fallbacks | [mock-match-whole](#rule-mock-match-whole) | Pattern mappings | judgment |
| <a id="row-58"></a>58 | TF `references/mock.md:76-82`; eval 6 | Chain `.Once()` expectations to return different results per call | keep | How a retry unit's test sets up a failure then a success | [mock-calls](#rule-mock-calls) | Pattern mappings | judgment |
| <a id="row-59"></a>59 | TF `SKILL.md:141-162`; eval 7.1-7.2, 7.5 | Suites group tests with shared setup; `SetupTest` per test, `SetupSuite` once | adapt | Suites only as the infrastructure lifecycle of a black-box package (row 41): suite methods keep state on `s`, so they cannot safely call `t.Parallel()`; unit tests stay plain table tests | [test-suite](#rule-test-suite) | Pattern mappings | judgment |
| <a id="row-60"></a>60 | TF `SKILL.md:177-181`, `:191`; eval 7.3 | A suite needs its `suite.Run` launcher, or none of its tests run | keep | Go pitfall: silent | [test-suite](#rule-test-suite) | Pattern mappings | guard candidate |
| <a id="row-61"></a>61 | TF `SKILL.md:183`; eval 8 | Suite methods such as `s.Equal` behave like `assert`; use `s.Require()` | adapt | Under test-require every suite assertion goes through `s.Require()` | [test-suite](#rule-test-suite) | Pattern mappings | guard candidate |
| <a id="row-62"></a>62 | TF `SKILL.md:188`; eval 3.1-3.2 | `Equal(ErrNotFound, err)` fails on a wrapped error; use `ErrorIs` | keep | Go pitfall; fits Failure Identity step 6 | [test-error-is](#rule-test-error-is) | Go pitfalls | guard candidate |
| <a id="row-63"></a>63 | TF `SKILL.md:192`; eval 9 | `Equal(ptr1, ptr2)` compares addresses; dereference or use `EqualExportedValues` | drop | False: `require.Equal` is `reflect.DeepEqual` (bs-f3o.2 comment 2026-11-03 09:09), which compares what the pointers point to | [dropped](#drop-63) | — | - |
| <a id="row-64"></a>64 | TF `SKILL.md:194-196`; eval 11 | Run testifylint | keep | Same rule as row 49 | [tool-lint](#rule-tool-lint) | Tooling | tool: testifylint (named by TF `SKILL.md:196`) |
| <a id="row-65"></a>65 | EH `SKILL.md:22-30`, `:64-72` | Coding, review and audit modes; five audit sub-agents | drop | Instructions for running an agent | [dropped](#drop-1) | — | - |
| <a id="row-66"></a>66 | EH `SKILL.md:40`; `references/error-creation.md:25-40` | Check every returned error; never discard with `_` | adapt | Add CU's exit (row 226): a deliberate discard with a comment saying why; "cannot fail" is only CU's example (`go-error-handling/SKILL.md:86`) | [err-check](#rule-err-check) | Go pitfalls | tool: errcheck (named by SF `SKILL.md:246`) |
| <a id="row-67"></a>67 | EH `references/error-creation.md:25` | A function that can fail returns `error` as its last result | keep | Go convention callers and linters rely on | [err-results](#rule-err-results) | Pattern mappings | guard candidate |
| <a id="row-68"></a>68 | EH `references/error-creation.md:31-39` | Check the error before using the other results | keep | Same rule | [err-results](#rule-err-results) | Pattern mappings | judgment |
| <a id="row-69"></a>69 | EH `SKILL.md:41`; `references/error-wrapping.md:15-28`; eval 5.1, 5.5, 9.2 | Wrap every error with context, at each layer | drop | Contradicts err-wrap-where (bjornstack.md row 121): a private helper's error returns unwrapped | [dropped](#drop-245) | — | - |
| <a id="row-70"></a>70 | EH `SKILL.md:42`; `references/error-creation.md:42-54`; eval 4.2-4.3 | Error strings lower-case, no trailing punctuation | adapt | Add CU's exception (row 224): exported names, proper nouns, acronyms | [err-string](#rule-err-string) | Pattern mappings | guard candidate |
| <a id="row-71"></a>71 | EH `references/error-creation.md:44-60` | Don't repeat context wrapping will add: no `UserService:` prefix | adapt | Keeps the wrapped chain readable (Failure Identity step 5); says what this unit was doing, as err-wrap-where asks. "No 'failed to'" sits only in a bad example (EH `references/error-creation.md:48-49`) and is not taken | [err-string](#rule-err-string) | Pattern mappings | judgment |
| <a id="row-72"></a>72 | EH `SKILL.md:43`; `references/error-wrapping.md:30-48` | `%w` inside the module, `%v` at the public API boundary | drop | Only EH's public-API example (`references/error-wrapping.md:36-46`) diverges: err-wrap-verb (bjornstack.md row 48) puts `%v` at the edge where an outside error enters (Failure Identity step 3); EH's "%v at system boundaries" agrees with it (row 73) | [dropped](#drop-72) | — | - |
| <a id="row-73"></a>73 | EH eval 12 | A gateway inspects backend errors with `errors.As`, translates them to its own sentinels with `%v` | already ours | bjornstack.md row 48 (err-wrap-verb): the gateway is the edge | [err-wrap-verb](bjornstack.md#rule-err-wrap-verb) | Go pitfalls | judgment |
| <a id="row-74"></a>74 | EH `SKILL.md:44`; `references/error-wrapping.md:50-80`; eval 4.4-4.5, 9.3 | `errors.Is` for sentinels, `errors.As` for types; never `==` or a bare type assertion | keep | Go pitfall: both miss a wrapped error | [err-inspect](#rule-err-inspect) | Go pitfalls | guard candidate |
| <a id="row-75"></a>75 | EH `SKILL.md:44`; `references/error-wrapping.md:76-80` | Go 1.26: prefer `errors.AsType[T](err)` | keep | Same check, typed | [err-inspect](#rule-err-inspect) | Go pitfalls | guard candidate |
| <a id="row-76"></a>76 | EH `SKILL.md:45`; `references/error-wrapping.md:82-101`; evals 2.3, 3.5, 6.1, 11.3 | `errors.Join` to combine independent errors, such as field violations | already ours | bjornstack.md row 19 (scrub-collect): Join inside a layer, one error type per thing the caller acts on at the boundary | [scrub-collect](bjornstack.md#rule-scrub-collect) | Pattern mappings | judgment |
| <a id="row-77"></a>77 | EH `references/error-wrapping.md:117-124` | `errors.Is` matches any member of a Join | already ours | bjornstack.md row 50 (err-join-match) | [err-join-match](bjornstack.md#rule-err-join-match) | Go pitfalls | judgment |
| <a id="row-78"></a>78 | EH `references/error-wrapping.md:103-115`; eval 8.2, 8.4 | Close every resource even when one fails; each error names its resource | keep | Eval 8 adds the rule the `closeAll` example implies | [err-close-all](#rule-err-close-all) | Pattern mappings | judgment |
| <a id="row-79"></a>79 | EH `SKILL.md:46`; `references/error-handling.md:12-48`; evals 7, 10.1, 11.5 | Log an error or return it, never both | keep | Each failure appears once in the logs | [err-handle-once](#rule-err-handle-once) | Pattern mappings | judgment |
| <a id="row-80"></a>80 | EH `SKILL.md:47`; `references/error-creation.md:62-69`, `:85-92`, `:117-138`; eval 4.1, 9.4 | Sentinel when the caller matches, custom type when it reads data, `fmt.Errorf` otherwise | adapt | Go spelling of Failure Identity steps 1-2; FI's test is whether a caller handles the failure differently, not whether it is "expected" | [err-identity-form](#rule-err-identity-form) | Pattern mappings | judgment |
| <a id="row-81"></a>81 | EH `SKILL.md:48`; `references/error-handling.md:50-74` | Never panic for expected failures; panic only for programmer errors | adapt | Go form of Fail Early and Loud: an expected failure is a returned error. "MustX only while initialising" is an example label (EH `references/error-handling.md:57`), so the limit is programmer errors | [err-panic](#rule-err-panic) | Pattern mappings | judgment |
| <a id="row-82"></a>82 | EH `references/error-handling.md:76-97` | Recover in a deferred function at goroutine boundaries | adapt | Fail Early and Loud: recovering to carry on keeps a broken invariant running; net/http already recovers panics in handlers | [err-recover](#rule-err-recover) | Pattern mappings | judgment |
| <a id="row-83"></a>83 | EH `SKILL.md:49`; eval 1.1, 7.3, 10.3 | Log with `slog`, not `fmt.Println` or `log.Printf` | keep | Structured logging; the logger comes from ctx (ctx-scope) | [log-slog](#rule-log-slog) | Tooling | guard candidate |
| <a id="row-84"></a>84 | EH `SKILL.md:50`; `references/error-handling.md:99-134`; `references/error-creation.md:73-81`, `:109-113`; evals 1.3, 2.2, 3.2, 5.3, 11.2 | `samber/oops` for stack traces and structured attributes | drop | The author's own library; Failure Identity step 2 puts values in our own error types | [dropped](#drop-84) | — | - |
| <a id="row-85"></a>85 | EH `SKILL.md:51` | Log HTTP requests with middleware: method, path, status, duration | keep | Go spelling of Don't Fly Blind for a server | [log-requests](#rule-log-requests) | Pattern mappings | judgment |
| <a id="row-86"></a>86 | EH `SKILL.md:52` | Use log levels to indicate severity | drop | Names no levels and no mapping, so it decides nothing | [dropped](#drop-86) | — | - |
| <a id="row-87"></a>87 | EH `SKILL.md:53` | Never expose technical errors to users; translate, log details separately | drop | Unit Testing step 3.4 says it for every language | [dropped](#drop-87) | — | - |
| <a id="row-88"></a>88 | EH `SKILL.md:54`; `references/error-creation.md:94-115`; eval 2.1, 7.4-7.5, 10.4 | Stable log messages; IDs, paths and counts as structured attributes | adapt | Applies to log messages only; error messages still name their values (Failure Identity step 5) | [log-static-msg](#rule-log-static-msg) | Pattern mappings | guard candidate |
| <a id="row-89"></a>89 | EH evals 1.2, 3.1, 5.2, 9.1, 11.1 | Error strings stay static: no IDs or row numbers in them | drop | The evals remove the text's exit ("sometimes", "may"); Failure Identity step 5 asks the message to name the values | [dropped](#drop-89) | — | - |
| <a id="row-90"></a>90 | EH `references/error-creation.md:140-157` | A custom type that wraps an error implements `Unwrap()` | adapt | Above the edge only; at the edge it leaks the outside identity (err-unwrap, Failure Identity step 3) | [err-unwrap-where](#rule-err-unwrap-where) | Go pitfalls | judgment |
| <a id="row-91"></a>91 | EH evals 2.5, 3.3, 6.3-6.4 | Validate every field, with cross-field rules, before rejecting | adapt | Differs: the source validates every field; scrub-validate (bjornstack.md row 17) checks acted-on fields only, and Scrub on Entry lists validating everything as a misapplication | [scrub-validate](bjornstack.md#rule-scrub-validate) | Pattern mappings | judgment |
| <a id="row-92"></a>92 | CX `SKILL.md:30`, `:51-65`; eval 1.2-1.3, 6.2, 6.5 | Propagate the same ctx through the whole call chain | already ours | bjornstack.md row 46 (ctx-per-call) | [ctx-per-call](bjornstack.md#rule-ctx-per-call) | Pattern mappings | guard candidate |
| <a id="row-93"></a>93 | CX `SKILL.md:31`; eval 4.5, 7.4 | ctx is the first parameter, named `ctx` | already ours | bjornstack.md row 46 (ctx-per-call) | [ctx-per-call](bjornstack.md#rule-ctx-per-call) | Pattern mappings | guard candidate |
| <a id="row-94"></a>94 | CX `SKILL.md:32`; eval 4 | Never store ctx in a struct | already ours | bjornstack.md row 46 (ctx-per-call) | [ctx-per-call](bjornstack.md#rule-ctx-per-call) | Pattern mappings | guard candidate |
| <a id="row-95"></a>95 | CX `SKILL.md:33`; eval 7.5 | Pass `context.TODO()`, never a nil ctx | keep | Go pitfall: nil panics far from the caller | [ctx-no-nil](#rule-ctx-no-nil) | Go pitfalls | guard candidate |
| <a id="row-96"></a>96 | CX `SKILL.md:34`; `references/cancellation.md:43-60`; eval 2.2-2.3, 6.4 | Call `cancel()` on every path, unless ownership is handed on; `defer cancel()` for scoped work | keep | Go pitfall: leaks the child and its timer | [ctx-cancel](#rule-ctx-cancel) | Go pitfalls | guard candidate |
| <a id="row-97"></a>97 | CX `SKILL.md:35`, `:41-49`; eval 7.2 | `context.Background()` only at entry points: main, init, tests | adapt | Tests take `t.Context()` instead (ES, row 240); `TestMain` has no `t` and starts infrastructure (bb-infra-lifecycle); cleanup outlives `t.Context()` | [ctx-root](#rule-ctx-root) | Pattern mappings | guard candidate |
| <a id="row-98"></a>98 | CX `SKILL.md:47`; `references/http-services.md:9-29`; eval 1.1 | A handler uses `r.Context()`, never a new `Background()` | keep | Same rule | [ctx-root](#rule-ctx-root) | Pattern mappings | guard candidate |
| <a id="row-99"></a>99 | CX `SKILL.md:36`; eval 7.1, 7.3 | `context.TODO()` as the placeholder while no ctx exists yet | adapt | Add ES's limit (row 253): replaced before the change ships | [ctx-todo](#rule-ctx-todo) | Pattern mappings | guard candidate |
| <a id="row-100"></a>100 | CX `SKILL.md:37`; `references/values-tracing.md:7-31`; eval 3.1-3.2 | ctx value keys are unexported types | keep | Go pitfall: string keys collide across packages | [ctx-keys](#rule-ctx-keys) | Pattern mappings | guard candidate |
| <a id="row-101"></a>101 | CX `references/values-tracing.md:18-26`; eval 3.3-3.5 | Typed setter and getter per value; the getter reports a missing value | adapt | Except the logger: `logctx.From` reports nothing and returns a discarding logger (ctx-scope) | [ctx-keys](#rule-ctx-keys) | Pattern mappings | judgment |
| <a id="row-102"></a>102 | CX `SKILL.md:38`; `references/values-tracing.md:3-5`, `:33-41`; eval 9.1, 9.3, 9.5 | Only request-scoped metadata in ctx values; never parameters, connections or flags | adapt | Differs: the source's "request-scoped data" is wider; ctx-scope (bjornstack.md row 47) narrows it to cancellation and program-wide per-goroutine settings (see row 103) | [ctx-scope](bjornstack.md#rule-ctx-scope) | Pattern mappings | judgment |
| <a id="row-103"></a>103 | CX `references/values-tracing.md:38`; eval 9.4; CU `go-context/SKILL.md:83` | The authenticated user or tenant travels in ctx values | adapt | Owner ruling 2026-11-17 (bs-f3o.2, round 2, S-1): ctx-scope is "almost never", not "never". Middleware puts the principal in ctx and the handler passes it on as input; deeper code may read it from ctx only for finer-grained checks | [ctx-principal](#rule-ctx-principal) | Pattern mappings | judgment |
| <a id="row-104"></a>104 | CX `references/values-tracing.md:42`; eval 9.2 | Logger in ctx only when enriched with request fields; eval 9.2: never in ctx | drop | Contradicts ctx-scope (bjornstack.md row 47): the logger lives in ctx only | [dropped](#drop-104) | — | - |
| <a id="row-105"></a>105 | CX `SKILL.md:39`; `references/cancellation.md:163-186`; eval 5 | `context.WithoutCancel` for work that outlives the request | adapt | Add ES's rule (row 252): detached work gets its own timeout | [ctx-detach](#rule-ctx-detach) | Pattern mappings | judgment |
| <a id="row-106"></a>106 | CX `references/cancellation.md:106-128` | Select on `ctx.Done()` alongside other work | keep | Go mechanism for honouring cancellation | [ctx-listen](#rule-ctx-listen) | Pattern mappings | judgment |
| <a id="row-107"></a>107 | CX `references/cancellation.md:130-144` | CPU-bound loops check `ctx.Err()` periodically | keep | Same rule | [ctx-listen](#rule-ctx-listen) | Pattern mappings | judgment |
| <a id="row-108"></a>108 | CX `references/cancellation.md:146-161`; eval 10 | `context.AfterFunc` for cleanup on cancellation; keep its `stop` | keep | Cleanup without blocking the main flow | [ctx-afterfunc](#rule-ctx-afterfunc) | Pattern mappings | judgment |
| <a id="row-109"></a>109 | CX `references/http-services.md:17-24`; eval 1.5 | After a failure, a handler whose `ctx.Err()` is set writes no response | adapt | Rests on a code comment that assumes any ctx error means the client left; when the handler's own timeout fired, the client is still waiting | [ctx-client-gone](#rule-ctx-client-gone) | Pattern mappings | judgment |
| <a id="row-110"></a>110 | CX `references/http-services.md:31-61` | Middleware attaches request values with `r.WithContext` before handlers run | keep | Where row 101's setter is called | [ctx-keys](#rule-ctx-keys) | Pattern mappings | judgment |
| <a id="row-111"></a>111 | CX `references/http-services.md:63-77`; `references/values-tracing.md:44-78` | Copy the trace ID from ctx into outgoing request headers | keep | Keeps one trace across services | [ctx-trace-out](#rule-ctx-trace-out) | Pattern mappings | judgment |
| <a id="row-112"></a>112 | CX `references/http-services.md:80-113`; evals 1.4, 8 | Context-aware calls: `NewRequestWithContext`, `QueryContext`, `ExecContext`, `BeginTx` | keep | Go pitfall: the plain variants ignore cancellation | [ctx-aware-calls](#rule-ctx-aware-calls) | Go pitfalls | guard candidate |
| <a id="row-113"></a>113 | CX eval 2.1, 2.5 | Each retry attempt derives its own timeout from the caller's ctx | adapt | A per-attempt timeout is a design choice from one eval; kept only where an attempt can hang | [ctx-retry-timeout](#rule-ctx-retry-timeout) | Pattern mappings | judgment |
| <a id="row-114"></a>114 | CX `SKILL.md:82-84` | `govet` and `staticcheck` catch context pitfalls | keep | Same rule as row 49 | [tool-lint](#rule-tool-lint) | Tooling | tool: govet, staticcheck (named by CX `SKILL.md:84`) |
| <a id="row-115"></a>115 | PL `SKILL.md:22`, `:26-34`; eval 1.1-1.4 | Ask the developer for the architecture, then the DI approach, one question at a time | drop | Agent process; Domain-First Packaging and coord-inject already decide both | [dropped](#drop-115) | — | - |
| <a id="row-116"></a>116 | PL `SKILL.md:28`; eval 1.5 | Don't over-structure small projects | drop | Domain-First Packaging's SKIP WHEN and over-packaging misapplication say it for every language | [dropped](#drop-116) | — | - |
| <a id="row-117"></a>117 | PL `SKILL.md:36-38`; eval 7.1, 7.5 | 12-factor: config through environment variables | drop | Language-neutral deployment rule; its home is bs-1ep | [dropped](#drop-117) | — | - |
| <a id="row-118"></a>118 | PL `SKILL.md:38`; eval 7.2 | 12-factor: logs to stdout | drop | Same | [dropped](#drop-117) | — | - |
| <a id="row-119"></a>119 | PL `SKILL.md:38` | 12-factor: stateless processes | drop | Same | [dropped](#drop-117) | — | - |
| <a id="row-120"></a>120 | PL `SKILL.md:38` | 12-factor: graceful shutdown | drop | Same | [dropped](#drop-117) | — | - |
| <a id="row-121"></a>121 | PL `SKILL.md:38` | 12-factor: backing services as attached resources | drop | Same | [dropped](#drop-117) | — | - |
| <a id="row-122"></a>122 | PL `SKILL.md:38` | 12-factor: admin tasks as one-off commands (`cmd/migrate/`) | drop | Same; row 126 already gives each binary its `cmd/` directory | [dropped](#drop-117) | — | - |
| <a id="row-123"></a>123 | PL `references/config.md:51` | Configuration is never hard-coded | drop | Same | [dropped](#drop-117) | — | - |
| <a id="row-124"></a>124 | PL `references/config.md:51`; eval 10 | Secrets come from environment variables or a secret manager, never config files | drop | Same | [dropped](#drop-117) | — | - |
| <a id="row-125"></a>125 | PL `SKILL.md:42-48` | Project-type table: a library under `pkg/{name}/` | drop | Contradicted by the skill's own `references/directory-layouts.md:92-96` and eval 8.1 | [dropped](#drop-125) | — | - |
| <a id="row-126"></a>126 | PL `SKILL.md:80`; `references/directory-layouts.md:98-137`; eval 11 | Every `main` package in `cmd/<name>/`, one directory per binary | keep | Mechanical, Go-specific layout | [layout-cmd](#rule-layout-cmd) | Pattern mappings | guard candidate |
| <a id="row-127"></a>127 | PL `SKILL.md:80`; `references/directory-layouts.md:100`; eval 2 | `main` only parses flags, wires dependencies and calls `Run()`; no business logic in `cmd/` | keep | main is where coord-inject's collaborators are built | [layout-cmd](#rule-layout-cmd) | Pattern mappings | judgment |
| <a id="row-128"></a>128 | PL `SKILL.md:80`, `:114`; eval 5.2, 5.5 | An application's packages live under `internal/` | keep | Go's mechanism for Intentionally Public step 1 at the module level | [layout-internal](#rule-layout-internal) | Pattern mappings | judgment |
| <a id="row-129"></a>129 | PL `SKILL.md:80`, `:115`; eval 5.1, 5.4 | `pkg/` only for code useful to other modules | adapt | Intentionally Public step 2 asks for a concrete, current need, which "useful to other modules" does not | [layout-internal](#rule-layout-internal) | Pattern mappings | judgment |
| <a id="row-130"></a>130 | PL `references/directory-layouts.md:72-96`; eval 8 | A library: public packages at the root, private code in `internal/`, no `cmd/` | keep | Go-specific layout | [layout-library](#rule-layout-library) | Pattern mappings | judgment |
| <a id="row-131"></a>131 | PL `references/directory-layouts.md:15-51` | Universal layout with `internal/{app,config,handler,model,service}` | drop | Technical-role packages: Domain-First Packaging step 1 and proto-packages | [dropped](#drop-131) | — | - |
| <a id="row-132"></a>132 | PL `references/directory-layouts.md:143-150`; eval 3.1 | No `src/` directory | keep | Mechanical, Go-specific | [layout-cmd](#rule-layout-cmd) | Pattern mappings | guard candidate |
| <a id="row-133"></a>133 | PL `references/directory-layouts.md:146`; eval 3.6 | No `main.go` at the module root | adapt | Owner ruling 2026-11-17 (bs-f3o.2, S-7): `cmd/<name>/` by default; a root `main.go` is a local exception, decided when the tool is created | [layout-cmd](#rule-layout-cmd) | Pattern mappings | guard candidate |
| <a id="row-134"></a>134 | PL `references/directory-layouts.md:147-149`; eval 3.2-3.5 | No `utils/`, `helpers/`, `common/` packages | already ours | bjornstack.md row 3 (proto-packages) | [proto-packages](bjornstack.md#rule-proto-packages) | For the protocols | guard candidate |
| <a id="row-135"></a>135 | PL `references/directory-layouts.md:152-163` | The fix: `internal/util/` "specific utility names" | drop | Still a technical-role name (proto-packages) | [dropped](#drop-135) | — | - |
| <a id="row-136"></a>136 | PL `SKILL.md:47`, `:98-100`; `references/workspaces.md:12-25`; eval 6 | `go.work` for developing several modules together: a monorepo, modules that import each other, local cross-module testing | keep | Go-specific; the uses the source lists | [layout-workspace](#rule-layout-workspace) | Tooling | judgment |
| <a id="row-137"></a>137 | PL `SKILL.md:56`; eval 4.2 | Module path matches the repository URL | keep | Mechanical, Go-specific | [mod-path](#rule-mod-path) | Tooling | guard candidate |
| <a id="row-138"></a>138 | PL `SKILL.md:57`; eval 4.3 | Module path lower-case only | keep | Same | [mod-path](#rule-mod-path) | Tooling | guard candidate |
| <a id="row-139"></a>139 | PL `SKILL.md:58`; eval 4.4 | Hyphens between words in the module path | keep | Same | [mod-path](#rule-mod-path) | Tooling | guard candidate |
| <a id="row-140"></a>140 | PL `SKILL.md:59`; eval 4.5 | The module name says what it is for | keep | Same | [mod-path](#rule-mod-path) | Tooling | judgment |
| <a id="row-141"></a>141 | PL `SKILL.md:74-76` | Package names lower-case, singular, matching the directory | adapt | pkg-naming (bjornstack.md row 1) holds lower-case nouns; add matching the directory. "Singular" is contradicted by the standard library (`strings`, `bytes`, `errors`) | [pkg-dir](#rule-pkg-dir) | Pattern mappings | guard candidate |
| <a id="row-142"></a>142 | PL `SKILL.md:88`; `assets/Makefile` | A Makefile at the root | drop | Build automation is the project's choice; nothing about Go code | [dropped](#drop-142) | — | - |
| <a id="row-143"></a>143 | PL `SKILL.md:89`, `:118`; `assets/.gitignore` | A `.gitignore` with `/vendor/` and binaries | drop | Same | [dropped](#drop-142) | — | - |
| <a id="row-144"></a>144 | PL `SKILL.md:90` | A `.golangci.yml` at the root | keep | Where tool-lint's linters are configured | [tool-lint](#rule-tool-lint) | Tooling | tool: golangci-lint (named by PL `SKILL.md:90`) |
| <a id="row-145"></a>145 | PL `SKILL.md:92`; `references/config.md:1-49` | Config struct with `mapstructure` tags loaded by Viper in `cmd/` | drop | A library choice no rule needs | [dropped](#drop-145) | — | - |
| <a id="row-146"></a>146 | PL `SKILL.md:96`; `references/testing-layout.md:26-47`; eval 9.1-9.3 | Tests sit beside the code they test; no central `tests/` directory | already ours | bjornstack.md row 63 (test-pkg) for package tests; black-box tests are the exception, in their own package (bb-package) | [test-pkg](bjornstack.md#rule-test-pkg) | Pattern mappings | guard candidate |
| <a id="row-147"></a>147 | PL `references/testing-layout.md:49-53`, `:55-88`; eval 9.5 | Unit tests in the same package; `_test` package for behavioural tests | drop | Contradicts test-pkg (bjornstack.md row 63) | [dropped](#drop-147) | — | - |
| <a id="row-148"></a>148 | PL `references/testing-layout.md:15-24`, `:90-131`, `:219-226` | `_bench_test.go` and `{package}_example_test.go` files, in the code's own package | drop | Contradicts test-pkg: the files sit in the code's own package; test-file-name allows a split by concern | [dropped](#drop-148) | — | - |
| <a id="row-149"></a>149 | PL `references/testing-layout.md:141-159`, `:227` | Shared test helpers in `test/testutils/` or `internal/testutil/` | drop | Contradicts builders-a, Test Data Builders step 2 and proto-packages | [dropped](#drop-149) | — | - |
| <a id="row-150"></a>150 | PL `SKILL.md:96`; `references/testing-layout.md:165-176`; eval 9.4 | Package-specific fixture files in `testdata/` | keep | Go tool convention | [test-testdata](#rule-test-testdata) | Pattern mappings | judgment |
| <a id="row-151"></a>151 | PL `references/testing-layout.md:178-188`, `:205` | Fixture files shared across packages in `test/fixtures/` | drop | Isolated Test Execution step 2 ("factories, not fixtures") and builders-a: data several packages share is built per test | [dropped](#drop-151) | — | - |
| <a id="row-152"></a>152 | PL `references/testing-layout.md:203`, `:206` | No `.go` files in `testdata/`: the go tool ignores them | keep | Go pitfall | [test-testdata](#rule-test-testdata) | Pattern mappings | guard candidate |
| <a id="row-153"></a>153 | PL `SKILL.md:111` | Run `go version` to detect the current Go version | drop | Agent setup step | [dropped](#drop-153) | — | - |
| <a id="row-154"></a>154 | PL `SKILL.md:117` | `gofmt -s -w .` | already ours | bjornstack.md row 78 (tool-finish); ours checks `gofmt -l .` without `-s` | [tool-finish](bjornstack.md#rule-tool-finish) | Tooling | tool: gofmt, go vet, go test (named by the P0 brief) |
| <a id="row-155"></a>155 | PL `SKILL.md:119`, `:129` | Write the always-load directive for `golang-how-to` into CLAUDE.md | drop | Installs a skill; owner ruled install none (bjornstack.md row 56) | [dropped](#drop-155) | — | - |
| <a id="row-156"></a>156 | SI `SKILL.md:28-52`, `:289` | Interfaces of one to three methods; compose larger ones | adapt | The source says "SHOULD have 1-3 methods" and names 5+ as the mistake (SI `SKILL.md:34`, `:289`); the number is a prompt to look for a split, not a cap, as Unit Testing 3.1 treats counts | [iface-small](#rule-iface-small) | Pattern mappings | judgment |
| <a id="row-157"></a>157 | SI `SKILL.md:64-81`, `:290`; eval 1 | Interfaces defined where consumed | keep | Same rule as row 11 | [iface-consumer](#rule-iface-consumer) | Pattern mappings | judgment |
| <a id="row-158"></a>158 | SI `SKILL.md:83-93`, `:291`; eval 2 | Accept interfaces, return concrete types | keep | Go convention; callers keep the whole type | [iface-return-concrete](#rule-iface-return-concrete) | Pattern mappings | judgment |
| <a id="row-159"></a>159 | SI `SKILL.md:95-110`, `:298`; eval 3 | No premature interfaces; extract one when a second consumer, implementation or test double needs it | adapt | Keep its test-double exit: a coordinator's collaborators are replaced by doubles (Unit Testing step 3.3), so they are interfaces from the start | [iface-when](#rule-iface-when) | Pattern mappings | judgment |
| <a id="row-160"></a>160 | SI `SKILL.md:112-136`, `:299`; eval 4 | Make the zero value useful; initialise maps lazily | adapt | For types that need nothing from the caller; a type built from collaborators is built by its constructor (coord-inject) | [zero-value](#rule-zero-value) | Pattern mappings | judgment |
| <a id="row-161"></a>161 | SI `SKILL.md:138-148`, `:300`; eval 10 | Generics over `any` where the type is known; `any` only at true boundaries | keep | Go-specific | [generics-over-any](#rule-generics-over-any) | Pattern mappings | judgment |
| <a id="row-162"></a>162 | SI `SKILL.md:150-163`, `:297` | Honour canonical method signatures: `String()`, never `ToString()` | keep | Go convention | [iface-canonical](#rule-iface-canonical) | Pattern mappings | guard candidate |
| <a id="row-163"></a>163 | SI `SKILL.md:165-173`, `:296`; eval 6 | Compile-time check `var _ I = (*T)(nil)` near the type | adapt | Add CU's limit (row 232): only where no other static conversion would catch it | [iface-assert-compile](#rule-iface-assert-compile) | Pattern mappings | judgment |
| <a id="row-164"></a>164 | SI `SKILL.md:175-177`, `:292`; `references/type-assertions.md:3-16`; eval 7 | Type assertions use the comma-ok form | keep | Go pitfall: the single-value form panics | [type-assert-ok](#rule-type-assert-ok) | Go pitfalls | tool: forcetypeassert (named by SF `SKILL.md:246`) |
| <a id="row-165"></a>165 | SI `SKILL.md:177`; `references/type-assertions.md:39-60`; eval 8 | Assert to a small optional interface (`Flusher`) to use a richer implementation | keep | Go pattern | [iface-optional](#rule-iface-optional) | Pattern mappings | judgment |
| <a id="row-166"></a>166 | SI `references/type-assertions.md:62-64` | Assert to the smallest interface, not a concrete type | keep | Same rule | [iface-optional](#rule-iface-optional) | Pattern mappings | judgment |
| <a id="row-167"></a>167 | SI `references/type-assertions.md:35` | In a type switch, concrete types before interfaces they satisfy | keep | Go pitfall: the later case is unreachable | [type-switch](#rule-type-switch) | Go pitfalls | guard candidate |
| <a id="row-168"></a>168 | SI `references/type-assertions.md:37` | `case nil` when nil is a valid input | keep | Go pitfall: nil falls to `default` | [type-switch](#rule-type-switch) | Go pitfalls | judgment |
| <a id="row-169"></a>169 | SI `references/type-assertions.md:66-68` | Inspect errors with `errors.As`, not a type assertion | keep | Same rule as row 74 | [err-inspect](#rule-err-inspect) | Go pitfalls | guard candidate |
| <a id="row-170"></a>170 | SI `SKILL.md:181-221`, `:293`; eval 5 | Embed only to promote the whole API; a named field otherwise | adapt | Add CU's warning (row 233): embedding in an exported struct puts the inner method set in the public API | [embed-when](#rule-embed-when) | Pattern mappings | judgment |
| <a id="row-171"></a>171 | SI `SKILL.md:223-237` | Accept dependencies as interfaces in constructors | already ours | bjornstack.md row 69 (coord-inject) | [coord-inject](bjornstack.md#rule-coord-inject) | Pattern mappings | judgment |
| <a id="row-172"></a>172 | SI `SKILL.md:243-254`, `:294`; `references/struct-fields.md:3-17` | Every exported field of a serialized struct has a tag | keep | Go pitfall: renaming a field silently changes the wire format | [tags](#rule-tags) | Pattern mappings | guard candidate |
| <a id="row-173"></a>173 | SI `references/struct-fields.md:34` | Unexported fields are not serialized; a tag on one does nothing | keep | Go pitfall; an embedded unexported struct (not a pointer) is the exception, since `encoding/json` promotes its exported fields | [tags](#rule-tags) | Pattern mappings | guard candidate |
| <a id="row-174"></a>174 | SI `references/struct-fields.md:35` | `omitempty` drops zero values; use a pointer, `mo.Option` or `omitzero` when zero and absent differ | adapt | Drop `mo.Option`, a library no rule needs | [tags](#rule-tags) | Pattern mappings | judgment |
| <a id="row-175"></a>175 | SI `references/struct-fields.md:36-38` | `go vet` structtag in CI | already ours | bjornstack.md row 78 (tool-finish) runs `go vet ./...` | [tool-finish](bjornstack.md#rule-tool-finish) | Tooling | tool: gofmt, go vet, go test (named by the P0 brief) |
| <a id="row-176"></a>176 | SI `references/struct-fields.md:38` | A marshal-unmarshal round trip catches field-name drift | drop | A round trip passes after a rename, the case the source names; tags covers renames | [dropped](#drop-176) | — | - |
| <a id="row-177"></a>177 | SI `SKILL.md:256-266` | Pointer receiver when the method modifies, holds a mutex or is large; value for small immutable types | keep | Go-specific | [receivers](#rule-receivers) | Pattern mappings | judgment |
| <a id="row-178"></a>178 | SI `SKILL.md:267`, `:295`; eval 11; CU `go-interfaces/SKILL.md:133-137` | All methods of a type use the same receiver kind | keep | Same rule | [receivers](#rule-receivers) | Pattern mappings | guard candidate |
| <a id="row-179"></a>179 | SI `SKILL.md:269-275`; `references/struct-fields.md:40-71`; eval 9 | `noCopy` sentinel for structs that must not be copied; pass by pointer | adapt | Go-specific; only for a struct holding no lock, since copylocks already reports a struct with a `sync.Mutex` | [nocopy](#rule-nocopy) | Go pitfalls | tool: `go vet` copylocks (named by SI `SKILL.md:273`) |
| <a id="row-180"></a>180 | SF `SKILL.md:30` | Generics over `any` when the type set is known | keep | Same rule as row 161 | [generics-over-any](#rule-generics-over-any) | Pattern mappings | judgment |
| <a id="row-181"></a>181 | SF `SKILL.md:31`, `:263`; eval 7 | Comma-ok type assertions | keep | Same rule as row 164 | [type-assert-ok](#rule-type-assert-ok) | Go pitfalls | tool: forcetypeassert (named by SF `SKILL.md:246`) |
| <a id="row-182"></a>182 | SF `SKILL.md:31`, `:248-256` | Go 1.25: `reflect.TypeAssert[T](v)` over `v.Interface().(T)` | keep | Mechanical | [type-assert-ok](#rule-type-assert-ok) | Go pitfalls | guard candidate |
| <a id="row-183"></a>183 | SF `SKILL.md:32`, `:44-67`, `:264`; `references/nil-safety.md:98-121`; evals 1, 13, 25 | A typed nil pointer in an interface is not nil; return untyped `nil` | keep | Go pitfall | [typed-nil](#rule-typed-nil) | Go pitfalls | judgment |
| <a id="row-184"></a>184 | SF `SKILL.md:33`, `:69-91`, `:265`; evals 9, 28 | Writing to a nil map panics; initialise before use | keep | Go pitfall | [nil-collections](#rule-nil-collections) | Go pitfalls | judgment |
| <a id="row-185"></a>185 | SF `SKILL.md:69-75`, `:273` | A nil channel blocks forever; initialise before use | keep | Go pitfall, except where a nil channel deliberately disables a `select` case | [nil-collections](#rule-nil-collections) | Go pitfalls | judgment |
| <a id="row-186"></a>186 | SF `SKILL.md:34`, `:95-107`, `:266`; `references/slice-map-safety.md:67-89`; evals 2, 24 | `append` may share the backing array; full slice expression or `slices.Clone` first | keep | Go pitfall | [append-alias](#rule-append-alias) | Go pitfalls | judgment |
| <a id="row-187"></a>187 | SF `SKILL.md:109-111` | Maps are never accessed concurrently without synchronisation | keep | Go pitfall | [map-concurrent](#rule-map-concurrent) | Go pitfalls | judgment |
| <a id="row-188"></a>188 | SF `SKILL.md:35`, `:188-208`, `:271`; evals 3, 11, 15, 34 | Return copies of internal slices and maps; collection fields unexported | keep | Matches compliance-suite's returned-copy check; the source's "SHOULD" kept as a documented exit | [copy-out](#rule-copy-out) | Pattern mappings | judgment |
| <a id="row-189"></a>189 | SF eval 26 | A constructor copies a caller's slice it keeps | keep | The ingress side of row 188; SF eval 26 and cxuu go-defensive (row 259) state it | [copy-out](#rule-copy-out) | Pattern mappings | judgment |
| <a id="row-190"></a>190 | SF `references/slice-map-safety.md:116-131` | `slices.Clone` and `maps.Clone` as the preferred way to copy | keep | Same rule; the source calls Clone "the preferred way" (SF `references/slice-map-safety.md:131`), not the only one | [copy-out](#rule-copy-out) | Pattern mappings | judgment |
| <a id="row-191"></a>191 | SF `SKILL.md:36`, `:158-182`, `:267`; evals 4, 18, 27, 35 | `defer` in a loop runs at function exit; extract the body | keep | Go pitfall | [defer-loop](#rule-defer-loop) | Go pitfalls | guard candidate |
| <a id="row-192"></a>192 | SF `SKILL.md:37`, `:115-129`, `:268`; evals 5, 20, 30 | Bounds-check before narrowing an integer | adapt | Same split as div-zero: Scrub on Entry checks outside values at the boundary, and code past it does not re-check (its "re-validating" misapplication) | [int-narrow](#rule-int-narrow) | Go pitfalls | guard candidate |
| <a id="row-193"></a>193 | SF `SKILL.md:38`, `:131-141`, `:269`; evals 10, 23 | Compare floats with a tolerance or use `math/big` | keep | Go pitfall | [float-compare](#rule-float-compare) | Go pitfalls | judgment |
| <a id="row-194"></a>194 | SF eval 23.4, 31.5 | `reflect.DeepEqual` compares floats with `==` | adapt | Eval-only fact that `require.Equal` inherits; spelled for test-whole-value by analogy with Whole-Object Assertion step 2 | [test-float](#rule-test-float) | Go pitfalls | judgment |
| <a id="row-195"></a>195 | SF `SKILL.md:143-156`, `:270`; evals 17, 33, 36 | Guard integer division by zero; float division gives Inf or NaN | adapt | Where zero is invalid input, Scrub on Entry rejects it at the boundary and domain code does not re-check (its "re-validating" misapplication) | [div-zero](#rule-div-zero) | Go pitfalls | judgment |
| <a id="row-196"></a>196 | SF `SKILL.md:39`, `:210-221`; eval 19 | Design useful zero values | adapt | Same rule as row 160 | [zero-value](#rule-zero-value) | Pattern mappings | judgment |
| <a id="row-197"></a>197 | SF `references/nil-safety.md:162-180` | A constructor that sets defaults | keep | The other half of the same rule; the source's claim that it makes the zero value impossible for outside callers is false for an exported type (`var c pkg.Client` still compiles) | [zero-value](#rule-zero-value) | Pattern mappings | judgment |
| <a id="row-198"></a>198 | SF `SKILL.md:40`, `:222-238` | `sync.Once` for lazy initialisation under concurrency | keep | Go-specific | [sync-once](#rule-sync-once) | Pattern mappings | judgment |
| <a id="row-199"></a>199 | SF `SKILL.md:240-242`, `:272` | No ordering assumptions between `init()` functions; explicit constructors instead | keep | Go pitfall | [init-order](#rule-init-order) | Go pitfalls | judgment |
| <a id="row-200"></a>200 | SF `SKILL.md:244-246` | `errcheck`, `forcetypeassert`, `nilerr`, `govet`, `staticcheck` | keep | Same rule as row 49 | [tool-lint](#rule-tool-lint) | Tooling | tool: golangci-lint linters (named by SF `SKILL.md:246`) |
| <a id="row-201"></a>201 | SF `references/nil-safety.md:19-43`; eval 14 | Check for nil before calling methods on pointers from external sources; never call a method on a nil pointer | adapt | Checked where external data crosses the system boundary (Scrub on Entry steps 1 and 4); code past that point does not re-check it (Scrub on Entry outcome) | [nil-entry](#rule-nil-entry) | Pattern mappings | judgment |
| <a id="row-202"></a>202 | SF `references/nil-safety.md:45-58` | Nil-safe receivers sparingly, documented when nil is expected | keep | Go-specific; the source's optional components are an example, not the only case (SF `references/nil-safety.md:47`, `:58`) | [nil-entry](#rule-nil-entry) | Pattern mappings | judgment |
| <a id="row-203"></a>203 | SF `references/nil-safety.md:60-96`; evals 8, 22, 32 | Never call a nil func; check it or give a no-op default | keep | Go pitfall | [nil-func](#rule-nil-func) | Go pitfalls | judgment |
| <a id="row-204"></a>204 | SF `references/nil-safety.md:127-160` | Generic code handles the zero value of type parameters correctly | drop | The failing case does not compile; the rest names nothing to apply | [dropped](#drop-204) | — | - |
| <a id="row-205"></a>205 | SF `references/slice-map-safety.md:18-43`, `:45-63` | Before Go 1.22, never capture or take the address of a loop variable | drop | Applies only to modules on Go 1.21 or older | [dropped](#drop-205) | — | - |
| <a id="row-206"></a>206 | SF `references/slice-map-safety.md:65` | Prefer `&items[i]` to `&item` even on Go 1.22+ | drop | `&items[i]` aliases the element, `&item` points at a per-iteration copy; which one is right follows from whether the code must change the element, so no preference rule is needed | [dropped](#drop-206) | — | - |
| <a id="row-207"></a>207 | SF `references/slice-map-safety.md:91-114`; evals 6, 21, 29 | Clone a small piece kept from a large slice so the array can be freed | keep | Go pitfall | [subslice-retain](#rule-subslice-retain) | Go pitfalls | judgment |
| <a id="row-208"></a>208 | SF `references/slice-map-safety.md:133-149`; eval 16 | Never depend on map iteration order; sort the keys | keep | Go pitfall | [map-order](#rule-map-order) | Go pitfalls | judgment |
| <a id="row-209"></a>209 | SF `references/slice-map-safety.md:166-187` | Delete from a slice with `slices.DeleteFunc` or backwards, not inside a forward `range` | keep | Go pitfall | [slice-delete](#rule-slice-delete) | Go pitfalls | guard candidate |
| <a id="row-210"></a>210 | SF `references/slice-map-safety.md:189-207` | `slices.Equal` / `maps.Equal`, never `==` | drop | `==` on slices and maps does not compile, so the compiler enforces it | [dropped](#drop-210) | — | - |
| <a id="row-211"></a>211 | SF eval 27.5 | Check the error from `Close` on a file you wrote | keep | Eval-only rule; a write error can surface only at `Close` | [err-close-write](#rule-err-close-write) | Go pitfalls | guard candidate |
| <a id="row-212"></a>212 | SF evals 18.4, 35.4 | Preallocate a result slice with `make([]T, 0, n)` | drop | Performance choice no rule asks for | [dropped](#drop-212) | — | - |
| <a id="row-213"></a>213 | SF eval 6.3 | Check a slice's length before slicing a fixed prefix, or document the precondition | keep | Eval-only rule; slicing past the length panics | [slice-bounds](#rule-slice-bounds) | Go pitfalls | judgment |
| <a id="row-214"></a>214 | SF eval 33.4 | Multiply before dividing in integer percentages | drop | Arithmetic, not a Go convention | [dropped](#drop-212) | — | - |
| <a id="row-215"></a>215 | SF eval 16.3 | `strings.Builder` instead of `+=` in a loop | drop | Performance choice no rule asks for | [dropped](#drop-212) | — | - |
| <a id="row-216"></a>216 | CU `go-testing/SKILL.md:55-68` | No assertion libraries; `cmp.Diff` | drop | Contradicts test-require (bjornstack.md row 39) | [dropped](#drop-50) | — | - |
| <a id="row-217"></a>217 | CU `go-testing/SKILL.md:35-51` | Failure messages name function, inputs, got and want; got first | drop | test-messages (bjornstack.md row 92) and `require`'s diff cover it | [dropped](#drop-217) | — | - |
| <a id="row-218"></a>218 | CU `go-testing/SKILL.md:72-80` | `t.Error` by default, `t.Fatal` only when continuing is impossible | drop | Contradicts test-require (bjornstack.md row 39) | [dropped](#drop-50) | — | - |
| <a id="row-219"></a>219 | CU `go-testing/SKILL.md:82-83`; ES `go-test-quality/SKILL.md:206-209` | `t.Fatal`, `t.FailNow` and `require` only on the test goroutine | keep | Go pitfall: from another goroutine they cannot stop the test | [test-goroutine-fatal](#rule-test-goroutine-fatal) | Go pitfalls | tool: `go vet` testinggoroutine for `t.Fatal`/`t.FailNow`, testifylint go-require for `require.*` (named by ES `go-test-quality/SKILL.md:207-209`) |
| <a id="row-220"></a>220 | CU `go-testing/SKILL.md:91-101` | A single `shouldErr` bool in a table is acceptable | drop | Contradicts test-table (bjornstack.md row 64): assertion functions, no conditionals | [dropped](#drop-220) | — | - |
| <a id="row-221"></a>221 | CU `go-testing/SKILL.md:107-122`; ES `go-test-quality/SKILL.md:124-125` | Helpers register teardown with `t.Cleanup`, not `defer` | keep | Runs after `t.FailNow` and is scoped to the test | [test-cleanup](#rule-test-cleanup) | Pattern mappings | guard candidate |
| <a id="row-222"></a>222 | CU `go-testing/SKILL.md:126-144` | Test error semantics, not message strings | drop | Failure Identity step 6 says it for every language; row 74 gives the Go spelling | [dropped](#drop-222) | — | - |
| <a id="row-223"></a>223 | CU `go-error-handling/SKILL.md:35-46` | Exported functions return `error`, never a concrete error type | keep | Go pitfall behind row 183 | [typed-nil](#rule-typed-nil) | Go pitfalls | guard candidate |
| <a id="row-224"></a>224 | CU `go-error-handling/SKILL.md:48-62` | Error strings lower-case except exported names, proper nouns, acronyms | adapt | The exception row 70 takes | [err-string](#rule-err-string) | Pattern mappings | guard candidate |
| <a id="row-225"></a>225 | CU `go-error-handling/SKILL.md:64-67` | Non-error results are unspecified when an error is returned | keep | Same rule as row 68 | [err-results](#rule-err-results) | Pattern mappings | judgment |
| <a id="row-226"></a>226 | CU `go-error-handling/SKILL.md:74-87` | Ignore an error only deliberately, with a comment saying why | adapt | The exit row 66 takes | [err-check](#rule-err-check) | Go pitfalls | tool: errcheck (named by SF `SKILL.md:246`) |
| <a id="row-227"></a>227 | CU `go-error-handling/SKILL.md:99-113` | No in-band errors (`-1`, `""`); return `(T, bool)` or an error | keep | Go-specific | [err-no-inband](#rule-err-no-inband) | Pattern mappings | judgment |
| <a id="row-228"></a>228 | CU `go-error-handling/SKILL.md:163-164` | `%w` at the end of the format string | keep | Keeps the wrapped chain reading outermost first | [err-string](#rule-err-string) | Pattern mappings | guard candidate |
| <a id="row-229"></a>229 | CU `go-error-handling/SKILL.md:24` | `%v` at a storage or RPC boundary | already ours | bjornstack.md row 48 (err-wrap-verb) | [err-wrap-verb](bjornstack.md#rule-err-wrap-verb) | Go pitfalls | judgment |
| <a id="row-230"></a>230 | CU `go-context/SKILL.md:52-70` | No custom Context types or interfaces in signatures | keep | Go convention | [ctx-no-custom](#rule-ctx-no-custom) | Pattern mappings | guard candidate |
| <a id="row-231"></a>231 | CU `go-context/SKILL.md:72-91` | Data goes in parameters, then receivers, then globals; ctx values only for request-scoped data | adapt | Differs: CU's "request-scoped data" is wider and lists auth info (`go-context/SKILL.md:83`); ctx-scope (bjornstack.md row 47) narrows it (see row 103) | [ctx-scope](bjornstack.md#rule-ctx-scope) | Pattern mappings | judgment |
| <a id="row-232"></a>232 | CU `go-interfaces/SKILL.md:109-127` | Interface satisfaction checks only where no other static conversion catches it | adapt | The limit row 163 takes | [iface-assert-compile](#rule-iface-assert-compile) | Pattern mappings | judgment |
| <a id="row-233"></a>233 | CU `go-interfaces/SKILL.md:102-105` | Avoid embedding types in public structs | adapt | The warning row 170 takes, softened: embedding is allowed where the whole method set is meant to be public | [embed-when](#rule-embed-when) | Pattern mappings | judgment |
| <a id="row-234"></a>234 | ES `go-test-quality/SKILL.md:122-123` | Factory functions with options for complex test objects | already ours | bjornstack.md row 27 (builders-a); test-sut-options is for when a full builder would be more than the type needs | [builders-a](bjornstack.md#rule-builders-a) | Pattern mappings | judgment |
| <a id="row-235"></a>235 | ES `go-test-quality/SKILL.md:137` | Golden files in `testdata/` for complex output (JSON, HTML, SQL) | adapt | Whole-Object Assertion's misapplication: output with a structure the language can compare, such as JSON, is decoded and compared as a value | [test-golden](#rule-test-golden) | Pattern mappings | judgment |
| <a id="row-236"></a>236 | ES `go-test-quality/SKILL.md:142-148` | Don't mock value objects, pure functions, the stdlib, or your own code in the same package | drop | The last item contradicts Unit Testing step 3.3, and "don't mock the stdlib" contradicts step 3.2; step 2.1 already covers the rest | [dropped](#drop-236) | — | - |
| <a id="row-237"></a>237 | ES `go-test-quality/SKILL.md:158-160` | No `t.Parallel()` with shared mutable state or shared files; `t.Setenv` and `t.Chdir` panic in a parallel test | adapt | The exit row 7 takes, narrowed to process-wide state; shared files and data get scoped instead | [test-parallel](#rule-test-parallel) | Pattern mappings | tool: paralleltest (named by T `SKILL.md:396`) |
| <a id="row-238"></a>238 | ES `go-test-quality/SKILL.md:174-175` | Never synchronise a test with `time.Sleep` | keep | Same rule as row 48 | [test-no-sleep](#rule-test-no-sleep) | Pattern mappings | guard candidate |
| <a id="row-239"></a>239 | ES `go-test-quality/SKILL.md:183-185` | Any package that starts goroutines checks for leaks with goleak | keep | Same rule as row 9 | [test-goleak](#rule-test-goleak) | Tooling | guard candidate |
| <a id="row-240"></a>240 | ES `go-test-quality/SKILL.md:189-191`; `go-context/SKILL.md:206-207` | Tests use `t.Context()`, not `context.Background()` | keep | The test half of row 97 | [ctx-root](#rule-ctx-root) | Pattern mappings | guard candidate |
| <a id="row-241"></a>241 | ES `go-test-quality/SKILL.md:203-205` | Build `assert.New`/`require.New` inside each `t.Run` | keep | Same rule as row 22 | [test-subtest-t](#rule-test-subtest-t) | Go pitfalls | guard candidate |
| <a id="row-242"></a>242 | ES `go-test-quality/SKILL.md:210-211` | `require` for preconditions, `assert` for independent checks | drop | Contradicts test-require (bjornstack.md row 39) | [dropped](#drop-50) | — | - |
| <a id="row-243"></a>243 | ES `go-test-quality/SKILL.md:212` | `assert.Eventually` hides timing bugs; prefer `synctest` | already ours | bjornstack.md row 85 (test-eventually): time-dependent logic uses clock-inject, `Eventually` only waits on asynchronous outcomes in black-box tests | [test-eventually](bjornstack.md#rule-test-eventually) | Pattern mappings | judgment |
| <a id="row-244"></a>244 | ES `go-error-handling/SKILL.md:98-108` | A custom type that wraps a cause must expose it with `Unwrap` | adapt | Same rule as row 90 | [err-unwrap-where](#rule-err-unwrap-where) | Go pitfalls | judgment |
| <a id="row-245"></a>245 | ES `go-error-handling/SKILL.md:111-131` | Always add context when propagating; a bare `return err` is bad | drop | Contradicts err-wrap-where (bjornstack.md row 121): a private helper's error returns unwrapped | [dropped](#drop-245) | — | - |
| <a id="row-246"></a>246 | ES `go-context/SKILL.md:190-192` | ctx values: request ID, trace or span ID, a request-scoped logger | already ours | bjornstack.md row 47 (ctx-scope) | [ctx-scope](bjornstack.md#rule-ctx-scope) | Pattern mappings | judgment |
| <a id="row-247"></a>247 | ES `go-context/SKILL.md:190-191` | ctx values: the authenticated user | adapt | Same as row 103 | [ctx-principal](#rule-ctx-principal) | Pattern mappings | judgment |
| <a id="row-248"></a>248 | ES `go-context/SKILL.md:194-196` | Export accessor functions so callers never type-assert `ctx.Value` | keep | Same rule as row 101 | [ctx-keys](#rule-ctx-keys) | Pattern mappings | judgment |
| <a id="row-249"></a>249 | ES `go-context/SKILL.md:206-208` | Wrap the call under test in `context.WithTimeout` so a hang fails the test | keep | Bounds one test, unlike row 27's panic | [test-ctx](#rule-test-ctx) | Pattern mappings | judgment |
| <a id="row-250"></a>250 | ES `go-context/SKILL.md:208-209` | Assert `errors.Is(err, context.Canceled)` to prove cancellation is honoured | keep | Works because err-wrap-verb always wraps ctx errors with `%w` | [test-ctx](#rule-test-ctx) | Pattern mappings | judgment |
| <a id="row-251"></a>251 | ES `go-context/SKILL.md:213-219` | `WithCancelCause`, `WithTimeoutCause` to record why work was cancelled | keep | A cancellation that says why (Fail Early and Loud) | [ctx-cause](#rule-ctx-cause) | Pattern mappings | judgment |
| <a id="row-252"></a>252 | ES `go-context/SKILL.md:221-224` | Detached work always gets its own timeout | adapt | Joins row 105's `WithoutCancel` | [ctx-detach](#rule-ctx-detach) | Pattern mappings | judgment |
| <a id="row-253"></a>253 | ES `go-context/SKILL.md:233` | `context.TODO()` is a smell in production code; replace it before shipping | keep | The limit row 99 takes | [ctx-todo](#rule-ctx-todo) | Pattern mappings | guard candidate |
| <a id="row-254"></a>254 | CU `go-defensive/SKILL.md:107-119`, `:30`, `:44` | Enums start at `iota + 1` unless zero is the sensible default | keep | Go pitfall: an unset field reads as the first enum value | [enum-zero](#rule-enum-zero) | Go pitfalls | judgment |
| <a id="row-255"></a>255 | CU `go-defensive/SKILL.md:31`, `:140-150` | `crypto/rand` for keys and tokens, never `math/rand` | keep | Go pitfall: `math/rand` output is predictable | [rand-crypto](#rule-rand-crypto) | Go pitfalls | guard candidate |
| <a id="row-256"></a>256 | CU `go-defensive/SKILL.md:29`, `:43` | `time.Time` and `time.Duration` instead of raw integers | keep | Go-specific; the type carries the unit | [time-types](#rule-time-types) | Pattern mappings | judgment |
| <a id="row-257"></a>257 | CU `go-defensive/SKILL.md:171` | No panic across package boundaries | adapt | A broken invariant still panics to the top, since nothing recovers to carry on (err-recover) | [err-panic](#rule-err-panic) | Pattern mappings | judgment |
| <a id="row-258"></a>258 | CU `go-defensive/SKILL.md:156-157`, `:172` | Library functions avoid panic; a panic in `init()` is acceptable | keep | Same rule as row 81 | [err-panic](#rule-err-panic) | Pattern mappings | judgment |
| <a id="row-259"></a>259 | CU `go-defensive/SKILL.md:25`, `:40`, `:63-65` | Copy slices and maps received from callers at every API boundary | keep | The ingress side of row 188, as row 189 | [copy-out](#rule-copy-out) | Pattern mappings | judgment |
| <a id="row-260"></a>260 | T eval 10.2, 10.4 | `t.Helper()` is the first line of a test helper | already ours | bjornstack.md row 91 (test-helper) | [test-helper](bjornstack.md#rule-test-helper) | Pattern mappings | guard candidate |
| <a id="row-261"></a>261 | SF eval 12.1 | Receive with comma-ok to tell a closed channel from a zero value | keep | Go pitfall: a closed channel yields zero values forever | [chan-close](#rule-chan-close) | Go pitfalls | judgment |
| <a id="row-262"></a>262 | SF eval 12.4 | A function taking channels as variadic arguments handles a nil one | keep | Same pitfall as row 185 | [nil-collections](#rule-nil-collections) | Go pitfalls | judgment |
| <a id="row-263"></a>263 | SF eval 12.2 | An output channel is closed exactly once, by its sender | keep | Go pitfall: a second close panics | [chan-close](#rule-chan-close) | Go pitfalls | judgment |
| <a id="row-264"></a>264 | SF eval 14.2 | Return a meaningful error when a `Notifier` dependency is nil | drop | Contradicts SF's own text (`references/nil-safety.md:52`) and nil-entry; a collaborator the constructor receives is not re-checked per call (coord-inject) | [dropped](#drop-264) | — | - |

## Rules

Each rule below is the wording go.md takes. Source lines give the key
from Sources and pins, the short commit, and the file and line inside
that skill. Strategy citations are at bjornstack `67b1213`.

### Tooling

<a id="rule-tool-race"></a>**tool-race.** CI runs the tests with `go test -race ./...`.
Source: T `d68d80a` `SKILL.md:60`, `:419`, eval 14.2; read 2026-11-16.
↩ row [13](#row-13)

<a id="rule-tool-coverage"></a>**tool-coverage.** A plain `-cover`
measures a package through its own tests, `foo_test` files in its
directory included. Code exercised only by tests in other packages,
black-box tests among them, needs `-coverpkg=./...`, or it reports
nothing. A coverage run of `t.Parallel()` tests without `-race` passes
`-covermode=atomic`; `-race` already sets it.
Source: T `d68d80a` `references/coverage.md:35-43`; read 2026-11-16.
Differs: T asks for `-covermode=atomic` with `-race` as well.
↩ rows [37](#row-37), [38](#row-38)

<a id="rule-tool-lint"></a>**tool-lint.** golangci-lint runs from a `.golangci.yml` at the module
root and enables at least errcheck, forcetypeassert, nilerr, govet,
staticcheck, thelper, paralleltest, testifylint, revive and goimports.
This one rule replaces uber.md tool-lint (owner ruling, bs-f3o.2
comment "Owner rulings from go-decisions (2026-11-17)", S-4). It is a
guard candidate, not part of tool-finish. Reuse golangci-lint's
linters where they exist, and write our own linters so they could
later go into golangci-lint.
Source: T `d68d80a` `SKILL.md:396`; TF `SKILL.md:196`, eval 11; CX
`SKILL.md:84`; PL `SKILL.md:90`; SF `SKILL.md:246`; read 2026-11-16;
Uber Go Style Guide "Linting" and "Lint Runners" (:4083-4103),
`1d60a91aa5e8`, read 2026-11-16.
↩ rows [49](#row-49), [64](#row-64), [114](#row-114), [144](#row-144), [200](#row-200); uber.md rows [115](uber.md#row-115), [116](uber.md#row-116)

<a id="rule-tool-stdversion"></a>**tool-stdversion.** On Go 1.27, `go test` runs the `stdversion`
vet check. A failure is fixed by raising the `go` directive or by not
using the newer API, never by silencing the check; this holds once the
Go 1.27 release notes confirm the check runs by default.
Source: T `d68d80a` `SKILL.md:298-300`; read 2026-11-16.
Differs: conditional until bs-f3o.2.7 checks the release notes; this
bead could not look them up.
↩ row [34](#row-34)

<a id="rule-test-goleak"></a>**test-goleak.** A package whose code starts goroutines checks for
leaks: `goleak.VerifyTestMain(m)` in its `TestMain`, or
`defer goleak.VerifyNone(t)` in a test. `-race` does not find a
goroutine that never exits.
Source: T `d68d80a` `SKILL.md:56`, `:181-213`, eval 1; ES `e25b517`
`go-test-quality/SKILL.md:183-185`; read 2026-11-16.
↩ rows [9](#row-9), [239](#row-239)

<a id="rule-test-artifacts"></a>**test-artifacts.** Files a test, benchmark or fuzz target keeps for
inspection go in `t.ArtifactDir()` (Go 1.26), not in ad-hoc paths or
the repository.
Source: T `d68d80a` `SKILL.md:279-296`; read 2026-11-16.
↩ row [33](#row-33)

<a id="rule-log-slog"></a>**log-slog.** Log with `log/slog`, through the logger ctx carries
(ctx-scope), never `fmt.Println` or `log.Printf`.
Source: EH `d68d80a` `SKILL.md:49`, evals 1.1, 7.3, 10.3; read
2026-11-16.
↩ row [83](#row-83)

<a id="rule-layout-workspace"></a>**layout-workspace.** Use `go.work`
only to develop several modules together, for the uses PL lists: such
as a repository holding several modules that import each other, or
testing a change across modules locally. A single module with many
packages has none.
Source: PL `d68d80a` `SKILL.md:98-100`,
`references/workspaces.md:12-25`, eval 6; read 2026-11-16.
↩ row [136](#row-136)

<a id="rule-mod-path"></a>**mod-path.** The module path is the repository URL, lower-case,
with hyphens between words (`github.com/jdoe/payment-processor`), and
names what the module is for.
Source: PL `d68d80a` `SKILL.md:54-59`, eval 4; read 2026-11-16.
↩ rows [137](#row-137), [138](#row-138), [139](#row-139), [140](#row-140)

### Pattern mappings

<a id="rule-test-parallel"></a>**test-parallel.** Tests and subtests
call `t.Parallel()` wherever they can. Only a test that changes
process-wide state stays serial: it calls `t.Setenv` or `t.Chdir`
(both panic in a parallel test), or changes a package-level variable.
A test that would collide with another on shared files or
infrastructure data does not opt out; it gets its data scoped, such as
with `t.TempDir()` (bb-parallel; Isolated Test Execution step 4).
Source: T `d68d80a` `SKILL.md:54`, `:302-326`, eval 3.1-3.2; ES
`e25b517` `go-test-quality/SKILL.md:158-160`; read 2026-11-16.
Differs: T and ES let any test with shared mutable state opt out, ES
naming shared files; ours scopes the data instead.
↩ rows [7](#row-7), [237](#row-237)

<a id="rule-test-file-name"></a>**test-file-name.** A package's tests for `foo.go` live in
`foo_test.go`, in the order the functions appear in `foo.go`. Split a
test file only when it becomes unwieldy, and then by concern with a
name derived from the source file (`foo_edgecases_test.go`), never
from a function. Black-box tests are named by feature instead
(bb-package).
Source: T `d68d80a` `SKILL.md:62-63`, `:77-89`; read 2026-11-16.
Differs: T has no black-box exception; Black Box Integration step 4
organises those by feature.
↩ rows [19](#row-19), [20](#row-20)

<a id="rule-test-examples"></a>**test-examples.** A package other
modules import documents its exported API with `ExampleXxx` functions
that `go test` runs. Prefer ending each with `// Output:`, or `//
Unordered output:` when lines come in no stable order, such as map
iteration; without one the example is only compiled, which suits an
example that needs a live dependency. A variant's suffix after the
second underscore starts lower-case (`ExampleStore_Get_cached`), or
godoc detaches it.
Source: T `d68d80a` `SKILL.md:61`, `:348-352`,
`references/examples.md:3-40`, eval 8; read 2026-11-16.
Differs: T asks for examples without limiting them to packages other
modules import.
↩ rows [14](#row-14), [15](#row-15), [16](#row-16), [17](#row-17)

<a id="rule-test-handler-recorder"></a>**test-handler-recorder.** A handler's own test, a coordinator test
(Unit Testing step 3), calls `ServeHTTP` with
`httptest.NewRequest` and `httptest.NewRecorder`, with doubles for its
collaborators. Black-box tests still call the running server
(bb-http).
Source: T `d68d80a` `SKILL.md:177-179`, `references/http-testing.md:3`,
eval 11; read 2026-11-16.
Differs: eval 11 rejects `httptest.NewServer` for handler tests
outright; black-box tests need the real server.
↩ row [23](#row-23)

<a id="rule-test-no-sleep"></a>**test-no-sleep.** No test waits with
`time.Sleep`. Code whose result depends on time takes the injected
clock or runs in `synctest` (clock-inject); a black-box test waits for
an asynchronous outcome with `require.Eventually` (test-eventually).
Source: T `d68d80a` `SKILL.md:219-223`, `references/mocking.md:181`,
eval 4.4; ES `e25b517` `go-test-quality/SKILL.md:174-175`; read
2026-11-16.
↩ rows [48](#row-48), [238](#row-238)

<a id="rule-test-fuzz"></a>**test-fuzz.** A function that parses or checks untrusted input gets a
fuzz test, seeded with `f.Add`, that asserts properties of the result,
beside its table test of known cases.
Source: T `d68d80a` `SKILL.md:328-346`, eval 9; ES `e25b517`
`go-test-quality/SKILL.md:138`; read 2026-11-16.
↩ row [35](#row-35)

<a id="rule-bench-shape"></a>**bench-shape.** A benchmark compares
variants, and input sizes, as sub-benchmarks with `b.Run`, so each
gets its own name for `benchstat`, and reports allocations, with
`b.ReportAllocs()` or by running with `-benchmem`.
Source: T `d68d80a` `SKILL.md:273`, `references/benchmarks.md:5-46`,
eval 13.1-13.2; ES `e25b517` `go-test-quality/SKILL.md:193`; read
2026-11-16.
↩ rows [28](#row-28), [29](#row-29), [31](#row-31)

<a id="rule-bb-infra-lifecycle"></a>**bb-infra-lifecycle.** Shared infrastructure starts once per test
package, in `TestMain` or a testify suite's `SetupSuite`, and stops in
its teardown. It may be cleared once before the run, never between
tests. Each test creates its own scoped data (bb-parallel); nothing
truncates or reseeds between tests (Isolated Test Execution steps 2
and 4).
Source: T `d68d80a` `references/integration-testing.md:97-161`, eval
12; read 2026-11-16.
Differs: T truncates and reseeds in `SetupTest` and waits a fixed five
seconds for the containers.
↩ row [41](#row-41)

<a id="rule-mock-expectations"></a>**mock-expectations.** A testify mock with expectations is verified
with `m.AssertExpectations(t)` before the test ends, directly or
through `t.Cleanup`. `.Test(t)` (coord-doubles) catches unexpected
calls; only `AssertExpectations` catches expected calls that never
happened.
Source: TF `d68d80a` `SKILL.md:135`, `:187`, `references/mock.md:3`,
eval 4.3; T `references/mocking.md:10-73`; read 2026-11-16.
↩ rows [44](#row-44), [54](#row-54)

<a id="rule-mock-calls"></a>**mock-calls.** When a test expects a call a fixed number of times,
it says so with `.Once()` or `.Times(n)`. To return different results
on successive calls, such as a failure then a success for a retry,
chain one `.Once()` expectation per call.
Source: TF `d68d80a` `references/mock.md:61-82`, evals 4.4, 6; read
2026-11-16.
↩ rows [55](#row-55), [58](#row-58)

<a id="rule-mock-ctx-anything"></a>**mock-ctx-anything.** A
`context.Context` argument may be matched with `mock.Anything`; a test
seldom has a reason to compare contexts.
Source: TF `d68d80a` eval 4.5; read 2026-11-16.
Differs: TF's eval states it as a condition ("for arguments that don't
need specific matching (e.g., context)"), not a rule.
↩ row [56](#row-56)

<a id="rule-mock-match-whole"></a>**mock-match-whole.** Match a mock's argument against a whole
expected value (Whole-Object Assertion step 1). When a field is not
deterministic, inject its source (clock-inject). Use `mock.MatchedBy`
only for Whole-Object Assertion step 2's fallbacks, capturing and
checking the value or zeroing it on both sides, or where its SKIP WHEN
applies (one or two fields, or unrelated types); never to check a few
chosen fields of a larger value.
Source: TF `d68d80a` `SKILL.md:137`, `references/mock.md:55-58`, eval
5; read 2026-11-16.
Differs: eval 5 matches level and message text only, because the
entry's timestamp varies.
↩ row [57](#row-57)

<a id="rule-test-suite"></a>**test-suite.** A testify suite is used
only for the infrastructure lifecycle of a black-box test package
(bb-infra-lifecycle): `SetupSuite` starts infrastructure and never
creates state tests change (Isolated Test Execution step 2). Suite
methods keep state on `s` and cannot safely call `t.Parallel()`, so
unit tests stay plain table tests (test-table, test-parallel). Every
assertion goes through `s.Require()`, because `s.Equal` and the like
behave like `assert` (test-require). Each suite has its launcher,
`func TestXxx(t *testing.T) { suite.Run(t, new(XxxSuite)) }`; without
it none of its tests run.
Source: TF `d68d80a` `SKILL.md:141-183`, `:191`, evals 7, 8; read
2026-11-16.
Differs: TF uses suites for any group of tests with shared setup, uses
suite assertions in `assert` style and gives `SetupSuite` no limit.
↩ rows [59](#row-59), [60](#row-60), [61](#row-61)

<a id="rule-test-eventually-witht"></a>**test-eventually-witht.** Where `require.Eventually` applies
(test-eventually) and the awaited outcome needs more than one check,
use `require.EventuallyWithT` and assert on its `*assert.CollectT`,
never on `t`.
Source: TF `d68d80a` `SKILL.md:119-131`, eval 10; read 2026-11-16.
↩ row [53](#row-53)

<a id="rule-test-cleanup"></a>**test-cleanup.** A test helper that sets something up registers its
teardown with `t.Cleanup`, not `defer`.
Source: CU `91f0c2e` `go-testing/SKILL.md:107-122`; ES `e25b517`
`go-test-quality/SKILL.md:124-125`; read 2026-11-16.
↩ row [221](#row-221)

<a id="rule-test-golden"></a>**test-golden.** Compare output with a golden file in `testdata/` only
when it has no structure Go can compare, such as HTML or SQL text.
Output the language can decode, such as JSON, is decoded and compared
as a value (Whole-Object Assertion misapplication "asserting on
serialized representations").
Source: ES `e25b517` `go-test-quality/SKILL.md:137`; read 2026-11-16.
Differs: ES lists JSON among golden-file outputs.
↩ row [235](#row-235)

<a id="rule-test-testdata"></a>**test-testdata.** Fixture files one
package's tests read live in its `testdata/` directory, which the go
tool ignores when building, `.go` files in it included.
Source: PL `d68d80a` `SKILL.md:96`,
`references/testing-layout.md:161-176`, `:203`, `:206`, eval 9.4; read
2026-11-16.
↩ rows [150](#row-150), [152](#row-152)

<a id="rule-test-ctx"></a>**test-ctx.** A test of code that could hang derives its ctx from
`t.Context()` with `context.WithTimeout`, so a hang fails that test
instead of blocking the suite. To show that code honours cancellation,
cancel its ctx and check `errors.Is(err, context.Canceled)`.
Source: ES `e25b517` `go-context/SKILL.md:206-209`; read 2026-11-16.
↩ rows [249](#row-249), [250](#row-250)

<a id="rule-iface-consumer"></a>**iface-consumer.** Define an interface in the package that consumes
it, with only the methods that consumer calls; the implementing
package exports a concrete type. Test doubles implement the consumer's
interface, never stand in for a concrete type.
Source: SI `d68d80a` `SKILL.md:64-81`, `:290`, eval 1; T `SKILL.md:58`,
`:388-392`, eval 5; read 2026-11-16.
↩ rows [11](#row-11), [157](#row-157)

<a id="rule-iface-small"></a>**iface-small.** An interface holds only
what its consumer calls (iface-consumer). Past three methods, look for
a split into smaller interfaces that compose.
Source: SI `d68d80a` `SKILL.md:28-52`, `:289`; read 2026-11-16.
Differs: SI says interfaces should have one to three methods.
↩ row [156](#row-156)

<a id="rule-iface-return-concrete"></a>**iface-return-concrete.** Accept interfaces, return concrete
types: a constructor returns `*T`, not an interface.
Source: SI `d68d80a` `SKILL.md:83-93`, `:291`, eval 2; read 2026-11-16.
↩ row [158](#row-158)

<a id="rule-iface-when"></a>**iface-when.** Start with a concrete type. Define an interface once a
second implementation, a second consumer or a test double needs one.
A coordinator's collaborators are replaced by doubles in its tests
(Unit Testing step 3.3), so it takes each as an interface or a
function type from the start.
Source: SI `d68d80a` `SKILL.md:95-110`, `:298`, eval 3; read
2026-11-16.
↩ row [159](#row-159)

<a id="rule-iface-canonical"></a>**iface-canonical.** A method with a well-known name matches its
standard signature: `String() string` for `fmt.Stringer`, never
`ToString()` or `ReadData()`.
Source: SI `d68d80a` `SKILL.md:150-163`, `:297`; read 2026-11-16.
↩ row [162](#row-162)

<a id="rule-iface-assert-compile"></a>**iface-assert-compile.** Put
`var _ I = (*T)(nil)` beside `T` when `T` must satisfy `I` and no
other static conversion would catch it breaking, such as a type that
implements `json.Marshaler`. Not for every interface.
Source: SI `d68d80a` `SKILL.md:165-173`, `:296`, eval 6; CU `91f0c2e`
`go-interfaces/SKILL.md:109-127`; read 2026-11-16.
Differs: SI lists a missing check as a mistake for any type; CU
contradicts itself (`go-interfaces/SKILL.md:126-127` against `:129`).
↩ rows [163](#row-163), [232](#row-232)

<a id="rule-iface-optional"></a>**iface-optional.** Check for an optional capability by asserting to
the smallest interface that has it (`if f, ok := w.(Flusher); ok`),
not to a concrete type, and keep the parameter's declared type
minimal.
Source: SI `d68d80a` `SKILL.md:177`,
`references/type-assertions.md:39-64`, eval 8; read 2026-11-16.
↩ rows [165](#row-165), [166](#row-166)

<a id="rule-embed-when"></a>**embed-when.** Embed a type only to
expose its whole method set; otherwise hold it in a named field and
delegate. Embedding in an exported struct makes the inner type's
methods part of the public API (Intentionally Public step 3).
Source: SI `d68d80a` `SKILL.md:181-221`, `:293`, eval 5; CU `91f0c2e`
`go-interfaces/SKILL.md:102-105`; read 2026-11-16.
Differs: CU says to avoid embedding types in public structs and use
unexported fields instead (`go-interfaces/SKILL.md:104-105`); ours
allows it where the whole method set is meant to be public.
↩ rows [170](#row-170), [233](#row-233)

<a id="rule-generics-over-any"></a>**generics-over-any.** Use a type parameter, not `any`, when the
type is known to the caller; `any` only where it is not, such as
decoding arbitrary JSON or reflection.
Source: SI `d68d80a` `SKILL.md:138-148`, `:300`, eval 10; SF
`SKILL.md:30`; read 2026-11-16.
↩ rows [161](#row-161), [180](#row-180)

<a id="rule-tags"></a>**tags.** Every exported field of a type that is
marshalled has an explicit tag; such types are wire types in the
boundary adapter (scrub-boundary). Unexported fields are not
serialized, so a tag on one does nothing; the exception is an embedded
unexported struct, not a pointer, whose exported fields
`encoding/json` promotes. `omitempty` drops zero values; where zero
and absent mean different things, use a pointer or `omitzero` (Go
1.24).
Source: SI `d68d80a` `SKILL.md:243-254`, `:294`,
`references/struct-fields.md:3-35`; read 2026-11-16.
Differs: SI also offers `mo.Option`, and says unexported fields are
never serialized.
↩ rows [172](#row-172), [173](#row-173), [174](#row-174)

<a id="rule-receivers"></a>**receivers.** Use a pointer receiver when the method changes the
receiver, the type holds a mutex, or the type is large; a value
receiver for small immutable types. All methods of a type use the same
kind.
Source: SI `d68d80a` `SKILL.md:256-267`, `:295`, eval 11; CU `91f0c2e`
`go-interfaces/SKILL.md:133-137`; read 2026-11-16.
↩ rows [177](#row-177), [178](#row-178)

<a id="rule-zero-value"></a>**zero-value.** A type that needs nothing from its caller works as
its zero value: initialise its maps lazily in the methods that write
them. A type that needs collaborators or settings is built by its
constructor, which sets every field (coord-inject).
Source: SI `d68d80a` `SKILL.md:112-136`, `:299`, eval 4; SF
`SKILL.md:39`, `:210-221`, `references/nil-safety.md:162-180`, eval
19; read 2026-11-16.
Differs: SI and SF eval 19 favour the usable zero value without
naming when a constructor is the better choice.
↩ rows [160](#row-160), [196](#row-196), [197](#row-197)

<a id="rule-sync-once"></a>**sync-once.** Lazy initialisation that concurrent callers may reach
uses `sync.Once`.
Source: SF `d68d80a` `SKILL.md:40`, `:222-238`; read 2026-11-16.
↩ row [198](#row-198)

<a id="rule-copy-out"></a>**copy-out.** An exported function or method
that returns a slice or map the type keeps returns a copy, unless its
documentation says the caller must not modify the result. A
constructor or method that keeps a slice or map a caller passed in
stores a copy. Prefer `slices.Clone` and `maps.Clone`. Collection
fields stay unexported.
Source: SF `d68d80a` `SKILL.md:35`, `:188-208`, `:271`,
`references/slice-map-safety.md:116-131`, evals 3, 11, 15, 26, 34; CU
`91f0c2e` `go-defensive/SKILL.md:25`, `:40`, `:63-65`; read
2026-11-16.
Differs: SF's text covers only the copy out; SF eval 26 and CU
go-defensive add the copy in at every API boundary.
↩ rows [188](#row-188), [189](#row-189), [190](#row-190), [259](#row-259)

<a id="rule-nil-entry"></a>**nil-entry.** A pointer in external data
is checked for nil where that data crosses the system boundary (Scrub
on Entry steps 1 and 4); code past that point does not check it again.
A nil receiver is valid only where the method's documentation says so;
use that sparingly.
Source: SF `d68d80a` `references/nil-safety.md:19-58`, eval 14; read
2026-11-16.
Differs: SF does not say where the check happens; Scrub on Entry puts
it at the system boundary.
↩ rows [201](#row-201), [202](#row-202)

<a id="rule-err-results"></a>**err-results.** A function that can fail returns `error` last. When
the error is not nil, the other results are unspecified unless
documented: check the error before using them.
Source: EH `d68d80a` `references/error-creation.md:25-39`; CU
`91f0c2e` `go-error-handling/SKILL.md:64-67`; read 2026-11-16.
↩ rows [67](#row-67), [68](#row-68), [225](#row-225)

<a id="rule-err-string"></a>**err-string.** Error strings start
lower-case, except for an exported name, a proper noun or an acronym,
and end without punctuation. They say what this unit was doing, the
call it made (`fetching user`), not the package or type name. `%w`
goes at the end of the format string.
Source: EH `d68d80a` `SKILL.md:42`,
`references/error-creation.md:42-60`, eval 4.2-4.3; CU `91f0c2e`
`go-error-handling/SKILL.md:48-62`, `:163-164`; read 2026-11-16.
Differs: EH has no exception for names and acronyms.
↩ rows [70](#row-70), [71](#row-71), [224](#row-224), [228](#row-228)

<a id="rule-err-identity-form"></a>**err-identity-form.** When a failure needs an identity (Failure
Identity step 1), give it one of two forms. With no values a caller
reads, a package-level sentinel `var ErrX = errors.New("...")`. With
values, an exported error type that carries them as fields (Failure
Identity step 2), matched with `errors.As`. A failure no caller
handles differently gets neither: `fmt.Errorf` or `errors.New` inline.
Source: EH `d68d80a` `SKILL.md:47`,
`references/error-creation.md:62-69`, `:85-92`, `:117-138`, evals 4.1,
9.4; read 2026-11-16.
Differs: EH reserves sentinels for "expected conditions"; Failure
Identity asks whether a caller handles the failure differently.
↩ row [80](#row-80)

<a id="rule-err-close-all"></a>**err-close-all.** Closing several resources tries every one even
when an earlier one fails, wraps each error with the resource it came
from, and returns them joined (scrub-collect).
Source: EH `d68d80a` `references/error-wrapping.md:103-115`, eval 8;
read 2026-11-16.
↩ row [78](#row-78)

<a id="rule-err-handle-once"></a>**err-handle-once.** Handle an error once: log it or return it,
never both. The unit that handles it, at the top of the call chain or
whose job is handling it, logs it.
Source: EH `d68d80a` `SKILL.md:46`,
`references/error-handling.md:12-48`, evals 7, 10.1, 11.5; read
2026-11-16.
↩ row [79](#row-79)

<a id="rule-err-panic"></a>**err-panic.** Return an error for any
failure a caller can expect, such as a missing file or a timeout; a
library returns errors to its callers. Panic only for a programmer
error, or for a broken invariant whose failure leaves state
unrecoverable, with a message naming the invariant. A `Must` helper
panics, so call it only where a failure is a programmer error, such as
package initialisation.
Source: EH `d68d80a` `SKILL.md:48`,
`references/error-handling.md:50-74`; CU `91f0c2e`
`go-defensive/SKILL.md:156-157`, `:171-172`; read 2026-11-16.
Differs: CU keeps every panic inside its package
(`go-defensive/SKILL.md:171`); an invariant panic here reaches the
top, because nothing recovers to carry on (err-recover).
↩ rows [81](#row-81), [257](#row-257), [258](#row-258)

<a id="rule-err-recover"></a>**err-recover.** Recover a panic only to
fail that unit of work loudly: answer 500, or mark the job failed, and
log the panic with its stack. Never carry on the work. net/http
already recovers panics in handlers; a goroutine the code starts
itself needs its own deferred recover.
Source: EH `d68d80a` `references/error-handling.md:76-97`; read
2026-11-16.
Differs: EH recovers so that one panic does not stop the process.
↩ row [82](#row-82)

<a id="rule-err-no-inband"></a>**err-no-inband.** Never signal failure with an in-band value such as
`-1` or `""`; return `(T, bool)` or `(T, error)`.
Source: CU `91f0c2e` `go-error-handling/SKILL.md:99-113`; read
2026-11-16.
↩ row [227](#row-227)

<a id="rule-log-requests"></a>**log-requests.** A server logs each request through middleware with
its method, path, status and duration as attributes.
Source: EH `d68d80a` `SKILL.md:51`; read 2026-11-16.
↩ row [85](#row-85)

<a id="rule-log-static-msg"></a>**log-static-msg.** A log call's
message is a fixed string; IDs, paths and counts go in `slog`
attributes. This governs log messages only: an error's own message
still names the values involved (Failure Identity step 5).
Source: EH `d68d80a` `SKILL.md:54`,
`references/error-creation.md:94-115`, evals 2.1, 7.4-7.5, 10.4; read
2026-11-16.
Differs: EH's text prefers static strings at the log boundary with a
"sometimes" exit; its evals drop the exit and keep values out of error
strings too (row 89).
↩ row [88](#row-88)

<a id="rule-ctx-root"></a>**ctx-root.** `context.Background()` appears
only in `main`, `init` and `TestMain`, which has no `t`. A handler
uses `r.Context()`; a test uses `t.Context()` (Go 1.24), and a
`t.Cleanup` function uses `context.WithoutCancel(t.Context())`,
because `t.Context()` is already cancelled when cleanup runs. Code
below them uses the ctx it was given, or one derived from it.
Source: CX `d68d80a` `SKILL.md:35`, `:41-49`,
`references/http-services.md:9-29`, evals 1.1, 7.2; ES `e25b517`
`go-test-quality/SKILL.md:189-191`, `go-context/SKILL.md:206-207`;
read 2026-11-16.
Differs: CX lets tests call `context.Background()`.
↩ rows [97](#row-97), [98](#row-98), [240](#row-240)

<a id="rule-ctx-todo"></a>**ctx-todo.** Where a function needs a ctx its caller does not pass
yet, use `context.TODO()` as the placeholder, and replace it before
the change ships.
Source: CX `d68d80a` `SKILL.md:36`, eval 7; ES `e25b517`
`go-context/SKILL.md:233`; read 2026-11-16.
Differs: CX sets no deadline for replacing it.
↩ rows [99](#row-99), [253](#row-253)

<a id="rule-ctx-keys"></a>**ctx-keys.** Each ctx value has an
unexported key type, an exported setter that middleware calls with
`r.WithContext`, and an exported getter that reports a missing value;
callers never type-assert `ctx.Value` themselves. The logger is the
exception: its getter returns a logger that discards everything when
ctx carries none (ctx-scope).
Source: CX `d68d80a` `SKILL.md:37`,
`references/values-tracing.md:7-31`,
`references/http-services.md:31-61`, eval 3; ES `e25b517`
`go-context/SKILL.md:194-196`; read 2026-11-16.
↩ rows [100](#row-100), [101](#row-101), [110](#row-110), [248](#row-248)

<a id="rule-ctx-principal"></a>**ctx-principal.** Auth middleware puts the
authenticated principal in the request ctx (ctx-keys). The handler
reads it and passes it down as input (Unit Testing step 3.2). Code
below the handler may read it from ctx only for a finer-grained check
than the middleware made, so it doesn't redo the authentication.
This is the one data value ctx carries beyond ctx-scope's list: ctx
carries data almost never, not never.
Source: CX `d68d80a` `references/values-tracing.md:38`, eval 9.4; ES
`e25b517` `go-context/SKILL.md:190-191`; CU `91f0c2e`
`go-context/SKILL.md:83`; read 2026-11-16; owner ruling, bs-f3o.2
comment "Owner rulings, round 2 (2026-11-17)", S-1.
Differs: the sources put the user or tenant in ctx for any code to
read; here the handler passes it down, and deeper reads are for
finer-grained checks only.
↩ rows [103](#row-103), [247](#row-247)

<a id="rule-ctx-detach"></a>**ctx-detach.** Work that must outlive the request gets
`context.WithoutCancel(ctx)`, which keeps ctx's values such as the
logger and trace ID (ctx-scope), plus a timeout of its own.
Source: CX `d68d80a` `SKILL.md:39`,
`references/cancellation.md:163-186`, eval 5; ES `e25b517`
`go-context/SKILL.md:221-224`; read 2026-11-16.
Differs: CX gives detached work no timeout.
↩ rows [105](#row-105), [252](#row-252)

<a id="rule-ctx-listen"></a>**ctx-listen.** Code that blocks selects on `ctx.Done()` alongside
its other channels; a long CPU-bound loop checks `ctx.Err()` between
iterations.
Source: CX `d68d80a` `references/cancellation.md:106-144`; read
2026-11-16.
↩ rows [106](#row-106), [107](#row-107)

<a id="rule-ctx-afterfunc"></a>**ctx-afterfunc.** To clean up when ctx is cancelled without blocking,
register the cleanup with `context.AfterFunc` and keep its `stop`
function.
Source: CX `d68d80a` `references/cancellation.md:146-161`, eval 10;
read 2026-11-16.
↩ row [108](#row-108)

<a id="rule-ctx-client-gone"></a>**ctx-client-gone.** When a handler's
call fails and `errors.Is(r.Context().Err(), context.Canceled)`, the
client is gone: write nothing. When the handler's own deadline fired,
the client is still waiting: answer 503 or 504.
Source: CX `d68d80a` `references/http-services.md:17-24`, eval 1.5;
read 2026-11-16.
Differs: CX writes nothing whenever `ctx.Err()` is set.
↩ row [109](#row-109)

<a id="rule-ctx-trace-out"></a>**ctx-trace-out.** An outgoing request carries the trace ID from ctx
in its headers, by hand or through OpenTelemetry's propagator.
Source: CX `d68d80a` `references/http-services.md:63-77`,
`references/values-tracing.md:44-78`; read 2026-11-16.
↩ row [111](#row-111)

<a id="rule-ctx-retry-timeout"></a>**ctx-retry-timeout.** Where a
retry attempt can hang, it derives its own timeout from the caller's
ctx and cancels it before the next attempt.
Source: CX `d68d80a` eval 2; read 2026-11-16.
Differs: CX eval 2 gives every attempt its own timeout.
↩ row [113](#row-113)

<a id="rule-ctx-no-custom"></a>**ctx-no-custom.** Signatures take `context.Context`, never a custom
context type or an interface that embeds it.
Source: CU `91f0c2e` `go-context/SKILL.md:52-70`; read 2026-11-16.
↩ row [230](#row-230)

<a id="rule-ctx-cause"></a>**ctx-cause.** Cancel with `context.WithCancelCause`, and set
deadlines with `WithTimeoutCause` or `WithDeadlineCause`, where the
reason for stopping matters to whoever reads the failure.
Source: ES `e25b517` `go-context/SKILL.md:213-219`; read 2026-11-16.
↩ row [251](#row-251)

<a id="rule-layout-cmd"></a>**layout-cmd.** Each binary's `main` package lives in `cmd/<name>/`,
and no `src/` directory. `main` parses flags
and configuration, builds the collaborators (coord-inject) and calls
`Run`; no business logic lives in `cmd/`. A module with one binary
uses `cmd/<name>/` too, unless it is made a local exception with
`main.go` at the root. When a tool is created, ask the owner whether
it will have several binaries and whether to add the folder.
Source: PL `d68d80a` `SKILL.md:80`,
`references/directory-layouts.md:98-150`, evals 2, 3.1, 3.6, 11; read
2026-11-16; owner ruling, bs-f3o.2 comment "Owner rulings from
go-decisions (2026-11-17)", S-7.
Differs: PL allows no `main.go` at the root; we allow it as a local
exception.
↩ rows [126](#row-126), [127](#row-127), [132](#row-132), [133](#row-133)

<a id="rule-layout-internal"></a>**layout-internal.** An application's
packages live under `internal/`; `pkg/` holds only a package another
module imports now (Intentionally Public steps 1-2).
Source: PL `d68d80a` `SKILL.md:80`, `:114-115`, eval 5; read
2026-11-16.
Differs: PL allows `pkg/` for code useful to other modules.
↩ rows [128](#row-128), [129](#row-129)

<a id="rule-layout-library"></a>**layout-library.** A library puts its public packages at the module
root and its private code under `internal/`, and has no `cmd/` except
for example binaries.
Source: PL `d68d80a` `references/directory-layouts.md:72-96`, eval 8;
read 2026-11-16.
Differs: PL's own table (`SKILL.md:45`) puts a library under
`pkg/{name}/` (row 125).
↩ row [130](#row-130)

<a id="rule-pkg-dir"></a>**pkg-dir.** A package's name matches its
directory, except `package main` (under `cmd/<name>/`) and `_test`
packages; pkg-naming covers the rest.
Source: PL `d68d80a` `SKILL.md:74-76`; read 2026-11-16.
Differs: PL also asks for singular names, which the standard library
does not follow.
↩ row [141](#row-141)

<a id="rule-time-types"></a>**time-types.** Times and durations are
`time.Time` and `time.Duration`, not raw integers of seconds or
milliseconds.
Source: CU `91f0c2e` `go-defensive/SKILL.md:29`, `:43`; read
2026-11-16.
↩ row [256](#row-256)

### Go pitfalls

<a id="rule-test-subtest-t"></a>**test-subtest-t.** Inside `t.Run`, assert with the subtest's `t`.
An `assert.New` or `require.New` built from the parent's `t` reports
the subtest's failure against the parent, and the failing subtest
prints PASS.
Source: T `d68d80a` `SKILL.md:145-171`; ES `e25b517`
`go-test-quality/SKILL.md:203-205`; read 2026-11-16.
↩ rows [22](#row-22), [241](#row-241)

<a id="rule-test-goroutine-fatal"></a>**test-goroutine-fatal.** `t.Fatal`, `t.FailNow` and `require.*`
run only on the test's own goroutine. A goroutine the test starts
sends its result back on a channel, and the test asserts after
receiving it.
Source: CU `91f0c2e` `go-testing/SKILL.md:82-83`; ES `e25b517`
`go-test-quality/SKILL.md:206-209`; read 2026-11-16.
↩ row [219](#row-219)

<a id="rule-test-synctest-api"></a>**test-synctest-api.** Use `synctest.Test` (Go 1.25). `synctest.Run`
is the Go 1.24 experiment, only for a module that targets Go 1.24 with
`GOEXPERIMENT=synctest`.
Source: T `d68d80a` `SKILL.md:255`; read 2026-11-16.
↩ row [25](#row-25)

<a id="rule-bench-loop"></a>**bench-loop.** New benchmarks loop with
`for b.Loop()` (Go 1.24), not over `b.N`. A `b.N` loop stays only
where the module targets Go older than 1.24, or in existing benchmark
code, which keeps its form until a migration is asked for (owner
ruling on migrations, bs-f3o.2 comment 2026-11-16). With `b.Loop`,
setup before the loop is not timed, and the result needs no sink or
`b.ResetTimer`.
Source: T `d68d80a` `SKILL.md:273`, `references/benchmarks.md:48-50`,
eval 13.3; read 2026-11-16.
↩ row [30](#row-30)

<a id="rule-test-arg-order"></a>**test-arg-order.** testify takes `(expected, actual)`, and
`ErrorIs(err, target)`; a swapped order prints a backwards diff.
Source: TF `d68d80a` `SKILL.md:108`, `:189`, evals 1.5, 3.4; read
2026-11-16.
↩ row [52](#row-52)

<a id="rule-test-error-is"></a>**test-error-is.** `require.Equal` on a
returned error compares it with `DeepEqual`, so a sentinel wrapped
with context no longer matches. Check a sentinel with
`require.ErrorIs`; take a typed failure out with `require.ErrorAs`,
then compare its data whole (scrub-collect, err-is-fresh-pointer).
Source: TF `d68d80a` `SKILL.md:188`, eval 3.1-3.2; read 2026-11-16.
↩ row [62](#row-62)

<a id="rule-test-float"></a>**test-float.** `require.Equal` is
`reflect.DeepEqual`, which compares floats with `==`. Check a float
the code computes with `require.InDelta`, then copy it into `want`
before the whole-value comparison. This borrows Whole-Object Assertion
step 2's capture and verify by analogy: step 2 covers
non-deterministic fields, and a computed float is deterministic, only
inexact.
Source: SF `d68d80a` evals 23.4, 31.5; read 2026-11-16.
↩ row [194](#row-194)

<a id="rule-err-check"></a>**err-check.** Check every returned error.
Discard one with `_` only deliberately, with a comment saying why (`n,
_ := b.Write(p) // bytes.Buffer.Write never fails`).
Source: EH `d68d80a` `SKILL.md:40`,
`references/error-creation.md:25-40`; CU `91f0c2e`
`go-error-handling/SKILL.md:74-87`; read 2026-11-16.
Differs: EH never allows `_`.
↩ rows [66](#row-66), [226](#row-226)

<a id="rule-err-inspect"></a>**err-inspect.** Match a sentinel with `errors.Is` and a type with
`errors.As`, or `errors.AsType[T](err)` from Go 1.26; never `==` or a
bare type assertion, which miss a wrapped error.
Source: EH `d68d80a` `SKILL.md:44`,
`references/error-wrapping.md:50-80`, eval 4.4-4.5; SI
`references/type-assertions.md:66-68`; read 2026-11-16.
↩ rows [74](#row-74), [75](#row-75), [169](#row-169)

<a id="rule-err-unwrap-where"></a>**err-unwrap-where.** An error type that carries a cause implements
`Unwrap` only above the edge. At the edge, where an outside system's
error enters, the type keeps the outside message in `Error()` without
`Unwrap`, as `%v` does (err-wrap-verb, err-unwrap; Failure Identity
step 3). `context.Canceled` and `context.DeadlineExceeded` stay
reachable even there (err-wrap-verb).
Source: EH `d68d80a` `references/error-creation.md:140-157`; ES
`e25b517` `go-error-handling/SKILL.md:98-108`; read 2026-11-16.
Differs: EH and ES implement `Unwrap` on every wrapping type.
↩ rows [90](#row-90), [244](#row-244)

<a id="rule-err-close-write"></a>**err-close-write.** Check the error `Close` returns on a file you
wrote: a write error can surface only there.
Source: SF `d68d80a` eval 27.5; read 2026-11-16.
↩ row [211](#row-211)

<a id="rule-ctx-no-nil"></a>**ctx-no-nil.** Never pass a nil ctx; it panics at the first `Done()`
or `Value()`, far from the caller.
Source: CX `d68d80a` `SKILL.md:33`, eval 7.5; read 2026-11-16.
↩ row [95](#row-95)

<a id="rule-ctx-cancel"></a>**ctx-cancel.** Call the `cancel` from `WithCancel`, `WithTimeout` or
`WithDeadline` on every path, unless the function returns or hands on
both the ctx and its `cancel`. In scoped work, `defer cancel()` right
after creating it.
Source: CX `d68d80a` `SKILL.md:34`, `references/cancellation.md:43-60`,
eval 2.2-2.3, 6.4; read 2026-11-16.
↩ row [96](#row-96)

<a id="rule-ctx-aware-calls"></a>**ctx-aware-calls.** Pass ctx to every call that takes one:
`http.NewRequestWithContext`, `QueryContext`, `ExecContext`,
`QueryRowContext`, `BeginTx`. The plain variants ignore cancellation.
Source: CX `d68d80a` `references/http-services.md:80-113`, evals 1.4,
8; read 2026-11-16.
↩ row [112](#row-112)

<a id="rule-type-assert-ok"></a>**type-assert-ok.** Type assertions use the comma-ok form,
`v, ok := x.(T)`, or a type switch; the single-value form panics on a
mismatch. On Go 1.25, reflection code uses `reflect.TypeAssert[T](v)`
instead of `v.Interface().(T)`.
Source: SI `d68d80a` `SKILL.md:175-177`, `:292`,
`references/type-assertions.md:3-16`, eval 7; SF `SKILL.md:31`,
`:248-256`, `:263`; read 2026-11-16.
↩ rows [164](#row-164), [181](#row-181), [182](#row-182)

<a id="rule-type-switch"></a>**type-switch.** In a type switch, list concrete types before the
interfaces they satisfy, or their cases are unreachable. Add
`case nil` when nil is a valid input; otherwise it falls to `default`.
Source: SI `d68d80a` `references/type-assertions.md:35-37`; read
2026-11-16.
↩ rows [167](#row-167), [168](#row-168)

<a id="rule-nocopy"></a>**nocopy.** A struct that must not be copied
after first use, and holds no lock of its own, carries an unexported
named field `noCopy noCopy` whose `Lock` and `Unlock` do nothing, and
is passed by pointer; `go vet`'s copylocks reports every copy. A
struct that already holds a `sync.Mutex` needs none: copylocks reports
it already. The field is named, not embedded, so `Lock` and `Unlock`
do not join the type's method set.
Source: SI `d68d80a` `SKILL.md:269-275`,
`references/struct-fields.md:40-71`, eval 9; read 2026-11-16.
↩ row [179](#row-179)

<a id="rule-typed-nil"></a>**typed-nil.** An interface holding a typed nil pointer is not nil.
Return untyped `nil` on success; never return a typed pointer variable
that may be nil, or assign one to an `error` result unconditionally.
Exported functions return `error`, never a concrete error type.
Source: SF `d68d80a` `SKILL.md:32`, `:44-67`, `:264`,
`references/nil-safety.md:98-121`, evals 1, 13, 25; CU `91f0c2e`
`go-error-handling/SKILL.md:35-46`; read 2026-11-16.
↩ rows [183](#row-183), [223](#row-223)

<a id="rule-nil-collections"></a>**nil-collections.** Writing to a nil
map panics, and a nil channel blocks every send and receive forever.
Initialise both before use, or lazily (zero-value), unless a nil
channel deliberately disables a `select` case. A function that takes
several channels handles a nil one among them.
Source: SF `d68d80a` `SKILL.md:33`, `:69-91`, `:265`, `:273`, evals 9,
12.4, 28; read 2026-11-16.
↩ rows [184](#row-184), [185](#row-185), [262](#row-262)

<a id="rule-nil-func"></a>**nil-func.** Calling a nil func panics. An optional func field gets a
no-op default from the constructor, or a nil check where it is called.
Source: SF `d68d80a` `references/nil-safety.md:60-96`, evals 8, 22, 32;
read 2026-11-16.
↩ row [203](#row-203)

<a id="rule-append-alias"></a>**append-alias.** `append` writes into the existing array when it has
room, so two slices can share memory. Before appending to a slice a
caller passed in, cut its capacity (`s[:len(s):len(s)]`) or clone it.
Source: SF `d68d80a` `SKILL.md:34`, `:95-107`, `:266`,
`references/slice-map-safety.md:67-89`, evals 2, 24; read 2026-11-16.
↩ row [186](#row-186)

<a id="rule-map-concurrent"></a>**map-concurrent.** A map read and written from several goroutines
needs synchronisation.
Source: SF `d68d80a` `SKILL.md:109-111`; read 2026-11-16.
↩ row [187](#row-187)

<a id="rule-defer-loop"></a>**defer-loop.** `defer` runs when the function returns, not at the end
of a loop iteration. A loop that opens a resource per iteration moves
the body into a function, so each `defer` runs in time.
Source: SF `d68d80a` `SKILL.md:36`, `:158-182`, `:267`, evals 4, 18, 27,
35; read 2026-11-16.
↩ row [191](#row-191)

<a id="rule-int-narrow"></a>**int-narrow.** Converting to a narrower
integer type wraps silently. Where the value comes from outside, Scrub
on Entry checks it against the target's bounds at the boundary and
rejects it there; code past that point does not check it again. A
value the code computes itself is checked against the bounds before
narrowing, returning an error when it does not fit.
Source: SF `d68d80a` `SKILL.md:37`, `:115-129`, `:268`, evals 5, 20,
30; read 2026-11-16.
Differs: SF bounds-checks before every narrowing conversion; Scrub on
Entry's misapplication rules out re-checking scrubbed values.
↩ row [192](#row-192)

<a id="rule-float-compare"></a>**float-compare.** Floating-point arithmetic is not exact: compare
computed floats with a tolerance, or use `math/big` where exact values
matter.
Source: SF `d68d80a` `SKILL.md:38`, `:131-141`, `:269`, evals 10, 23;
read 2026-11-16.
↩ row [193](#row-193)

<a id="rule-div-zero"></a>**div-zero.** Integer division by zero
panics; float division by zero gives Inf or NaN. Where zero is a valid
divisor, the code defines the result for it before dividing. Where
zero is invalid input, Scrub on Entry rejects it at the boundary, and
domain code does not check it again.
Source: SF `d68d80a` `SKILL.md:143-156`, `:270`, evals 17, 33, 36;
read 2026-11-16.
Differs: SF's text (`SKILL.md:270`, the average example at `:147-153`)
and eval 17.3 guard every division; Scrub on Entry's misapplication
rules out re-checking scrubbed values.
↩ row [195](#row-195)

<a id="rule-init-order"></a>**init-order.** The order of `init()` functions across files is not
something to rely on; set things up in explicit constructors.
Source: SF `d68d80a` `SKILL.md:240-242`, `:272`; read 2026-11-16.
↩ row [199](#row-199)

<a id="rule-subslice-retain"></a>**subslice-retain.** A small slice cut from a large one keeps the
whole array alive. Clone what you keep (`slices.Clone(data[:64])`).
Source: SF `d68d80a` `references/slice-map-safety.md:91-114`, evals 6,
21, 29; read 2026-11-16.
↩ row [207](#row-207)

<a id="rule-map-order"></a>**map-order.** Map iteration order changes between runs. Where order
matters, iterate over `slices.Sorted(maps.Keys(m))`.
Source: SF `d68d80a` `references/slice-map-safety.md:133-149`, eval 16;
read 2026-11-16.
↩ row [208](#row-208)

<a id="rule-slice-delete"></a>**slice-delete.** Remove elements from a slice with
`slices.DeleteFunc`, or by iterating backwards; removing inside a
forward `range` skips elements.
Source: SF `d68d80a` `references/slice-map-safety.md:166-187`; read
2026-11-16.
↩ row [209](#row-209)

<a id="rule-slice-bounds"></a>**slice-bounds.** Slicing past a slice's length panics. Check the
length before cutting a fixed-size prefix, or document that the
caller guarantees it.
Source: SF `d68d80a` eval 6.3; read 2026-11-16.
↩ row [213](#row-213)

<a id="rule-enum-zero"></a>**enum-zero.** An enum's constants start at
`iota + 1`, so the zero value means unset, unless zero is the sensible
default.
Source: CU `91f0c2e` `go-defensive/SKILL.md:30`, `:44`, `:107-119`;
read 2026-11-16.
↩ row [254](#row-254)

<a id="rule-rand-crypto"></a>**rand-crypto.** Keys, tokens and
anything else an attacker must not guess come from `crypto/rand`,
never `math/rand`.
Source: CU `91f0c2e` `go-defensive/SKILL.md:31`, `:140-150`; read
2026-11-16.
↩ row [255](#row-255)

<a id="rule-chan-close"></a>**chan-close.** A receive that must tell a
closed channel from a zero value uses the comma-ok form, `v, ok :=
<-ch`. The sender closes an output channel, exactly once; a second
close panics.
Source: SF `d68d80a` evals 12.1-12.2; read 2026-11-16.
↩ rows [261](#row-261), [263](#row-263)

## Dropped

One section per drop, or per group of drops with one reason: what the
source said, what it would have meant in practice, and why it was
dropped.

### <a id="drop-1"></a>Rows 1 and 65: Agent modes and sub-agent fan-out

Source: T `SKILL.md:26-37` (write, review, audit and debug modes;
"Launch up to 3 parallel sub-agents"), EH `SKILL.md:22-30`, `:64-72`
("use up to 5 parallel sub-agents").

In practice: How an agent running the skill splits its work.

Dropped because: Instructions for running an agent, not rules for Go
code; our dispatch process sets how agents work.

↩ rows [1](#row-1), [65](#row-65)

### <a id="drop-2"></a>Row 2: Scaffold with gotests

Source: T `SKILL.md:34`: "use `gotests` to scaffold table-driven
tests".

In practice: A generator writes each table's first shape.

Dropped because: A tool, not a rule; the shape a table takes is
test-table's.

↩ row [2](#row-2)

### <a id="drop-4"></a>Rows 4-5: Integration build tag

Source: T `SKILL.md:52`: integration tests behind `//go:build
integration`, `testing.Short()` no substitute;
`references/coverage.md:44`: tagged tests are invisible to coverage
unless the tag is passed.

In practice: Every test run that should include infrastructure tests
passes `-tags=integration`, the finish run (tool-finish) included.

Dropped because: tool-bb-infra (bjornstack.md row 7) already starts
the infrastructure inside the tests, so a tag buys nothing. It hides
black-box tests from a plain `go test ./...` and from gopls, and would
change the owner's finish command (tool-finish, bjornstack.md row 78).

↩ rows [4](#row-4), [5](#row-5)

### <a id="drop-6"></a>Row 6: Tests independent of order

Source: T `SKILL.md:53`: "Tests MUST NOT depend on execution order".

In practice: Any test passes when run alone or in any order.

Dropped because: Isolated Test Execution's outcomes say it for every
language; test-parallel is the Go form.

↩ row [6](#row-6)

### <a id="drop-10"></a>Row 10: testify as helpers

Source: T `SKILL.md:57`: "Use testify as helpers, not a replacement
for standard library".

In practice: Tests keep `*testing.T` as their entry point.

Dropped because: testify's API already requires `*testing.T`;
test-require settles which assertions to use.

↩ row [10](#row-10)

### <a id="drop-12"></a>Row 12: Unit tests under 1 ms

Source: T `SKILL.md:59`: "Keep unit tests fast (< 1ms)"; `:175`.

In practice: A time budget per unit test.

Dropped because: No strategy sets a time budget; isolation and
determinism already come from Unit Testing and Isolated Test
Execution.

↩ row [12](#row-12)

### <a id="drop-26"></a>Row 26: Go 1.27 synctest.Sleep and httptest.NewTestServer

Source: T `SKILL.md:263-265`.

In practice: Two new APIs for tests inside a `synctest` bubble.

Dropped because: It describes APIs and sets no rule beyond row 25;
Go 1.27 facts are bs-f3o.2.7's to check.

↩ row [26](#row-26)

### <a id="drop-27"></a>Row 27: Timeout helper that panics

Source: T `references/helpers.md:5-41`: a goroutine that panics "with
caller location" once the timeout passes.

In practice: A hung test crashes the test binary with its location.

Dropped because: A panic in a goroutine ends every test in the binary;
test-ctx's timeout fails only the hung test.

↩ row [27](#row-27)

### <a id="drop-32"></a>Row 32: Result sink and ResetTimer

Source: T eval 13.5-13.6: assign the result to a package-level
variable; keep setup out of the timed loop or call `b.ResetTimer`.

In practice: Boilerplate around a `b.N` loop.

Dropped because: `b.Loop` keeps setup out of the timed region and the
result alive (T `references/benchmarks.md:50`); bench-loop requires it.

↩ row [32](#row-32)

### <a id="drop-36"></a>Row 36: Coverage as a gap finder

Source: T `SKILL.md:356`: "treat a percentage as a gap finder rather
than a target".

In practice: Read uncovered lines; set no coverage target.

Dropped because: Language-neutral advice. No layer of bjornstack holds
it yet; bs-1ep finds it a home.

↩ row [36](#row-36)

### <a id="drop-39"></a>Row 39: Exclude generated code before thresholds

Source: T `references/coverage.md:45`.

In practice: Filter generated files out of the coverage number.

Dropped because: The stack sets no coverage threshold (row 36).

↩ row [39](#row-39)

### <a id="drop-42"></a>Row 42: Truncate and reseed between tests

Source: T `references/integration-testing.md:128-139`: `SetupTest`
runs `TRUNCATE TABLE orders, users CASCADE` and reloads
`testdata.sql`.

In practice: Every test starts from the same shared rows, and tests
cannot run in parallel.

Dropped because: Isolated Test Execution steps 2 and 4: per-test
factories, and no clearing between tests.

↩ row [42](#row-42)

### <a id="drop-43"></a>Row 43: Embedded fixtures in the production package

Source: T `references/integration-testing.md:164-195`: `package
myfeature` embeds `testdata/*.sql` and exports `SetupDB`.

In practice: Production code ships test seed data and a test-only
function.

Dropped because: Shared seed data (row 42) and an export made for
tests (Public API Surface Testing misapplication).

↩ row [43](#row-43)

### <a id="drop-46"></a>Row 46: Package-level fixtures

Source: T `references/mocking.md:143-177`: `var DefaultUser = &User{...}`
and `NewUser` with `uuid.New()` and `time.Now()`.

In practice: Tests share mutable pointers, and fixtures differ on
every run.

Dropped because: Contradicts builders-a, builders-ids, clock-inject
and Isolated Test Execution steps 2-3.

↩ row [46](#row-46)

### <a id="drop-50"></a>Rows 50, 216, 218 and 242: assert, t.Error or cmp.Diff by default

Source: TF `SKILL.md:68`: "`require` for preconditions, `assert` for
verifications"; CU `go-testing/SKILL.md:57`: "Do not use assertion
libraries"; CU `:74`: "`t.Error` by default"; ES
`go-test-quality/SKILL.md:210`.

In practice: Tests carry on after a failed check and report every
failure in one run.

Dropped because: The owner chose `require` everywhere, with `assert`
only for deliberately independent failures (test-require, bjornstack.md
row 39).

↩ rows [50](#row-50), [216](#row-216), [218](#row-218), [242](#row-242)

### <a id="drop-51"></a>Row 51: `is` and `must`

Source: TF `SKILL.md:51`: "Use `assert.New(t)` / `require.New(t)` for
readability. Name them `is` and `must`".

In practice: Every test starts with `must := require.New(t)`.

Dropped because: test-whole-value spells assertions as
`require.Equal(t, ...)`; one form across all tests. It also invites
row 22's pitfall.

↩ row [51](#row-51)

### <a id="drop-63"></a>Row 63: Equal on pointers compares addresses

Source: TF `SKILL.md:192`: "`is.Equal(ptr1, ptr2)` compares
addresses".

In practice: Tests would dereference pointers before comparing.

Dropped because: `require.Equal` is `reflect.DeepEqual`, as the owner's
2026-11-03 decision records, and `DeepEqual` compares what two
pointers point to. testify's `Same` is the address check.

↩ row [63](#row-63)

### <a id="drop-72"></a>Row 72: %v at the public API

Source: EH `references/error-wrapping.md:32`: "Use `%w` within your
module ... Use `%v` at public API / system boundaries"; example at
`:36-46`.

In practice: A service's exported method breaks the chain; internal
packages pass outside identities up to it.

Dropped because: EH's "`%v` at system boundaries" (`SKILL.md:43`)
agrees with err-wrap-verb (bjornstack.md row 48), and row 73 takes
EH's gateway example as already ours. Only the public-API example
diverges: it lets outside identities travel up to the exported method,
where err-wrap-verb puts `%v` at the edge where an outside error
enters, so no unit above it sees the outside identity (Failure
Identity step 3).

↩ row [72](#row-72)

### <a id="drop-84"></a>Row 84: samber/oops

Source: EH `SKILL.md:50`: "Use `samber/oops` for production errors
needing stack traces, user/tenant context, or structured attributes".

In practice: Errors built with `oops.With(...).Wrapf(...)`.

Dropped because: The skill author's own library and a new dependency;
Failure Identity step 2 puts the values a caller needs in our own
error types, and log-static-msg keeps log attributes in `slog`.

↩ row [84](#row-84)

### <a id="drop-86"></a>Row 86: Log levels

Source: EH `SKILL.md:52`: "Use log levels to indicate error severity";
`references/error-handling.md:138` points log levels to another skill.

In practice: Nothing specific: no levels or mapping are named.

Dropped because: It decides nothing a reader can apply, and the skill
it points to is outside this table's sources.

↩ row [86](#row-86)

### <a id="drop-87"></a>Row 87: No technical errors for users

Source: EH `SKILL.md:53`: "translate internal errors to user-friendly
messages, log technical details separately".

In practice: Handlers answer with safe messages.

Dropped because: Unit Testing step 3.4 says it for every language.

↩ row [87](#row-87)

### <a id="drop-89"></a>Row 89: Static error strings

Source: EH evals 1.2, 3.1, 9.1, 11.1, for example "Error messages
static (no row numbers in error string)".

In practice: An error says "csv parsing error" without the row.

Dropped because: EH's text prefers static strings at the log boundary
but leaves an exit ("sometimes", "may":
`references/error-creation.md:76`, `:101-115`; `SKILL.md:54`); the
evals drop that exit. Failure Identity step 5 asks an error's message
to name the values involved. log-static-msg keeps log messages stable
instead.

↩ row [89](#row-89)

### <a id="drop-104"></a>Row 104: Logger in ctx only sometimes

Source: CX `references/values-tracing.md:42`: "Logger | Depends | OK
if enriched with request-scoped fields; otherwise pass explicitly";
eval 9.2: "Logger is passed as a struct field or explicit parameter,
NOT via context value".

In practice: Some code gets its logger as a field, some from ctx.

Dropped because: The owner ruled that the logger lives in ctx only
(ctx-scope, bjornstack.md row 47).

↩ row [104](#row-104)

### <a id="drop-115"></a>Row 115: Ask for architecture and DI approach

Source: PL `SKILL.md:22`, `:28`, `:34`.

In practice: The agent stops to ask before laying out a project.

Dropped because: Agent process; Domain-First Packaging decides the
packages and coord-inject decides constructor injection.

↩ row [115](#row-115)

### <a id="drop-116"></a>Row 116: Don't over-structure small projects

Source: PL `SKILL.md:28`.

In practice: A small tool stays flat.

Dropped because: Domain-First Packaging's SKIP WHEN and its
over-packaging misapplication say it for every language.

↩ row [116](#row-116)

### <a id="drop-117"></a>Rows 117-124: 12-factor and secrets

Source: PL `SKILL.md:36-38`: "For applications (services, APIs,
workers)" follow 12-factor: "config via environment variables, logs to
stdout, stateless processes, graceful shutdown, backing services as
attached resources, and admin tasks as one-off commands";
`references/config.md:51`: "Configuration MUST be loaded from env
vars, files, or flags — NEVER hardcoded. Sensitive values MUST come
from env vars or secret managers, NEVER config files." Eval 10.4
allows config files for non-sensitive values.

In practice: How an application is configured, logs and is deployed.

Dropped because: Each is a deployment rule for any language, and none
is about Go code. No layer of bjornstack holds them yet; bs-1ep finds
them a home.

↩ rows [117](#row-117), [118](#row-118), [119](#row-119), [120](#row-120), [121](#row-121), [122](#row-122), [123](#row-123), [124](#row-124)

### <a id="drop-125"></a>Row 125: Library under pkg/

Source: PL `SKILL.md:45`: "Library | ... | `pkg/{name}/`, `internal/`".

In practice: Library code under `pkg/`.

Dropped because: The skill's own `references/directory-layouts.md:94`
and eval 8.1 put a library's public packages at the root
(layout-library).

↩ row [125](#row-125)

### <a id="drop-131"></a>Row 131: Universal layout

Source: PL `references/directory-layouts.md:30-35`:
`internal/{app,config,handler,model,service}`.

In practice: Packages named for technical roles.

Dropped because: Domain-First Packaging step 1 and proto-packages.

↩ row [131](#row-131)

### <a id="drop-135"></a>Row 135: internal/util as the fix

Source: PL `references/directory-layouts.md:160`: "`util/` # Specific
utility names".

In practice: `utils/` renamed `util/`.

Dropped because: Still a technical-role name (proto-packages).

↩ row [135](#row-135)

### <a id="drop-142"></a>Rows 142-143: Makefile and .gitignore

Source: PL `SKILL.md:88-89`, `:118`; `assets/Makefile`,
`assets/.gitignore`.

In practice: Template build and ignore files in every project.

Dropped because: Project choices, not rules for Go code.

↩ rows [142](#row-142), [143](#row-143)

### <a id="drop-145"></a>Row 145: Config with Viper

Source: PL `references/config.md:18-49`: a `Config` struct with
`mapstructure` tags, loaded by `viper.Unmarshal` in `cmd/`.

In practice: Cobra and Viper in every application.

Dropped because: A library choice no rule needs.

↩ row [145](#row-145)

### <a id="drop-147"></a>Row 147: White-box unit tests

Source: PL `references/testing-layout.md:51`: "Tests live in the same
package as the code"; `:87`: "Use same package for unit tests that
need to test internals".

In practice: Unit tests reach unexported code.

Dropped because: Contradicts test-pkg (bjornstack.md row 63) and Public
API Surface Testing step 1.

↩ row [147](#row-147)

### <a id="drop-148"></a>Row 148: _bench_test.go and _example_test.go

Source: PL `references/testing-layout.md:21-23`, `:131`, `:224-225`.

In practice: Benchmarks and examples in their own files, in the code's
package.

Dropped because: test-pkg keeps every test file out of `package foo`;
T's own `references/examples.md:40` agrees. The file names alone would
pass test-file-name, which allows a split by concern.

↩ row [148](#row-148)

### <a id="drop-149"></a>Row 149: testutil packages

Source: PL `references/testing-layout.md:141-159`: `test/testutils/`
or `internal/testutil/` holding `mock.go` and `fixtures.go`; `:227`
puts them in `*_test.go` files of `package testutil`.

In practice: A shared grab-bag of mocks and fixtures.

Dropped because: Builders live in `test/a` (builders-a), doubles stay
in their test file (Test Data Builders step 2), and the name is a
technical role (proto-packages). Other packages cannot import a
`_test.go` file either.

↩ row [149](#row-149)

### <a id="drop-151"></a>Row 151: Shared fixtures in test/fixtures/

Source: PL `references/testing-layout.md:178-188`, `:205`: fixture
files shared across packages in `test/fixtures/`, offered as "Option
2" (`:163`, `:178`).

In practice: Tests in several packages read one `users.json`.

Dropped because: Isolated Test Execution step 2 says "factories, not
fixtures", and builders-a builds shared test data per test. The go
tool also compiles `.go` files under `test/fixtures/`; only
`testdata/` is ignored.

↩ row [151](#row-151)

### <a id="drop-153"></a>Row 153: Run go version

Source: PL `SKILL.md:111`.

In practice: The agent checks the toolchain before `go mod init`.

Dropped because: An agent setup step, not a rule.

↩ row [153](#row-153)

### <a id="drop-155"></a>Row 155: Always-load directive

Source: PL `SKILL.md:119`: "Write the always-load directive for
`samber/cc-skills-golang@golang-how-to` into the project's
agent-config file ... no user confirmation needed".

In practice: The skill installs itself into CLAUDE.md.

Dropped because: The owner ruled that no skill is installed
(bjornstack.md row 56).

↩ row [155](#row-155)

### <a id="drop-176"></a>Row 176: Round-trip test for field names

Source: SI `references/struct-fields.md:38`: "round-trip test:
marshal, unmarshal, compare — catches field-name drift the compiler
cannot see".

In practice: A test that encodes and decodes a value.

Dropped because: A round trip passes after a rename, the case the
source names, because both directions use the new name; tags covers
renames. It does catch a field that silently drops out (`json:"-"`,
two fields with one JSON name), which no rule here asks a test for.

↩ row [176](#row-176)

### <a id="drop-204"></a>Row 204: Zero values in generic code

Source: SF `references/nil-safety.md:131`: "Generic code MUST handle
the zero value of type parameters correctly"; `:133-144`.

In practice: Care with `var zero T` comparisons.

Dropped because: The failing case (`v == nil` for an unconstrained
`T`) does not compile, and the advice at `:133-144`, comparing against
the zero value under a `comparable` constraint, is what the compiler
already demands; nothing is left to apply.

↩ row [204](#row-204)

### <a id="drop-205"></a>Row 205: Loop variables before Go 1.22

Source: SF `references/slice-map-safety.md:22`: "NEVER store pointers
to loop variables in Go < 1.22".

In practice: `v := v` inside loops.

Dropped because: It applies only to modules whose `go.mod` says 1.21
or older; new code targets a current Go (new-stdlib).

↩ row [205](#row-205)

### <a id="drop-206"></a>Row 206: &items[i] over &item

Source: SF `references/slice-map-safety.md:65`.

In practice: Index-based loops to take addresses.

Dropped because: The source's point is that `&items[i]` aliases the
slice element while `&item` points at a per-iteration copy. Which one
is right follows from whether the code must change the element in the
slice; a blanket preference would take the alias where a copy was
meant.

↩ row [206](#row-206)

### <a id="drop-210"></a>Row 210: slices.Equal, never ==

Source: SF `references/slice-map-safety.md:191`.

In practice: Production code compares slices with `slices.Equal`.

Dropped because: `==` on slices and maps does not compile, so the
compiler already enforces it; tests compare with `require.Equal`.

↩ row [210](#row-210)

### <a id="drop-212"></a>Rows 212, 214 and 215: Eval-only micro-choices

Source: SF evals 18.4 and 35.4 (preallocate with
`make([]T, 0, len(xs))`), 33.4 (`active * 100 / capacity`), 16.3
(`strings.Builder` over `+=`).

In practice: Small performance and arithmetic choices in each prompt's
solution.

Dropped because: Performance choices or arithmetic no rule asks for;
none is stated in the skill text.

↩ rows [212](#row-212), [214](#row-214), [215](#row-215)

### <a id="drop-217"></a>Row 217: got/want failure messages

Source: CU `go-testing/SKILL.md:40`: "Every failure message must
include: function name, inputs, actual (got), and expected (want)".

In practice: Hand-written `t.Errorf("Add(2, 3) = %d, want %d", ...)`.

Dropped because: Tests assert with `require` (test-require), whose diff
shows both values; test-messages (bjornstack.md row 92) sets the
message.

↩ row [217](#row-217)

### <a id="drop-220"></a>Row 220: shouldErr bool

Source: CU `go-testing/SKILL.md:94`: "A single `shouldErr` bool is
acceptable".

In practice: `if tt.shouldErr { ... }` in the test body.

Dropped because: test-table (bjornstack.md row 64) carries assertion
functions per case and allows no conditionals in the body.

↩ row [220](#row-220)

### <a id="drop-222"></a>Row 222: Test error semantics

Source: CU `go-testing/SKILL.md:128`: "Test error semantics, not error
message strings".

In practice: `errors.Is` instead of comparing `err.Error()`.

Dropped because: Failure Identity step 6 says it for every language;
err-inspect and test-error-is give the Go spelling.

↩ row [222](#row-222)

### <a id="drop-236"></a>Row 236: What not to mock

Source: ES `go-test-quality/SKILL.md:145-146`: "Do NOT mock: value
objects, pure functions, the standard library, or your own code in the
same package".

In practice: A coordinator's collaborator in the same package, or a
standard-library function that does I/O, is used for real.

Dropped because: Unit Testing step 3.3 replaces every direct
collaborator, never a subset, and step 3.2 counts package functions
that do I/O as collaborators, standard library included; step 2.1
already keeps doubles out of computation tests.

↩ row [236](#row-236)

### <a id="drop-245"></a>Rows 69 and 245: Always add context

Source: EH `SKILL.md:41`, `references/error-wrapping.md:15-28`: wrap
every error with context at each layer; ES
`go-error-handling/SKILL.md:113`: "ALWAYS add context when propagating
errors up the stack"; `:126`: "Bad — no context: return nil, err".

In practice: Every return wraps.

Dropped because: err-wrap-where (bjornstack.md row 121) returns a
private helper's error unwrapped.

↩ rows [69](#row-69), [245](#row-245)

### <a id="drop-264"></a>Row 264: Error for a nil dependency

Source: SF eval 14.2: "Returns a meaningful error when Notifier is
nil".

In practice: Every method checks its collaborators for nil and returns
an error.

Dropped because: It contradicts SF's own text
(`references/nil-safety.md:52`). A collaborator comes fully built from
the constructor (coord-inject), and nil-entry checks a pointer only
where external data enters.

↩ row [264](#row-264)

## Open for owner

None. The owner ruled on both earlier questions on 2026-11-17
(bs-f3o.2 comments "Owner rulings from go-decisions" and "Owner
rulings, round 2"):

1. **Authenticated user in ctx (rows 103, 247):** allowed, as
   ctx-principal states.
2. **main.go for a single binary (row 133):** `cmd/<name>/` by
   default, as layout-cmd states.

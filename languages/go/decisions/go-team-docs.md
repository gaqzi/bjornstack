# Go sources F: Go team docs and blog posts

Decision table for bs-f3o.2.7. It reviews the Go team's own guidance
on go.dev and decides, item by item, what goes into
`languages/go.md`. A rule that `bjornstack.md` already holds reads
"already ours" and names that table's row.

All pages read 2026-11-16 from go.dev; nothing else was read. Strategy
and tenet text was judged at bjornstack commit `67b1213`.

## Sources and pins

| Key | Source | Pin |
|---|---|---|
| EG | Effective Go, https://go.dev/doc/effective_go | Read 2026-11-16 (page sha256 `9a72a7a4580f` as fetched); the page notes it was written for Go's 2009 release and is not actively updated |
| CS | "Contexts and structs", Jean Barkhuysen and Matt T. Proud, https://go.dev/blog/context-and-structs | Posted 24 February 2021; read 2026-11-16 (sha256 `7940d132ddf9`) |
| ER | "Working with Errors in Go 1.13", Damien Neil and Jonathan Amsterdam, https://go.dev/blog/go1.13-errors | Posted 17 October 2019; read 2026-11-16 (sha256 `408e8059dd6f`) |
| ML | "Organizing a Go module", https://go.dev/doc/modules/layout | Read 2026-11-16 (sha256 `58a1a21573a8`) |
| RN21 | Go 1.21 release notes, https://go.dev/doc/go1.21 | Read 2026-11-16 (sha256 `e6fc7240003d`) |
| RN22 | Go 1.22 release notes, https://go.dev/doc/go1.22 | Read 2026-11-16 (sha256 `35a57ba0b3be`) |
| RN23 | Go 1.23 release notes, https://go.dev/doc/go1.23 | Read 2026-11-16 (sha256 `a901eea21550`) |
| RN24 | Go 1.24 release notes, https://go.dev/doc/go1.24 | Read 2026-11-16 (sha256 `d35c2d52a864`) |
| RN25 | Go 1.25 release notes, https://go.dev/doc/go1.25 | Read 2026-11-16 (sha256 `c9d872d374a3`) |
| RN26 | Go 1.26 release notes, https://go.dev/doc/go1.26 | Read 2026-11-16 (sha256 `38617801f918`) |
| RN27 | Go 1.27 release notes, https://go.dev/doc/go1.27 | Read 2026-11-16 (sha256 `a4c56ba584ac`); the notes say Go 1.27 arrives in August 2026 |

The sha256 values are of the HTML as fetched, first 12 hex digits.

### What counted as an item

- **Effective Go** was skimmed, as the bead asks. Its sections that
  teach the language (arrays, slices, maps, printing verbs, append,
  constants, `init`, embedding, the concurrency walk-throughs, the web
  server) state how Go works, not a convention, and give no row. Each
  sentence that tells a reader what to do or avoid gives one.
- **Release notes**: only the testing items, as the bead scopes it:
  `go test` changes, the `testing` packages, `net/http/httptest`, and
  the `vet` analyzers that `go test` runs. A feature with no rule that
  go.md could take gives no row: `-fullpath`, `go test -c` and `-o`
  (1.21), `-cover` on packages without tests (1.22), `TestFS` errors
  (1.23), `go test -json` build output (1.24), `T.Attr`, `T.Output`
  and `AllocsPerRun` panicking under parallel tests (1.25),
  `Server.Client` redirecting `example.com` (1.26), `go test -json`
  `OutputType` and `synctest.Sleep` (1.27). The json/v2 and uuid items
  are in scope because this bead owns the check named in bjornstack.md
  row 60a.

## Decision table

"Section" names the go.md section: Tooling, Pattern mappings, Go
pitfalls, or For the protocols. "Check" says how a keep or adapt rule
is enforced: "tool" when a check the pinned source itself names
enforces it, "guard candidate" when the rule is mechanical but no check
is named, "judgment" when a person or an agent has to decide. Drop
rows have "-". An "already ours" row takes the Section and Check of the
bjornstack.md row it names.

| # | Source | Item | Decision | Reason | Rule id | Section | Check |
|---|---|---|---|---|---|---|---|
| <a id="row-1"></a>1 | EG Formatting | Let `gofmt` format the code; if its answer looks wrong, rearrange the program, don't work around it | already ours | bjornstack.md [row 78](bjornstack.md#row-78) | [tool-finish](bjornstack.md#rule-tool-finish) | Tooling | tool: gofmt, go vet, go test (named by the P0 brief) |
| <a id="row-2"></a>2 | EG Formatting | Tabs for indentation; no line-length limit, wrap a long line and indent it with an extra tab | drop | `gofmt` (bjornstack.md row 78) settles indentation; the line-length remark sets no limit to hold code to | [dropped](#drop-2) | — | - |
| <a id="row-3"></a>3 | EG Package names | Package names are short, lower case, a single word, with no underscores or mixedCaps | adapt | bjornstack.md [row 1](bjornstack.md#row-1) pkg-naming says "short lower-case noun" but not "single word, no underscores or mixedCaps"; this adds those words | [pkg-name-word](#rule-pkg-name-word) | Pattern mappings | guard candidate |
| <a id="row-4"></a>4 | EG Package names | The package name is the base name of its source directory | keep | Mechanical Go convention not yet in our table; the exits Go's own toolchain has (`package main`, an external `_test` package, a `/vN` suffix) are written in, so it agrees with layout-cmd | [pkg-dir-name](#rule-pkg-dir-name) | Pattern mappings | guard candidate |
| <a id="row-5"></a>5 | EG Package names | Don't worry about name collisions a priori; the importer can rename a package locally | keep | Keeps names short, as pkg-naming asks | [pkg-dir-name](#rule-pkg-dir-name) | Pattern mappings | judgment |
| <a id="row-6"></a>6 | EG Package names | Exported names use the package name to avoid repetition: `bufio.Reader`, `ring.New` | already ours | bjornstack.md [row 4](bjornstack.md#row-4) | [pkg-naming](bjornstack.md#rule-pkg-naming) | Pattern mappings | guard candidate |
| <a id="row-7"></a>7 | EG Package names | Don't use `import .`, except in tests that must run outside the package they test | adapt | EG's exception is for a test that cannot be in the package it tests (it would create an import cycle), not for every external test; we take no exception, because the package qualifier shows where a name comes from (Be Your Name) | [no-dot-import](#rule-no-dot-import) | Pattern mappings | guard candidate |
| <a id="row-8"></a>8 | EG Package names | Long names don't make code more readable; a doc comment can do more than a long name | drop | Name length is language-neutral; Be Your Name's good cases already cover a short name used near its definition | [dropped](#drop-8) | — | - |
| <a id="row-9"></a>9 | EG Getters | A getter for `owner` is `Owner()`, not `GetOwner()`; a setter is `SetOwner()` | keep | Go-specific naming convention | [go-accessors](#rule-go-accessors) | Pattern mappings | guard candidate |
| <a id="row-10"></a>10 | EG Interface names | A one-method interface is named for its method plus -er: `Reader`, `Formatter` | keep | Go-specific naming convention | [iface-er](#rule-iface-er) | Pattern mappings | judgment |
| <a id="row-11"></a>11 | EG Interface names | Use a canonical method name (`Read`, `Write`, `Close`, `Flush`, `String`) only with its canonical signature and meaning; a method with that meaning takes that name (`String`, not `ToString`) | keep | Go-specific; both sides of the rule kept | [method-canonical](#rule-method-canonical) | Pattern mappings | judgment |
| <a id="row-12"></a>12 | EG MixedCaps | Multi-word names use `MixedCaps` or `mixedCaps`, not underscores | adapt | Test, benchmark, fuzz and example function names keep the underscores `go test` and test-names (bjornstack.md row 89) give them, such as `Test<Type>_<Method>` and `ExampleT_M` | [mixedcaps](#rule-mixedcaps) | Pattern mappings | guard candidate |
| <a id="row-13"></a>13 | EG If | Omit the `else` when the `if` body ends in `return`, `break`, `continue` or `goto`; the success path runs down the page | adapt | Only the omit-else sentence is a rule; EG's "each error case returned as it arises" describes code, and Scrub on Entry step 4 collects a record's violations. Owner ruling 2026-11-16 adds when to collect and when to return at once | [early-return](#rule-early-return) | Pattern mappings | guard candidate |
| <a id="row-14"></a>14 | EG Switch | An if-else-if-else chain can be written as a `switch` with no expression | drop | An allowed form; no rule to follow | [dropped](#drop-14) | — | - |
| <a id="row-15"></a>15 | EG Type switch | A type switch reuses the variable's name in each case | drop | An allowed form; no rule to follow | [dropped](#drop-14) | — | - |
| <a id="row-16"></a>16 | EG Named result parameters | Named results are documentation and can make code shorter and clearer | drop | An allowed form; no rule to follow | [dropped](#drop-14) | — | - |
| <a id="row-17"></a>17 | EG Defer | Defer the release (`Close`, `Unlock`) right after acquiring, so no later return path forgets it and the release sits next to the acquire | adapt | A bare `defer f.Close()` discards Close's error, which for a file that was written can be the write failing (err-check, Fail Early and Loud); the bare form is kept for resources only read | [defer-release](#rule-defer-release) | Pattern mappings | judgment |
| <a id="row-18"></a>18 | EG Defer | A deferred call's arguments, receiver included, are evaluated when the `defer` executes | keep | A trap that reads wrong at a glance | [defer-args](#rule-defer-args) | Go pitfalls | judgment |
| <a id="row-19"></a>19 | EG Allocation with `new` | Arrange for a type's zero value to be usable without further initialization | adapt | A domain type is constructed from validated data (Scrub on Entry step 6), so the rule applies to types with no invariant to establish | [zero-value](#rule-zero-value) | Pattern mappings | judgment |
| <a id="row-20"></a>20 | EG Interface conversions | Use the comma-ok form to test a type assertion safely; the one-value form fails at run time | keep | Go form of Fail Early and Loud: a mismatch is checked, not a crash or a silent zero | [comma-ok](#rule-comma-ok) | Go pitfalls | judgment |
| <a id="row-21"></a>21 | EG Maps | Use comma-ok to tell a missing key from a zero value | keep | Fail Early and Loud's "hashmap lookup ... substitutes a default" violation, in Go | [comma-ok](#rule-comma-ok) | Go pitfalls | judgment |
| <a id="row-22"></a>22 | EG Printing | Don't build a `String` method with a `Sprintf` that prints the receiver as a string; it recurs forever. Convert to the basic type first | keep | Go-specific trap | [string-recursion](#rule-string-recursion) | Go pitfalls | judgment |
| <a id="row-23"></a>23 | EG Generality | A type that exists only to implement an interface stays unexported; its constructor returns the interface | adapt | Returning an interface the consumer owns would need a sideways import, which Domain-First Packaging step 5 and bjornstack.md proto-packages forbid; the constructor returns an interface its own package or a shared package defines | [export-iface](#rule-export-iface) | Pattern mappings | judgment |
| <a id="row-24"></a>24 | EG Blank identifier in multiple assignment | Never discard an error with `_`; always check error returns | keep | Fail Early and Loud; not yet in our table. Covers `Close` on a file that was written, which defer-release's bare form would drop | [err-check](#rule-err-check) | Go pitfalls | guard candidate |
| <a id="row-25"></a>25 | EG Unused imports and variables | Silence an unused import with a blank declaration while developing, then use or remove it | drop | A work-in-progress device; nothing for finished code to follow | [dropped](#drop-25) | — | - |
| <a id="row-26"></a>26 | EG Interface checks | Assert at compile time that a type implements an interface (`var _ json.Marshaler = (*RawMessage)(nil)`) only where no static conversion already checks it | keep | Both sides kept: the assertion where needed, and not on every type | [iface-check](#rule-iface-check) | Pattern mappings | judgment |
| <a id="row-27"></a>27 | EG Share by communicating | Share memory by communicating over channels; a mutex can still be best, such as for a reference count | keep | Both sides kept; the source warns the approach "can be taken too far" | [share-by-communicating](#rule-share-by-communicating) | Pattern mappings | judgment |
| <a id="row-28"></a>28 | EG Errors | Return detailed error information beside the result, in an error type carrying the operation, the values and the cause (`os.PathError`) | drop | Failure Identity steps 2 and 5 say it for every language | [dropped](#drop-28) | — | - |
| <a id="row-29"></a>29 | EG Errors | Error strings identify their origin, such as a prefix naming the package or operation ("image: unknown format") | drop | Under bjornstack.md err-wrap-where (row 121) and Failure Identity step 3 each unit boundary adds where the error came from; a package prefix on every string would repeat it | [dropped](#drop-29) | — | - |
| <a id="row-30"></a>30 | EG Errors | Callers inspect error details with a type switch or type assertion | adapt | Written before Go 1.13; ER replaces it with `errors.As` | [err-is-as](#rule-err-is-as) | Go pitfalls | guard candidate |
| <a id="row-31"></a>31 | EG Panic | Library functions avoid `panic`; if a problem can be masked or worked around, keep running; panicking during initialization can be reasonable | adapt | Fail Early and Loud: no silent masking; a fallback only when someone chose it and it signals that it is in use. EG's other legitimate panic, "something impossible has happened", is kept: owner ruling 2026-11-16, an invariant failure panics | [panic-avoid](#rule-panic-avoid) | Pattern mappings | judgment |
| <a id="row-32"></a>32 | EG Recover | Panic and recover inside a package only; turn internal panics into errors and never expose them to clients | keep | Go-specific; scoped, as EG is, to a panic the package raises to unwind its own work, so it leaves panic-avoid's initialization and invariant panics alone | [panic-recover](#rule-panic-recover) | Pattern mappings | judgment |
| <a id="row-33"></a>33 | CS Prefer contexts passed as arguments | `context.Context` is the first argument of each function that needs it, not stored in a struct | already ours | bjornstack.md [row 46](bjornstack.md#row-46) | [ctx-per-call](bjornstack.md#rule-ctx-per-call) | Pattern mappings | guard candidate |
| <a id="row-34"></a>34 | CS Exception to the rule | Add context support to an existing API by duplicating the function with a `Context` suffix, the old one calling it with `context.Background()` | adapt | Grow Don't Break: external callers get the duplicate and a deprecation (steps 3 and 5); internal callers are migrated and the old form removed (step 4); its SKIP WHEN holds | [ctx-retrofit](#rule-ctx-retrofit) | Pattern mappings | judgment |
| <a id="row-35"></a>35 | CS Exception to the rule | Store the context in a struct, as `net/http`'s `Request` does, where duplicating every function is impractical | drop | ctx-per-call (owner, bjornstack.md row 46) allows no struct field; the exception serves the standard library's compatibility promise across a large API | [dropped](#drop-35) | — | - |
| <a id="row-36"></a>36 | ER Examining errors with Is and As | Compare errors with `errors.Is` and `errors.As`, not `==` or a type assertion; they examine the whole chain | keep | Go form of Failure Identity step 2 (the caller compares the identity) | [err-is-as](#rule-err-is-as) | Go pitfalls | guard candidate |
| <a id="row-37"></a>37 | ER Examining errors with Is and As | Prefer `errors.Is`/`errors.As` over `errors.Unwrap` | keep | Same rule | [err-is-as](#rule-err-is-as) | Go pitfalls | guard candidate |
| <a id="row-38"></a>38 | ER Examining errors with Is and As | The `errors.As` target is a pointer to a variable of the error's type, so a pointer to a pointer for a pointer error | already ours | bjornstack.md [row 51](bjornstack.md#row-51) | [err-as-pointer](bjornstack.md#rule-err-as-pointer) | Go pitfalls | guard candidate |
| <a id="row-39"></a>39 | ER Whether to Wrap | Wrap to expose a cause to callers; don't wrap when that exposes implementation details, because wrapping makes the error part of the API | adapt | ER's `io.Reader` example wraps, at the edge, the error of a reader the caller supplied. Owner ruling 2026-11-17 (bs-f3o.2, S-2): err-wrap-verb wraps an error from a collaborator the caller supplied with `%w`, even at the edge, as it does ctx errors (bjornstack.md [row 48](bjornstack.md#row-48)) | [err-wrap-verb](bjornstack.md#rule-err-wrap-verb) | Go pitfalls | judgment |
| <a id="row-40"></a>40 | ER Errors and package APIs | An error from another package is converted so it does not expose the underlying error (`fmt.Errorf("%v", err)`), unless you commit to returning it | already ours | bjornstack.md [row 48](bjornstack.md#row-48) | [err-wrap-verb](bjornstack.md#rule-err-wrap-verb) | Go pitfalls | judgment |
| <a id="row-41"></a>41 | ER Customizing error tests with Is and As methods | An error type can define an `Is` method, such as one matching a template's non-zero fields | drop | A typed failure is checked with `errors.As` and its fields read as data (bjornstack.md err-is-fresh-pointer, row 87; Failure Identity step 2); a matching `Is` adds a second way to the same check | [dropped](#drop-41) | — | - |
| <a id="row-42"></a>42 | ER Errors and package APIs | A package documents which properties of its errors callers may rely on | drop | Failure Identity step 2 ("document it with the operation that reports it") says it for every language | [dropped](#drop-42) | — | - |
| <a id="row-43"></a>43 | ER Errors and package APIs | An identifiable condition is an error wrapping a sentinel; a sentinel returned directly, a type, or a predicate function also work | adapt | Failure Identity step 2 puts the values a caller needs in the identity as data, which a sentinel cannot carry, so such an identity is a type; predicate methods such as `Timeout()` stay allowed (bjornstack.md err-timeout-ctx relies on one) | [err-identity-form](#rule-err-identity-form) | Go pitfalls | judgment |
| <a id="row-44"></a>44 | ER Errors and package APIs | A function documented to return an error wrapping a sentinel never returns the sentinel itself, so callers must use `errors.Is` | keep | Lets context be added later without breaking callers | [err-sentinel-wrap](#rule-err-sentinel-wrap) | Go pitfalls | judgment |
| <a id="row-45"></a>45 | ML Basic package | The package name matches the last path component of the module path | keep | Same convention as row 4 at the module root, with its `/vN` exit | [pkg-dir-name](#rule-pkg-dir-name) | Pattern mappings | guard candidate |
| <a id="row-46"></a>46 | ML Basic package, Basic command | The `module` line in `go.mod` is the path the module is fetched from, so `go install <path>@latest` works | keep | Mechanical | [mod-path](#rule-mod-path) | Tooling | guard candidate |
| <a id="row-47"></a>47 | ML Package or command with supporting packages; Multiple packages | Put supporting packages in `internal/` at first; keep packages in `internal/` as much as possible | keep | Go form of Intentionally Public steps 1-2 at module level, with its SKIP WHEN | [layout-internal](#rule-layout-internal) | Pattern mappings | judgment |
| <a id="row-48"></a>48 | ML Multiple commands | Each command has its own directory of `package main` files; a top-level `internal/` holds what they share | keep | Go layout convention | [layout-cmd](#rule-layout-cmd) | Pattern mappings | guard candidate |
| <a id="row-49"></a>49 | ML Packages and commands in the same repository | In a repository with both importable packages and commands, the commands go under `cmd/` | keep | Go layout convention | [layout-cmd](#rule-layout-cmd) | Pattern mappings | guard candidate |
| <a id="row-50"></a>50 | ML Server project | A server keeps its logic packages in `internal/` and all its commands in `cmd/` | keep | Go layout convention; ML calls its example names "entirely arbitrary", so the packages under `internal/` follow Domain-First Packaging and bjornstack.md proto-packages (rows 3, 71) | [layout-server](#rule-layout-server) | Pattern mappings | judgment |
| <a id="row-51"></a>51 | ML Server project | When a server's package becomes useful to other projects, split it into a separate module | keep | Go layout convention | [layout-server](#rule-layout-server) | Pattern mappings | judgment |
| <a id="row-52"></a>52 | RN21 New testing/slogtest package | `testing/slogtest` validates `slog.Handler` implementations | adapt | RN21 says slogtest "can help"; it applies to a handler whose output the test can read back | [slog-handler-test](#rule-slog-handler-test) | Pattern mappings | guard candidate |
| <a id="row-53"></a>53 | RN21 testing | `testing.Testing()` reports whether the program is a test | adapt | Production code branching on it is the "test-only flags" misapplication of Public API Surface Testing, and bjornstack.md bb-setup bans test-only flags; the feature becomes a pitfall | [no-testing-branch](#rule-no-testing-branch) | Go pitfalls | guard candidate |
| <a id="row-54"></a>54 | RN23 net/http/httptest | `httptest.NewRequestWithContext` creates an incoming request carrying a context | keep | Gives a handler test a ctx derived from the test's | [test-ctx](#rule-test-ctx) | Pattern mappings | guard candidate |
| <a id="row-55"></a>55 | RN24 testing | `T.Context` and `B.Context` return a context cancelled when the test completes, before cleanup runs | keep | A ctx scoped to the test, so work it started stops with it. Owner ruling 2026-11-16: the compliance suite drops its ctx parameter and each scenario uses `t.Context()`; a test adds its logger (ctx-scope) to a ctx derived from it | [test-ctx](#rule-test-ctx) | Pattern mappings | guard candidate |
| <a id="row-56"></a>56 | RN24 testing | `T.Chdir` and `B.Chdir` change the working directory for the duration of a test | adapt | The working directory belongs to the whole process, so a test that changes it cannot run beside parallel tests (bjornstack.md bb-parallel); code takes its directory as a parameter, and `t.Chdir` is left for code whose contract is to read the working directory | [test-chdir](#rule-test-chdir) | Pattern mappings | judgment |
| <a id="row-57"></a>57 | RN24 New benchmark function | Benchmarks iterate with `for b.Loop()` instead of over `b.N`: setup runs once per `-count`, and the loop body is not optimized away | keep | Faster and less error-prone, as the source says | [bench-loop](#rule-bench-loop) | Pattern mappings | guard candidate |
| <a id="row-58"></a>58 | RN26 testing | `B.Loop` no longer prevents inlining; every benchmark can move from `B.N` to `B.Loop` | keep | Removes the one reason to keep `b.N` | [bench-loop](#rule-bench-loop) | Pattern mappings | guard candidate |
| <a id="row-59"></a>59 | RN24 New experimental testing/synctest package | `synctest.Run` behind `GOEXPERIMENT=synctest` | drop | Superseded by the 1.25 API; RN25 says the old API goes in Go 1.26 | [dropped](#drop-59) | — | - |
| <a id="row-60"></a>60 | RN25 New testing/synctest package | `synctest.Test` runs a test in a bubble with a fake clock; `synctest.Wait` waits for its goroutines to block | already ours | bjornstack.md [row 59](bjornstack.md#row-59): `testing/synctest` where injecting a clock is awkward | [clock-inject](bjornstack.md#rule-clock-inject) | Pattern mappings | guard candidate |
| <a id="row-61"></a>61 | RN24 Vet | The `tests` analyzer, run by `go test`, reports malformed test, fuzz, benchmark and example declarations | already ours | bjornstack.md [row 78](bjornstack.md#row-78): `go vet ./...` clean and `go test` passing | [tool-finish](bjornstack.md#rule-tool-finish) | Tooling | tool: gofmt, go vet, go test (named by the P0 brief) |
| <a id="row-62"></a>62 | RN26 testing | `T.ArtifactDir` returns a directory for test output files, kept under `-outputdir` with `go test -artifacts` | keep | Gives files a person inspects after a run one place | [test-artifacts](#rule-test-artifacts) | Pattern mappings | judgment |
| <a id="row-63"></a>63 | RN26 testing/cryptotest | `cryptotest.SetGlobalRandom` sets a deterministic source for `crypto/rand` and the crypto packages for the test's duration | keep | Whole-Object Assertion step 2's controlled source where the randomness cannot be injected | [crypto-random](#rule-crypto-random) | Pattern mappings | judgment |
| <a id="row-64"></a>64 | RN27 go test | `go test` runs the `stdversion` vet check by default, reporting standard-library symbols newer than the `go` directive | already ours | bjornstack.md [row 78](bjornstack.md#row-78); it is also the tool behind [row 60a](bjornstack.md#row-60a)'s version condition | [tool-finish](bjornstack.md#rule-tool-finish) | Tooling | tool: gofmt, go vet, go test (named by the P0 brief) |
| <a id="row-65"></a>65 | RN27 net/http/httptest | `httptest.NewTestServer` creates a server on an in-memory fake network suitable for `testing/synctest` | keep | The HTTP server for a test that uses synctest | [synctest-http](#rule-synctest-http) | Pattern mappings | judgment |
| <a id="row-66"></a>66 | RN25 New experimental encoding/json/v2 package | `encoding/json/v2` behind `GOEXPERIMENT=jsonv2` | drop | Superseded by RN27, where the package needs no experiment | [dropped](#drop-66) | — | - |
| <a id="row-67"></a>67 | RN27 New encoding/json/v2 and encoding/json/jsontext packages | `encoding/json/v2` is available without an experiment, with stricter defaults | already ours | bjornstack.md [row 60a](bjornstack.md#row-60a); its condition is met, see [Check for row 60a](#check-60a). Owner ruling 2026-11-16: an existing wire format or package stays on v1 until a migration is asked for | [new-stdlib](bjornstack.md#rule-new-stdlib) | Tooling | guard candidate |
| <a id="row-68"></a>68 | RN27 New uuid package | The standard library's new `uuid` package generates and parses UUIDs | already ours | bjornstack.md [row 60a](bjornstack.md#row-60a); its condition is met for the package, see [Check for row 60a](#check-60a). It generates UUIDv7: the owner checked (bs-f3o.2, 2026-11-17, S-8) | [new-stdlib](bjornstack.md#rule-new-stdlib) | Tooling | guard candidate |
| <a id="row-69"></a>69 | RN27 Vet | The `printf` analyzer reports `fmt.Errorf("...: %w", p)` where `p` is a `*E` and `E` itself implements `error`: the pointer makes type checks and `errors.Is` miss | already ours | bjornstack.md [row 78](bjornstack.md#row-78): `go vet ./...` clean; the same trap family as [err-as-pointer](bjornstack.md#rule-err-as-pointer) | [tool-finish](bjornstack.md#rule-tool-finish) | Tooling | tool: gofmt, go vet, go test (named by the P0 brief) |
| <a id="row-70"></a>70 | RN22 Vet | In a file on Go 1.22 or later, vet no longer reports a function literal that captures a loop variable, because each iteration has its own variable | drop | The per-iteration copy (`tc := tc`) is dead code from Go 1.22 on; nothing for go.md to require | [dropped](#drop-70) | — | - |

## Rules

Each rule below is the wording go.md takes. Strategy and tenet
citations are at bjornstack `67b1213`.

### Tooling

<a id="rule-mod-path"></a>**mod-path.** The `module` line in `go.mod` is the path the module
is fetched from, such as `github.com/someuser/modname`, so
`go install github.com/someuser/modname@latest` works.
Source: ML "Basic package" and "Basic command", go.dev/doc/modules/layout,
read 2026-11-16.
↩ row [46](#row-46)

### Pattern mappings

<a id="rule-pkg-name-word"></a>**pkg-name-word.** A package name is a single lower-case word, with
no underscores and no mixedCaps. This adds to bjornstack.md pkg-naming
("short lower-case noun").
Source: EG "Package names", go.dev/doc/effective_go, read 2026-11-16.
↩ row [3](#row-3)

<a id="rule-pkg-dir-name"></a>**pkg-dir-name.** A package's name is the last element of its
directory path; the package at a module's root is named for the last
element of the module path. Take the first exception that fits:
- A command's directory holds `package main`.
- An external test file is in package `<name>_test`.
- A major-version suffix such as `/v2` at the end of a path is not the
  name; the element before it is.

Don't pick a longer name to avoid a clash with another package: the
importer renames it locally when it must.
Source: EG "Package names", go.dev/doc/effective_go; ML "Basic
package", go.dev/doc/modules/layout; read 2026-11-16.
↩ rows [4](#row-4), [5](#row-5), [45](#row-45)

<a id="rule-no-dot-import"></a>**no-dot-import.** No file uses `import .`, test files included.
Source: EG "Package names", go.dev/doc/effective_go, read 2026-11-16.
Differs: EG allows `import .` in a test that cannot be in the package
it tests because of an import cycle. We make no exception: the package
qualifier shows where a name comes from (Be Your Name).
↩ row [7](#row-7)

<a id="rule-go-accessors"></a>**go-accessors.** A getter for the field `owner` is `Owner()`, not
`GetOwner()`. A setter, if there is one, is `SetOwner()`.
Source: EG "Getters", go.dev/doc/effective_go, read 2026-11-16.
↩ row [9](#row-9)

<a id="rule-iface-er"></a>**iface-er.** A one-method interface is named for its method plus
-er, or a similar agent noun: `Reader`, `Formatter`, `CloseNotifier`.
Source: EG "Interface names", go.dev/doc/effective_go, read 2026-11-16.
↩ row [10](#row-10)

<a id="rule-method-canonical"></a>**method-canonical.** Give a method a well-known name such as
`Read`, `Write`, `Close`, `Flush` or `String` only when it has that
method's usual signature and meaning. A method with that meaning takes
the well-known name and signature: `String`, not `ToString`.
Source: EG "Interface names", go.dev/doc/effective_go, read 2026-11-16.
↩ row [11](#row-11)

<a id="rule-mixedcaps"></a>**mixedcaps.** Multi-word names use `MixedCaps` or `mixedCaps`, never
underscores. Test, benchmark, fuzz and example function names are the
exception: they take the underscores `go test` and test-names give
them, such as `Test<Type>_<Method>` and `ExampleT_M`.
Source: EG "MixedCaps", go.dev/doc/effective_go, read 2026-11-16.
Differs: EG names no exception; `go test`'s example names and
bjornstack.md test-names (row 89) use an underscore between type and
method.
↩ row [12](#row-12)

<a id="rule-early-return"></a>**early-return.** When an `if` body ends in `return`, `break`,
`continue` or `goto`, leave out the `else` and carry on below the
`if`. Collecting every violation before returning is for input
validation (Scrub on Entry, bjornstack.md scrub-collect). An
operational failure, such as a full disk or a refused connection,
returns at once.
Source: EG "If", go.dev/doc/effective_go, read 2026-11-16; owner
ruling, bs-f3o.2 comment 2026-11-16 16:26.
↩ row [13](#row-13)

<a id="rule-defer-release"></a>**defer-release.** Defer the release of a resource right after
acquiring it, so no return path added later skips it: `defer
mu.Unlock()` after `Lock`, and `defer f.Close()` after opening a file
that is only read. For a file that was written, `Close` can report the
write failing, so its error is checked (err-check): close it
explicitly on the success path, or in a deferred function that
returns the error.
Source: EG "Defer", go.dev/doc/effective_go, read 2026-11-16.
Differs: EG's example defers `f.Close()` without regard to whether the
file was written.
↩ row [17](#row-17)

<a id="rule-zero-value"></a>**zero-value.** Where a type has no invariant to establish, such as a
buffer or a struct guarding state with a mutex, prefer a design whose
zero value is ready to use without a constructor, as `bytes.Buffer`
and `sync.Mutex` are. A
domain type is constructed from validated data (Scrub on Entry step 6)
and need not have a usable zero value.
Source: EG "Allocation with `new`", go.dev/doc/effective_go, read
2026-11-16.
Differs: EG gives the advice for every type; a domain value exists only
once its input has been checked.
↩ row [19](#row-19)

<a id="rule-export-iface"></a>**export-iface.** When a type exists only to implement an interface
and will never have exported methods beyond it, leave the type
unexported and have its constructor return the interface, as
`crc32.NewIEEE` returns `hash.Hash32`. This holds only for an
interface the type's own package or a shared package defines; when the
interface belongs to a consumer, the constructor returns the concrete
type rather than import the consumer (Domain-First Packaging step 5,
bjornstack.md proto-packages).
Source: EG "Generality", go.dev/doc/effective_go, read 2026-11-16.
Differs: EG's example is a producer-owned interface and doesn't
address one the consumer owns.
↩ row [23](#row-23)

<a id="rule-iface-check"></a>**iface-check.** Where nothing in the code converts a type to an
interface it must satisfy, assert it at compile time:
`var _ json.Marshaler = (*RawMessage)(nil)`. Don't add the assertion
where a static conversion already checks it.
Source: EG "Interface checks", go.dev/doc/effective_go, read
2026-11-16.
↩ row [26](#row-26)

<a id="rule-share-by-communicating"></a>**share-by-communicating.** Prefer passing a value between goroutines
over a channel, so one goroutine has it at a time, to sharing it under
a lock. Where a lock is simpler, such as for a reference count, use a
mutex.
Source: EG "Share by communicating", go.dev/doc/effective_go, read
2026-11-16.
↩ row [27](#row-27)

<a id="rule-panic-avoid"></a>**panic-avoid.** Library code returns an error rather than panicking.
Take the first exception that fits:
- An invariant the code guarantees is broken, so the state cannot be
  recovered: panic with a message naming the invariant. Nothing
  recovers to carry on.
- The program cannot set itself up during initialization: a panic is
  acceptable.

Don't mask a problem to keep running; a fallback is allowed only when
someone chose it and it signals that it is in use (Fail Early and
Loud).
Source: EG "Panic", go.dev/doc/effective_go, read 2026-11-16; owner
ruling and coordinator call, bs-f3o.2 comment 2026-11-16 16:26.
Differs: EG says it is "always better to let things continue to run"
when a problem can be masked or worked around.
↩ row [31](#row-31)

<a id="rule-panic-recover"></a>**panic-recover.** A package that uses `panic` internally to unwind,
as a parser can, recovers at its exported functions and returns an
error. A panic the package raises to unwind its own work never reaches
a client; this leaves panic-avoid's invariant and initialization
panics alone.
Source: EG "Recover", go.dev/doc/effective_go, read 2026-11-16.
↩ row [32](#row-32)

<a id="rule-ctx-retrofit"></a>**ctx-retrofit.** When an exported function gains a `context.Context`:
- Callers you don't control: add `XxxContext(ctx, ...)` beside it,
  keep the old function working by calling the new one with
  `context.Background()`, and mark it deprecated in favour of the new
  one (Grow Don't Break steps 3 and 5).
- Every caller is yours: add the new form, migrate every caller, then
  remove the old one (Grow Don't Break step 4).

In neither case is the ctx stored in a struct (ctx-per-call). Skip
this when the function has no callers beyond its own package, or in
early prototyping before any consumer depends on it (Grow Don't
Break's SKIP WHEN): change the signature in place.
Source: CS "Exception to the rule: preserving backwards
compatibility", go.dev/blog/context-and-structs, posted 2021-02-24,
read 2026-11-16.
Differs: CS says nothing about deprecating the old function; we add
the deprecation and the internal-callers case. CS also allows a ctx in
a struct where duplicating every function is impractical; we don't.
↩ row [34](#row-34)

<a id="rule-layout-internal"></a>**layout-internal.** A module's supporting packages start under
`internal/`. A package moves out only when a consumer outside the
module has a concrete, current need (Intentionally Public steps 1-2).
Intentionally Public's SKIP WHEN holds: a leaf with a single consumer
that needs most of what is inside, and early prototyping, revisited
before the design stabilizes.
Source: ML "Package or command with supporting packages" and "Multiple
packages", go.dev/doc/modules/layout, read 2026-11-16.
↩ row [47](#row-47)

<a id="rule-layout-cmd"></a>**layout-cmd.** Each command has its own directory of `package main`
files. In a repository that also holds importable packages, the
command directories sit under `cmd/`, as `cmd/prog1/main.go`. Code the
commands share lives under the top-level `internal/`.
Source: ML "Multiple commands" and "Packages and commands in the same
repository", go.dev/doc/modules/layout, read 2026-11-16.
↩ rows [48](#row-48), [49](#row-49)

<a id="rule-layout-server"></a>**layout-server.** A server keeps the packages that implement its
logic under `internal/`, named for their domains (Domain-First
Packaging), and all its commands under `cmd/`. When one of its
packages becomes useful to other projects, split it into a module of
its own.
Source: ML "Server project", go.dev/doc/modules/layout, read
2026-11-16.
↩ rows [50](#row-50), [51](#row-51)

<a id="rule-slog-handler-test"></a>**slog-handler-test.** A `slog.Handler` we write whose output the
test can read back is tested with `testing/slogtest`.
Source: RN21 "New testing/slogtest package", go.dev/doc/go1.21, read
2026-11-16.
↩ row [52](#row-52)

<a id="rule-test-ctx"></a>**test-ctx.** A test derives its ctx from `t.Context()`, which is
cancelled when the test completes and before its cleanup functions
run; a benchmark from `b.Context()`. A test that puts its own logger
in ctx (bjornstack.md ctx-scope) adds it to a ctx derived from
`t.Context()`. A compliance suite takes no ctx parameter; each
scenario uses its own `t.Context()`. A handler test builds its request
with `httptest.NewRequestWithContext(ctx, ...)` from that ctx.
Source: RN24 "testing", go.dev/doc/go1.24; RN23 "net/http/httptest",
go.dev/doc/go1.23; read 2026-11-16; owner ruling, bs-f3o.2 comment
2026-11-16 16:26.
↩ rows [54](#row-54), [55](#row-55)

<a id="rule-test-chdir"></a>**test-chdir.** The working directory belongs to the whole process,
so code under test takes the directory it works in as a parameter, and
a black-box test sets `exec.Cmd.Dir` on the command it runs. Only a
test of code whose contract is to read the working directory changes
it, with `t.Chdir` (a benchmark with `b.Chdir`), which restores it when
the test ends; such a test does not call `t.Parallel()`. Tests do not
call `os.Chdir`.
Source: RN24 "testing", go.dev/doc/go1.24, read 2026-11-16.
Differs: RN24 introduces `t.Chdir` with no limit on when to use it; we
keep tests parallel (bjornstack.md bb-parallel).
↩ row [56](#row-56)

<a id="rule-bench-loop"></a>**bench-loop.** A benchmark iterates with `for b.Loop() { ... }`,
not over `b.N`. Setup before the loop runs once per `-count`, and
the loop body's calls are kept alive, not optimized away.
Source: RN24 "New benchmark function", go.dev/doc/go1.24; RN26
"testing", go.dev/doc/go1.26; read 2026-11-16.
↩ rows [57](#row-57), [58](#row-58)

<a id="rule-test-artifacts"></a>**test-artifacts.** A file a test writes for a person to inspect
after the run goes in `t.ArtifactDir()`; `go test -artifacts` keeps
it under the output directory.
Source: RN26 "testing", go.dev/doc/go1.26, read 2026-11-16.
↩ row [62](#row-62)

<a id="rule-crypto-random"></a>**crypto-random.** Make randomness deterministic by injecting its
source where the code allows it (Whole-Object Assertion step 2,
bjornstack.md clock-inject). Where the randomness is drawn inside
`crypto/rand` or another crypto package and cannot be injected,
`cryptotest.SetGlobalRandom` makes it a controlled source for the
test's duration.
Source: RN26 "testing/cryptotest", go.dev/doc/go1.26, read 2026-11-16.
↩ row [63](#row-63)

<a id="rule-synctest-http"></a>**synctest-http.** A test inside a `testing/synctest` bubble that
needs an HTTP server uses `httptest.NewTestServer`, which runs on an
in-memory fake network suited to synctest.
Source: RN27 "net/http/httptest", go.dev/doc/go1.27, read 2026-11-16.
↩ row [65](#row-65)

### Go pitfalls

<a id="rule-defer-args"></a>**defer-args.** A deferred call's arguments, its receiver included,
are evaluated when the `defer` statement runs, not when the deferred
call runs.
Source: EG "Defer", go.dev/doc/effective_go, read 2026-11-16.
↩ row [18](#row-18)

<a id="rule-comma-ok"></a>**comma-ok.** A type assertion that can fail uses the two-value form,
`v, ok := x.(T)`; the one-value form panics on a mismatch. A map
lookup where a missing key must not read as the zero value uses
`v, ok := m[k]` (Fail Early and Loud).
Source: EG "Interface conversions and type assertions" and "Maps",
go.dev/doc/effective_go, read 2026-11-16.
↩ rows [20](#row-20), [21](#row-21)

<a id="rule-string-recursion"></a>**string-recursion.** A `String` method that formats its receiver
with `%s` or `%v` calls itself forever. Convert the receiver to its
basic type first: `fmt.Sprintf("MyString=%s", string(m))`.
Source: EG "Printing", go.dev/doc/effective_go, read 2026-11-16.
↩ row [22](#row-22)

<a id="rule-err-check"></a>**err-check.** Never discard an error with `_`; check every error a
call returns, including `Close` on a file that was written
(defer-release).
Source: EG "The blank identifier in multiple assignment",
go.dev/doc/effective_go, read 2026-11-16.
↩ row [24](#row-24)

<a id="rule-err-is-as"></a>**err-is-as.** Check an error's identity with `errors.Is` against a
value or `errors.As` into a type, never with `==`, a type assertion or
type switch, or by calling `errors.Unwrap`: `Is` and `As` examine the
whole chain.
Source: ER "Examining errors with Is and As", go.dev/blog/go1.13-errors,
posted 2019-10-17, read 2026-11-16; EG "Errors",
go.dev/doc/effective_go, read 2026-11-16.
Differs: EG's examples use `err == io.EOF` and a type assertion on
`*os.PathError`; they predate Go 1.13.
↩ rows [30](#row-30), [36](#row-36), [37](#row-37)

<a id="rule-err-identity-form"></a>**err-identity-form.** An identity the caller only compares is an
exported sentinel, `var ErrNotFound = errors.New("not found")`. An
identity carrying values the caller needs is an error type the caller
reads with `errors.As` (Failure Identity step 2).
Source: ER "Errors and package APIs", go.dev/blog/go1.13-errors,
posted 2019-10-17, read 2026-11-16.
Differs: ER lets a sentinel stand for any identifiable condition; an
identity carrying values is a type here, because a sentinel cannot
carry them.
↩ row [43](#row-43)

<a id="rule-no-testing-branch"></a>**no-testing-branch.** Production code never branches on
`testing.Testing()`. A test reaches the behaviour it needs through the
public interface, as bjornstack.md bb-setup asks, not through a
test-only path.
Source: RN21 "testing", go.dev/doc/go1.21, read 2026-11-16; Public API
Surface Testing's "test-only flags" misapplication.
↩ row [53](#row-53)

<a id="rule-err-sentinel-wrap"></a>**err-sentinel-wrap.** A function documented to return an error
wrapping a sentinel never returns the sentinel itself: it returns
`fmt.Errorf("...: %w", ErrX)`, so callers use `errors.Is` and context
can be added later without breaking them.
Source: ER "Errors and package APIs", go.dev/blog/go1.13-errors,
posted 2019-10-17, read 2026-11-16.
↩ row [44](#row-44)

## <a id="check-60a"></a>Check for row 60a

bjornstack.md row 60a carries new-stdlib as conditional until the Go
1.27 release notes confirm `encoding/json/v2` and a standard-library
uuid package. They do (RN27, go.dev/doc/go1.27, read 2026-11-16):

- "New encoding/json/v2 and encoding/json/jsontext packages": both are
  available with no experiment flag. v2 rejects invalid UTF-8 and
  duplicate object names by default. `encoding/json` (v1) is now
  backed by the v2 implementation, keeps its behaviour apart from
  error message text, and stays supported: "users are not required to
  migrate". During the experiment the `format` and `unknown` tag
  options were removed and `inline` was renamed `embed`, so code
  written against `GOEXPERIMENT=jsonv2` in Go 1.25 or 1.26 may need
  changes.
- "New uuid package": a package named `uuid`, linked at `/pkg/uuid`,
  "generates and parses UUIDs". The notes say nothing about which
  UUID versions it generates.
- "go test": `go test` now runs the `stdversion` check, which reports
  a standard-library symbol newer than the module's `go` directive. A
  module that imports either package without `go 1.27` fails it. That
  checks the precondition only, not whether new code uses the new
  packages, so rows 67 and 68 keep row 60a's "guard candidate".

Two things the notes leave to us:

- v2's stricter defaults narrow what an existing wire format accepts,
  which Grow Don't Break step 1 counts as a breaking change. Owner
  ruling (bs-f3o.2 comment 2026-11-16 16:26): code already on v1 stays
  on it until a migration is asked for.
- bjornstack.md builders-ids and TD's `a.UUID()` assume UUIDv7. The
  notes don't say whether the standard library's package generates v7.
  The owner looked it up: it does (bs-f3o.2 comment "Owner rulings
  from go-decisions (2026-11-17)", S-8).

Proposed wording for go.md, replacing the conditional one:

**new-stdlib.** In a module whose `go` directive is 1.27 or later, new
code uses `encoding/json/v2`, and generates and parses UUIDs with the
standard library's `uuid` package. An existing wire format or package
on `encoding/json` (v1) stays on it until a migration is asked for;
go.md names the module as being on the old form, so a migration can
be considered.
Source: Go 1.27 release notes, go.dev/doc/go1.27, read 2026-11-16;
bs-f3o.2 comment 2026-11-03 09:09; owner ruling, bs-f3o.2 comment
2026-11-16 16:26; owner check that the `uuid` package generates
UUIDv7, bs-f3o.2 comment "Owner rulings from go-decisions
(2026-11-17)", S-8.

## Dropped

### <a id="drop-2"></a>Row 2: Tabs and line length
EG "Formatting": "We use tabs for indentation and `gofmt` emits them
by default." "Go has no line length limit. ... If a line feels too
long, wrap it and indent with an extra tab." `gofmt` already produces
the indentation (bjornstack.md row 78), and the line-length remark
sets no limit to check. ↩ row [2](#row-2)

### <a id="drop-8"></a>Row 8: Long names
EG "Package names": "Long names don't automatically make things more
readable. A helpful doc comment can often be more valuable than an
extra long name." Nothing Go-specific; Be Your Name already holds a
short name used where its definition is in sight as good.
↩ row [8](#row-8)

### <a id="drop-14"></a>Rows 14-16: Switch forms and named results
EG "Switch": an if-else-if-else chain can be written as a `switch` with
no expression. EG "Type switch": `switch t := t.(type)` reuses the
name. EG "Named result parameters": named results document what each
result is. Each is a form Go already allows, stated as idiomatic, with
nothing for code to follow. ↩ rows [14](#row-14), [15](#row-15),
[16](#row-16)

### <a id="drop-25"></a>Row 25: Silencing unused imports
EG "Unused imports and variables": `var _ = fmt.Printf // For
debugging; delete when done.` A device for a program still being
written; a finished change has no such line. ↩ row [25](#row-25)

### <a id="drop-28"></a>Row 28: Detailed error types
EG "Errors": "It is good style to use this feature to provide detailed
error information", with `os.PathError` carrying `Op`, `Path` and
`Err`. Failure Identity step 2 (values as data) and step 5 (message
names what failed and the values) already say this for every
language. ↩ row [28](#row-28)

### <a id="drop-29"></a>Row 29: Error strings name their origin
EG "Errors": "When feasible, error strings should identify their
origin, such as by having a prefix naming the operation or package
that generated the error", such as "image: unknown format". Under
bjornstack.md err-wrap-where (row 121) the caller wraps an error from
another unit's public function with where it came from, and Failure
Identity step 3 has each unit above add what it was doing; a package
prefix inside every message would repeat that. ↩ row [29](#row-29)

### <a id="drop-35"></a>Row 35: Context stored in a struct
CS "Exception to the rule": `net/http` added a `ctx` field to
`Request` to keep `Do`'s signature, and CS allows this where
duplicating a large API is impractical. bjornstack.md ctx-per-call
(row 46, owner decision) allows no ctx in a struct; the exception
exists for the standard library's compatibility promise. Reading a
request's ctx with `r.Context()` is unaffected. ↩ row [35](#row-35)

### <a id="drop-41"></a>Row 41: Custom Is methods
ER "Customizing error tests with Is and As methods": an `Is` method
matching a template's non-zero fields, so
`errors.Is(err, &Error{User: "someuser"})` works. bjornstack.md
err-is-fresh-pointer (row 87) checks a typed failure with `errors.As`
and reads its fields as data (Failure Identity step 2); a field-matching
`Is` is a second way to the same check. ↩ row [41](#row-41)

### <a id="drop-42"></a>Row 42: Document error properties
ER "Errors and package APIs": "A package which returns errors ...
should describe what properties of those errors programmers may rely
on." Failure Identity step 2 says it for every language: "document it
with the operation that reports it". The same section's "avoid
returning errors with properties that should not be relied upon" is
row 39's rule. ↩ row [42](#row-42)

### <a id="drop-59"></a>Row 59: Experimental synctest
RN24: `testing/synctest` behind `GOEXPERIMENT=synctest` with
`synctest.Run`. RN25 replaced it with `synctest.Test` and said the old
API would be removed in Go 1.26. ↩ row [59](#row-59)

### <a id="drop-66"></a>Row 66: Experimental json/v2
RN25: `encoding/json/v2` behind `GOEXPERIMENT=jsonv2`. RN27 makes it
available without the experiment (row 67). ↩ row [66](#row-66)

### <a id="drop-70"></a>Row 70: Loop-variable copies
RN22 "Vet": in a file that requires Go 1.22 or newer, vet "no longer
reports references to loop variables from within a function literal
that might outlive the iteration of the loop", because "loop variables
are created anew for each iteration". A copy such as `tc := tc` before
a parallel subtest is dead code from then on; go.md has nothing to
require. ↩ row [70](#row-70)

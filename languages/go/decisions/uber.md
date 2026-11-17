# Go sources D: Uber Go style guide

Decision table for bs-f3o.2.5. It reviews the Uber Go style guide and
decides, rule by rule, what goes into `languages/go.md`. A rule that
our own table, [bjornstack.md](bjornstack.md), already holds reads
"already ours" and names that table's row. A rule that the Google
tables, [google-guide-decisions.md](google-guide-decisions.md) (C1,
bs-f3o.2.3) and [google-best-practices.md](google-best-practices.md)
(C2, bs-f3o.2.4), already decide reads "covered by C" and names the C
row; C's decision stands, whether it kept, adapted or dropped the rule.

Source: `https://github.com/uber-go/guide`, commit
`1d60a91aa5e87d443002e23c21903c49489dbde5` (committed 2026-04-15),
file `style.md`, which stitchmd generates from `src/`. Read
2026-11-16. Strategy and tenet text, and bjornstack.md, were judged at
bjornstack commit `67b1213`; the C tables were read as uncommitted
drafts on 2026-11-16, so their row ids may still shift.

## Sources and pins

| Key | Source | Pin |
|---|---|---|
| U | Uber "Uber Go Style Guide", `style.md` | `github.com/uber-go/guide` commit `1d60a91aa5e8`, read 2026-11-16 |

The Source column names the heading and the line range in `style.md`
at that commit. Introductions, explanations and pointers to other
pages hold no rule and get no row; the headings that hold nothing else
are listed under [Headings with no rule](#headings-with-no-rule).
Nothing else was read: the guide's links to Effective Go, the Go Wiki,
blog posts, package docs and its `.golangci.yml` were not followed.

## Decision table

"Section" names the go.md section: Tooling, Pattern mappings (a
strategy or one of our rules spelled for Go), Go pitfalls, or For the
protocols (material bs-y5h turns into protocol steps; Go style rules
that map to no strategy go here). "Check" says how a rule is enforced:
"tool" when a check the pinned source itself names enforces it, "guard
candidate" when the rule is mechanical but no check is named,
"judgment" when a person or an agent has to decide. An "already ours"
row carries the Section and Check of the bjornstack.md row it names,
and a "covered by C" row those of the C row it names. Drop rows, and
"covered by C" rows whose C row is a drop, have "—" and "-".

| # | Source | Item | Decision | Reason | Rule id | Section | Check |
|---|---|---|---|---|---|---|---|
| <a id="row-1"></a>1 | U Introduction (:101) | Code is free of `go vet` errors | already ours | bjornstack.md [row 78](bjornstack.md#row-78) (tool-finish) | [tool-finish](bjornstack.md#rule-tool-finish) | Tooling | tool: gofmt, go vet, go test (named by the P0 brief) |
| <a id="row-2"></a>2 | U Introduction (:101, :105) | Code is free of `golint` errors | drop | The source's own Linting section (:4096) calls `golint` deprecated and names `revive` its successor; row 115 takes `revive` | [dropped](#drop-2) | — | - |
| <a id="row-3"></a>3 | U Introduction (:102-105) | Set up the editor to run `goimports` on save and `golint` and `go vet` | drop | Editor setup, not a rule about code; the same tools run as checks in rows 1 and 115 | [dropped](#drop-3) | — | - |
| <a id="row-4"></a>4 | U Pointers to Interfaces (:114-115) | Pass interfaces as values; a pointer to an interface is almost never needed | covered by C | C1 [row 99](google-guide-decisions.md#row-99) (pass-values) names `*io.Reader` as an argument to pass by value | [pass-values](google-guide-decisions.md#rule-pass-values) | For the protocols | judgment |
| <a id="row-5"></a>5 | U Pointers to Interfaces (:124-125) | For interface methods to change the underlying data, the interface holds a pointer | covered by C | C1 [row 100](google-guide-decisions.md#row-100) (recv-type): a method that mutates has a pointer receiver, so only a pointer satisfies the interface | [recv-type](google-guide-decisions.md#rule-recv-type) | For the protocols | judgment |
| <a id="row-6"></a>6 | U Verify Interface Compliance (:129-135, :177-178) | Assert interface compliance at compile time, `var _ http.Handler = (*Handler)(nil)`, where breaking it would break users | keep | Go-specific; no C row covers it. The source's three cases are kept as the test of "where appropriate" | [iface-assert](#rule-iface-assert) | For the protocols | judgment |
| <a id="row-7"></a>7 | U Verify Interface Compliance (:180-182) | The assertion's right-hand side is the zero value of the asserted type | keep | Same | [iface-assert](#rule-iface-assert) | For the protocols | guard candidate |
| <a id="row-8"></a>8 | U Zero-value Mutexes are Valid (:277-298) | A zero `sync.Mutex` is ready to use: `var mu sync.Mutex`, not `new(sync.Mutex)` | covered by C | C2 [row 86](google-best-practices.md#row-86) (var-decl): an empty value ready to use is `var x T`; [row 88](google-best-practices.md#row-88) (var-pointer) keeps a mutex field a value | [var-decl](google-best-practices.md#rule-var-decl) | For the protocols | guard candidate |
| <a id="row-9"></a>9 | U Zero-value Mutexes are Valid (:300-301) | A struct used by pointer holds its mutex as a non-pointer field | covered by C | C2 [row 88](google-best-practices.md#row-88) (var-pointer) | [var-pointer](google-best-practices.md#rule-var-pointer) | For the protocols | guard candidate |
| <a id="row-10"></a>10 | U Zero-value Mutexes are Valid (:301, :356-362); Embedding in Structs (:2931) | Never embed a mutex, even in an unexported type | keep | Go-specific: embedding puts `Lock` and `Unlock` in the outer type's method set; stated twice in the source, one rule | [embed](#rule-embed) | For the protocols | guard candidate |
| <a id="row-11"></a>11 | U Copy Slices and Maps at Boundaries (:369-415) | A slice or map received and stored still shares data with the caller; copy it when that is not meant | keep | Go aliasing trap; the source says "be wary", so it stays a judgment, not "always copy". Related: bjornstack.md compliance-suite checks returned values don't share stored state ([row 100](bjornstack.md#row-100)) | [slice-map-alias](#rule-slice-map-alias) | Go pitfalls | judgment |
| <a id="row-12"></a>12 | U Copy Slices and Maps at Boundaries (:417-470) | Returning an internal slice or map exposes the state, outside the lock that guards it | keep | Same | [slice-map-alias](#rule-slice-map-alias) | Go pitfalls | judgment |
| <a id="row-13"></a>13 | U Defer to Clean Up (:474-520) | Release files and locks with `defer`; skip it only where the function provably runs in nanoseconds | keep | Go-specific; exception kept | [defer-cleanup](#rule-defer-cleanup) | For the protocols | judgment |
| <a id="row-14"></a>14 | U Channel Size is One or None (:524-528) | Channels are unbuffered or size one; any other size gets scrutiny: how it is sized, what stops it filling, what happens when it fills | keep | Go-specific; "should usually" and "scrutiny" keep it a judgment | [chan-size](#rule-chan-size) | For the protocols | judgment |
| <a id="row-15"></a>15 | U Start Enums at One (:554-605) | `iota` enums start at one, unless the zero value is the right default | keep | Go-specific: an unset variable reads as the first member; exception kept | [enum-start](#rule-enum-start) | For the protocols | judgment |
| <a id="row-16"></a>16 | U Use `"time"` to handle time (:623-651) | Instants are `time.Time`, compared and shifted with its methods | keep | Go-specific; no C row covers it | [time-types](#rule-time-types) | For the protocols | judgment |
| <a id="row-17"></a>17 | U Use `time.Duration` for periods of time (:653-687) | Periods are `time.Duration`, not an `int` of unknown unit | keep | Same | [time-types](#rule-time-types) | For the protocols | judgment |
| <a id="row-18"></a>18 | U Use `time.Duration` for periods of time (:689-698) | `AddDate` for the same time on the next calendar day, `Add` for an exact duration, by intent | adapt | `AddDate` works on the calendar of the value's own zone; UTC Computation step 3 converts into the computation's zone before turning a value into a date | [time-add](#rule-time-add) | Go pitfalls | judgment |
| <a id="row-19"></a>19 | U Use `time.Time` and `time.Duration` with external systems (:700-712) | Use `time.Time` and `time.Duration` with flags, JSON, SQL and YAML where possible | adapt | UTC Computation step 2 converts an instant to UTC where it enters, except a value step 1 keeps local, which crosses as local date and time plus zone name, never as a bare `time.Time`; code that passes a timestamp on without reading it is UTC Computation's SKIP WHEN | [time-external](#rule-time-external) | Pattern mappings | judgment |
| <a id="row-20"></a>20 | U Use `time.Time` and `time.Duration` with external systems (:714-742) | Where a format has no `Duration`, use `int` or `float64` with the unit in the field name (`IntervalMillis`) | keep | Go spelling of a wire field; no conflict | [time-external](#rule-time-external) | Pattern mappings | judgment |
| <a id="row-21"></a>21 | U Use `time.Time` and `time.Duration` with external systems (:744-747) | Where a format has no `time.Time`, use an RFC 3339 string, unless another format is agreed | adapt | UTC Computation step 4: output programs read is UTC with the offset written out, or local time with its zone's name for values step 1 keeps local | [time-external](#rule-time-external) | Pattern mappings | judgment |
| <a id="row-22"></a>22 | U Use `time.Time` and `time.Duration` with external systems (:749-753) | The `time` package ignores leap seconds | drop | A fact that asks nothing of the code; the source says it is rarely a problem | [dropped](#drop-22) | — | - |
| <a id="row-23"></a>23 | U Error Types (:762-764, :776-777, :779-884) | An error a caller matches is an exported `errors.New` variable for a fixed message, a custom type for one with values | covered by C | C2 [rows 33](google-best-practices.md#row-33) and [36](google-best-practices.md#row-36) (err-identity), which follow Failure Identity steps 1-2 | [err-identity](google-best-practices.md#rule-err-identity) | Pattern mappings | judgment |
| <a id="row-24"></a>24 | U Error Types (:765-768, :772-775) | An error no caller matches is `errors.New` for a fixed message, `fmt.Errorf` for one with values | keep | The other half of the source's table; no C row picks the constructor | [err-plain](#rule-err-plain) | For the protocols | judgment |
| <a id="row-25"></a>25 | U Error Types (:886-887) | An exported error variable or type is part of the package's public API | keep | Failure Identity step 2 documents an identity with its operation, and its rationale ("Why not every failure gets an identity") puts it under Grow Don't Break | [err-contract](#rule-err-contract) | Pattern mappings | judgment |
| <a id="row-26"></a>26 | U Error Wrapping (:897-900) | Return the error as it is when there is no context to add | covered by C | C2 [row 39](google-best-practices.md#row-39) (err-annotate), which keeps bjornstack.md err-wrap-where | [err-annotate](google-best-practices.md#rule-err-annotate) | Pattern mappings | guard candidate |
| <a id="row-27"></a>27 | U Error Wrapping (:902-904) | Otherwise add context: "call service foo: connection refused" | already ours | bjornstack.md [row 121](bjornstack.md#row-121) (err-wrap-where) says where: errors from another unit's public function. Ours is narrower: a private helper's error goes back unwrapped, where Uber adds context "where possible" | [err-wrap-where](bjornstack.md#rule-err-wrap-where) | Go pitfalls | judgment |
| <a id="row-28"></a>28 | U Error Wrapping (:906-918) | `%w` when the caller should reach the cause, a good default; `%v` to hide it | already ours | bjornstack.md [row 48](bjornstack.md#row-48) (err-wrap-verb): `%v` at the edge, a single `%w` above it | [err-wrap-verb](bjornstack.md#rule-err-wrap-verb) | Go pitfalls | judgment |
| <a id="row-29"></a>29 | U Error Wrapping (:913-915) | A wrapped known variable or type is documented and tested as part of the function's contract | covered by C | C2 [row 75](google-best-practices.md#row-75) (err-doc) documents it; Failure Identity step 6 tests it | [err-doc](google-best-practices.md#rule-err-doc) | Pattern mappings | judgment |
| <a id="row-30"></a>30 | U Error Wrapping (:920-960) | Keep added context short; no "failed to" | covered by C | C2 [row 40](google-best-practices.md#row-40) (err-annotate) | [err-annotate](google-best-practices.md#rule-err-annotate) | Pattern mappings | guard candidate |
| <a id="row-31"></a>31 | U Error Wrapping (:962-963) | Once an error goes to another system, such as a log, mark it as an error (an `err` tag, a "Failed" prefix) | keep | No C row says it; C2 log-errors covers what a log line says, not how it is marked | [log-err-mark](#rule-log-err-mark) | For the protocols | judgment |
| <a id="row-32"></a>32 | U Error Naming (:969-989) | Package-level error values are named `ErrX` when exported, `errX` when not | keep | Go naming convention; no C row covers it | [err-naming](#rule-err-naming) | For the protocols | guard candidate |
| <a id="row-33"></a>33 | U Error Naming (:991-1018) | Custom error types end in `Error` | keep | Same. bjornstack.md [row 87](bjornstack.md#row-87) adopts the test-design example `cart.UnknownTaxRate`, which this rule would name `UnknownTaxRateError` | [err-naming](#rule-err-naming) | For the protocols | guard candidate |
| <a id="row-34"></a>34 | U Handle Errors Once (:1037-1065) | Handle each error once; don't log an error and return it | covered by C | C2 [row 52](google-best-practices.md#row-52) (log-errors) | [log-errors](google-best-practices.md#rule-log-errors) | For the protocols | judgment |
| <a id="row-35"></a>35 | U Handle Errors Once (:1031-1032, :1086-1101) | An error from an operation that is not strictly needed may be logged while the work carries on | keep | Failure Identity step 1's own example: a background job logs a failed cache refresh and carries on | [err-degrade](#rule-err-degrade) | Pattern mappings | judgment |
| <a id="row-36"></a>36 | U Handle Errors Once (:1028-1030, :1104-1127) | Match one recoverable error the callee's contract defines and degrade; wrap and return the rest | adapt | The branch goes in a unit whose job is handling that failure: bjornstack.md coord-logic ([row 105](bjornstack.md#row-105)) and Failure Identity step 3 | [err-degrade](#rule-err-degrade) | Pattern mappings | judgment |
| <a id="row-37"></a>37 | U Handle Type Assertion Failures (:1132-1156) | Always use the comma-ok form of a type assertion | keep | Go-specific; no C row covers it | [type-assert](#rule-type-assert) | For the protocols | guard candidate |
| <a id="row-38"></a>38 | U Don't Panic (:1163-1205) | Production code returns errors and lets the caller decide; it does not panic | covered by C | C1 [row 82](google-guide-decisions.md#row-82) (err-no-panic) | [err-no-panic](google-guide-decisions.md#rule-err-no-panic) | Pattern mappings | judgment |
| <a id="row-39"></a>39 | U Don't Panic (:1207-1214) | Panic only for the irrecoverable; program start-up may panic (`template.Must`) | covered by C | C2 [row 67](google-best-practices.md#row-67) (panic-scope); C1 [row 84](google-guide-decisions.md#row-84) (must-funcs). By owner ruling 2026-11-16 (bs-f3o.2), panic-scope moves from log-and-exit to Uber's side: a broken invariant whose failure leaves state unrecoverable panics with a message naming it, and nothing recovers to carry on | [panic-scope](google-best-practices.md#rule-panic-scope) | For the protocols | judgment |
| <a id="row-40"></a>40 | U Don't Panic (:1216-1245) | In tests, prefer failing with `t.Fatal` or `t.FailNow` over `panic` | adapt | Spelled with `require` (bjornstack.md test-require); `require` and `t.FailNow` work only on the test goroutine, so code running elsewhere reports with `t.Error`; builders-a's panic for a state not written yet stays, since `Build()` takes no `t` | [test-no-panic](#rule-test-no-panic) | Pattern mappings | judgment |
| <a id="row-41"></a>41 | U Use go.uber.org/atomic (:1247-1300) | Use `go.uber.org/atomic`'s typed values instead of raw integers with `sync/atomic` functions | adapt | Typed atomics kept for values used atomically, not for all shared state; the package follows C1 least-mechanism ([row 4](google-guide-decisions.md#row-4)): standard library before a new dependency, as jetbrains-modern [rows 58-59](jetbrains-modern.md#row-58) also reach. Owner ruling 2026-11-16 on migrations: new code uses typed atomics, existing code stays until a migration is asked for | [atomic-typed](#rule-atomic-typed) | For the protocols | guard candidate |
| <a id="row-42"></a>42 | U Avoid Mutable Globals (:1302-1377) | Don't mutate globals, function pointers included; inject dependencies | already ours | bjornstack.md [row 69](bjornstack.md#row-69) (coord-inject); the `time.Now` example is [row 74](bjornstack.md#row-74) (clock-inject). Ours is looser: coord-globals ([row 107](bjornstack.md#row-107)) allows diagnostic logging and metrics as globals | [coord-inject](bjornstack.md#rule-coord-inject) | Pattern mappings | judgment |
| <a id="row-43"></a>43 | U Avoid Embedding Types in Public Structs (:1379-1508) | Don't embed types in exported structs; write the delegating methods | keep | Embedding exports the inner type's methods without the check Intentionally Public step 3 asks for, and the embedded type can't change without a subtractive change (Grow Don't Break step 1). The source calls such embedding "rarely necessary" (:1448), so in an exported struct a named field is the default; its `Book` example illustrates zero values, not a licence | [embed](#rule-embed) | Pattern mappings | judgment |
| <a id="row-44"></a>44 | U Avoid Using Built-In Names (:1510-1599) | No predeclared identifier as a variable, parameter or field name | keep | Go-specific. The source only hedges that `go vet` "should correctly point out" such names (:1598), and default `go vet` is not known to check them, so no named check enforces it; revive's `redefines-builtin-id` might (unchecked) | [builtin-names](#rule-builtin-names) | For the protocols | guard candidate |
| <a id="row-45"></a>45 | U Avoid `init()` (:1601-1620, :1708-1714) | Avoid `init()`; when used, it should attempt to be deterministic, order-independent, not access or change global or environment state, and do no I/O; such code likely belongs in `main`; the source's fitting uses kept | keep | Go-specific; the source's "should attempt to" and "likely belongs" kept, and its exceptions; registering a hook writes global state and is allowed | [no-init](#rule-no-init) | For the protocols | judgment |
| <a id="row-46"></a>46 | U No goroutines in `init()` (:2069-2072) | `init()` starts no goroutines | keep | Same | [no-init](#rule-no-init) | For the protocols | guard candidate |
| <a id="row-47"></a>47 | U Exit in Main (:1716-1789) | `os.Exit` and `log.Fatal` only in `main`; other functions return errors | adapt | C has no "exit only in `main`": C2 main-exit ([row 58](google-best-practices.md#row-58)) routes start-up errors to `main`, and err-no-panic and panic-scope allow an end from initialization or an invariant check. Kept in main-run, with panic-scope's invariant panic as the exception | [main-run](#rule-main-run) | For the protocols | guard candidate |
| <a id="row-48"></a>48 | U Exit Once (:1790-1906) | Exit at most once in `main`; the logic goes in a `run` function returning an error or exit code | keep | Go-specific; "if possible, prefer" keeps it a judgment | [main-run](#rule-main-run) | For the protocols | judgment |
| <a id="row-49"></a>49 | U Use field tags in marshaled structs (:1908-1954) | Every marshaled field carries a tag naming it | keep | The serialized form is a contract (Boundary Communication step 3); the tag keeps it fixed when the Go field is renamed. Such types live in the boundary adapter (bjornstack.md scrub-boundary, [row 20](bjornstack.md#row-20)) | [wire-tags](#rule-wire-tags) | Pattern mappings | guard candidate |
| <a id="row-50"></a>50 | U Don't fire-and-forget goroutines (:1967, :1971-1977) | Every goroutine has a predictable end or a stop signal, and a way to wait for it | keep | C1 [row 86](google-guide-decisions.md#row-86) (go-lifetime) accepts documenting when a goroutine exits instead of a way to wait; Uber's requirement is kept on top of it, as go-owner already does for background goroutines | [go-wait](#rule-go-wait) | Pattern mappings | judgment |
| <a id="row-51"></a>51 | U Don't fire-and-forget goroutines (:1968-1969) | Test packages that may start goroutines for leaks with `go.uber.org/goleak` | keep | A check the source names; a guard candidate, not part of tool-finish (owner ruling 2026-11-17, S-5) | [tool-goleak](#rule-tool-goleak) | Tooling | guard candidate |
| <a id="row-52"></a>52 | U Wait for goroutines to exit (:2036-2067) | `sync.WaitGroup` for several goroutines, a `done` channel for one | keep | The `WaitGroup` is already in C1 [row 86](google-guide-decisions.md#row-86) (go-lifetime); the `done` channel for a single goroutine is not | [go-wait](#rule-go-wait) | Pattern mappings | judgment |
| <a id="row-53"></a>53 | U No goroutines in `init()` (:2074-2078) | A package's background goroutine is owned by an object the user creates, whose `Close`, `Stop` or `Shutdown` signals it and waits | keep | Adds an owner to go-lifetime; no C row says it | [go-owner](#rule-go-owner) | For the protocols | judgment |
| <a id="row-54"></a>54 | U Performance (:2150); Prefer strconv over fmt (:2152-2155) | On the hot path, `strconv` over `fmt` for primitives | keep | Hot-path scope kept | [perf-hot-path](#rule-perf-hot-path) | For the protocols | judgment |
| <a id="row-55"></a>55 | U Performance (:2150); Avoid repeated string-to-byte conversions (:2192-2195) | On the hot path, convert a fixed string to `[]byte` once | keep | Same | [perf-hot-path](#rule-perf-hot-path) | For the protocols | judgment |
| <a id="row-56"></a>56 | U Specifying Map Capacity Hints (:2239-2255); Initializing Maps (:3575-3578) | Give maps a capacity hint where possible | covered by C | C2 [row 93](google-best-practices.md#row-93) (size-hints): only with measurement or a known final size | [size-hints](google-best-practices.md#rule-size-hints) | For the protocols | judgment |
| <a id="row-57"></a>57 | U Specifying Slice Capacity (:2297-2310) | Give slices a capacity where possible, especially when appending | covered by C | Same | [size-hints](google-best-practices.md#rule-size-hints) | For the protocols | judgment |
| <a id="row-58"></a>58 | U Avoid overly long lines (:2355-2363) | Soft line limit of 99 characters | covered by C | C1 [row 13](google-guide-decisions.md#row-13) (fmt-line-length): no fixed line length | [fmt-line-length](google-guide-decisions.md#rule-fmt-line-length) | For the protocols | judgment |
| <a id="row-59"></a>59 | U Be Consistent (:2365-2379) | Above all else, be consistent | covered by C | C1 [row 14](google-guide-decisions.md#row-14), dropped: Consistent Beats Correct says it for every language | [dropped in C1](google-guide-decisions.md#drop-14) | — | - |
| <a id="row-60"></a>60 | U Be Consistent (:2381-2383) | Apply a guideline at package level or larger, not to part of a package | covered by C | C1 [row 15](google-guide-decisions.md#row-15), dropped: Consistent Beats Correct's "changed everywhere it appears" | [dropped in C1](google-guide-decisions.md#drop-15) | — | - |
| <a id="row-61"></a>61 | U Group Similar Declarations (:2385-2454) | Group imports, constants, variables and types in parenthesised blocks | keep | Go convention; no C row covers it | [decl-group](#rule-decl-group) | For the protocols | guard candidate |
| <a id="row-62"></a>62 | U Group Similar Declarations (:2456-2489) | Only related declarations share a group | keep | The other side of row 61 | [decl-group](#rule-decl-group) | For the protocols | judgment |
| <a id="row-63"></a>63 | U Group Similar Declarations (:2491-2562) | Inside functions, adjacent variables go in one `var ( ... )` group, even unrelated ones | drop | Plain style the standard conventions leave free; go.md carries only our additions (owner ruling 2026-11-17, S-6) | [dropped](#drop-63) | — | - |
| <a id="row-64"></a>64 | U Import Group Ordering (:2564-2600) | Two import groups: standard library, then everything else | covered by C | C1 [row 48](google-guide-decisions.md#row-48) (import-groups): up to four groups | [import-groups](google-guide-decisions.md#rule-import-groups) | For the protocols | guard candidate |
| <a id="row-65"></a>65 | U Package Names (:2606, :2608-2609) | Package names are lower case, short and succinct | already ours | bjornstack.md [row 1](bjornstack.md#row-1) (pkg-naming) | [pkg-naming](bjornstack.md#rule-pkg-naming) | Pattern mappings | judgment |
| <a id="row-66"></a>66 | U Package Names (:2607) | A package name needs no renaming at most call sites | covered by C | C2 [row 21](google-best-practices.md#row-21) (shadow-pkg-name) | [shadow-pkg-name](google-best-practices.md#rule-shadow-pkg-name) | For the protocols | judgment |
| <a id="row-67"></a>67 | U Package Names (:2610) | Package names are not plural: `net/url`, not `net/urls` | keep | Not in pkg-naming or any C row | [pkg-singular](#rule-pkg-singular) | For the protocols | judgment |
| <a id="row-68"></a>68 | U Package Names (:2611) | No `common`, `util`, `shared` or `lib` packages | already ours | bjornstack.md [row 3](bjornstack.md#row-3) (proto-packages): no package named for a technical role | [proto-packages](bjornstack.md#rule-proto-packages) | For the protocols | guard candidate |
| <a id="row-69"></a>69 | U Function Names (:2615-2618) | Function names use MixedCaps | covered by C | C1 [row 12](google-guide-decisions.md#row-12) (name-mixedcaps) | [name-mixedcaps](google-guide-decisions.md#rule-name-mixedcaps) | For the protocols | guard candidate |
| <a id="row-70"></a>70 | U Function Names (:2618-2620) | Test function names may use an underscore to group cases: `TestMyFunction_WhatIsBeingTested` | already ours | bjornstack.md [row 89](bjornstack.md#row-89) (test-names): `Test<Type>_<Method>` | [test-names](bjornstack.md#rule-test-names) | Pattern mappings | guard candidate |
| <a id="row-71"></a>71 | U Import Aliasing (:2622-2634) | Name an import explicitly when its package name differs from the last element of its path | keep | Not a rename: the name given is the package's own. C1 import-rename lists when to rename and does not cover this | [import-alias](#rule-import-alias) | For the protocols | guard candidate |
| <a id="row-72"></a>72 | U Import Aliasing (:2636-2667) | Otherwise no import alias unless two imports conflict | covered by C | C1 [row 20](google-guide-decisions.md#row-20) (import-rename) | [import-rename](google-guide-decisions.md#rule-import-rename) | For the protocols | guard candidate |
| <a id="row-73"></a>73 | U Function Grouping and Ordering (:2671) | Functions sorted in rough call order | keep | Go convention; no C row covers it | [file-order](#rule-file-order) | For the protocols | judgment |
| <a id="row-74"></a>74 | U Function Grouping and Ordering (:2672, :2680-2681) | Functions grouped by receiver; plain utility functions toward the end | keep | Same | [file-order](#rule-file-order) | For the protocols | judgment |
| <a id="row-75"></a>75 | U Function Grouping and Ordering (:2674-2675) | `struct`, `const` and `var` definitions first, then exported functions | keep | Same | [file-order](#rule-file-order) | For the protocols | guard candidate |
| <a id="row-76"></a>76 | U Function Grouping and Ordering (:2677-2678) | A constructor may follow its type, before the type's methods | keep | Same; the source says "may appear", so it is a judgment | [file-order](#rule-file-order) | For the protocols | judgment |
| <a id="row-77"></a>77 | U Reduce Nesting (:2725-2769) | Handle errors and special cases first; return early or `continue` | covered by C | C1 [row 60](google-guide-decisions.md#row-60) (err-indent-flow) | [err-indent-flow](google-guide-decisions.md#rule-err-indent-flow) | For the protocols | guard candidate |
| <a id="row-78"></a>78 | U Unnecessary Else (:2771-2800) | A variable set in both branches of an `if` gets a default and a single `if` | keep | C1 err-indent-flow covers `else` after a return, not this | [if-default](#rule-if-default) | For the protocols | guard candidate |
| <a id="row-79"></a>79 | U Top-level Variable Declarations (:2802-2843) | Top-level variables use `var` and leave the type out unless it differs from the expression's | keep | Go convention; C2 var-decl covers locals only | [top-var](#rule-top-var) | For the protocols | guard candidate |
| <a id="row-80"></a>80 | U Prefix Unexported Globals with _ (:2845-2894) | Unexported top-level variables and constants start with `_` | covered by C | C1 [row 16](google-guide-decisions.md#row-16) (name-underscores) allows no underscore in such names | [name-underscores](google-guide-decisions.md#rule-name-underscores) | For the protocols | guard candidate |
| <a id="row-81"></a>81 | U Embedding in Structs (:2896-2925) | Embedded fields come first in a struct, with a blank line before the other fields | keep | Go convention; no C row covers it | [embed](#rule-embed) | For the protocols | guard candidate |
| <a id="row-82"></a>82 | U Embedding in Structs (:2927-3051) | Embed only for a real benefit with no adverse effect on users; the litmus: would every exported inner method and field be added to the outer type directly? If not, use a field | keep | Go-specific; the source's list of what embedding must not do is kept | [embed](#rule-embed) | For the protocols | judgment |
| <a id="row-83"></a>83 | U Local Variable Declarations (:3053-3074) | `:=` when a variable is set to a value | covered by C | C2 [row 85](google-best-practices.md#row-85) (var-decl) | [var-decl](google-best-practices.md#rule-var-decl) | For the protocols | guard candidate |
| <a id="row-84"></a>84 | U Local Variable Declarations (:3076-3109) | `var` where the default value is clearer, such as an empty slice | covered by C | C1 [row 70](google-guide-decisions.md#row-70) (nil-slice) | [nil-slice](google-guide-decisions.md#rule-nil-slice) | For the protocols | guard candidate |
| <a id="row-85"></a>85 | U nil is a valid slice (:3113-3138) | Return `nil`, not a zero-length slice literal | keep | C1 nil-slice covers declaring and testing, not returning | [nil-slice-return](#rule-nil-slice-return) | For the protocols | guard candidate |
| <a id="row-86"></a>86 | U nil is a valid slice (:3140-3163) | Test emptiness with `len(s) == 0`, not `s == nil` | covered by C | C1 [row 71](google-guide-decisions.md#row-71) (nil-slice) | [nil-slice](google-guide-decisions.md#rule-nil-slice) | For the protocols | judgment |
| <a id="row-87"></a>87 | U nil is a valid slice (:3165-3201) | A `var` slice is usable without `make()` | covered by C | C1 [row 70](google-guide-decisions.md#row-70) (nil-slice) | [nil-slice](google-guide-decisions.md#rule-nil-slice) | For the protocols | guard candidate |
| <a id="row-88"></a>88 | U nil is a valid slice (:3203-3205) | A nil slice and an empty one can be treated differently, such as in serialization | keep | The exception to row 85, kept with it | [nil-slice-return](#rule-nil-slice-return) | For the protocols | judgment |
| <a id="row-89"></a>89 | U Reduce Scope of Variables (:3207-3233) | Narrow a variable's scope, as in an `if` initializer, unless that adds nesting | keep | C1 err-indent-flow covers only the opposite case (row 90) | [var-scope](#rule-var-scope) | For the protocols | judgment |
| <a id="row-90"></a>90 | U Reduce Scope of Variables (:3235-3274) | A result needed after the `if` is declared before it | covered by C | C1 [row 61](google-guide-decisions.md#row-61) (err-indent-flow) | [err-indent-flow](google-guide-decisions.md#rule-err-indent-flow) | For the protocols | judgment |
| <a id="row-91"></a>91 | U Reduce Scope of Variables (:3276-3308) | A constant need not be package-level unless several functions or files use it or it is part of the package's contract | keep | Go convention; no C row covers it; the source's "do not need to be global" kept | [var-scope](#rule-var-scope) | For the protocols | judgment |
| <a id="row-92"></a>92 | U Avoid Naked Parameters (:3310-3335) | Comment unclear arguments in the call: `true /* isLocal */` | covered by C | C1 [row 75](google-guide-decisions.md#row-75) (fmt-arg-comments): no inline comments on call arguments | [fmt-arg-comments](google-guide-decisions.md#rule-fmt-arg-comments) | For the protocols | judgment |
| <a id="row-93"></a>93 | U Avoid Naked Parameters (:3337-3358) | Better, replace a naked `bool` with a named type | keep | No C row covers it | [bool-param](#rule-bool-param) | For the protocols | judgment |
| <a id="row-94"></a>94 | U Use Raw String Literals to Avoid Escaping (:3360-3382) | Raw string literals instead of hand-escaped strings | keep | C2 string-build covers multi-line constants, not escaping | [raw-strings](#rule-raw-strings) | For the protocols | guard candidate |
| <a id="row-95"></a>95 | U Use Field Names to Initialize Structs (:3386-3411) | Almost always name the fields of a struct literal | covered by C | C1 [rows 63](google-guide-decisions.md#row-63) and [64](google-guide-decisions.md#row-64) (lit-field-names) | [lit-field-names](google-guide-decisions.md#rule-lit-field-names) | For the protocols | guard candidate |
| <a id="row-96"></a>96 | U Use Field Names to Initialize Structs (:3413-3424) | Test-table literals with three fields or fewer may leave names out | covered by C | C2 [row 126](google-best-practices.md#row-126) (test-case-fields): table-case literals name their fields | [test-case-fields](google-best-practices.md#rule-test-case-fields) | Pattern mappings | guard candidate |
| <a id="row-97"></a>97 | U Omit Zero Value Fields in Structs (:3426-3459) | Leave zero-value fields out unless they give meaningful context | covered by C | C1 [row 68](google-guide-decisions.md#row-68) (lit-zero-fields) | [lit-zero-fields](google-guide-decisions.md#rule-lit-zero-fields) | For the protocols | judgment |
| <a id="row-98"></a>98 | U Omit Zero Value Fields in Structs (:3461-3473) | Test-table cases may keep zero-value fields for their names | already ours | bjornstack.md [row 65](bjornstack.md#row-65) (test-table): every case sets every field | [test-table](bjornstack.md#rule-test-table) | Pattern mappings | guard candidate |
| <a id="row-99"></a>99 | U Use `var` for Zero Value Structs (:3475-3500) | `var user User`, not `user := User{}` | covered by C | C2 [row 86](google-best-practices.md#row-86) (var-decl) | [var-decl](google-best-practices.md#rule-var-decl) | For the protocols | guard candidate |
| <a id="row-100"></a>100 | U Initializing Struct References (:3502-3529) | `&T{}`, not `new(T)` | covered by C | C2 [row 92](google-best-practices.md#row-92) (var-decl): both are fine | [var-decl](google-best-practices.md#rule-var-decl) | For the protocols | judgment |
| <a id="row-101"></a>101 | U Initializing Maps (:3531-3573) | `make` for an empty map or one filled by code | keep | Not covered: C2 var-decl's `var x T` gives a nil map, which panics on write (C2 map-nil-write) | [map-init](#rule-map-init) | For the protocols | guard candidate |
| <a id="row-102"></a>102 | U Initializing Maps (:3580-3610) | A map literal for a fixed set of entries | covered by C | C2 [row 91](google-best-practices.md#row-91) (var-decl): a composite literal when the members are known | [var-decl](google-best-practices.md#rule-var-decl) | For the protocols | judgment |
| <a id="row-103"></a>103 | U Format Strings outside Printf (:3612-3637) | A format string declared outside the call is a `const`, so `go vet` can check it | keep | Go-specific; the source names `go vet` as what checks the format, not as a check of this rule | [printf-vet](#rule-printf-vet) | For the protocols | guard candidate |
| <a id="row-104"></a>104 | U Naming Printf-style Functions (:3639-3656) | A Printf-style function uses a standard name or one ending in `f` | keep | Same | [printf-vet](#rule-printf-vet) | For the protocols | guard candidate |
| <a id="row-105"></a>105 | U Test Tables (:3662-3667, :3795-3799) | Use a table test when cases vary only in inputs and outputs | covered by C | C1 [row 155](google-guide-decisions.md#row-155), dropped: Parameterized Test Structure step 1 says it for every language | [dropped in C1](google-guide-decisions.md#drop-155) | — | - |
| <a id="row-106"></a>106 | U Test Tables (:3746-3762) | The case slice is `tests`, each case `tt`; inputs prefixed `give`, expectations `want` | keep | A naming convention nothing else fixes. The source only "encourage[s]" the prefixes (:3747), and under bjornstack.md test-table (owner ruling 2026-11-16) a case often carries an assertion function instead of `want` fields, so the prefixes are a preference | [test-table-names](#rule-test-table-names) | Pattern mappings | judgment |
| <a id="row-107"></a>107 | U Avoid Unnecessary Complexity in Table Tests (:3764-3774) | No table test where subtests need conditional or complex logic; split it | already ours | bjornstack.md [row 64](bjornstack.md#row-64) (test-table): the body has no conditionals | [test-table](bjornstack.md#rule-test-table) | Pattern mappings | guard candidate |
| <a id="row-108"></a>108 | U Avoid Unnecessary Complexity in Table Tests (:3780-3781) | Every table field is used in every case, and all test logic runs for every case | already ours | bjornstack.md [rows 64](bjornstack.md#row-64) and [65](bjornstack.md#row-65) (test-table) | [test-table](bjornstack.md#rule-test-table) | Pattern mappings | guard candidate |
| <a id="row-109"></a>109 | U Avoid Unnecessary Complexity in Table Tests (:3778-3779, :3783-3788) | Aim for the narrowest unit of behaviour and a shallow "test depth" | drop | Aims the source states as ideals, not rules; test-whole-value's single `require.Equal` already keeps a check to one comparison | [dropped](#drop-109) | — | - |
| <a id="row-110"></a>110 | U Avoid Unnecessary Complexity in Table Tests (:3790-3793) | Functions inside the table (`setupMocks func(*FooMock)`) make it confusing | adapt | The setup half is already ours: cases with different setup are separate tests (Parameterized Test Structure step 1), and coordinator tests follow Unit Testing's N+1 (its SKIP WHEN), as the source's own Good example (:3860-3887) does. Only assertion functions differ: bjornstack.md test-table ([row 64](bjornstack.md#row-64), owner ruling 2026-11-16) keeps one per case | [test-table-funcs](#rule-test-table-funcs) | Pattern mappings | judgment |
| <a id="row-111"></a>111 | U Avoid Unnecessary Complexity in Table Tests (:3801-3803) | A short test body may branch once on a `shouldErr` field | covered by C | C1 [row 157](google-guide-decisions.md#row-157), dropped: contradicts bjornstack.md test-table | [dropped in C1](google-guide-decisions.md#drop-157) | — | - |
| <a id="row-112"></a>112 | U Parallel Tests (:3896-3922) | With `t.Parallel()`, assign the loop variable inside the loop | drop | Since Go 1.22, in a module declaring `go 1.22` or later, each iteration has its own loop variable; jetbrains-modern [row 27](jetbrains-modern.md#row-27) already decides redundant `v := v` copies | [dropped](#drop-112) | — | - |
| <a id="row-113"></a>113 | U Functional Options (:3926-4009) | Variadic options for optional arguments of constructors and public APIs expected to grow, especially at three or more arguments | covered by C | C2 [row 99](google-best-practices.md#row-99) (func-options): C's criteria (most callers pass none, the options are many or take arguments, an option can fail, other packages define their own) replace Uber's "expected to grow, three or more arguments" | [func-options](google-best-practices.md#rule-func-options) | Pattern mappings | judgment |
| <a id="row-114"></a>114 | U Functional Options (:4011-4071) | Implement options as an `Option` interface with an unexported `apply` method on an unexported `options` struct, not closures | adapt | The source calls it "our suggested way" (:4011), so it is a preference. It clashes with C2 func-options where other packages may define options: an unexported `apply` method rules that out, so there the option type stays open to them | [option-iface](#rule-option-iface) | For the protocols | judgment |
| <a id="row-115"></a>115 | U Linting (:4083-4096) | Lint consistently, with at least `errcheck`, `goimports`, `revive`, `govet` and `staticcheck` | keep | A guard candidate, not part of tool-finish; merged into community-skills.md tool-lint (owner ruling 2026-11-17, S-4); `errcheck` checks C1 err-handle | [tool-lint](community-skills.md#rule-tool-lint) | Tooling | tool: errcheck, goimports, revive, go vet, staticcheck (named by the source) |
| <a id="row-116"></a>116 | U Lint Runners (:4098-4103) | Run the linters with `golangci-lint` | keep | Same | [tool-lint](community-skills.md#rule-tool-lint) | Tooling | tool: golangci-lint (named by the source) |

### Headings with no rule

- Introduction (:75-99, :107-108): history, the guide's sources, and
  which Go versions its samples target.
- Receivers and Interfaces (:200-273): explains which receivers a
  value or pointer can call and which satisfy an interface; the
  compiler rejects the cases it warns of.
- Errors, Performance, Style, Initializing Structs, Patterns:
  introductions to the rules below them; Performance's one sentence,
  "apply only to the hot path", is kept in rows 54-55.
- Exit in Main (:1779-1788) and Use field tags (:1949-1954): the
  rationale for rows 47 and 49.
- Exit Once (:1880-1906): says `run()`'s name and signature are free;
  kept in main-run's wording.
- Group Similar Declarations (:2491-2492): says groups may be used
  inside functions; the rule it leads to is row 63.
- Lint Runners (:4105-4107): teams may add linters.

## Rules

Each rule below is the wording go.md takes. Source lines cite the rows
above; strategy citations are at bjornstack `67b1213`; U is `style.md`
at `1d60a91aa5e8`, read 2026-11-16.

### Tooling

<a id="rule-tool-goleak"></a>**tool-goleak.** A package that may start goroutines checks for
leaked goroutines in its tests with `go.uber.org/goleak`. This is a
guard candidate, not part of tool-finish (owner ruling, bs-f3o.2
comment "Owner rulings from go-decisions (2026-11-17)", S-5).
Source: U "Don't fire-and-forget goroutines" (:1966-1969),
`1d60a91aa5e8`, read 2026-11-16.
↩ row [51](#row-51)

<a id="rule-tool-lint"></a>**tool-lint.** Merged into community-skills.md
[tool-lint](community-skills.md#rule-tool-lint), which lists this
source's linters with the others (owner ruling, bs-f3o.2 comment
"Owner rulings from go-decisions (2026-11-17)", S-4). go.md takes that
rule.
↩ rows [115](#row-115), [116](#row-116)

### Pattern mappings

<a id="rule-time-external"></a>**time-external.** Exchange times with outside systems as `time.Time`
and `time.Duration` where the format supports them (flags, JSON, SQL,
YAML). Code that reads an instant converts it to UTC where it enters
(UTC Computation step 2); code that only passes a timestamp on without
reading it leaves it as it is (UTC Computation, SKIP WHEN). A value
that UTC Computation step 1 keeps as local time crosses as local date
and time plus its zone's name, never as a bare `time.Time`, whose
RFC 3339 form carries an offset but no zone name. Where a format
cannot carry a `time.Duration`, use an `int` or `float64` with the
unit in the field name: `IntervalMillis`. Where it cannot carry a
`time.Time`, write an RFC 3339 string in UTC (UTC Computation step 4),
unless another format is agreed.
Source: U "Use `time.Time` and `time.Duration` with external systems"
(:700-747), `1d60a91aa5e8`, read 2026-11-16.
Differs: Uber writes RFC 3339 in any offset, does not convert on
entry, and sends every time as `time.Time` where the format allows.
↩ rows [19](#row-19), [20](#row-20), [21](#row-21)

<a id="rule-err-contract"></a>**err-contract.** An exported sentinel or error type is part of the
package's contract: document it with the operation that returns it
(Failure Identity step 2) and change it as Grow Don't Break changes
any contract (Failure Identity rationale, "Why not every failure gets
an identity"). Export it only for callers outside the package that
match it; one matched only inside stays unexported (`errNotFound`,
`resolveError`).
Source: U "Error Types" (:886-887), "Error Naming" (:969-1018),
`1d60a91aa5e8`, read 2026-11-16.
↩ row [25](#row-25)

<a id="rule-err-degrade"></a>**err-degrade.** An error from an operation the work does not strictly
need, such as emitting metrics, may be logged while the work carries
on (Failure Identity step 1's background job that logs a failed cache
refresh). Recovering from one failure the callee's contract
identifies, such as using UTC when the user is not found, while
wrapping and returning every other, belongs in a unit whose job is
handling that failure (coord-logic; Failure Identity step 3).
Source: U "Handle Errors Once" (:1022-1130), `1d60a91aa5e8`, read
2026-11-16.
Differs: Uber matches and recovers inline, wherever the error is
received.
↩ rows [35](#row-35), [36](#row-36)

<a id="rule-test-no-panic"></a>**test-no-panic.** A test, and code it calls to set up, prefers
failing through `t` with `require` (test-require) over `panic`, so the
test is marked failed. `require` and `t.FailNow` work only on the test
goroutine; code that runs elsewhere, such as an `httptest` handler or
a double the code under test calls, reports with `t.Error`. Exception:
builders-a's panic for a state not written yet, since `Build()` takes
no `*testing.T`.
Source: U "Don't Panic" (:1216-1245), `1d60a91aa5e8`, read 2026-11-16.
Differs: Uber names `t.Fatal` and `t.FailNow`; we use `require`, which
fails through `t.FailNow`.
↩ row [40](#row-40)

<a id="rule-embed"></a>**embed.** Embed a type in a struct only when every exported method and
field of the inner type belongs on the outer type, as with a writer
that counts the bytes it passes on; otherwise hold it in a named field
and write the delegating methods. Embedding must not make the outer
type harder to build or use, spoil a useful zero value, change its
copy semantics, expose unexported types or internals, or change what
the inner methods do in a surprising way. In an exported struct,
default to a named field with delegating methods: there the
embedded type joins the contract (Intentionally Public step 3):
adding methods to an embedded interface, removing methods from an
embedded struct, or removing or replacing the embedded type breaks
callers (Grow Don't Break step 1). Never embed a `sync.Mutex` or
`sync.RWMutex`, even in an unexported type. Embedded fields come first
in a struct, separated from the other fields by a blank line.
Source: U "Zero-value Mutexes are Valid" (:300-301), "Avoid Embedding
Types in Public Structs" (:1379-1508), "Embedding in Structs"
(:2896-3051), `1d60a91aa5e8`, read 2026-11-16.
↩ rows [10](#row-10), [43](#row-43), [81](#row-81), [82](#row-82)

<a id="rule-wire-tags"></a>**wire-tags.** Every field of a struct marshaled to JSON, YAML or
another format that names fields by tag carries a tag with its name,
so the serialized form, a contract with other systems (Boundary
Communication step 3), stays fixed when the Go field is renamed. Such
types live in the boundary adapter (scrub-boundary).
Source: U "Use field tags in marshaled structs" (:1908-1954),
`1d60a91aa5e8`, read 2026-11-16.
↩ row [49](#row-49)

<a id="rule-test-table-names"></a>**test-table-names.** In a table test the slice of cases is `tests`
and each case `tt`. Prefer `give` as the prefix of input fields and
`want` for expected-value fields; a case that carries an assertion
function (test-table) may have no `want` field.
Source: U "Test Tables" (:3743-3762), `1d60a91aa5e8`, read 2026-11-16.
↩ row [106](#row-106)

<a id="rule-test-table-funcs"></a>**test-table-funcs.** A table carries no setup or
mock-expectation functions: cases that need different setup are
separate tests (Parameterized Test Structure step 1), and coordinator
tests with one case per collaborator's failure follow Unit Testing's
N+1 pattern (Parameterized Test Structure, SKIP WHEN). A case may
carry an assertion function (test-table).
Source: U "Avoid Unnecessary Complexity in Table Tests" (:3790-3793,
:3860-3887), `1d60a91aa5e8`, read 2026-11-16.
Differs: Uber counts any function in the table as confusing, an
assertion function included.
↩ row [110](#row-110)

### Go pitfalls

<a id="rule-slice-map-alias"></a>**slice-map-alias.** A slice or map shares its backing data with
every copy of it. A function that stores one it received sees whatever
the caller changes later, and one that returns one it holds lets the
caller change its state, outside any lock that guards it. Where the
other side must not share it, copy it on the way in or out.
Source: U "Copy Slices and Maps at Boundaries" (:367-470),
`1d60a91aa5e8`, read 2026-11-16.
↩ rows [11](#row-11), [12](#row-12)

<a id="rule-time-add"></a>**time-add.** `t.AddDate(0, 0, 1)` moves to the same clock time on the
next calendar day; `t.Add(24 * time.Hour)` moves exactly 24 hours.
Choose by intent. `AddDate` counts days on the calendar of the value's
own zone, so convert into the computation's zone first (UTC
Computation step 3).
Source: U "Use `time.Duration` for periods of time" (:689-698),
`1d60a91aa5e8`, read 2026-11-16.
Differs: Uber does not mention the zone.
↩ row [18](#row-18)

### For the protocols

<a id="rule-iface-assert"></a>**iface-assert.** Assert at compile time that a type implements an
interface, `var _ http.Handler = (*Handler)(nil)`, where breaking it
would break users: an exported type whose contract is to implement
the interface, every type in a set implementing the same interface,
and any other case where a missing method would break a user. The
right-hand side is the asserted type's zero value: `nil` for a
pointer, slice or map, `T{}` for a struct.
Source: U "Verify Interface Compliance" (:127-198), `1d60a91aa5e8`,
read 2026-11-16.
↩ rows [6](#row-6), [7](#row-7)

<a id="rule-defer-cleanup"></a>**defer-cleanup.** Release files, locks and other resources with
`defer` right after acquiring them. Leave `defer` out only where you
can show the function runs in nanoseconds.
Source: U "Defer to Clean Up" (:472-520), `1d60a91aa5e8`, read
2026-11-16.
↩ row [13](#row-13)

<a id="rule-chan-size"></a>**chan-size.** A channel is usually unbuffered or has a buffer of one.
Before using any other size, answer how the size was chosen, what
keeps the channel from filling under load, and what happens to its
writers when it does.
Source: U "Channel Size is One or None" (:522-550), `1d60a91aa5e8`,
read 2026-11-16.
↩ row [14](#row-14)

<a id="rule-enum-start"></a>**enum-start.** An `iota` enum starts at one, `Add Operation = iota + 1`,
so an unset variable is not a valid member. Start at zero only where
the zero value is the right default, as `LogToStdout` is.
Source: U "Start Enums at One" (:552-605), `1d60a91aa5e8`, read
2026-11-16.
↩ row [15](#row-15)

<a id="rule-time-types"></a>**time-types.** Hold an instant in a `time.Time` and compare or shift
it with its methods (`Before`, `Equal`, `Add`). Hold a period in a
`time.Duration`, never an `int` whose unit the reader must guess.
Source: U "Use `"time"` to handle time" (:609-687), `1d60a91aa5e8`,
read 2026-11-16.
↩ rows [16](#row-16), [17](#row-17)

<a id="rule-err-plain"></a>**err-plain.** An error that no caller matches is `errors.New` for a
fixed message and `fmt.Errorf` for one that carries values.
Source: U "Error Types" (:759-831), `1d60a91aa5e8`, read 2026-11-16.
↩ row [24](#row-24)

<a id="rule-log-err-mark"></a>**log-err-mark.** When an error's message goes to another system, such
as a log, make it plain that it is an error: put it under an `err`
key of the log record, or mark the line as a failure.
Source: U "Error Wrapping" (:962-963), `1d60a91aa5e8`, read 2026-11-16.
↩ row [31](#row-31)

<a id="rule-err-naming"></a>**err-naming.** A package-level error value is named `ErrX` when
exported and `errX` when not. An error type's name ends in `Error`:
`NotFoundError`, `resolveError`.
Source: U "Error Naming" (:967-1018), `1d60a91aa5e8`, read 2026-11-16.
↩ rows [32](#row-32), [33](#row-33)

<a id="rule-type-assert"></a>**type-assert.** Use the two-result form of a type assertion,
`t, ok := i.(string)`, and handle `!ok`; the one-result form panics
on the wrong type.
Source: U "Handle Type Assertion Failures" (:1132-1159),
`1d60a91aa5e8`, read 2026-11-16.
↩ row [37](#row-37)

<a id="rule-atomic-typed"></a>**atomic-typed.** Where new code reads and writes a value
atomically, use a typed atomic from `sync/atomic`, such as
`atomic.Bool`, not a plain integer passed to the `sync/atomic`
functions, where one plain read is a race (least-mechanism). Code
already on the functions stays on them until a migration is asked
for; say that it is on the old form, so a migration can be considered.
Source: U "Use go.uber.org/atomic" (:1247-1300), `1d60a91aa5e8`, read
2026-11-16.
Differs: Uber uses `go.uber.org/atomic`.
↩ row [41](#row-41)

<a id="rule-builtin-names"></a>**builtin-names.** No variable, parameter or field takes the name of a
predeclared identifier such as `error` or `string`; use `msg`, `err`,
`str`.
Source: U "Avoid Using Built-In Names" (:1510-1599), `1d60a91aa5e8`,
read 2026-11-16.
↩ row [44](#row-44)

<a id="rule-no-init"></a>**no-init.** Avoid `init()`. Where it is unavoidable, it aims to be
deterministic, to not depend on the order or effects of other `init()`
functions, to not read or change global or environment state
(environment variables, working directory, arguments), and to do no
I/O; code that can't meet these likely belongs in a function called
from `main`. It never starts goroutines. Fitting uses: a value no
single expression can build, registering a pluggable hook such as a
`database/sql` driver, which writes global state and is allowed, and
deterministic precomputation.
Source: U "Avoid `init()`" (:1601-1714), "No goroutines in `init()`"
(:2069-2072), `1d60a91aa5e8`, read 2026-11-16.
↩ rows [45](#row-45), [46](#row-46)

<a id="rule-main-run"></a>**main-run.** Only `main` calls `os.Exit` or `log.Fatal`; other
functions return errors. The exception is panic-scope's panic on a
broken invariant. Where possible, `main` ends the process in one
place: it calls a function, such as `run`, that returns an error or an
exit code, and exits once on failure. The function's name and
signature are free.
Source: U "Exit in Main" (:1716-1789), "Exit Once" (:1790-1906),
`1d60a91aa5e8`, read 2026-11-16.
↩ rows [47](#row-47), [48](#row-48)

<a id="rule-go-owner"></a>**go-owner.** A package that needs a background goroutine starts it
only when the user creates the object that owns it. That object has a
method, such as `Close`, `Stop` or `Shutdown`, that signals the
goroutine to stop and waits for it to exit.
Source: U "No goroutines in `init()`" (:2069-2146), `1d60a91aa5e8`,
read 2026-11-16.
↩ row [53](#row-53)

<a id="rule-go-wait"></a>**go-wait.** Every goroutine has a predictable end or a signal that
stops it, and the code that starts it has a way to wait for it to
exit: a `sync.WaitGroup` for several goroutines, a `done` channel the
goroutine closes for one.
Source: U "Don't fire-and-forget goroutines" (:1967-1977), "Wait for
goroutines to exit" (:2036-2067), `1d60a91aa5e8`, read 2026-11-16.
Differs: C1 go-lifetime also accepts documenting when the goroutine
exits; we require a way to wait.
↩ rows [50](#row-50), [52](#row-52)

<a id="rule-perf-hot-path"></a>**perf-hot-path.** On a hot path only: convert primitives to and from
strings with `strconv`, not `fmt`, and convert a fixed string to
`[]byte` once, outside the loop.
Source: U "Performance" (:2148-2231), `1d60a91aa5e8`, read 2026-11-16.
↩ rows [54](#row-54), [55](#row-55)

<a id="rule-decl-group"></a>**decl-group.** Group related `import`, `const`, `var` and `type`
declarations in one parenthesised block, and put unrelated ones in
separate blocks.
Source: U "Group Similar Declarations" (:2385-2489), `1d60a91aa5e8`,
read 2026-11-16.
↩ rows [61](#row-61), [62](#row-62)

<a id="rule-pkg-singular"></a>**pkg-singular.** A package name is singular: `net/url`, not
`net/urls`.
Source: U "Package Names" (:2610), `1d60a91aa5e8`, read 2026-11-16.
↩ row [67](#row-67)

<a id="rule-import-alias"></a>**import-alias.** Name an import explicitly when its package name
differs from the last element of its path:
`client "example.com/client-go"`, `trace "example.com/trace/v2"`.
Source: U "Import Aliasing" (:2622-2634), `1d60a91aa5e8`, read
2026-11-16.
↩ row [71](#row-71)

<a id="rule-file-order"></a>**file-order.** In a file, types, constants and variables come first,
then exported functions, then the rest, sorted roughly in call order.
Functions with the same receiver sit together; a constructor may
follow its type, before its methods; plain functions come last.
Source: U "Function Grouping and Ordering" (:2669-2723),
`1d60a91aa5e8`, read 2026-11-16.
↩ rows [73](#row-73), [74](#row-74), [75](#row-75), [76](#row-76)

<a id="rule-if-default"></a>**if-default.** When both branches of an `if` only set one variable,
set the default first and override it in a single `if`.
Source: U "Unnecessary Else" (:2771-2800), `1d60a91aa5e8`, read
2026-11-16.
↩ row [78](#row-78)

<a id="rule-top-var"></a>**top-var.** Declare top-level variables with `var` and leave the type
out, unless it differs from the expression's type, as when an `error`
variable holds a value of a concrete error type.
Source: U "Top-level Variable Declarations" (:2802-2843),
`1d60a91aa5e8`, read 2026-11-16.
↩ row [79](#row-79)

<a id="rule-nil-slice-return"></a>**nil-slice-return.** Return `nil` for an empty slice, not `[]T{}`.
A nil slice and an empty one are still different values, and a
serialized form may tell them apart; where a contract does, return
what it needs.
Source: U "nil is a valid slice" (:3111-3205), `1d60a91aa5e8`, read
2026-11-16.
↩ rows [85](#row-85), [88](#row-88)

<a id="rule-var-scope"></a>**var-scope.** Narrow a variable's scope where that adds no nesting:
`if err := os.WriteFile(name, data, 0o644); err != nil`. A constant
need not be package-level unless several functions or files use it or
it is part of the package's contract.
Source: U "Reduce Scope of Variables" (:3207-3308), `1d60a91aa5e8`,
read 2026-11-16.
↩ rows [89](#row-89), [91](#row-91)

<a id="rule-bool-param"></a>**bool-param.** Where a `bool` argument's meaning is unclear at the call
site, give the parameter a named type with constants, such as
`Region` or `Status`; it also leaves room for more than two states.
Source: U "Avoid Naked Parameters" (:3310-3358), `1d60a91aa5e8`, read
2026-11-16.
Differs: Uber first suggests a `/* isLocal */` comment at the call;
fmt-arg-comments (C1) rules out comments on call arguments.
↩ row [93](#row-93)

<a id="rule-raw-strings"></a>**raw-strings.** Write a string that would need escaped quotes or
backslashes as a raw string literal: `` `unknown error:"test"` ``.
Source: U "Use Raw String Literals to Avoid Escaping" (:3360-3382),
`1d60a91aa5e8`, read 2026-11-16.
↩ row [94](#row-94)

<a id="rule-map-init"></a>**map-init.** Create an empty map, or one that code fills, with `make`,
so creating it looks different from declaring it; give a size hint
only as size-hints allows. A map with a fixed set of entries is a
literal (var-decl).
Source: U "Initializing Maps" (:3531-3610), `1d60a91aa5e8`, read
2026-11-16.
↩ row [101](#row-101)

<a id="rule-printf-vet"></a>**printf-vet.** A format string declared outside its call is a `const`,
so `go vet` can check it. A Printf-style function has a standard name
(`Printf`, `Errorf`) or one ending in `f` (`Wrapf`), so `go vet`
checks its format string, with `-printfuncs` for a custom name.
Source: U "Format Strings outside Printf" and "Naming Printf-style
Functions" (:3612-3656), `1d60a91aa5e8`, read 2026-11-16.
↩ rows [103](#row-103), [104](#row-104)

<a id="rule-option-iface"></a>**option-iface.** Prefer implementing functional options as an
`Option` interface with an unexported `apply(*options)` method that
records into an unexported `options` struct, over closures: options
can then be compared in tests and can implement `fmt.Stringer`. Where
other packages are meant to define options (func-options), use
exported option functions instead, since the unexported `apply`
method keeps other packages from implementing `Option`.
Source: U "Functional Options" (:4011-4071), `1d60a91aa5e8`, read
2026-11-16.
Differs: Uber gives the interface as its suggested way without the
case of options defined in other packages.
↩ row [114](#row-114)

## Dropped

One section per drop row: what the source said, what it would have
meant in practice, and why it was dropped.

### <a id="drop-2"></a>Row 2: golint

Source: U "Introduction" (:101): "All code should be error-free when run through `golint` and `go vet`."

In practice: `golint` runs on every change and its findings block it.

Dropped because: The source's own Linting section (:4096) says `golint` is deprecated and `revive` is its successor; row 115 takes `revive`.

↩ row [2](#row-2)

### <a id="drop-3"></a>Row 3: Editor setup

Source: U "Introduction" (:102-105): "We recommend setting up your editor to: Run `goimports` on save; Run `golint` and `go vet` to check for errors".

In practice: Each developer's editor formats and lints on save.

Dropped because: Editor setup, not a rule about the code; the same tools run as checks in rows 1 and 115.

↩ row [3](#row-3)

### <a id="drop-22"></a>Row 22: Leap seconds

Source: U "Use `time.Time` and `time.Duration` with external systems" (:749-753): "the `"time"` package does not support parsing timestamps with leap seconds ... nor does it account for leap seconds in calculations."

In practice: A reader is told that the difference between two instants leaves out leap seconds.

Dropped because: A fact that asks nothing of the code; the source says it "tends to not be a problem in practice".

↩ row [22](#row-22)

### <a id="drop-63"></a>Row 63: Grouping local variables

Source: U "Group Similar Declarations" (:2491-2562): inside functions, adjacent variables go in one `var ( ... )` group, even unrelated ones.

In practice: `var n int` and `var err error` on adjacent lines become one `var ( ... )` block.

Dropped because: Plain style that gofmt and the standard conventions leave free, and go.md carries only our additions. Owner ruling, bs-f3o.2 comment "Owner rulings from go-decisions (2026-11-17)", S-6.

↩ row [63](#row-63)

### <a id="drop-109"></a>Row 109: Narrowest unit and test depth

Source: U "Avoid Unnecessary Complexity in Table Tests" (:3776-3788): "Some ideals to aim for are: Focus on the narrowest unit of behavior; Minimize "test depth" ..."

In practice: Reviewers count how many assertions in a test depend on earlier ones and push for fewer.

Dropped because: The source states them as ideals, not rules. The two concrete ideals in the same list are rows 107-108, and test-whole-value's single `require.Equal` already keeps a check to one comparison.

↩ row [109](#row-109)

### <a id="drop-112"></a>Row 112: Copy the loop variable for parallel subtests

Source: U "Parallel Tests" (:3898-3901): parallel tests "must take care to explicitly assign loop variables within the loop's scope to ensure that they hold the expected values."

In practice: Each loop starts with `tt := tt` before `t.Run`.

Dropped because: Since Go 1.22, in a module whose `go.mod` declares `go 1.22` or later, each loop iteration has its own variable, so the copy is redundant. jetbrains-modern [row 27](jetbrains-modern.md#row-27) already decides redundant `v := v` copies.

↩ row [112](#row-112)

## Open for owner

None. The owner ruled on all three earlier questions on 2026-11-17
(bs-f3o.2 comment "Owner rulings from go-decisions"): goleak (row 51)
and the linters (rows 115-116) are guard candidates, not part of
tool-finish; tool-lint is merged into community-skills.md; grouping
local variables (row 63) is dropped.

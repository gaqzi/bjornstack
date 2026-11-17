# Go sources C2: Google Go style guide, best practices

Decision table for bs-f3o.2.4. It reviews the best-practices page of
Google's Go style guide and decides, rule by rule, what goes into
`languages/go.md`. A rule that our own table,
[bjornstack.md](bjornstack.md), already holds reads "already ours" and
names that table's row.

Source: `https://github.com/google/styleguide`, commit
`a9c5f82b19811f1552d73df384a9f9d7c75ca16e` (2026-11-13), file
`go/best-practices.md` (published at
google.github.io/styleguide/go/best-practices). Read 2026-11-16. The
page calls itself neither normative nor canonical: guidance on applying
the core guide, which bs-f3o.2.3 reviews. Strategy text was judged at
bjornstack commit `67b1213`.

## Sources and pins

| Key | Source | Pin |
|---|---|---|
| BP | Google "Go Style Best Practices", `go/best-practices.md` | `github.com/google/styleguide` commit `a9c5f82b1981`, read 2026-11-16 |

The Source column names the heading and the line range in
`best-practices.md` at that commit. Introductions, explanations, lists
of examples and pointers to other pages hold no rule and get no row;
the headings that hold nothing else are listed under
[Headings with no rule](#headings-with-no-rule).

## Decision table

"Section" names the go.md section: Tooling, Pattern mappings (a
strategy or one of our rules spelled for Go), Go pitfalls, or For the
protocols (material bs-y5h turns into protocol steps; Go style rules
that map to no strategy go here). "Check" says how a rule is enforced:
"tool" when a check the pinned source itself names enforces it, "guard
candidate" when the rule is mechanical but no check is named,
"judgment" when a person or an agent has to decide. An "already ours"
row carries the Section and Check of the bjornstack.md row it names.
Drop rows have "—" and "-".

| # | Source | Item | Decision | Reason | Rule id | Section | Check |
|---|---|---|---|---|---|---|---|
| <a id="row-1"></a>1 | BP Avoid repetition (:49-53) | Names leave out the types of inputs and outputs, the receiver's type, and whether a value is a pointer | keep | Go naming convention; nothing in our layers says it | [name-call-site](#rule-name-call-site) | For the protocols | judgment |
| <a id="row-2"></a>2 | BP Avoid repetition (:55-72) | A function does not repeat its package's name | already ours | bjornstack.md [row 4](bjornstack.md#row-4) (pkg-naming) | [pkg-naming](bjornstack.md#rule-pkg-naming) | Pattern mappings | guard candidate |
| <a id="row-3"></a>3 | BP Avoid repetition (:74-86) | A method does not repeat its receiver's name | keep | Same call-site reading as row 1 | [name-call-site](#rule-name-call-site) | For the protocols | judgment |
| <a id="row-4"></a>4 | BP Avoid repetition (:88-100) | A name does not repeat its parameters' names | keep | Same | [name-call-site](#rule-name-call-site) | For the protocols | judgment |
| <a id="row-5"></a>5 | BP Avoid repetition (:102-114) | A name does not repeat its results' names and types | keep | Same | [name-call-site](#rule-name-call-site) | For the protocols | judgment |
| <a id="row-6"></a>6 | BP Avoid repetition (:116-124) | Extra words are fine where they tell apart functions with similar names | keep | The exception to rows 1-5, kept with them | [name-call-site](#rule-name-call-site) | For the protocols | judgment |
| <a id="row-7"></a>7 | BP Naming conventions (:133-139) | A function that returns something has a noun-like name | keep | Go naming convention | [name-shape](#rule-name-shape) | For the protocols | judgment |
| <a id="row-8"></a>8 | BP Naming conventions (:141-148) | No `Get` prefix | keep | Same | [name-shape](#rule-name-shape) | For the protocols | guard candidate |
| <a id="row-9"></a>9 | BP Naming conventions (:150-156) | A function that does something has a verb-like name | keep | Same | [name-shape](#rule-name-shape) | For the protocols | judgment |
| <a id="row-10"></a>10 | BP Naming conventions (:158-178) | Functions differing only by type end in the type's name; a clear primary version may omit it | keep | Same, exception included | [name-shape](#rule-name-shape) | For the protocols | judgment |
| <a id="row-11"></a>11 | BP Creating test helper packages (:228-242) | A package of test helpers for `creditcard` is named `creditcardtest` | adapt | compliance-suite already uses such a package (`storagetest`); everything this module's own tests share lives under `test/a` (Test Data Builders step 2), so the name is for the compliance suite and helpers published outside this module | [test-helper-pkg](#rule-test-helper-pkg) | Pattern mappings | judgment |
| <a id="row-12"></a>12 | BP Simple case (:272-287) | Mark the helper package's Bazel `go_library` as `testonly` | drop | Bazel; we build with the go tool | [dropped](#drop-12) | — | - |
| <a id="row-13"></a>13 | BP Simple case (:246-290) | One double for one type is named plainly (`Stub`), not `StubService` | adapt | Our doubles live in their test file, often as a function (Test Data Builders step 2; coord-doubles), so the names are unexported values, not types in a `footest` package | [double-names](#rule-double-names) | Pattern mappings | judgment |
| <a id="row-14"></a>14 | BP Multiple test double behaviors (:298-319) | Several doubles of one type are named for the behaviour they simulate (`AlwaysDeclines`) | adapt | Same as row 13 | [double-names](#rule-double-names) | Pattern mappings | judgment |
| <a id="row-15"></a>15 | BP Multiple doubles for multiple types (:323-362) | Doubles for several types add the type (`StubService`, `StubStoredValue`) | adapt | Same as row 13 | [double-names](#rule-double-names) | Pattern mappings | judgment |
| <a id="row-16"></a>16 | BP Local variables in tests (:366-454) | A variable holding a double says so (`spyCC`) where production values sit beside it | keep | Highlights which value is the double | [double-names](#rule-double-names) | Pattern mappings | judgment |
| <a id="row-17"></a>17 | BP Shadowing (:477-499) | Reusing a variable with `:=` in the same scope is fine once the old value is not needed | keep | Go-specific | [shadow-block](#rule-shadow-block) | Go pitfalls | judgment |
| <a id="row-18"></a>18 | BP Shadowing (:501-540) | `:=` inside a new block declares a new variable; code after the block sees the outer one | keep | Go-specific trap | [shadow-block](#rule-shadow-block) | Go pitfalls | guard candidate |
| <a id="row-19"></a>19 | BP Shadowing (:542-546) | Shadow on purpose only where a new name would not read better | keep | Same rule as rows 17-18 | [shadow-block](#rule-shadow-block) | Go pitfalls | judgment |
| <a id="row-20"></a>20 | BP Shadowing (:548-562) | No variable named after a standard package outside a very small scope | keep | Go-specific | [shadow-pkg-name](#rule-shadow-pkg-name) | For the protocols | guard candidate |
| <a id="row-21"></a>21 | BP Shadowing (:550-553) | A package name should not force clients to rename the import or take a good variable name | keep | Same | [shadow-pkg-name](#rule-shadow-pkg-name) | For the protocols | judgment |
| <a id="row-22"></a>22 | BP Util packages (:573-578) | No package named `util`, `helper`, `common` | already ours | bjornstack.md [row 3](bjornstack.md#row-3) (proto-packages); BP's "as part of a name" allowance does not conflict, a domain word with a suffix is not a role name | [proto-packages](bjornstack.md#rule-proto-packages) | For the protocols | guard candidate |
| <a id="row-23"></a>23 | BP Util packages (:570-604) | A package's name says what it provides; judge it at the call site | already ours | bjornstack.md [row 1](bjornstack.md#row-1) (pkg-naming) | [pkg-naming](bjornstack.md#rule-pkg-naming) | Pattern mappings | judgment |
| <a id="row-24"></a>24 | BP Package size (:618-631) | Types that clients use together, or whose implementations are tightly coupled, share a package; if a user must import both packages to use either, combine them | keep | Domain-First Packaging rationale (two packages that always change together are one domain) and its over-packaging misapplication | [pkg-size](#rule-pkg-size) | Pattern mappings | judgment |
| <a id="row-25"></a>25 | BP Package size (:633-638) | Something conceptually distinct gets its own small package | keep | Domain-First Packaging step 1 | [pkg-size](#rule-pkg-size) | Pattern mappings | judgment |
| <a id="row-26"></a>26 | BP Package size (:640-648) | No one-type-per-file rule; neither files of thousands of lines nor many tiny files | keep | Go convention | [file-size](#rule-file-size) | For the protocols | judgment |
| <a id="row-27"></a>27 | BP Package size (:649-651) | Long package documentation may go in `doc.go` | drop | A permission, not required; nothing to enforce | [dropped](#drop-27) | — | - |
| <a id="row-28"></a>28 | BP Package size (:653-656) | Bazel directory layout; one directory per package if you may open-source | drop | Bazel; with the go tool a directory is a package | [dropped](#drop-28) | — | - |
| <a id="row-29"></a>29 | BP Protocol Buffer Messages and Stubs (:721-737) | Rename generated proto imports with a `pb` suffix, gRPC stubs with `grpc` | adapt | BP ties the suffix to Bazel rule names; we tie it to what the generated package holds, and fall back on the proto package name, not the Bazel target name | [proto-import-names](#rule-proto-import-names) | For the protocols | guard candidate |
| <a id="row-30"></a>30 | BP Protocol Buffer Messages and Stubs (:739-755) | Prefer descriptive whole words over `pb` or `xpb`; existing short names need not change | keep | Same rule | [proto-import-names](#rule-proto-import-names) | For the protocols | judgment |
| <a id="row-31"></a>31 | BP Error handling (:777-788) | Handle errors deliberately; consider whether this frame is best placed to handle one | drop | Advice to use judgment; the checkable parts are rows 33-50, and Failure Identity step 3 says which unit handles a failure | [dropped](#drop-31) | — | - |
| <a id="row-32"></a>32 | BP Error handling (:790-796) | Where related operations run as a group and only the first error matters, `errgroup` is a convenient way to run them | keep | Go library form; Failure Identity step 4 (the caller acts on the whole) | [err-group](#rule-err-group) | Tooling | judgment |
| <a id="row-33"></a>33 | BP Error structure (:812-843) | Give an error structure when callers need to tell conditions apart; the simplest is a sentinel value | keep | Go spelling of Failure Identity steps 1-2 | [err-identity](#rule-err-identity) | Pattern mappings | judgment |
| <a id="row-34"></a>34 | BP Error structure (:845-878) | Compare a sentinel with `==`, or with `errors.Is` when the function wraps | adapt | A callee may start wrapping at any time (err-wrap-where, bjornstack.md [row 121](bjornstack.md#row-121); `%w` per err-wrap-verb, [row 48](bjornstack.md#row-48)), and `==` then stops matching without any error: always `errors.Is` | [err-is-sentinel](#rule-err-is-sentinel) | Go pitfalls | guard candidate |
| <a id="row-35"></a>35 | BP Error structure (:880-892) | Never tell errors apart by their string form | already ours | bjornstack.md [row 48](bjornstack.md#row-48) (err-wrap-verb: "never a match on the text") | [err-wrap-verb](bjornstack.md#rule-err-wrap-verb) | Go pitfalls | judgment |
| <a id="row-36"></a>36 | BP Error structure (:894-897) | Values the caller needs go in struct fields (`os.PathError.Path`) | keep | Failure Identity step 2 | [err-identity](#rule-err-identity) | Pattern mappings | judgment |
| <a id="row-37"></a>37 | BP Error structure (:899-904) | Package `status` is optional; if used, use canonical codes | keep | A handler choosing a status is Unit Testing step 3.4's user-facing coordinator | [err-grpc-status](#rule-err-grpc-status) | Pattern mappings | judgment |
| <a id="row-38"></a>38 | BP Adding information to errors (:917-947) | Don't repeat what the underlying error already says | keep | Failure Identity step 5 (what failed and the values), without doubling them | [err-annotate](#rule-err-annotate) | Pattern mappings | judgment |
| <a id="row-39"></a>39 | BP Adding information to errors (:949-957) | No annotation that only says it failed; return `err` instead | adapt | err-wrap-where (bjornstack.md [row 121](bjornstack.md#row-121)) always wraps another unit's public function's error, so a wrap that only says it failed names the action instead of being left out | [err-annotate](#rule-err-annotate) | Pattern mappings | guard candidate |
| <a id="row-40"></a>40 | BP Adding information to errors (:959-980) | Name the action that failed, without stop words ("failed to", "couldn't", "unable to") | keep | Failure Identity step 5 | [err-annotate](#rule-err-annotate) | Pattern mappings | guard candidate |
| <a id="row-41"></a>41 | BP Adding information to errors (:982-1002) | When a function does several actions, say which one failed | keep | Failure Identity step 5 | [err-annotate](#rule-err-annotate) | Pattern mappings | judgment |
| <a id="row-42"></a>42 | BP Adding information to errors (:1011-1019) | Use `%v` to add non-redundant context | drop | Owner ruled `%v` only at the edge, a single `%w` above it: bjornstack.md [row 48](bjornstack.md#row-48) (err-wrap-verb) | [dropped](#drop-42) | — | - |
| <a id="row-43"></a>43 | BP Adding information to errors (:1021-1025) | Use `%v` when the error is for logging or display and no caller is meant to inspect it | drop | Same: err-wrap-verb chooses the verb by position, not by who inspects | [dropped](#drop-43) | — | - |
| <a id="row-44"></a>44 | BP Adding information to errors (:1024-1025) | `errors.Unwrap` does not handle multi-errors | keep | Go-specific trap beside err-join-match | [err-unwrap-multi](#rule-err-unwrap-multi) | Go pitfalls | guard candidate |
| <a id="row-45"></a>45 | BP Adding information to errors (:1027-1064) | At system boundaries (RPC, IPC, storage) create a fresh error with `%v`, translating into a canonical error space | already ours | Storage side: bjornstack.md [row 48](bjornstack.md#row-48) (err-wrap-verb: `%v` at the edge where an outside error comes in); RPC response side: err-grpc-status ([row 37](#row-37)), the handler translating for our clients (Failure Identity step 3) | [err-wrap-verb](bjornstack.md#rule-err-wrap-verb) | Go pitfalls | judgment |
| <a id="row-46"></a>46 | BP Adding information to errors (:1073-1093) | Use `%w` to add context while keeping the cause inspectable | already ours | bjornstack.md [row 48](bjornstack.md#row-48) (err-wrap-verb: a single `%w` above the edge); where to wrap is [row 121](bjornstack.md#row-121) | [err-wrap-verb](bjornstack.md#rule-err-wrap-verb) | Go pitfalls | judgment |
| <a id="row-47"></a>47 | BP Adding information to errors (:1095-1100) | Where the system meets an external one, translate rather than wrap with `%w` | keep | BP means errors going out to our clients, not err-wrap-verb's errors coming in: the handler translates into canonical codes (Failure Identity step 3), as err-grpc-status ([row 37](#row-37)) says; not in bjornstack.md, so not "already ours" | [err-grpc-status](#rule-err-grpc-status) | Pattern mappings | judgment |
| <a id="row-48"></a>48 | BP Adding information to errors (:1102-1106) | Use `%w` when the API documents and tests the underlying errors it exposes | drop | err-wrap-verb wraps with `%w` above the edge whether or not the cause is documented; documenting identities is err-doc | [dropped](#drop-48) | — | - |
| <a id="row-49"></a>49 | BP Placement of %w in errors (:1117-1184) | Put `%w` at the end: `"...: %w"` | keep | Go-specific; the text then reads in chain order | [err-w-placement](#rule-err-w-placement) | For the protocols | guard candidate |
| <a id="row-50"></a>50 | BP Sentinel error placement (:1188-1244) | Exception: a categorising sentinel goes first, `"%w: ..."` | keep | The exception to row 49, kept with it | [err-w-placement](#rule-err-w-placement) | For the protocols | judgment |
| <a id="row-51"></a>51 | BP Logging errors (:1265-1267) | A log message says what went wrong and what is needed to diagnose it | keep | Go-neutral but nothing in our layers says it | [log-errors](#rule-log-errors) | For the protocols | judgment |
| <a id="row-52"></a>52 | BP Logging errors (:1269-1276) | Don't log an error you return; the caller decides | keep | Same | [log-errors](#rule-log-errors) | For the protocols | judgment |
| <a id="row-53"></a>53 | BP Logging errors (:1278-1279) | Be careful with personal data in logs | keep | Same | [log-errors](#rule-log-errors) | For the protocols | judgment |
| <a id="row-54"></a>54 | BP Logging errors (:1281-1285) | Use `log.Error` sparingly; error level means actionable | adapt | The flush cost is glog's; the "actionable" test holds for any logger | [log-errors](#rule-log-errors) | For the protocols | judgment |
| <a id="row-55"></a>55 | BP Logging errors (:1287-1290) | Google's monitoring systems alert better than log files | drop | Google infrastructure; no rule for us | [dropped](#drop-55) | — | - |
| <a id="row-56"></a>56 | BP Custom verbosity levels (:1302-1308) | Convention for `log.V(1)`, `V(2)`, `V(3)` | drop | glog's verbosity API; our logger is slog through `logctx.From(ctx)` (ctx-scope) | [dropped](#drop-56) | — | - |
| <a id="row-57"></a>57 | BP Custom verbosity levels (:1310-1332) | Don't call expensive functions for a log line whose level is off | adapt | glog's `if log.V(2)` becomes slog's level check | [log-lazy](#rule-log-lazy) | Go pitfalls | judgment |
| <a id="row-58"></a>58 | BP Program initialization (:1340-1344) | Initialization errors go up to `main`, which exits with an actionable message, not a stack trace | adapt | glog's `log.Exit` and `log.Fatal` become plain Go | [main-exit](#rule-main-exit) | For the protocols | judgment |
| <a id="row-59"></a>59 | BP Program checks and panics (:1350-1353) | Libraries return errors rather than abort, especially for transient ones | keep | Go convention | [panic-scope](#rule-panic-scope) | For the protocols | judgment |
| <a id="row-60"></a>60 | BP Program checks and panics (:1355-1361) | An invariant whose failure leaves state unrecoverable ends the program with `log.Fatal`, not `panic` | adapt | Owner ruling (bs-f3o.2.4, 2026-11-16): panic with a message naming the invariant, and nothing recovers to carry on. BP's reason the standard library panics is that it lacks levelled logging (:1388-1391), our position without glog; slog has no Fatal, and `os.Exit` in a library skips `t.Cleanup` in tests | [panic-scope](#rule-panic-scope) | For the protocols | judgment |
| <a id="row-61"></a>61 | BP Program checks and panics (:1363-1369) | Don't recover panics to avoid crashes | keep | Go form of Fail Early and Loud | [panic-no-recover](#rule-panic-no-recover) | For the protocols | guard candidate |
| <a id="row-62"></a>62 | BP Program checks and panics (:1371-1375) | `net/http` recovering handler panics is a mistake to avoid in your servers | keep | Same rule as row 61 | [panic-no-recover](#rule-panic-no-recover) | For the protocols | judgment |
| <a id="row-63"></a>63 | BP When to panic (:1384-1391) | Panic on API misuse, as the standard library does | keep | Go convention | [panic-scope](#rule-panic-scope) | For the protocols | judgment |
| <a id="row-64"></a>64 | BP When to panic (:1396-1441) | A package may panic internally if a matching recover turns it into an error before it crosses the package boundary | keep | Go-specific pattern with its conditions | [panic-recover](#rule-panic-recover) | For the protocols | judgment |
| <a id="row-65"></a>65 | BP When to panic (:1443-1460) | `panic("unreachable")` after a call the compiler does not know never returns | keep | Go-specific | [panic-scope](#rule-panic-scope) | For the protocols | judgment |
| <a id="row-66"></a>66 | BP When to panic (:1462) | Don't call `log` functions before flags are parsed | drop | glog-specific | [dropped](#drop-66) | — | - |
| <a id="row-67"></a>67 | BP When to panic (:1463-1465) | A panic may replace fatal logging in `init` or a `Must` function | keep | Go convention | [panic-scope](#rule-panic-scope) | For the protocols | judgment |
| <a id="row-68"></a>68 | BP Parameters and configuration (:1498-1536) | Not every parameter needs documenting; document the error-prone and non-obvious, saying why | adapt | Say It Once step 1 leaves existing caller documentation alone even when it repeats the name; owner ruling 2026-11-17 (S-12) | [doc-params](#rule-doc-params) | Pattern mappings | judgment |
| <a id="row-69"></a>69 | BP Contexts (:1556-1579) | Cancellation interrupting the call and returning `ctx.Err()` is implied; don't restate it | adapt | Same as row 68 | [doc-ctx](#rule-doc-ctx) | Pattern mappings | judgment |
| <a id="row-70"></a>70 | BP Contexts (:1581-1626) | Document ctx where behaviour differs: another error on cancellation, other interruption, expectations of lifetime, lineage or values | keep | Say It Once step 4.2: a rule callers follow goes in their documentation | [doc-ctx](#rule-doc-ctx) | Pattern mappings | judgment |
| <a id="row-71"></a>71 | BP Contexts (:1628-1630) | Avoid APIs that make such demands of ctx | keep | Fits ctx-scope (bjornstack.md [row 47](bjornstack.md#row-47)) | [doc-ctx](#rule-doc-ctx) | Pattern mappings | judgment |
| <a id="row-72"></a>72 | BP Concurrency (:1636-1659) | Read-only operations are assumed safe for concurrent use, mutating ones not; don't restate it | adapt | Read-only operations need no remark; a type not safe for concurrent use says so once, on the type, with what breaks (Say It Once step 4.2's Good example), not per method | [doc-concurrency](#rule-doc-concurrency) | Pattern mappings | judgment |
| <a id="row-73"></a>73 | BP Concurrency (:1661-1719) | Document concurrency when read-only versus mutating is unclear, when the API synchronizes, or when an interface's implementations must be safe | keep | Say It Once step 4.2 | [doc-concurrency](#rule-doc-concurrency) | Pattern mappings | judgment |
| <a id="row-74"></a>74 | BP Cleanup (:1725-1759) | Document cleanup the caller owes, and how where unclear | keep | Say It Once step 4.2 | [doc-cleanup](#rule-doc-cleanup) | Pattern mappings | judgment |
| <a id="row-75"></a>75 | BP Errors (:1771-1785) | Document the significant sentinels and error types a function returns | keep | Failure Identity step 2: document the identity with the operation | [err-doc](#rule-err-doc) | Pattern mappings | judgment |
| <a id="row-76"></a>76 | BP Errors (:1787-1810) | Say whether a returned error type is a pointer | keep | The `errors.As` target depends on it (err-as-pointer, bjornstack.md [row 51](bjornstack.md#row-51)) | [err-doc](#rule-err-doc) | Pattern mappings | judgment |
| <a id="row-77"></a>77 | BP Errors (:1812-1814) | Return `error`, not `*PathError`, because of how nil interface values work | keep | Go-specific trap | [err-nil-interface](#rule-err-nil-interface) | Go pitfalls | guard candidate |
| <a id="row-78"></a>78 | BP Errors (:1816-1835) | Error conventions shared by most of a package go in the package documentation | keep | Failure Identity step 2, said once | [err-doc](#rule-err-doc) | Pattern mappings | judgment |
| <a id="row-79"></a>79 | BP Preview (:1846-1850) | Preview rendered documentation with pkgsite before and during review | drop | A manual review step with a running server; no outcome an agent can check | [dropped](#drop-79) | — | - |
| <a id="row-80"></a>80 | BP Godoc formatting (:1860-1868) | A blank line separates paragraphs | keep | Go doc-comment syntax | [doc-format](#rule-doc-format) | For the protocols | guard candidate |
| <a id="row-81"></a>81 | BP Godoc formatting (:1870-1888, :1904-1905) | A runnable example in a test file is often more appropriate than code in a comment | keep | Same | [doc-format](#rule-doc-format) | For the protocols | judgment |
| <a id="row-82"></a>82 | BP Godoc formatting (:1890-1918) | Two extra spaces of indent render verbatim, also for lists and tables | keep | Same | [doc-format](#rule-doc-format) | For the protocols | judgment |
| <a id="row-83"></a>83 | BP Godoc formatting (:1920-1932) | A single capitalised line without punctuation, followed by a paragraph, is a heading | keep | Same | [doc-format](#rule-doc-format) | For the protocols | judgment |
| <a id="row-84"></a>84 | BP Signal boosting (:1942-1972) | Mark a line that looks common but isn't, such as `err == nil`, with a comment | adapt | BP's `// if NO error` restates the code (Say It Once step 3.1 and its outcome "No comment repeats the implementation"); what survives is step 3.2: say why the unusual branch is taken | [doc-signal-boost](#rule-doc-signal-boost) | Pattern mappings | judgment |
| <a id="row-85"></a>85 | BP Initialization (:1982-1995) | `:=` over `var` for a non-zero initial value | keep | Go convention | [var-decl](#rule-var-decl) | For the protocols | guard candidate |
| <a id="row-86"></a>86 | BP Declaring variables with zero values (:2015-2027) | `var x T` for an empty value ready to use, not a literal of zeros | keep | Same | [var-decl](#rule-var-decl) | For the protocols | guard candidate |
| <a id="row-87"></a>87 | BP Declaring variables with zero values (:2029-2047) | Zero value for an unmarshal target; `new(T)` or `&T{}` when a pointer is needed | keep | Same | [var-decl](#rule-var-decl) | For the protocols | judgment |
| <a id="row-88"></a>88 | BP Declaring variables with zero values (:2049-2066) | A field that must not be copied stays a value; the struct goes by pointer with pointer receivers | keep | Go-specific | [var-pointer](#rule-var-pointer) | For the protocols | guard candidate |
| <a id="row-89"></a>89 | BP Declaring variables with zero values (:2068-2099) | Declare as a pointer a composite that is returned as a pointer or always addressed; protobuf messages are pointers | keep | Same; a function that returns a value, such as builders-a's `Build()` (bjornstack.md [row 29](bjornstack.md#row-29)), is not covered | [var-pointer](#rule-var-pointer) | For the protocols | guard candidate |
| <a id="row-90"></a>90 | BP Declaring variables with zero values (:2103-2104) | A map must be initialized before writing; reading a nil map is fine | keep | Go-specific trap | [map-nil-write](#rule-map-nil-write) | Go pitfalls | judgment |
| <a id="row-91"></a>91 | BP Composite literals (:2126-2130) | A composite literal when the initial members are known, not for an empty value | keep | Go convention | [var-decl](#rule-var-decl) | For the protocols | judgment |
| <a id="row-92"></a>92 | BP Composite literals (:2132-2143) | `new(T)` and `&T{}` are both fine for a pointer to a zero value | keep | Same | [var-decl](#rule-var-decl) | For the protocols | judgment |
| <a id="row-93"></a>93 | BP Size hints (:2167-2180) | Size hints only with measurement or a known final size; default to none | keep | Go convention | [size-hints](#rule-size-hints) | For the protocols | judgment |
| <a id="row-94"></a>94 | BP Channel direction (:2188-2216) | Specify channel direction where possible | keep | Go-specific; the compiler then catches misuse, but not a missing direction | [chan-direction](#rule-chan-direction) | For the protocols | guard candidate |
| <a id="row-95"></a>95 | BP Function argument lists (:2229-2237) | Don't let a signature grow long; split a highly configurable function into simpler ones | adapt | Unit Testing step 2.1: past three or four values, look for a domain concept; the number prompts the question, it is not a limit | [func-args](#rule-func-args) | Pattern mappings | judgment |
| <a id="row-96"></a>96 | BP Option structure (:2261-2274, :2333-2337) | Collect arguments in an option struct, preferred when all callers set some, many set many, or functions share the options | adapt | Owner ruling 2026-11-17 (bs-f3o.2, S-3): optional settings are variadic `WithX` options with sane defaults, never an option struct; Unit Testing's misapplication "a wrapper made for one call" already ruled out a struct that only carries one function's arguments | [func-options](#rule-func-options) | Pattern mappings | judgment |
| <a id="row-97"></a>97 | BP Option structure (:2263-2264) | Export the option struct only if an exported function uses it | adapt | No option structs (owner ruling 2026-11-17, S-3); Intentionally Public step 2 still governs the type the options change | [func-options](#rule-func-options) | Pattern mappings | guard candidate |
| <a id="row-98"></a>98 | BP Option structure (:2331) | Contexts are never in option structs | already ours | bjornstack.md [row 46](bjornstack.md#row-46) (ctx-per-call: never stored in a struct) | [ctx-per-call](bjornstack.md#rule-ctx-per-call) | Pattern mappings | guard candidate |
| <a id="row-99"></a>99 | BP Variadic options (:2343-2365, :2461-2470) | Variadic options cost much code; use them when several of these hold: most callers pass none, options are many or take arguments, can fail, or others define their own | adapt | Owner ruling 2026-11-17 (S-3): variadic options are the one form for optional settings, so BP's conditions no longer choose between forms | [func-options](#rule-func-options) | Pattern mappings | judgment |
| <a id="row-100"></a>100 | BP Variadic options (:2472-2482) | An option takes its value as a parameter (`FailFast(bool)`), not by presence | keep | Same | [func-options](#rule-func-options) | Pattern mappings | judgment |
| <a id="row-101"></a>101 | BP Variadic options (:2484-2485) | Options apply in order; the last one wins | keep | Same | [func-options](#rule-func-options) | Pattern mappings | judgment |
| <a id="row-102"></a>102 | BP Variadic options (:2487-2490) | The option functions' parameter type is unexported by default | keep | Intentionally Public step 1 | [func-options](#rule-func-options) | Pattern mappings | judgment |
| <a id="row-103"></a>103 | BP Complex command-line interfaces (:2507-2523) | With no other preference, use `subcommands` (simplest); `cobra` where its features are needed | keep | Library choice; no other source decides it | [cli-subcommands](#rule-cli-subcommands) | Tooling | judgment |
| <a id="row-104"></a>104 | BP Complex command-line interfaces (:2525-2528) | A cobra command takes `cmd.Context()`, not `context.Background()` | keep | Go-specific trap | [cobra-context](#rule-cobra-context) | Go pitfalls | guard candidate |
| <a id="row-105"></a>105 | BP Complex command-line interfaces (:2530-2536) | Subcommands need no package each; the CLI is one more client of the library | keep | Domain-First Packaging decides boundaries here as anywhere | [cli-layout](#rule-cli-layout) | Pattern mappings | judgment |
| <a id="row-106"></a>106 | BP Leave testing to the Test function (:2554-2566) | Assertion helpers are not idiomatic | drop | Owner chose testify `require` (bjornstack.md [row 39](bjornstack.md#row-39)) and an assertion function per case (bjornstack.md [row 64](bjornstack.md#row-64)) | [dropped](#drop-106) | — | - |
| <a id="row-107"></a>107 | BP Leave testing to the Test function (:2556-2561) | Setup helpers call `t.Helper` | already ours | bjornstack.md [row 91](bjornstack.md#row-91) (test-helper) | [test-helper](bjornstack.md#rule-test-helper) | Pattern mappings | guard candidate |
| <a id="row-108"></a>108 | BP Leave testing to the Test function (:2568-2570) | Fail the test inside the `Test` function itself | drop | Same as row 106 | [dropped](#drop-108) | — | - |
| <a id="row-109"></a>109 | BP Leave testing to the Test function (:2585-2593) | Shared validation is inlined in the test, or in the loop of a table test | drop | test-table (bjornstack.md [row 64](bjornstack.md#row-64)): each case carries its assertion function | [dropped](#drop-109) | — | - |
| <a id="row-110"></a>110 | BP Leave testing to the Test function (:2594-2608) | A shared validation returns an `error` or a `cmp.Option` instead of taking `t` | drop | test-require and test-protobuf (bjornstack.md rows [39](bjornstack.md#row-39), [43](bjornstack.md#row-43)) | [dropped](#drop-110) | — | - |
| <a id="row-111"></a>111 | BP Leave testing to the Test function (:2659-2662) | Code called from a test does not stop it unless there is no point going on | drop | test-require (bjornstack.md [row 39](bjornstack.md#row-39)) | [dropped](#drop-111) | — | - |
| <a id="row-112"></a>112 | BP Writing an acceptance test (:2723-2738) | Offer implementers a `footest` package with a function that exercises their implementation | already ours | bjornstack.md [rows 95-96](bjornstack.md#row-96) (compliance-suite) | [compliance-suite](bjornstack.md#rule-compliance-suite) | Pattern mappings | judgment |
| <a id="row-113"></a>113 | BP Writing an acceptance test (:2741-2786) | Choose fail-fast or aggregated failures; aggregate in a custom error type | drop | compliance-suite reports each scenario through its own `t.Run`; the suite returns no error to design | [dropped](#drop-113) | — | - |
| <a id="row-114"></a>114 | BP Writing an acceptance test (:2788-2811) | The acceptance test calls `t.Fatal` only for setup; don't use it to bypass the assertion guidance | drop | Same as rows 106 and 113 | [dropped](#drop-114) | — | - |
| <a id="row-115"></a>115 | BP Use real transports (:2842-2861) | Test with the real client and transport connected to a test server, not a hand-written client | adapt | Contract Testing step 2.2 for the unit that calls out; coordinators above it still get doubles (Unit Testing step 3.3) | [test-real-transport](#rule-test-real-transport) | Pattern mappings | judgment |
| <a id="row-116"></a>116 | BP Use real transports (:2863-2864) | Prefer a testing library from the service's authors | keep | Same rule | [test-real-transport](#rule-test-real-transport) | Pattern mappings | judgment |
| <a id="row-117"></a>117 | BP t.Error vs. t.Fatal (:2870-2871) | Tests generally don't stop at the first problem | drop | test-require (bjornstack.md [row 39](bjornstack.md#row-39)) | [dropped](#drop-117) | — | - |
| <a id="row-118"></a>118 | BP t.Error vs. t.Fatal (:2873-2877) | `t.Fatal` when setup fails | already ours | bjornstack.md [row 39](bjornstack.md#row-39) (test-require: `require` stops the test) | [test-require](bjornstack.md#rule-test-require) | Tooling | guard candidate |
| <a id="row-119"></a>119 | BP t.Error vs. t.Fatal (:2879-2885) | One table entry failing: `t.Error` and `continue` without subtests, `t.Fatal` inside `t.Run` | already ours | bjornstack.md [row 83](bjornstack.md#row-83) (test-table runs every case in `t.Run`, where `require` ends only that case) | [test-table](bjornstack.md#rule-test-table) | Pattern mappings | judgment |
| <a id="row-120"></a>120 | BP Error handling in test helpers (:2902-2938) | A setup helper fails the test itself rather than returning an error | keep | Fits test-require | [test-setup-helper](#rule-test-setup-helper) | Pattern mappings | judgment |
| <a id="row-121"></a>121 | BP Error handling in test helpers (:2943-2946, :3024-3025) | A helper's failure message says what failed and why | keep | Same rule | [test-setup-helper](#rule-test-setup-helper) | Pattern mappings | judgment |
| <a id="row-122"></a>122 | BP Error handling in test helpers (:2948-2952) | Register cleanup with `t.Cleanup` | keep | Same rule; compliance-suite relies on it | [test-setup-helper](#rule-test-setup-helper) | Pattern mappings | judgment |
| <a id="row-123"></a>123 | BP Error handling in test helpers (:2954-3022) | `t.Helper` reports the failure at the caller's line | already ours | bjornstack.md [row 91](bjornstack.md#row-91) (test-helper) | [test-helper](bjornstack.md#rule-test-helper) | Pattern mappings | guard candidate |
| <a id="row-124"></a>124 | BP Error handling in test helpers (:3027-3029) | A helper that cannot fail the test takes no `t` | keep | Same as test-helper's scope; builders-a's `Build()` already takes none | [test-setup-helper](#rule-test-setup-helper) | Pattern mappings | guard candidate |
| <a id="row-125"></a>125 | BP Don't call t.Fatal from separate goroutines (:3037-3088) | `t.Fatal` and `t.FailNow` only from the test's goroutine | adapt | `require.*` fails through `t.FailNow`, so it falls under the same rule; the goroutine sends its result to the test's goroutine, which asserts with `require`, so test-require needs no `assert` exception | [test-fatal-goroutine](#rule-test-fatal-goroutine) | Go pitfalls | guard candidate |
| <a id="row-126"></a>126 | BP Use field names in struct literals (:3096-3127) | Name the fields of table-case literals, and leave out zero-valued ones | adapt | Parameterized Test Structure step 2 and test-table (bjornstack.md [row 65](bjornstack.md#row-65)): every case sets every field | [test-case-fields](#rule-test-case-fields) | Pattern mappings | guard candidate |
| <a id="row-127"></a>127 | BP Keep setup code scoped to specific tests (:3133-3221) | Each test calls the setup it needs; no `init` or package-level setup | keep | Fits Isolated Test Execution step 2 (per-test factories) | [test-setup-scope](#rule-test-setup-scope) | Pattern mappings | guard candidate |
| <a id="row-128"></a>128 | BP When to use a custom TestMain entrypoint (:3227-3241) | A custom `TestMain` only when every test needs setup with teardown; not the first choice | keep | Isolated Test Execution step 2 bans suite-level setup that produces shared mutable state, so `TestMain` may start shared infrastructure only; each test still creates its own scoped data (steps 1-2) | [test-setup-scope](#rule-test-setup-scope) | Pattern mappings | judgment |
| <a id="row-129"></a>129 | BP When to use a custom TestMain entrypoint (:3288-3293) | Each test resets the global state it modified, such as an external database | adapt | On shared infrastructure, Isolated Test Execution steps 1 and 4 scope the data instead of resetting it; BP's "global state" also covers in-process globals (package variables, environment), which cannot be scoped, so a test restores them | [test-global-state](#rule-test-global-state) | Pattern mappings | judgment |
| <a id="row-130"></a>130 | BP Amortizing common test setup (:3299-3353) | `sync.Once` for setup that is expensive, used by some tests only, and needs no teardown | keep | Read-only shared data is allowed by Isolated Test Execution step 2 | [test-setup-scope](#rule-test-setup-scope) | Pattern mappings | judgment |
| <a id="row-131"></a>131 | BP Amortizing common test setup (:3355-3360) | `sync.Once` does not suit setup that takes a ctx | keep | Same rule | [test-setup-scope](#rule-test-setup-scope) | Pattern mappings | judgment |
| <a id="row-132"></a>132 | BP Prefer "+" for simple cases (:3379-3388) | `+` for a few strings | keep | Go convention | [string-build](#rule-string-build) | For the protocols | judgment |
| <a id="row-133"></a>133 | BP Prefer fmt.Sprintf when formatting (:3392-3407) | `fmt.Sprintf` for formatted strings | keep | Same | [string-build](#rule-string-build) | For the protocols | judgment |
| <a id="row-134"></a>134 | BP Prefer fmt.Sprintf when formatting (:3409-3411) | `fmt.Fprintf` to a writer, not `Sprintf` then write | keep | Same | [string-build](#rule-string-build) | For the protocols | guard candidate |
| <a id="row-135"></a>135 | BP Prefer fmt.Sprintf when formatting (:3413-3414) | `text/template` or `safehtml/template` for more complex formatting | keep | Same | [string-build](#rule-string-build) | For the protocols | judgment |
| <a id="row-136"></a>136 | BP Prefer strings.Builder (:3421-3438) | `strings.Builder` to build a string piecemeal | keep | Same | [string-build](#rule-string-build) | For the protocols | guard candidate |
| <a id="row-137"></a>137 | BP Constant strings (:3444-3462) | Backticks for constant multi-line strings | keep | Same | [string-build](#rule-string-build) | For the protocols | guard candidate |
| <a id="row-138"></a>138 | BP Global state (:3474-3486) | Libraries don't make clients rely on global state or export package-level variables that steer behaviour; offer instances | adapt | Unit Testing step 3.2 and Boundary Communication step 4 agree; metrics stay allowed as globals (coord-globals, bjornstack.md [row 107](bjornstack.md#row-107)) | [global-state](#rule-global-state) | Pattern mappings | judgment |
| <a id="row-139"></a>139 | BP Global state (:3519-3521) | Pass dependencies as parameters to constructors, functions, methods or fields | already ours | bjornstack.md [row 69](bjornstack.md#row-69) (coord-inject) | [coord-inject](bjornstack.md#rule-coord-inject) | Pattern mappings | judgment |
| <a id="row-140"></a>140 | BP Major forms of package state APIs (:3652-3717) | Global state's forms: top-level variables, a global service locator, callback registries, singleton clients; legacy use is no precedent | keep | Lists what Unit Testing step 3.2 calls reading global state | [global-state](#rule-global-state) | Pattern mappings | guard candidate |
| <a id="row-141"></a>141 | BP Litmus tests (:3721-3733) | When global state is unsafe | keep | Same rule | [global-state](#rule-global-state) | Pattern mappings | judgment |
| <a id="row-142"></a>142 | BP Litmus tests (:3735-3776) | Global state is safe only when none of the unsafe conditions holds and it is logically constant, stateless to observers, not reaching outside the process, or not expected to be predictable | keep | The rule's exceptions, kept with it | [global-state](#rule-global-state) | Pattern mappings | judgment |
| <a id="row-143"></a>143 | BP Providing a default instance (:3782-3829) | A package-level convenience API only with isolated instances, as a thin proxy, used by binaries only, documented and resettable | keep | Go-specific pattern with its conditions | [global-default](#rule-global-default) | Pattern mappings | judgment |
| <a id="row-144"></a>144 | BP Avoid unnecessary interfaces (:3849-3852) | Don't declare an interface because something is a "service"; start from the concrete implementation | adapt | A coordinator declares each collaborator's interface for its doubles (Unit Testing steps 3.2-3.3), before the implementation exists | [iface-need](#rule-iface-need) | Pattern mappings | judgment |
| <a id="row-145"></a>145 | BP Avoid unnecessary interfaces (:3854-3857) | Reuse existing interfaces such as generated RPC clients; don't wrap them for testing | adapt | The edge unit uses the generated client directly and is tested over a real transport (test-real-transport); code above it depends on our own interface in domain types (Domain-First Packaging step 6, Failure Identity step 3), which its coordinator tests double. No interface over the generated client only to test the edge unit. Same id and reading as google-guide-decisions.md iface-need | [iface-need](#rule-iface-need) | Pattern mappings | judgment |
| <a id="row-146"></a>146 | BP Avoid unnecessary interfaces (:3859-3870) | Don't export a test double beside the real implementation; export an interface for substitution only with a material need | keep | Public API Surface Testing's misapplication "exporting internals solely for tests" | [iface-test-doubles](#rule-iface-test-doubles) | Pattern mappings | judgment |
| <a id="row-147"></a>147 | BP Avoid unnecessary interfaces (:3872-3875) | Where the real implementation is impractical, put doubles in a dedicated package (`spannertest`) | adapt | Test Data Builders step 2: doubles stay in the test file; a stateful one moves under `test/a` once a second test file in its domain, or a test outside the domain, needs it | [iface-test-doubles](#rule-iface-test-doubles) | Pattern mappings | judgment |
| <a id="row-148"></a>148 | BP Avoid unnecessary interfaces (:3879-3883) | An interface for two or more concrete types handled by the same logic | keep | Go convention | [iface-need](#rule-iface-need) | Pattern mappings | judgment |
| <a id="row-149"></a>149 | BP Avoid unnecessary interfaces (:3885-3891) | An interface to break an import cycle, often a sign of badly split packages | keep | Domain-First Packaging step 5 (a shared interface between siblings) | [iface-need](#rule-iface-need) | Pattern mappings | judgment |
| <a id="row-150"></a>150 | BP Avoid unnecessary interfaces (:3893-3895) | An interface for the one or two methods a function needs of a large type | keep | Go convention | [iface-need](#rule-iface-need) | Pattern mappings | judgment |
| <a id="row-151"></a>151 | BP Interface ownership and visibility (:3901-3904) | Don't export an interface used only inside its package | keep | Intentionally Public steps 1-2 | [iface-owner](#rule-iface-owner) | Pattern mappings | guard candidate |
| <a id="row-152"></a>152 | BP Interface ownership and visibility (:3906-3910) | The consumer defines the interface, with only the methods it uses | keep | Test Data Builders step 2: each consumer depends only on the operations it calls | [iface-owner](#rule-iface-owner) | Pattern mappings | judgment |
| <a id="row-153"></a>153 | BP Interface ownership and visibility (:3912-3944) | The producer exports it when the interface is the product, to prevent many identical copies, or to break a cycle | keep | The exceptions to row 152, kept with it | [iface-owner](#rule-iface-owner) | Pattern mappings | judgment |
| <a id="row-154"></a>154 | BP Designing effective interfaces (:3950-3952) | Keep interfaces small | keep | Go convention | [iface-design](#rule-iface-design) | Pattern mappings | judgment |
| <a id="row-155"></a>155 | BP Designing effective interfaces (:3954-3969) | Document interfaces in proportion to their load, unexported ones included | keep | Same | [iface-design](#rule-iface-design) | Pattern mappings | judgment |
| <a id="row-156"></a>156 | BP Designing effective interfaces (:3971-3974) | Accept interfaces, return concrete types | keep | Same | [iface-design](#rule-iface-design) | Pattern mappings | judgment |
| <a id="row-157"></a>157 | BP Designing effective interfaces (:3979-4037) | Return an interface to hide exported methods that would break the type's integrity, but not by rote | adapt | Intentionally Public step 3 first asks whether the method should be exported at all; step 4 reshapes the boundary or moves it into an internal package | [iface-design](#rule-iface-design) | Pattern mappings | judgment |
| <a id="row-158"></a>158 | BP Designing effective interfaces (:4039-4079) | Return an interface when the function picks one of several types at run time; guidelines, not rules | keep | Exception to row 156 | [iface-design](#rule-iface-design) | Pattern mappings | judgment |
| <a id="row-159"></a>159 | BP Designing effective interfaces (:4081-4157) | Return an interface when a concrete type would create an import cycle; prefer consolidating packages | keep | Exception to row 156; Domain-First Packaging's over-packaging misapplication | [iface-design](#rule-iface-design) | Pattern mappings | judgment |

### Headings with no rule

- Function and method names, Test double and helper packages, Error
  handling, Documentation, Conventions, Variable declarations, Tests,
  Designing extensible validation APIs, String concatenation,
  Interfaces: introductions to the rules below them.
- Import ordering (:759-761): a pointer to the core guide's
  "Import grouping", which bs-f3o.2.3 reviews.
- Package size (:661-684): reference examples of package sizes.
- Placement of %w (:1121-1124): says errors can also be wrapped by a
  type with `Unwrap() error`; describes, and err-unwrap (bjornstack.md
  [row 49](bjornstack.md#row-49)) governs identity types.
- Parameters and configuration (:1538-1541): consider the audience.
- Leave testing to the Test function (:2634-2652): the fuzz test is an
  example only.
- Acceptance testing (:2680-2710): explains the idea, with `io/fs` as
  an example.
- When to use a custom TestMain entrypoint (:3288-3289): "Ideally a
  test case is hermetic", the aim the rows around it serve.

## Rules

Each rule below is the wording go.md takes. Every Source line cites
`github.com/google/styleguide` commit `a9c5f82b1981`,
`go/best-practices.md`, read 2026-11-16; strategy citations are at
bjornstack `67b1213`.

### Tooling

<a id="rule-err-group"></a>**err-group.** When related operations run as a group and only the
first failure matters, `golang.org/x/sync/errgroup` may run them and
return that error. This is not for checking input, where every
violation is reported (scrub-validate).
Source: BP "Error handling" (:790-796), `a9c5f82b1981`, read
2026-11-16.
↩ row [32](#row-32)

<a id="rule-cli-subcommands"></a>**cli-subcommands.** With no other preference, a command-line tool
with subcommands uses `github.com/google/subcommands`, the simplest;
`github.com/spf13/cobra` where its features are needed.
Source: BP "Complex command-line interfaces" (:2507-2523),
`a9c5f82b1981`, read 2026-11-16.
↩ row [103](#row-103)

### Pattern mappings

<a id="rule-test-helper-pkg"></a>**test-helper-pkg.** Package `footest` holds `foo`'s compliance suite
(compliance-suite) and any helpers for `foo` published for tests
outside this module. Everything this module's own tests share,
builders and doubles alike, lives under `test/a` (builders-a), and a
double moves there on Test Data Builders step 2's trigger: a second
test file in its domain, or a test outside that domain, needs it.
Source: BP "Creating test helper packages" (:228-242),
`a9c5f82b1981`, read 2026-11-16.
Differs: BP puts a package's test doubles in `footest`; Test Data
Builders step 2 keeps a double in its test file and moves only a
stateful one, under the single entry point.
↩ row [11](#row-11)

<a id="rule-double-names"></a>**double-names.** Name a double for what it does. A test file with
one double of one type may call it `stub`. Several doubles of one type
are named for the behaviour they simulate: `alwaysCharges`,
`alwaysDeclines`. Doubles of several types in one file add the type:
`stubService`, `stubStoredValue`. A variable holding a double says so,
`spyCC`, where production values of the same type sit beside it.
Source: BP "Test double and helper packages" (:246-454),
`a9c5f82b1981`, read 2026-11-16.
Differs: BP names exported double types in a `footest` package; ours
are values in the test file, often functions (Test Data Builders step
2, coord-doubles). BP's example test is in `package payment`; test-pkg
puts it in `payment_test`.
↩ rows [13](#row-13), [14](#row-14), [15](#row-15), [16](#row-16)

<a id="rule-pkg-size"></a>**pkg-size.** Put types in one package when clients need values of
both to work together, or when their implementations are tightly
coupled: if a user must import both packages to use either in any
meaningful way, they usually belong together. Give something
conceptually distinct its own small package, whose name and exported
type read as one (`bytes.Buffer`). Domain-First Packaging step 1 finds
the packages; splitting further is its over-packaging misapplication.
Source: BP "Package size" (:618-638), `a9c5f82b1981`, read 2026-11-16.
↩ rows [24](#row-24), [25](#row-25)

<a id="rule-err-identity"></a>**err-identity.** When a caller handles a failure differently from
others (Failure Identity step 1), give it an identity Go can compare:
a package-level sentinel, `var ErrDuplicate = errors.New("duplicate")`,
when it carries no values; an error type whose fields hold the values
the caller reads, as `os.PathError` holds `Path`, when it does
(Failure Identity step 2).
Source: BP "Error structure" (:812-897), `a9c5f82b1981`, read
2026-11-16.
Differs: BP applies the advice to tests that tell error conditions
apart as well; under Failure Identity step 1 a test alone is no reason
for an identity.
↩ rows [33](#row-33), [36](#row-36)

<a id="rule-err-grpc-status"></a>**err-grpc-status.** A handler that answers with a gRPC status uses
the canonical codes of `google.golang.org/grpc/codes`. Package
`status` is one way to carry them, not a requirement. The handler
translates our failures into those codes for the client rather than
wrapping them with `%w` (Failure Identity step 3).
Source: BP "Error structure" (:899-904) and "Adding information to
errors" (:1095-1100), `a9c5f82b1981`, read 2026-11-16.
↩ rows [37](#row-37), [47](#row-47)

<a id="rule-err-annotate"></a>**err-annotate.** Where an error is wrapped (err-wrap-where), the
wrap names the action that failed and the values the underlying error
does not already carry: `load launch code settings: %w`, since
`os.Open`'s error already names the file. It uses no stop words such
as "failed to", "couldn't" or "unable to". A wrap that only says
something failed adds nothing: name the action instead. When a
function does several things, each wrap says which one failed (Failure
Identity step 5).
Source: BP "Adding information to errors" (:917-1002), `a9c5f82b1981`,
read 2026-11-16.
Differs: BP's examples wrap with `%v`; the verb follows err-wrap-verb.
BP returns the error unannotated where the wrap would add nothing;
err-wrap-where always wraps another unit's public function's error.
↩ rows [38](#row-38), [39](#row-39), [40](#row-40), [41](#row-41)

<a id="rule-err-doc"></a>**err-doc.** Document with each operation the error identities a
caller may branch on (Failure Identity step 2): the sentinel, or the
type and whether it comes as a pointer (`*PathError`), which decides
the `errors.As` target (err-as-pointer). When most of a package's
errors follow one convention, say it once in the package
documentation.
Source: BP "Errors" (:1771-1835), `a9c5f82b1981`, read 2026-11-16.
↩ rows [75](#row-75), [76](#row-76), [78](#row-78)

<a id="rule-doc-params"></a>**doc-params.** Not every parameter, struct field or option needs
documenting. Document the error-prone and non-obvious ones and say why
they matter; "format is the format" adds nothing. Caller documentation
that already restates the obvious stays (Say It Once step 1).
Source: BP "Parameters and configuration" (:1498-1536),
`a9c5f82b1981`, read 2026-11-16; owner ruling, bs-f3o.2 comment
"Owner rulings from go-decisions (2026-11-17)", S-12.
Differs: BP's bad example reads as text to remove; Say It Once step 1
leaves a public name's caller documentation alone even when it repeats
the name.
↩ row [68](#row-68)

<a id="rule-doc-ctx"></a>**doc-ctx.** Cancelling a `ctx` argument is understood to interrupt
the call, which then returns `ctx.Err()`; don't write that down.
Document ctx only where it behaves otherwise: the call returns another
error, or nil, on cancellation; something else, such as a `Stop`
method, also interrupts it or governs its lifetime; or it expects
something of ctx's lifetime, lineage or values. Avoid designing APIs
with such expectations (ctx-scope limits what ctx carries). Existing
caller documentation follows doc-params.
Source: BP "Contexts" (:1556-1630), `a9c5f82b1981`, read 2026-11-16.
↩ rows [69](#row-69), [70](#row-70), [71](#row-71)

<a id="rule-doc-concurrency"></a>**doc-concurrency.** Read-only operations are assumed safe for
concurrent use and need no remark. A type that is not safe for
concurrent use says so once, on the type, with what breaks: "takes no
locks; two callers at once corrupt the text" (Say It Once step 4.2),
not on each method. Document concurrency also where an operation that
looks read-only mutates, such as a lookup that reorders an LRU cache;
where the API synchronizes for the caller, on the type when that
covers the whole type; and where implementations of an interface the
API consumes must be safe for concurrent use. Existing caller
documentation follows doc-params.
Source: BP "Concurrency" (:1636-1719), `a9c5f82b1981`, read
2026-11-16.
↩ rows [72](#row-72), [73](#row-73)

<a id="rule-doc-cleanup"></a>**doc-cleanup.** Document every cleanup the caller owes, such as
calling `Stop` or closing `resp.Body`, and show how where it is not
obvious (Say It Once step 4.2).
Source: BP "Cleanup" (:1725-1759), `a9c5f82b1981`, read 2026-11-16.
↩ row [74](#row-74)

<a id="rule-doc-signal-boost"></a>**doc-signal-boost.** When a line looks like a common one but isn't,
such as `if err == nil`, comment why the unusual branch is taken (Say
It Once step 3.2), not what the line does.
Source: BP "Signal boosting" (:1942-1972), `a9c5f82b1981`, read
2026-11-16.
Differs: BP's comment, `// if NO error`, restates the code; Say It
Once step 3.1 leaves that out.
↩ row [84](#row-84)

<a id="rule-func-args"></a>**func-args.** When a signature grows long, look first for a domain
concept among its values (Unit Testing step 2.1: past three or four,
the number prompts the question; it is not a limit). A highly
configurable function may become several simpler ones that share an
unexported implementation. Exported functions are held to this more
strictly than unexported ones.
Source: BP "Function argument lists" (:2229-2247), `a9c5f82b1981`,
read 2026-11-16.
↩ row [95](#row-95)

<a id="rule-func-options"></a>**func-options.** Optional settings are variadic options,
`New(addr, WithTimeout(5*time.Second))`, with sane defaults, so a
caller passes only what differs. There are no option structs: a struct
that only carries one function's arguments is the one-call wrapper
Unit Testing names as a misapplication (`testing__unit.md`, "A wrapper
made for one call"), and a value that names a domain concept is passed
as that type, not as an option. ctx is never an option (ctx-per-call).
An option takes its value as
a parameter, `FailFast(enable bool)`, not `EnableFailFast()`. Options
apply in order, the last winning when one is given twice. The type the
option functions change is unexported unless other packages are meant
to define options.
Source: BP "Option structure" and "Variadic options" (:2259-2490),
`a9c5f82b1981`, read 2026-11-16; owner ruling, bs-f3o.2 comment
"Owner rulings, round 2 (2026-11-17)", S-3.
Differs: BP prefers an option struct in several cases and keeps
variadic options for when their cost pays; we use variadic options for
all optional settings.
↩ rows [96](#row-96), [97](#row-97), [99](#row-99), [100](#row-100), [101](#row-101), [102](#row-102)

<a id="rule-cli-layout"></a>**cli-layout.** A subcommand needs no package of its own; package
boundaries follow Domain-First Packaging as anywhere else. Code that
is both a library and a binary keeps the command-line part as one
more client of the library.
Source: BP "Complex command-line interfaces" (:2530-2536),
`a9c5f82b1981`, read 2026-11-16.
↩ row [105](#row-105)

<a id="rule-test-real-transport"></a>**test-real-transport.** Test the unit that calls another service
through the production client and the real transport, connected to a
test server such as `httptest.Server` or a gRPC server double, never a
hand-written imitation of the client (Contract Testing step 2.2).
Prefer a test server the service's authors provide. Coordinators above
that unit still receive doubles of it (Unit Testing step 3.3).
Source: BP "Use real transports" (:2842-2864), `a9c5f82b1981`, read
2026-11-16.
Differs: BP states it for component integration tests in general;
coordinator tests replace every collaborator with a double.
↩ rows [115](#row-115), [116](#row-116)

<a id="rule-test-setup-helper"></a>**test-setup-helper.** A setup helper fails the test itself, with
`require` or `t.Fatalf`, instead of returning an error. Its message
says which step failed and why: `setup: write asset pak0: ...`. It
registers teardown with `t.Cleanup`. A helper nothing in which can
fail the test takes no `*testing.T`.
Source: BP "Error handling in test helpers" (:2902-3029),
`a9c5f82b1981`, read 2026-11-16.
↩ rows [120](#row-120), [121](#row-121), [122](#row-122), [124](#row-124)

<a id="rule-test-case-fields"></a>**test-case-fields.** Table-case literals name their fields. Every
case still sets every field, zero values included (test-table).
Source: BP "Use field names in struct literals" (:3096-3127),
`a9c5f82b1981`, read 2026-11-16.
Differs: BP names fields mainly for long tables or adjacent fields of
one type, and so that zero-valued fields can be left out; Parameterized
Test Structure step 2 sets every field in every case.
↩ row [126](#row-126)

<a id="rule-test-setup-scope"></a>**test-setup-scope.** A test calls the setup it needs, so
`go test -run X` pays only for X; test files have no `init` and no
package-level setup outside `TestMain`. A custom `TestMain`
is for setup that every test in the package needs and that needs
teardown, and only once a setup helper or `sync.Once` will not do. It
may start shared infrastructure only, such as a database server; each
test still creates its own scoped data (Isolated Test Execution steps
1-2). `sync.Once` may share setup that is expensive, used by only some
tests, needs no teardown, and that tests only read (Isolated Test
Execution step 2). It does not suit setup that takes a ctx: a second
caller waits for the first without honouring its own cancellation.
Source: BP "Keep setup code scoped to specific tests" (:3133-3360),
`a9c5f82b1981`, read 2026-11-16.
↩ rows [127](#row-127), [128](#row-128), [130](#row-130), [131](#row-131)

<a id="rule-test-global-state"></a>**test-global-state.** A test does not reset data it wrote to shared
infrastructure such as a database: it scopes that data under its own
identity instead (Isolated Test Execution steps 1 and 4). A test that
changes in-process global state, such as a package variable or an
environment variable, restores it with `t.Cleanup` or `t.Setenv` and
does not call `t.Parallel`.
Source: BP "When to use a custom TestMain entrypoint" (:3291-3293),
`a9c5f82b1981`, read 2026-11-16.
Differs: BP has each test reset what it changed in an external
database; Isolated Test Execution step 4 does not clear between tests.
↩ row [129](#row-129)

<a id="rule-global-state"></a>**global-state.** A package that keeps state lets its clients
create instances and pass them on. It does not make clients rely on
package-level state, nor export package-level variables that change
behaviour for every client. Global state takes these forms, exported
or not: top-level variables, a service locator held in a global, a
registry of callbacks, and a singleton client for a backend; standard
library and legacy APIs that use them are no precedent. It is unsafe
when otherwise independent code or tests interact through it, when
users would swap it for a test double, or when it imposes an order,
such as calls only during `init`. It is safe only when none of those
holds and one of these does: it is logically constant; the package's
observable behaviour is stateless (a private cache); it does not reach
outside the process (sidecars, shared files); or nobody expects
predictable behaviour (`math/rand`). Metrics may be package-level globals (coord-globals).
Source: BP "Global state", "Major forms of package state APIs",
"Litmus tests" (:3474-3776), `a9c5f82b1981`, read 2026-11-16.
Differs: BP makes no exception for metrics; the owner allowed them as
globals (bjornstack.md row 107).
↩ rows [138](#row-138), [140](#row-140), [141](#row-141), [142](#row-142)

<a id="rule-global-default"></a>**global-default.** A package-level convenience API over global
state is acceptable only when the package also offers isolated
instances, the convenience API is a thin proxy to one of them
(`http.Handle` over `http.DefaultServeMux`), only binaries use it and
no library relies on it, and it documents and enforces its invariants
and offers a way to reset it to a known default.
Source: BP "Providing a default instance" (:3782-3829),
`a9c5f82b1981`, read 2026-11-16.
↩ row [143](#row-143)

<a id="rule-iface-need"></a>**iface-need.** Don't declare an interface because something is
called a service or a repository. Declare one where it has a use: a
consumer handles two or more concrete types with the same logic; a
coordinator receives a collaborator its tests replace with a double
(Unit Testing steps 3.2-3.3), as an interface or a function type
(coord-doubles); a function needs one or two methods of a large type;
or two packages would otherwise import each other, which more often
means they are split wrongly (pkg-size; Domain-First Packaging step
5). A generated RPC client is used directly by the edge unit that
calls the service, which is tested over a real transport
(test-real-transport); no interface goes over the client only to test
that unit. Code above the edge unit depends on our own interface in
domain types (Domain-First Packaging step 6, Failure Identity step 3),
which its coordinator tests replace with a double.
Source: BP "Avoid unnecessary interfaces" (:3846-3895),
`a9c5f82b1981`, read 2026-11-16.
Differs: BP starts from the concrete implementation; outside-in, a
coordinator's test declares the collaborator's interface before any
implementation exists.
Same id as google-guide-decisions.md iface-need, which states the
coordinator case; bs-f3o.2.9 merges the two.
↩ rows [144](#row-144), [145](#row-145), [148](#row-148), [149](#row-149), [150](#row-150)

<a id="rule-iface-owner"></a>**iface-owner.** An interface belongs to the package that uses it and
lists only the methods that package calls (Test Data Builders step 2).
It stays unexported unless something outside the package needs it
(Intentionally Public steps 1-2). The producer defines and exports it
instead when the interface is the product, a protocol many
implementations follow such as `io.Writer` or a generated service
interface, possibly in a package of its own with no implementation;
when many packages would otherwise each keep an identical copy; or to
break an import cycle.
Source: BP "Interface ownership and visibility" (:3899-3944),
`a9c5f82b1981`, read 2026-11-16.
↩ rows [151](#row-151), [152](#row-152), [153](#row-153)

<a id="rule-iface-design"></a>**iface-design.** Keep interfaces small. Document an interface in
proportion to what a user must understand: its contract, edge cases
and expected errors on the type when it has one method, each method
when it has several; document unexported ones too. Accept interfaces
and return concrete types. Return an interface instead when the
function picks one of several concrete types at run time (factories,
strategies, chaining), when a concrete return type would create an
import cycle, which usually means packages should merge (pkg-size),
and for errors (err-nil-interface). Don't force an interface where one
concrete type handles the variation, as `database/sql`'s `DB` does.
Before returning an interface to hide a method that would break the
type's integrity, ask whether that method should be exported at all
(Intentionally Public steps 3-4).
Source: BP "Designing effective interfaces" (:3948-4157),
`a9c5f82b1981`, read 2026-11-16.
Differs: BP exports the dangerous method (`Refill`) and hides it
behind a returned interface; Intentionally Public steps 3-4 first
reshape the boundary or moves the method into an internal package.
↩ rows [154](#row-154), [155](#row-155), [156](#row-156), [157](#row-157), [158](#row-158), [159](#row-159)

<a id="rule-iface-test-doubles"></a>**iface-test-doubles.** A package does not export a test double
beside its real implementation, nor an interface whose only purpose is
substitution in tests, unless there is a material need for it. Our own
tests keep their doubles in the test file and move a stateful one
under `test/a` once a second test file in its domain, or a test
outside that domain, needs it, and only after it passes the compliance
suite (Test Data Builders step 2). `footest` holds only the compliance
suite and helpers published outside this module (test-helper-pkg).
Source: BP "Avoid unnecessary interfaces" (:3859-3875),
`a9c5f82b1981`, read 2026-11-16.
Differs: BP puts doubles for an impractical real implementation in a
dedicated package such as `spannertest`.
↩ rows [146](#row-146), [147](#row-147)

### Go pitfalls

<a id="rule-shadow-block"></a>**shadow-block.** When `:=` reuses a name already declared in the
same scope, it assigns to it, which is fine once the old value is no
longer needed. Inside a new block, `:=` declares a new variable that
hides the outer one, and code after the block sees the outer value
again: `ctx, cancel := context.WithTimeout(ctx, d)` inside an `if`
leaves the outer `ctx` uncapped. Declare `var cancel func()` and
assign with `=`. Shadow on purpose only where a new name would not
read better.
Source: BP "Shadowing" (:458-546), `a9c5f82b1981`, read 2026-11-16.
↩ rows [17](#row-17), [18](#row-18), [19](#row-19)

<a id="rule-err-is-sentinel"></a>**err-is-sentinel.** Check for a sentinel with `errors.Is(err,
ErrX)`, never `err == ErrX`: a callee may start wrapping at any time
(err-wrap-where, with `%w` per err-wrap-verb), and `==` then stops
matching without any error.
Source: BP "Error structure" (:845-878), `a9c5f82b1981`, read
2026-11-16.
Differs: BP allows `==` where the function returns sentinels
unwrapped.
↩ row [34](#row-34)

<a id="rule-err-unwrap-multi"></a>**err-unwrap-multi.** `errors.Unwrap` returns nil for an error that
wraps several, from `errors.Join` or a `fmt.Errorf` with more than one
`%w`. Inspect errors with `errors.Is` and `errors.As`, which see every
member (and see err-join-match).
Source: BP "Adding information to errors" (:1024-1025),
`a9c5f82b1981`, read 2026-11-16.
↩ row [44](#row-44)

<a id="rule-log-lazy"></a>**log-lazy.** A log call's arguments are evaluated even when its
level is off. Guard an expensive one with a level check,
`if logger.Enabled(ctx, slog.LevelDebug)`, instead of passing it
straight in.
Source: BP "Custom verbosity levels" (:1310-1332), `a9c5f82b1981`,
read 2026-11-16.
Differs: BP's form is glog's `if log.V(2)`; our logger is slog from
`logctx.From(ctx)` (ctx-scope).
↩ row [57](#row-57)

<a id="rule-err-nil-interface"></a>**err-nil-interface.** A function that returns an error type
declares its result as `error`, not `*PathError`: a nil `*PathError`
stored in an `error` is not nil, so the caller's `err != nil` is true.
Source: BP "Errors" (:1812-1814), `a9c5f82b1981`, read 2026-11-16.
↩ row [77](#row-77)

<a id="rule-map-nil-write"></a>**map-nil-write.** Writing to a nil map panics; reading from one is
fine. Initialise a map with `make` or a literal before writing to it.
Source: BP "Declaring variables with zero values" (:2103-2104),
`a9c5f82b1981`, read 2026-11-16.
↩ row [90](#row-90)

<a id="rule-cobra-context"></a>**cobra-context.** A cobra command takes its context from
`cmd.Context()`, never a fresh `context.Background()`.
Source: BP "Complex command-line interfaces" (:2525-2528),
`a9c5f82b1981`, read 2026-11-16.
↩ row [104](#row-104)

<a id="rule-test-fatal-goroutine"></a>**test-fatal-goroutine.** `t.Fatal`, `t.FailNow` and `require.*`,
which fails through `t.FailNow`, must not run in a goroutine the test
started. That goroutine sends its result on a channel, and the test's
own goroutine receives it and asserts with `require` (test-require).
`t.Parallel` does not change this; a setup helper calls them from the
test's own goroutine.
Source: BP "Don't call t.Fatal from separate goroutines" (:3037-3088),
`a9c5f82b1981`, read 2026-11-16.
Differs: BP names only the `testing` methods; `require` fails the same
way.
↩ row [125](#row-125)

### For the protocols

<a id="rule-name-call-site"></a>**name-call-site.** A function or method name leaves out what the
call site already shows: the types of its inputs and outputs when no
other function's name collides, the receiver's type and name, whether
a value is a pointer, the names of its parameters, and the names and
types of its results. `c.WriteTo(w)`, not `c.WriteConfigTo(w)`;
`Override(dest, source)`, not `OverrideFirstWithSecond`. Add such
words back where they tell apart functions that would otherwise share
a name: `WriteTextTo` and `WriteBinaryTo`. The package name is
pkg-naming's.
Source: BP "Avoid repetition" (:43-124), `a9c5f82b1981`, read
2026-11-16.
↩ rows [1](#row-1), [3](#row-3), [4](#row-4), [5](#row-5), [6](#row-6)

<a id="rule-name-shape"></a>**name-shape.** A function that returns something has a noun-like
name and no `Get` prefix: `c.JobName(key)`. A function that does
something has a verb-like name: `c.WriteDetail(w)`. Functions that
differ only in the type they handle end in that type's name,
`ParseInt` and `ParseInt64`; a clear primary version may leave its
type out, `Marshal` beside `MarshalText`.
Source: BP "Naming conventions" (:128-178), `a9c5f82b1981`, read
2026-11-16.
↩ rows [7](#row-7), [8](#row-8), [9](#row-9), [10](#row-10)

<a id="rule-shadow-pkg-name"></a>**shadow-pkg-name.** Don't name a variable after a standard package,
such as `url`, outside a scope of a few lines: it hides the package for
the rest of the scope. Name a package so its clients need not rename
it on import and it does not take a name they would want for a
variable.
Source: BP "Shadowing" (:548-562), `a9c5f82b1981`, read 2026-11-16.
↩ rows [20](#row-20), [21](#row-21)

<a id="rule-file-size"></a>**file-size.** There is no one-type-per-file rule. Avoid both files
of many thousands of lines and many tiny files: a maintainer should be
able to tell which file holds something and find it there.
Source: BP "Package size" (:640-648), `a9c5f82b1981`, read 2026-11-16.
↩ row [26](#row-26)

<a id="rule-proto-import-names"></a>**proto-import-names.** Rename a generated protobuf import to a
word for the package plus `pb`, and a gRPC stub import to that word
plus `grpc`: `foopb`, `foogrpc`. Prefer whole, descriptive words over
short names like `pb` or `xpb`; when unsure, use the proto package name
plus `pb`. Existing short names need not change.
Source: BP "Protocol Buffer Messages and Stubs" (:719-755),
`a9c5f82b1981`, read 2026-11-16.
Differs: BP ties the suffixes to the Bazel rules `go_proto_library`
and `go_grpc_library`; we tie them to what the generated package
holds.
↩ rows [29](#row-29), [30](#row-30)

<a id="rule-err-w-placement"></a>**err-w-placement.** Put `%w` at the end, `"...: %w"`, so the text
reads newest to oldest like the chain. The exception is a sentinel
that names the failure's category: it goes first,
`"%w: invalid character in header: %v"`, so the category leads, as at
the edge, where the outside error goes in with `%v` (err-wrap-verb).
Source: BP "Placement of %w in errors" and "Sentinel error placement"
(:1115-1244), `a9c5f82b1981`, read 2026-11-16.
↩ rows [49](#row-49), [50](#row-50)

<a id="rule-log-errors"></a>**log-errors.** A log line about an error says what went wrong and
carries what a maintainer needs to diagnose it. Don't log an error you
return: the caller decides whether to log it, rate-limit it, recover
or stop. Keep personal data out of log sinks not cleared for it. Log
at error level only what someone must act on, not what merely seems
more serious than a warning.
Source: BP "Logging errors" (:1259-1290), `a9c5f82b1981`, read
2026-11-16.
Differs: BP's reason to use error level sparingly is glog flushing on
every error line; only the "actionable" test is kept.
↩ rows [51](#row-51), [52](#row-52), [53](#row-53), [54](#row-54)

<a id="rule-main-exit"></a>**main-exit.** Start-up errors, such as bad flags or configuration,
are returned up to `main`, which prints a message saying how to fix
the problem and exits non-zero, without a stack trace.
Source: BP "Program initialization" (:1338-1344), `a9c5f82b1981`,
read 2026-11-16.
Differs: BP uses glog's `log.Exit` and warns off `log.Fatal`.
↩ row [58](#row-58)

<a id="rule-panic-scope"></a>**panic-scope.** Return errors: a library does not end the program,
least of all for a transient failure. When an invariant check finds
the program's state unrecoverable, panic with a message naming the
invariant that broke; nothing recovers that panic to carry on
(panic-no-recover). A panic is also right for API misuse that tests
and review should catch, as the standard library does; in `init` or a
`Must` function that has to stop the program; and as
`panic("unreachable")` after a call the compiler does not know never
returns. Don't log and call `os.Exit` from a library instead: slog
has no Fatal, and `os.Exit` skips `t.Cleanup` in tests.
Source: BP "Program checks and panics" and "When to panic"
(:1348-1465), `a9c5f82b1981`, read 2026-11-16; owner ruling on
bs-f3o.2.4, 2026-11-16.
Differs: BP ends the program on a broken invariant with glog's
`log.Fatal`, so deferred code does not run; without glog we are where
BP says the standard library is (:1388-1391), and panic.
↩ rows [59](#row-59), [60](#row-60), [63](#row-63), [65](#row-65), [67](#row-67)

<a id="rule-panic-no-recover"></a>**panic-no-recover.** Don't recover panics to avoid a crash: the
further from the panic, the less is known about the program's state.
Let it crash and surface it through monitoring. `net/http` recovering
handler panics is a historical mistake, not a model for a server's own
code. panic-recover is the one exception.
Source: BP "Program checks and panics" (:1363-1375), `a9c5f82b1981`,
read 2026-11-16.
↩ rows [61](#row-61), [62](#row-62)

<a id="rule-panic-recover"></a>**panic-recover.** Deeply nested code inside one package, such as a
parser, may panic with its own error type and recover in a deferred
function at the exported entry point, turning the panic into a
returned error. The panic never crosses the package boundary; the
recover re-panics anything that is not its own type; and code in such
sections releases its resources (close, free, unlock) itself.
Source: BP "When to panic" (:1396-1441), `a9c5f82b1981`, read
2026-11-16.
Same rule as go-team-docs.md panic-recover (Effective Go "Recover");
this one adds the re-panic and resource conditions.
↩ row [64](#row-64)

<a id="rule-doc-format"></a>**doc-format.** In a doc comment, a blank comment line separates
paragraphs; lines indented two extra spaces render verbatim, which
also suits lists and tables; and a single capitalised line with no
punctuation but parentheses and commas, followed by a paragraph,
renders as a heading. Prefer showing usage as a runnable `Example`
function in a test file over code in a comment.
Source: BP "Godoc formatting" (:1856-1936) and "Conventions"
(:1487-1490), `a9c5f82b1981`, read 2026-11-16.
↩ rows [80](#row-80), [81](#row-81), [82](#row-82), [83](#row-83)

<a id="rule-var-decl"></a>**var-decl.** Initialize a new variable with a non-zero value using
`:=`, not `var x = ...`. Declare an empty value that is ready to use,
an unmarshal target included, as `var x T`, not as a literal spelling
out zeros. Use a composite literal when the initial members are known.
For a pointer to a zero value, `new(T)` and `&T{}` are both fine;
`new` reminds the reader a literal would not do.
Source: BP "Initialization", "Declaring variables with zero values",
"Composite literals" (:1980-2145), `a9c5f82b1981`, read 2026-11-16.
↩ rows [85](#row-85), [86](#row-86), [87](#row-87), [91](#row-91), [92](#row-92)

<a id="rule-var-pointer"></a>**var-pointer.** A struct with a field that must not be copied, such
as `sync.Mutex`, holds that field as a value; the struct is then
passed by pointer and its methods take pointer receivers. A local
composite may be a value, but declare it as a pointer from the start
when the function returns a pointer to it, or every use takes its
address. Declare protobuf
messages as pointers: only `*pb.T` satisfies `proto.Message`.
Source: BP "Declaring variables with zero values" (:2049-2099),
`a9c5f82b1981`, read 2026-11-16.
↩ rows [88](#row-88), [89](#row-89)

<a id="rule-size-hints"></a>**size-hints.** Leave size hints out of `make` by default. Give one
when measurement shows it matters, or when the final size is known, as
when converting a map to a slice. Overallocating wastes memory.
Source: BP "Size hints" (:2149-2182), `a9c5f82b1981`, read 2026-11-16.
↩ row [93](#row-93)

<a id="rule-chan-direction"></a>**chan-direction.** Declare a channel parameter's direction,
`<-chan int` or `chan<- int`, wherever it has one, so the compiler
catches misuse such as closing a channel the function only reads.
Source: BP "Channel direction" (:2186-2223), `a9c5f82b1981`, read
2026-11-16.
↩ row [94](#row-94)

<a id="rule-string-build"></a>**string-build.** Join a few strings with `+`. Build a formatted
string with `fmt.Sprintf`, and write straight to an `io.Writer` with
`fmt.Fprintf` instead of formatting a string first. Use
`text/template`, or `safehtml/template` for HTML, when formatting is
more complex. Build a string piece by piece with `strings.Builder`:
repeated `+` or `Sprintf` takes quadratic time. Write a constant
multi-line string with backticks.
Source: BP "String concatenation" (:3364-3462), `a9c5f82b1981`, read
2026-11-16.
↩ rows [132](#row-132), [133](#row-133), [134](#row-134), [135](#row-135), [136](#row-136), [137](#row-137)

## Dropped

One section per drop row: what the source said, what it would have
meant in practice, and why it was dropped.

### <a id="drop-12"></a>Row 12: Bazel testonly

Source: BP "Simple case" (:272-274): "if the package is built with Bazel, make sure the new `go_library` rule for the package is marked as `testonly`".

In practice: A build attribute that keeps production targets from depending on a test helper package.

Dropped because: Bazel; we build with the go tool, which has no such attribute.

↩ row [12](#row-12)

### <a id="drop-27"></a>Row 27: Optional doc.go

Source: BP "Package size" (:649-651): "Packages with long package documentation may choose to dedicate one file called `doc.go` ... but this is not required."

In practice: A file holding only the package comment and the package clause.

Dropped because: A permission, not required; there is nothing to check.

↩ row [27](#row-27)

### <a id="drop-28"></a>Row 28: Bazel directory layout

Source: BP "Package size" (:653-656): "in projects using Bazel ... you can have multiple `go_library` targets in a single directory. A good reason to give each package its own directory is if you expect to open source your project".

In practice: Several packages in one directory, which the go tool does not allow.

Dropped because: Bazel; with the go tool a directory is a package.

↩ row [28](#row-28)

### <a id="drop-31"></a>Row 31: Handle errors deliberately

Source: BP "Error handling" (:777-788): "it is always worth considering whether the current function in the call frame is positioned to handle the error most effectively. This is a large topic and it is hard to give categorical advice. Use your judgment".

In practice: A prompt to think before propagating, followed by pointers to the sections below.

Dropped because: Advice to use judgment; the checkable parts are rows 33-50, and Failure Identity step 3 already says which unit handles a failure and which passes it on.

↩ row [31](#row-31)

### <a id="drop-42"></a>Row 42: %v for adding context

Source: BP "Adding information to errors" (:1011-1019): "`%v` for simple annotation or new error ... Adding interesting, non-redundant context".

In practice: Most wraps would use `%v`, dropping the cause's identity at every layer.

Dropped because: The owner ruled `%v` only at the edge where an outside error becomes our own identity, and a single `%w` everywhere above it (bjornstack.md row 48, err-wrap-verb).

↩ row [42](#row-42)

### <a id="drop-43"></a>Row 43: %v for logging or display

Source: BP "Adding information to errors" (:1021-1025): "When the primary goal is to present a human-readable error message in logs or to a user, and you don't intend for the caller to programmatically `errors.Is` or `errors.As` the error".

In practice: The wrapping verb chosen by guessing whether any caller will inspect the error.

Dropped because: err-wrap-verb chooses the verb by where the code sits (edge or above), not by who reads the error. Whether a caller branches decides whether the failure gets an identity (Failure Identity step 1), not the verb.

↩ row [43](#row-43)

### <a id="drop-48"></a>Row 48: %w for documented underlying errors

Source: BP "Adding information to errors" (:1102-1106): "If your package's API guarantees that certain underlying errors can be unwrapped and checked by callers ... then `%w` is appropriate. This forms part of your package's contract."

In practice: `%w` only where the package documents which wrapped errors callers may check.

Dropped because: err-wrap-verb wraps with `%w` above the edge whether or not the cause is documented; the edge already keeps outside identities out, so what passes up is ours. Documenting identities is err-doc.

↩ row [48](#row-48)

### <a id="drop-55"></a>Row 55: Monitoring over logs

Source: BP "Logging errors" (:1287-1290): "Inside Google, we have monitoring systems that can be set up for more effective alerting than writing to a log file and hoping someone notices it."

In practice: Alerts wired to Google's monitoring instead of log scraping.

Dropped because: Google infrastructure; it states no rule for code.

↩ row [55](#row-55)

### <a id="drop-56"></a>Row 56: Verbosity level convention

Source: BP "Custom verbosity levels" (:1302-1308): "Write a small amount of extra information at `V(1)`; Trace more information in `V(2)`; Dump large internal states in `V(3)`".

In practice: A numbering convention for glog's verbose levels.

Dropped because: glog's API; our logger is slog, taken with `logctx.From(ctx)` (ctx-scope), which has named levels instead.

↩ row [56](#row-56)

### <a id="drop-66"></a>Row 66: No logging before flags are parsed

Source: BP "When to panic" (:1462): "Do not call `log` functions before flags have been parsed."

In practice: glog reads its own flags, so logging before `flag.Parse` misbehaves.

Dropped because: glog-specific; slog has no flags.

↩ row [66](#row-66)

### <a id="drop-79"></a>Row 79: Preview documentation

Source: BP "Preview" (:1846-1850): "It is recommended to preview the documentation your code produces both before and during the code review process."

In practice: Running pkgsite locally and reading the rendered pages.

Dropped because: A manual review step with a running server; it leaves no outcome an agent can check. doc-format states the syntax the preview would confirm.

↩ row [79](#row-79)

### <a id="drop-106"></a>Row 106: Assertion helpers are not idiomatic

Source: BP "Leave testing to the Test function" (:2564-2566): "Assertion helpers are functions that check the correctness of a system and fail the test if an expectation is not met. Assertion helpers are not considered idiomatic in Go."

In practice: No assertion library and no shared functions that fail the test; checks written as `if got != want { t.Errorf(...) }`.

Dropped because: The owner chose testify `require` (bjornstack.md row 39, test-require) and an assertion function per table case (bjornstack.md row 64, test-table).

↩ row [106](#row-106)

### <a id="drop-108"></a>Row 108: Fail inside the Test function

Source: BP "Leave testing to the Test function" (:2568-2570): "The ideal place to fail a test is within the `Test` function itself".

In practice: Failure calls only in the `Test` body, never in a helper or a case's function.

Dropped because: Same as row 106: test-table's assertion functions fail the test from the case.

↩ row [108](#row-108)

### <a id="drop-109"></a>Row 109: Inline the shared validation

Source: BP "Leave testing to the Test function" (:2589-2593): "Inline the logic ... in the `Test` function, even if it is repetitive" and "unifying them into a table-driven test while keeping the logic inlined in the loop".

In practice: A table test whose loop holds the checks, branching where cases differ.

Dropped because: test-table (bjornstack.md row 64) has each case carry its assertion function and the body no conditionals (Parameterized Test Structure steps 3-4).

↩ row [109](#row-109)

### <a id="drop-110"></a>Row 110: Validation returns an error or a cmp.Option

Source: BP "Leave testing to the Test function" (:2594-2608): "arrange the validation function so that it returns a value (typically an `error`) rather than taking a `testing.T` parameter" and "If your common testing code provides a `cmp.Transformer` for your data type, that can often be the simplest design."

In practice: Shared checks that return an error the test then reports, and `cmp` options per data type.

Dropped because: Assertions use `require` (bjornstack.md row 39), and `cmp.Diff` has no role beyond protobuf messages (bjornstack.md row 43, test-protobuf).

↩ row [110](#row-110)

### <a id="drop-111"></a>Row 111: Don't stop the test from called code

Source: BP "Leave testing to the Test function" (:2659-2662): "code called from a test should not stop the test unless there is no point in proceeding."

In practice: `t.Error` in shared code, so a test reports every failure in one run.

Dropped because: test-require (bjornstack.md row 39): `require` stops at the first failure; `assert` only where a test deliberately collects independent failures.

↩ row [111](#row-111)

### <a id="drop-113"></a>Row 113: Fail fast or aggregate in an acceptance test

Source: BP "Writing an acceptance test" (:2741-2786): "Your design can choose between two disciplines for failure reporting: Fail fast ... Aggregate all failures", the latter in "a custom error type that aggregates errors".

In practice: An exercise function that returns one error or a `SimulationError` holding every bad move.

Dropped because: compliance-suite (bjornstack.md rows 95-96) takes `t` and runs each scenario in its own `t.Run`, so failures are reported per scenario and the suite returns no error to design.

↩ row [113](#row-113)

### <a id="drop-114"></a>Row 114: t.Fatal only for acceptance-test setup

Source: BP "Writing an acceptance test" (:2788-2811): "The acceptance test should honor the keep going guidance by not calling `t.Fatal` unless the test detects a broken invariant" and "do not attempt to use it to bypass the guidance on assertions."

In practice: The suite reports violations with `t.Error` and keeps going.

Dropped because: Same as rows 106 and 113: scenarios assert with `require` inside their own `t.Run`.

↩ row [114](#row-114)

### <a id="drop-117"></a>Row 117: Keep going

Source: BP "t.Error vs. t.Fatal" (:2870-2871): "tests should generally not abort at the first encountered problem."

In practice: `t.Error` by default, `t.Fatal` only when the rest of the test cannot run.

Dropped because: test-require (bjornstack.md row 39): `require` stops at the first failure; `assert` only where a test deliberately collects independent failures.

↩ row [117](#row-117)

## Open for owner

None. The owner ruled on both earlier questions on 2026-11-17 (bs-f3o.2
comments "Owner rulings from go-decisions" and "Owner rulings, round
2"):

1. **Option structs and variadic options (row 96):** variadic `WithX`
   options with sane defaults only, as func-options states (S-3).
2. **Documentation that restates the obvious (rows 68, 69):** new code
   doesn't write it, and existing caller documentation is left alone,
   as doc-params and doc-ctx state (S-12).

# Go sources C1: Google Go style guide, guide and decisions

Decision table for bs-f3o.2.3. It reviews the Google Go style guide's
core guide and its style decisions and decides, rule by rule, what
goes into `languages/go.md`. A row whose rule
[bjornstack.md](bjornstack.md) already holds reads "already ours" and
names that table's row.

Read 2026-11-16. Strategy and tenet text, and bjornstack.md, were
judged at bjornstack commit `67b1213`.

## Sources and pins

| Key | Source | Pin |
|---|---|---|
| G | `go/guide.md` in https://github.com/google/styleguide | commit `a9c5f82b19811f1552d73df384a9f9d7c75ca16e` (committed 2026-11-13), read 2026-11-16 |
| D | `go/decisions.md` in https://github.com/google/styleguide | same commit, read 2026-11-16 |

Line numbers in the Source column are lines of that file at that
commit. Nothing else was read for this table: the guide's links to
best-practices.md, Go Tips, blog posts and package docs were not
followed.

## Decision table

"Section" names the go.md section: Tooling, Pattern mappings (the Go
spelling of a strategy or of a rule in bjornstack.md), Go pitfalls,
or For the protocols (Go style conventions that bs-y5h turns into
protocol steps). "Check" says how a kept, adapted or already-ours rule
is enforced: "tool" when the pinned source itself names a check that
enforces it, "guard candidate" when the rule is mechanical but no
check is named, "judgment" when a person or an agent has to decide.
For "already ours" rows it repeats the check bjornstack.md gives.
Drop rows have "-".

| # | Source | Item | Decision | Reason | Rule id | Section | Check |
|---|---|---|---|---|---|---|---|
| <a id="row-1"></a>1 | G:23-41, G:365-378 | Principles in order clarity, simplicity, concision, maintainability, consistency; consistency only breaks ties | drop | Contradicts the Consistent Beats Correct tenet, which puts following established patterns above a locally better approach | [dropped](#drop-1) | — | - |
| <a id="row-2"></a>2 | G:79-105 | Comments explain why, not what; don't restate the code | drop | Same rule as bjornstack.md row 70, dropped there as language-neutral; bs-cbr's strategy owns where reasoning lives | [dropped](#drop-2) | — | - |
| <a id="row-3"></a>3 | G:155-180 | Add complexity deliberately and document it, with tests and examples | drop | Language-neutral principle with nothing Go-specific | [dropped](#drop-3) | — | - |
| <a id="row-4"></a>4 | G:184-197 | Least mechanism: core language construct, then standard library, then an existing core library, before a new dependency | adapt | Google's third tier is its internal codebase; ours is a dependency the module already has | [least-mechanism](#rule-least-mechanism) | For the protocols | judgment |
| <a id="row-5"></a>5 | G:199-203 | Tests override a flag-bound variable directly rather than with `flag.Set` | drop | Flags live only in `package main` (row 109); tests reach a binary through its command line (bjornstack.md bb-package) and a package only through its exports (test-pkg) | [dropped](#drop-5) | — | - |
| <a id="row-6"></a>6 | G:205-208 | A set is a `map[T]bool` unless it needs operations a map makes hard | keep | Go form of least mechanism | [least-mechanism](#rule-least-mechanism) | For the protocols | judgment |
| <a id="row-7"></a>7 | G:250-260 | Point out an unusual error check, such as `err == nil`, with a comment | keep | Go-specific: the reader expects `if err != nil` | [err-boost-signal](#rule-err-boost-signal) | For the protocols | judgment |
| <a id="row-8"></a>8 | G:295-340 | Where one character decides a line's meaning (`=` vs `:=`, a `!`), write it out or comment it | keep | Go-specific trap with `=` and `:=` | [explicit-critical](#rule-explicit-critical) | For the protocols | judgment |
| <a id="row-9"></a>9 | G:346-351 | Parameters and receivers for the same concept share a name | keep | Consistent Beats Correct, spelled for Go names | [name-predictable](#rule-name-predictable) | For the protocols | judgment |
| <a id="row-10"></a>10 | G:396-399 | All Go files are formatted by `gofmt` | already ours | bjornstack.md row 78 (tool-finish) | [tool-finish](bjornstack.md#rule-tool-finish) | Tooling | tool: gofmt (named by the source) |
| <a id="row-11"></a>11 | G:400-401 | Generated code is formatted too, e.g. with `format.Source` | keep | Not covered by tool-finish, which checks files on disk only after generation | [fmt-generated](#rule-fmt-generated) | Tooling | guard candidate |
| <a id="row-12"></a>12 | G:408-426 | MixedCaps for multi-word names, even against other languages' conventions | keep | Core Go convention; exemptions kept | [name-mixedcaps](#rule-name-mixedcaps) | For the protocols | guard candidate |
| <a id="row-13"></a>13 | G:432-442 | No fixed line length; refactor rather than split; don't split before an indentation change or inside a long string | keep | Go convention; no conflict | [fmt-line-length](#rule-fmt-line-length) | For the protocols | judgment |
| <a id="row-14"></a>14 | G:463-481 | Where the guide is silent, follow nearby code's consistent stance | drop | Consistent Beats Correct says it for every language | [dropped](#drop-14) | — | - |
| <a id="row-15"></a>15 | G:483-489 | A change may not worsen a style deviation; clean up in the same change or refactor first | drop | Language-neutral: Consistent Beats Correct's "changed everywhere it appears" and Tidy or Change's structural-first commits cover it | [dropped](#drop-15) | — | - |
| <a id="row-16"></a>16 | D:58-73, D:92-110 | No underscores in names, with exceptions: test function names, packages only generated code imports, `_test` packages, OS/cgo interop; file names may have them | keep | Go convention; exceptions kept | [name-underscores](#rule-name-underscores) | For the protocols | guard candidate |
| <a id="row-17"></a>17 | D:83-86 | Package names lower-case letters and digits, multi-word names unbroken (`tabwriter`) | already ours | bjornstack.md row 1 (pkg-naming: short lower-case noun) | [pkg-naming](bjornstack.md#rule-pkg-naming) | Pattern mappings | judgment |
| <a id="row-18"></a>18 | D:88-90 | Avoid package names a common local variable would shadow (`usercount`, not `count`) | keep | Not in pkg-naming; fits Domain-First Packaging step 2's domain noun | [pkg-name-shadow](#rule-pkg-name-shadow) | Pattern mappings | judgment |
| <a id="row-19"></a>19 | D:117-123 | Avoid uninformative package names: `util`, `common`, `helper`, `model`, `testhelper` | already ours | bjornstack.md rows 3 and 71 (proto-packages) | [proto-packages](bjornstack.md#rule-proto-packages) | For the protocols | guard candidate |
| <a id="row-20"></a>20 | D:92-94, D:125-130, D:887-899 | Imports are not renamed, except on a collision (rename the most local one); a local name follows package-name rules and is the same in every file | keep | Go convention | [import-rename](#rule-import-rename) | For the protocols | guard candidate |
| <a id="row-21"></a>21 | D:901-912 | Generated protobuf packages are renamed without underscores and with a `pb` suffix | keep | We use protobuf (bjornstack.md test-protobuf) | [import-rename](#rule-import-rename) | For the protocols | guard candidate |
| <a id="row-22"></a>22 | D:914-926 | An uninformative import name (`util`, `v1`) may be renamed, sparingly; prefer fixing the package's name | keep | Go convention | [import-rename](#rule-import-rename) | For the protocols | judgment |
| <a id="row-23"></a>23 | D:928-933 | An import that collides with a needed local variable is renamed with a `pkg` suffix (`urlpkg`) | keep | Go convention | [import-rename](#rule-import-rename) | For the protocols | guard candidate |
| <a id="row-24"></a>24 | D:148-160 | Receiver names: one or two letters, abbreviating the type, same on every method, never `this`, `self` or `_` | keep | Go convention; Be Your Name allows a short name whose definition is in sight | [recv-name](#rule-recv-name) | For the protocols | guard candidate |
| <a id="row-25"></a>25 | D:168-197 | Constants use MixedCaps; no `MAX_SIZE`, no `k` prefix | keep | Same rule as row 12, stated for constants | [name-mixedcaps](#rule-name-mixedcaps) | For the protocols | guard candidate |
| <a id="row-26"></a>26 | D:199-212 | Name constants for their role, not their value; a value with no role is not a constant | keep | Be Your Name for constants | [const-role](#rule-const-role) | For the protocols | judgment |
| <a id="row-27"></a>27 | D:228-260 | Initialisms keep one case (`URL`, `ID`, `xmlAPI`, `gRPC`/`GRPC`) | keep | Go convention; exemptions kept | [name-initialisms](#rule-name-initialisms) | For the protocols | guard candidate |
| <a id="row-28"></a>28 | D:276-278 | No `Get` prefix unless the concept is "get" (HTTP GET) | keep | Go convention | [name-getters](#rule-name-getters) | For the protocols | guard candidate |
| <a id="row-29"></a>29 | D:280-283 | `Compute` or `Fetch` for a call that is expensive or remote | keep | Be Your Name: the name warns it may block or fail | [name-getters](#rule-name-getters) | For the protocols | judgment |
| <a id="row-30"></a>30 | D:299-331 | Name length grows with scope and shrinks with use; the line counts are rough, not rules | keep | Be Your Name's short-name-in-sight case, spelled for Go | [name-var](#rule-name-var) | For the protocols | judgment |
| <a id="row-31"></a>31 | D:333-336 | A local's name says what it holds here, not where it came from | keep | Be Your Name | [name-var](#rule-name-var) | For the protocols | judgment |
| <a id="row-32"></a>32 | D:343-344 | Don't drop letters to save typing (`Sandbox`, not `Sbx`) | keep | Be Your Name | [name-var](#rule-name-var) | For the protocols | judgment |
| <a id="row-33"></a>33 | D:345-351, D:419-447 | Leave type words out of names (`users`, not `userSlice`), unless two forms of a value are in scope (`limitRaw`, `limit`) | keep | Go convention; exception kept | [name-var](#rule-name-var) | For the protocols | judgment |
| <a id="row-34"></a>34 | D:362-379 | Single-letter names only where the word is obvious: receivers, `r`/`w`, `i`/`x`/`y`, short loops | keep | Be Your Name's short-name-in-sight case | [name-var](#rule-name-var) | For the protocols | judgment |
| <a id="row-35"></a>35 | D:352-355, D:451-538 | Names leave out what the package, type, method or file already says (`(*Project).Name`, `sqldb.Connection`); judge at the call site | keep | Extends pkg-naming (exports vs package) to methods, types and locals | [name-context](#rule-name-context) | Pattern mappings | judgment |
| <a id="row-36"></a>36 | D:402-415 | Exports don't repeat the package name; a package's only type gets constructor `New` (`widget.New`) | already ours | bjornstack.md row 4 (pkg-naming: exports extend the package name) | [pkg-naming](bjornstack.md#rule-pkg-naming) | Pattern mappings | guard candidate |
| <a id="row-37"></a>37 | D:553-555 | Use doc preview during development and review | drop | A review habit, not a rule for code; no tool in our finish criteria | [dropped](#drop-37) | — | - |
| <a id="row-38"></a>38 | D:557-559 | Godoc formatting: indent lists and code; otherwise no decoration | keep | Go-specific doc format | [doc-comments](#rule-doc-comments) | For the protocols | judgment |
| <a id="row-39"></a>39 | D:566-599 | Wrap long comments, 80 or 100 columns as a guide, not a hard limit; consistent within a file | keep | Go convention | [comment-wrap](#rule-comment-wrap) | For the protocols | judgment |
| <a id="row-40"></a>40 | D:616-633 | Every exported top-level name has a doc comment, full sentences starting with the name; so does unexported code with unobvious behavior | adapt | bjornstack.md builders-a gives builder methods no doc comments; that exception is added | [doc-comments](#rule-doc-comments) | For the protocols | guard candidate |
| <a id="row-41"></a>41 | D:658-661 | A doc comment on unexported code also starts with its name | keep | Go convention | [doc-comments](#rule-doc-comments) | For the protocols | guard candidate |
| <a id="row-42"></a>42 | D:669-680 | Comments that are sentences are capitalized and punctuated; fragments need not be | keep | Go convention | [comment-sentences](#rule-comment-sentences) | For the protocols | judgment |
| <a id="row-43"></a>43 | D:708-718 | Document intended use with a runnable example in a test file, or formatted example code in a comment | keep | `Example` functions in `foo_test` fit test-pkg | [doc-examples](#rule-doc-examples) | For the protocols | judgment |
| <a id="row-44"></a>44 | D:726-776 | Name results only when it helps the caller: same-type results, an action the caller must take; not when repetitive or to avoid declaring a local | keep | Go convention | [named-results](#rule-named-results) | For the protocols | judgment |
| <a id="row-45"></a>45 | D:778-785 | Naked returns only in small functions; a result changed in a deferred closure may always be named | keep | Go convention | [named-results](#rule-named-results) | For the protocols | judgment |
| <a id="row-46"></a>46 | D:805-818 | One package comment per package, directly above the `package` clause | keep | Go convention | [pkg-comment](#rule-pkg-comment) | For the protocols | guard candidate |
| <a id="row-47"></a>47 | D:820-845 | A `main` package comment names the binary as the BUILD `go_binary` rule does | adapt | We don't build with Bazel; the comment names the command as it is invoked | [pkg-comment](#rule-pkg-comment) | For the protocols | judgment |
| <a id="row-48"></a>48 | D:939-969 | Import groups in order: standard library, other, protobuf, side-effect imports | keep | Go convention | [import-groups](#rule-import-groups) | For the protocols | guard candidate |
| <a id="row-49"></a>49 | D:977-1001 | Blank imports only in `main` or tests; exceptions: bypassing nogo, `embed` | adapt | We run no nogo checker, so that exception goes; the `embed` exception stays | [import-blank](#rule-import-blank) | For the protocols | guard candidate |
| <a id="row-50"></a>50 | D:1011-1042 | No dot imports | keep | Go convention | [import-dot](#rule-import-dot) | For the protocols | guard candidate |
| <a id="row-51"></a>51 | D:1054-1055 | `error` is the last result | keep | Go convention | [err-last](#rule-err-last) | For the protocols | guard candidate |
| <a id="row-52"></a>52 | D:1063-1067 | With a non-nil error, other results are unspecified unless documented | keep | Go-specific trap | [err-results](#rule-err-results) | Go pitfalls | judgment |
| <a id="row-53"></a>53 | D:1081-1090 | Exported functions return `error`, not a concrete error type: a nil pointer becomes a non-nil interface | keep | Go-specific trap; Failure Identity's identity types are still returned as `error` | [err-interface-return](#rule-err-interface-return) | Go pitfalls | guard candidate |
| <a id="row-54"></a>54 | D:1092-1094 | A function taking a `context.Context` usually returns an `error` | keep | Lets the caller see a cancellation; "usually" kept | [ctx-returns-error](#rule-ctx-returns-error) | Pattern mappings | judgment |
| <a id="row-55"></a>55 | D:1104-1119 | Error strings start lower-case (exceptions: exported names, proper nouns, acronyms) and end without punctuation | keep | Go convention; fits Failure Identity step 3's "adds what it was doing" chain | [err-strings](#rule-err-strings) | For the protocols | guard candidate |
| <a id="row-56"></a>56 | D:1121-1134 | Full displayed messages (logs, test failures, UI) are usually capitalized | drop | Test messages follow bjornstack.md test-messages ("expected ..."); log messages are set by ctx-scope's logger, not by this guide | [dropped](#drop-56) | — | - |
| <a id="row-57"></a>57 | D:1142-1151 | Every error is handled, returned, or, exceptionally, ends the program | keep | Fail Early and Loud, spelled for Go | [err-handle](#rule-err-handle) | Pattern mappings | guard candidate |
| <a id="row-58"></a>58 | D:1153-1163 | An error discarded with `_` carries a comment saying why that is safe | keep | Fail Early and Loud: a silent discard needs a stated reason | [err-handle](#rule-err-handle) | Pattern mappings | guard candidate |
| <a id="row-59"></a>59 | D:1177-1231 | No in-band errors (-1, "", nil); return an extra `ok bool` or `error`, last | keep | Fail Early and Loud's "silent default substitution" | [err-in-band](#rule-err-in-band) | Pattern mappings | judgment |
| <a id="row-60"></a>60 | D:1241-1267 | Handle errors first; no `else` after a block that ends in return, continue, panic or exit | keep | Go convention | [err-indent-flow](#rule-err-indent-flow) | For the protocols | guard candidate |
| <a id="row-61"></a>61 | D:1269-1296 | A variable used past a few lines is declared before the `if`, not in its initializer | keep | Go convention | [err-indent-flow](#rule-err-indent-flow) | For the protocols | judgment |
| <a id="row-62"></a>62 | D:1312-1317 | Build values with a composite literal rather than field by field, where possible | keep | Go convention | [lit-composite](#rule-lit-composite) | For the protocols | judgment |
| <a id="row-63"></a>63 | D:1325-1350 | Struct literals of types from other packages name their fields | keep | Go convention | [lit-field-names](#rule-lit-field-names) | For the protocols | guard candidate |
| <a id="row-64"></a>64 | D:1352-1374 | Field names optional for local types; use them when clearer, nearly always for many fields | keep | Go convention | [lit-field-names](#rule-lit-field-names) | For the protocols | judgment |
| <a id="row-65"></a>65 | D:1380-1420 | A multi-line literal's closing brace sits at the opening brace's indentation | keep | Go convention gofmt doesn't enforce | [lit-braces](#rule-lit-braces) | For the protocols | guard candidate |
| <a id="row-66"></a>66 | D:1426-1483 | Cuddle braces only when indentation matches and inner values are literals or proto builders | keep | Go convention | [lit-braces](#rule-lit-braces) | For the protocols | guard candidate |
| <a id="row-67"></a>67 | D:1489-1532 | Leave repeated type names out of slice and map literals, except for an uncommon complex type far apart; `gofmt -s` removes them | keep | Go convention; exception kept | [lit-elide-types](#rule-lit-elide-types) | For the protocols | tool: gofmt -s (named by the source) |
| <a id="row-68"></a>68 | D:1538-1583 | Zero-value fields may be left out of struct literals when no clarity is lost | adapt | Production code only; test tables follow bjornstack.md test-table (row 69) | [lit-zero-fields](#rule-lit-zero-fields) | For the protocols | judgment |
| <a id="row-69"></a>69 | D:1585-1640 | Table-test cases leave out zero-valued fields unrelated to the case | drop | Contradicts bjornstack.md test-table ("Every case sets every field") and Parameterized Test Structure step 2 | [dropped](#drop-69) | — | - |
| <a id="row-70"></a>70 | D:1666-1680 | Declare an empty local slice as `var s []T`, not `[]T{}` | keep | Go convention | [nil-slice](#rule-nil-slice) | For the protocols | guard candidate |
| <a id="row-71"></a>71 | D:1682-1739 | No API makes callers tell nil from an empty slice; test emptiness with `len` | keep | Go-specific; Fail Early and Loud (a hidden path on nil) | [nil-slice](#rule-nil-slice) | For the protocols | judgment |
| <a id="row-72"></a>72 | D:1749-1761 | Don't break a line so it aligns with an indented block; if unavoidable, leave a space | keep | Go convention | [fmt-line-length](#rule-fmt-line-length) | For the protocols | judgment |
| <a id="row-73"></a>73 | D:1773-1789 | A function signature stays on one line | keep | Go convention | [fmt-line-length](#rule-fmt-line-length) | For the protocols | guard candidate |
| <a id="row-74"></a>74 | D:1803-1817, D:1838-1857 | Don't split calls for length alone; break by meaning when the API can't change or the call is unusual | keep | Go convention; exception kept | [fmt-line-length](#rule-fmt-line-length) | For the protocols | judgment |
| <a id="row-75"></a>75 | D:1819-1836 | No inline comments on call arguments; use an option struct or document the function | keep | Go convention | [fmt-arg-comments](#rule-fmt-arg-comments) | For the protocols | judgment |
| <a id="row-76"></a>76 | D:1859-1880 | Don't break long string literals; arguments may follow the format string on new lines | keep | Go convention | [fmt-line-length](#rule-fmt-line-length) | For the protocols | judgment |
| <a id="row-77"></a>77 | D:1886-1981 | `if` and `for` clauses stay on one line; extract boolean operands into locals | keep | Go convention | [fmt-line-length](#rule-fmt-line-length) | For the protocols | guard candidate |
| <a id="row-78"></a>78 | D:1983-2033 | `switch` and `case` lines stay on one line; if too long, indent all cases and add a blank line | keep | Go convention; exception kept | [fmt-line-length](#rule-fmt-line-length) | For the protocols | judgment |
| <a id="row-79"></a>79 | D:2035-2055 | Variable on the left when comparing to a constant; no Yoda conditions | keep | Go convention | [cond-no-yoda](#rule-cond-no-yoda) | For the protocols | guard candidate |
| <a id="row-80"></a>80 | D:2063-2080 | Don't copy values whose methods are on the pointer type (`bytes.Buffer`, `sync.Mutex`) | keep | Go-specific trap | [copy-safety](#rule-copy-safety) | Go pitfalls | guard candidate |
| <a id="row-81"></a>81 | D:2082-2119 | APIs over structs with uncopyable fields take and return pointers | keep | Go-specific trap | [copy-safety](#rule-copy-safety) | Go pitfalls | judgment |
| <a id="row-82"></a>82 | D:2127-2128 | Don't panic for normal error handling | keep | Fail Early and Loud through returned errors | [err-no-panic](#rule-err-no-panic) | Pattern mappings | judgment |
| <a id="row-83"></a>83 | D:2130-2141 | In `main` and init, end with `log.Exit` (no stack trace); "impossible" bugs may return an error or `log.Fatal` | adapt | `log.Exit`/`log.Fatal` are Google's glog; we say what they do with the standard library | [err-no-panic](#rule-err-no-panic) | Pattern mappings | judgment |
| <a id="row-84"></a>84 | D:2150-2175, D:2210-2235 | `MustXYZ` names functions that stop the program; call them only at startup, never where an error can be handled | keep | Go convention | [must-funcs](#rule-must-funcs) | For the protocols | judgment |
| <a id="row-85"></a>85 | D:2177-2221 | A test `mustXYZ` helper stops the test with `t.Fatal` and is marked a helper | adapt | It fails with `require` (test-require) and calls `t.Helper()` (test-helper) | [must-funcs](#rule-must-funcs) | For the protocols | judgment |
| <a id="row-86"></a>86 | D:2243-2297 | Make each goroutine's exit evident; keep synchronization in the starting function or document when it exits | keep | Go-specific; no conflict | [go-lifetime](#rule-go-lifetime) | Pattern mappings | judgment |
| <a id="row-87"></a>87 | D:2347-2349 | No interface until a real need; name it for behavior, not "service" or "repository" | adapt | A coordinator's direct collaborator is such a need: Unit Testing steps 3.2-3.3 receive it and replace it with a double | [iface-need](#rule-iface-need) | Pattern mappings | judgment |
| <a id="row-88"></a>88 | D:2351-2354 | Don't wrap RPC clients in interfaces for testing; use real transports | drop | Unit Testing step 3.3 replaces every direct collaborator of a coordinator with a double; bjornstack.md coord-doubles spells it | [dropped](#drop-88) | — | - |
| <a id="row-89"></a>89 | D:2356-2358 | No back doors or exported test doubles only for tests; test through the real API | already ours | bjornstack.md rows 14 and 16 (pkg-internal: "Never export it for the test") | [pkg-internal](bjornstack.md#rule-pkg-internal) | Pattern mappings | judgment |
| <a id="row-90"></a>90 | D:2360-2363 | When the real implementation is impractical, test doubles go in a dedicated package (e.g. `spannertest`) | adapt | Test Data Builders step 2: doubles stay in their test file; a stateful double moves under the builders' entry point once shared and once it passes the compliance suite | [double-package](#rule-double-package) | Pattern mappings | judgment |
| <a id="row-91"></a>91 | D:2365-2368 | Keep interfaces small; document contract, edge cases and errors; unexported if only used inside the package | keep | Intentionally Public step 1; Failure Identity step 2 documents an identity with its operation | [iface-small](#rule-iface-small) | Pattern mappings | judgment |
| <a id="row-92"></a>92 | D:2370-2373 | The consumer defines the interface with only the methods it uses; the producer exports one only when it is the product | keep | Test Data Builders step 2: each consumer depends only on the operations it calls | [iface-consumer](#rule-iface-consumer) | Pattern mappings | judgment |
| <a id="row-93"></a>93 | D:2375-2383 | Accept interfaces, return concrete types; exceptions such as `error` and factory or strategy patterns | keep | Go convention; exceptions kept | [iface-return-concrete](#rule-iface-return-concrete) | Pattern mappings | judgment |
| <a id="row-94"></a>94 | D:2399-2403 | Generics where they meet a requirement; beware premature use | keep | Least mechanism (row 4) | [generics](#rule-generics) | For the protocols | judgment |
| <a id="row-95"></a>95 | D:2405-2406 | Exported generic APIs are documented, ideally with runnable examples | keep | Go convention | [generics](#rule-generics) | For the protocols | judgment |
| <a id="row-96"></a>96 | D:2408-2413 | Only one type instantiated: no generics yet | keep | Same direction as Earned Abstraction: don't abstract before cases exist | [generics](#rule-generics) | For the protocols | judgment |
| <a id="row-97"></a>97 | D:2415-2420 | No generic DSLs or error-handling frameworks; be wary of assertion libraries | adapt | The assertion-library caution does not cover testify, the owner's choice (test-require) | [generics](#rule-generics) | For the protocols | judgment |
| <a id="row-98"></a>98 | D:2422-2429 | Shared interface first; otherwise generics over `any` and type switches | keep | Go convention | [generics](#rule-generics) | For the protocols | judgment |
| <a id="row-99"></a>99 | D:2448-2459 | No pointer arguments just to save bytes; large or growing structs and protobuf messages by pointer | keep | Go convention; exceptions kept | [pass-values](#rule-pass-values) | For the protocols | judgment |
| <a id="row-100"></a>100 | D:2474-2590, D:2595-2601 | Receiver kind by correctness, then size; the case list; when in doubt, pointer; benchmark before claiming speed | keep | Go convention | [recv-type](#rule-recv-type) | For the protocols | judgment |
| <a id="row-101"></a>101 | D:2592-2593 | A type's methods are all pointer or all value | keep | Go convention ("as a general guideline" kept) | [recv-type](#rule-recv-type) | For the protocols | guard candidate |
| <a id="row-102"></a>102 | D:2613-2644 | No bare `break` at the end of a switch clause; comment an empty clause | keep | Go convention | [switch-break](#rule-switch-break) | For the protocols | guard candidate |
| <a id="row-103"></a>103 | D:2646-2668 | `break` in a switch inside a loop exits only the switch; use a label | keep | Go-specific trap | [switch-break-loop](#rule-switch-break-loop) | Go pitfalls | judgment |
| <a id="row-104"></a>104 | D:2676-2687 | Prefer synchronous functions; callers add concurrency | keep | Go convention; makes code testable without polling | [sync-funcs](#rule-sync-funcs) | Pattern mappings | judgment |
| <a id="row-105"></a>105 | D:2700-2703 | Type definitions for new types; aliases only to aid migration | keep | Go convention | [type-alias](#rule-type-alias) | For the protocols | judgment |
| <a id="row-106"></a>106 | D:2713-2734 | Quote strings in human output with `%q` | keep | Go convention | [fmt-q](#rule-fmt-q) | For the protocols | guard candidate |
| <a id="row-107"></a>107 | D:2740-2743 | `any` in new code, not `interface{}` | keep | Go convention | [use-any](#rule-use-any) | For the protocols | guard candidate |
| <a id="row-108"></a>108 | D:2755-2777 | Flag names in snake_case with a camelCase variable, using Google's internal flag package | drop | Tied to Google's internal flag package; nothing in our material picks a flag-name style | [dropped](#drop-108) | — | - |
| <a id="row-109"></a>109 | D:2779-2787 | Flags only in `package main`; libraries are configured through Go APIs, rarely exported globals | adapt | Adds Unit Testing step 3.2: a coordinator that reads global state has a hidden collaborator | [flags-main](#rule-flags-main) | Pattern mappings | guard candidate |
| <a id="row-110"></a>110 | D:2789-2790 | Global flag variables sit in their own `var` group after the imports | keep | Go convention | [flags-main](#rule-flags-main) | Pattern mappings | guard candidate |
| <a id="row-111"></a>111 | D:2810-2822 | Google's `log` (glog) package; `log.Info` over `log.Infof` without formatting | drop | We log through ctx (bjornstack.md ctx-scope: `logctx.From(ctx)`), not glog | [dropped](#drop-111) | — | - |
| <a id="row-112"></a>112 | D:2851-2856 | `context.Context` is always the first parameter | already ours | bjornstack.md row 46 (ctx-per-call) | [ctx-per-call](bjornstack.md#rule-ctx-per-call) | Pattern mappings | guard candidate |
| <a id="row-113"></a>113 | D:2858-2876 | Where ctx comes from without a caller: `r.Context()`, the stream, `t.Context()`, `context.Background()` in `main` or `init` | keep | Go convention | [ctx-sources](#rule-ctx-sources) | Pattern mappings | judgment |
| <a id="row-114"></a>114 | D:2878-2896 | Code mid-chain takes its caller's ctx, unless it is the wrong one; only server frameworks create one; discuss other uses with the style list | adapt | No style mailing list here; such a use is raised in review | [ctx-sources](#rule-ctx-sources) | Pattern mappings | judgment |
| <a id="row-115"></a>115 | D:2898-2904, D:3880-3883 | Test helper parameters: ctx first, then `t`, then the rest | keep | Go convention; consistent with ctx-per-call | [test-helper-params](#rule-test-helper-params) | Pattern mappings | guard candidate |
| <a id="row-116"></a>116 | D:2907-2912 | No ctx field in a struct; pass it to each method; exception for a signature fixed by an outside interface | already ours | bjornstack.md row 46 (ctx-per-call: "never stored in a struct"); Google's outside-interface exception is not in ctx-per-call | [ctx-per-call](bjornstack.md#rule-ctx-per-call) | Pattern mappings | guard candidate |
| <a id="row-117"></a>117 | D:2914-2918 | Tests use the innermost `t.Context()`, not `context.Background()`, and pass it to helpers and double setup | keep | Go convention | [ctx-test](#rule-ctx-test) | Pattern mappings | guard candidate |
| <a id="row-118"></a>118 | D:2920-2923 | `t.Context()` is cancelled before `t.Cleanup` runs; cleanup uses `context.Background()` or `context.WithoutCancel` | keep | Go-specific trap; meets bjornstack.md compliance-suite, whose factory cleans up with `t.Cleanup` | [ctx-cleanup](#rule-ctx-cleanup) | Go pitfalls | judgment |
| <a id="row-119"></a>119 | D:2929-2932 | Background work that outlives the parent context uses an internal detachment package | drop | Google-internal package | [dropped](#drop-119) | — | - |
| <a id="row-120"></a>120 | D:2949-2957 | No custom context types or other context interfaces in signatures, no exceptions | keep | Go convention | [ctx-no-custom](#rule-ctx-no-custom) | Pattern mappings | guard candidate |
| <a id="row-121"></a>121 | D:2959-2962 | Application data goes in a parameter, the receiver, a global, or a ctx value if it belongs there | drop | bjornstack.md ctx-scope limits ctx values, and coord-globals and Unit Testing step 3.2 limit globals | [dropped](#drop-121) | — | - |
| <a id="row-122"></a>122 | D:2970-2996 | Keys come from `crypto/rand`, never `math/rand` | keep | Go-specific security trap | [crypto-rand](#rule-crypto-rand) | Go pitfalls | guard candidate |
| <a id="row-123"></a>123 | D:3022-3069, D:4002-4008 | No assertion libraries; package `testing` is the only test framework | drop | Contradicts the owner's choice of testify `require` (bjornstack.md test-require) | [dropped](#drop-123) | — | - |
| <a id="row-124"></a>124 | D:3071-3087, D:3291-3307 | Compare with `cmp.Equal`/`cmp.Diff` and `fmt` | drop | bjornstack.md test-require and test-whole-value: `require.Equal`; `cmp.Diff` only for protobuf (test-protobuf) | [dropped](#drop-124) | — | - |
| <a id="row-125"></a>125 | D:3089-3105 | Domain-specific comparison helpers return a value or error instead of taking `*testing.T` | drop | Contradicts Parameterized Test Structure step 3 and bjornstack.md test-table, whose assertion functions take `t` | [dropped](#drop-125) | — | - |
| <a id="row-126"></a>126 | D:3107-3108 | A non-trivial helper used by tests is tested directly | drop | Language-neutral; Unit Testing step 2 tests computation directly | [dropped](#drop-126) | — | - |
| <a id="row-127"></a>127 | D:3128-3131 | Failure messages name the function: `YourFunc(%v) = %v, want %v` | drop | `require` prints expected and actual itself; messages follow bjornstack.md test-messages and the test name test-names | [dropped](#drop-127) | — | - |
| <a id="row-128"></a>128 | D:3137-3141 | Failure messages include short inputs; otherwise name the case and print its description | adapt | Naming the case is bjornstack.md test-names; what remains is putting a short input the name doesn't show into the message | [test-input-in-message](#rule-test-input-in-message) | Pattern mappings | judgment |
| <a id="row-129"></a>129 | D:3147-3156 | Got before want; say "got" and "want" | drop | `require.Equal(t, want, got)` fixes the order and labels the sides itself (test-whole-value) | [dropped](#drop-129) | — | - |
| <a id="row-130"></a>130 | D:3164-3171 | Compare whole structures, not field by field, unless irrelevant fields obscure the test | already ours | bjornstack.md rows 82 and 94 (test-whole-value); Google's irrelevant-fields exit is not in Whole-Object Assertion step 1 | [test-whole-value](bjornstack.md#rule-test-whole-value) | Pattern mappings | judgment |
| <a id="row-131"></a>131 | D:3173-3178 | Approximate or uncomparable fields: tune `cmp` with `cmpopts` | drop | bjornstack.md test-protobuf gives `cmp` no other role; Whole-Object Assertion step 2 accounts for such fields | [dropped](#drop-131) | — | - |
| <a id="row-132"></a>132 | D:3180-3200 | Multiple return values are compared one by one, not wrapped in a struct | already ours | bjornstack.md row 86 (test-table: `assertError` and `assertResult`, both called) | [test-table](bjornstack.md#rule-test-table) | Pattern mappings | guard candidate |
| <a id="row-133"></a>133 | D:3210-3220 | Don't compare output whose bytes a package you don't own decides (`json.Marshal`); parse and compare the structure | keep | Go form of Whole-Object Assertion's misapplication "asserting on serialized representations" | [test-stable-output](#rule-test-stable-output) | Pattern mappings | judgment |
| <a id="row-134"></a>134 | D:3228-3272 | Keep going: `t.Error` over `t.Fatal`; `t.Fatal` only when later checks would mislead | drop | Contradicts bjornstack.md test-require (`require` stops at the first failure; `assert` only for deliberately independent failures) | [dropped](#drop-134) | — | - |
| <a id="row-135"></a>135 | D:3274-3276 | Table tests: subtests and `t.Fatal`, not `t.Error` and `continue` | already ours | bjornstack.md row 83 (test-table: `t.Run`) and row 39 (test-require: `require` stops the subtest) | [test-table](bjornstack.md#rule-test-table), [test-require](bjornstack.md#rule-test-require) | Pattern mappings | guard candidate |
| <a id="row-136"></a>136 | D:3309-3321 | Protobuf messages compare with `cmp` and `protocmp.Transform()` | already ours | bjornstack.md rows 43 and 57 (test-protobuf) | [test-protobuf](bjornstack.md#rule-test-protobuf) | Tooling | guard candidate |
| <a id="row-137"></a>137 | D:3333-3351 | Older `pretty` library may stay for consistency; prefer `cmp` | drop | Not in our stack; comparison is set by test-require | [dropped](#drop-137) | — | - |
| <a id="row-138"></a>138 | D:3353-3357 | Don't use `reflect.DeepEqual` for equality | drop | The owner chose `require.Equal`, which compares like `DeepEqual`, for its time-zone strictness (test-require Differs) | [dropped](#drop-138) | — | - |
| <a id="row-139"></a>139 | D:3359-3363 | `cmp` is for tests; it may panic, so not in production code | keep | Go-specific trap | [cmp-test-only](#rule-cmp-test-only) | Go pitfalls | guard candidate |
| <a id="row-140"></a>140 | D:3373-3376 | Tests with complex interactions say which call failed and any state needed | keep | Fits test-messages; nothing in bjornstack.md covers repeated calls | [test-failure-detail](#rule-test-failure-detail) | Pattern mappings | judgment |
| <a id="row-141"></a>141 | D:3377-3379 | For a complex struct, describe only the important parts | drop | `require.Equal` prints the whole difference; Whole-Object Assertion compares everything | [dropped](#drop-141) | — | - |
| <a id="row-142"></a>142 | D:3380-3384 | Setup failures need less detail: say which setup step failed | keep | Fits test-messages; a setup failure is not an assertion | [test-failure-detail](#rule-test-failure-detail) | Pattern mappings | judgment |
| <a id="row-143"></a>143 | D:3386-3388 | Trigger the failure during development and read its message | drop | Language-neutral; Outside-In Development Loop step 1 already starts every test failing | [dropped](#drop-143) | — | - |
| <a id="row-144"></a>144 | D:3390-3396 | Print strings with `%q`, small structs with `%+v`, large values as a diff | drop | `require` formats the values it prints; `%q` in messages we write is row 106 | [dropped](#drop-144) | — | - |
| <a id="row-145"></a>145 | D:3402-3419 | Print a diff for large output; `cmp.Diff` preferred | drop | `require.Equal` prints a diff itself; `cmp.Diff` only for protobuf (test-protobuf) | [dropped](#drop-145) | — | - |
| <a id="row-146"></a>146 | D:3421-3445 | Say the diff's direction, e.g. `(-want +got)`, and print a newline before it | adapt | Applies where we still call `cmp.Diff`: protobuf comparisons (test-protobuf) | [test-diff-key](#rule-test-diff-key) | Pattern mappings | guard candidate |
| <a id="row-147"></a>147 | D:3451-3459 | Don't string-compare to check an error's kind; checking that a message has a property is fine | drop | Failure Identity step 6 says it for every language | [dropped](#drop-147) | — | - |
| <a id="row-148"></a>148 | D:3461-3469 | Test semantic error information; ask a dependency's owner rather than parse its messages | drop | Failure Identity steps 2-3 and its "identity carried in the text" misapplication say it for every language | [dropped](#drop-148) | — | - |
| <a id="row-149"></a>149 | D:3471-3475 | Checking only that an error is non-nil is enough when that is all you care about; else `errors.Is` or `cmpopts.EquateErrors` | drop | Failure Identity step 6 also checks the message's facts; we check identity with `require.ErrorIs`/`ErrorAs` (err-is-fresh-pointer), and EquateErrors is a trap (err-equate-errors) | [dropped](#drop-149) | — | - |
| <a id="row-150"></a>150 | D:3477-3489 | A `bool` `wantErr` compared with `!=` when no error identity matters | drop | bjornstack.md test-table carries an assertion function per case instead | [dropped](#drop-150) | — | - |
| <a id="row-151"></a>151 | D:3512-3514 | Subtests don't depend on other cases and run alone | drop | Isolated Test Execution's outcome "pass regardless of execution order" says it for every language | [dropped](#drop-151) | — | - |
| <a id="row-152"></a>152 | D:3523-3536 | Subtest names read like identifiers, not prose; a long description goes in its own field | drop | Contradicts bjornstack.md test-names and Parameterized Test Structure step 2: names read as sentences | [dropped](#drop-152) | — | - |
| <a id="row-153"></a>153 | D:3530-3532 | Avoid spaces and non-printing characters in subtest names (the runner rewrites them) | adapt | Spaces stay, as test-names wants sentences; non-printing characters are avoided | [test-name-chars](#rule-test-name-chars) | Pattern mappings | guard candidate |
| <a id="row-154"></a>154 | D:3541-3550 | No slashes in subtest names; they split a test filter | keep | Go-specific; compatible with sentence names | [test-name-chars](#rule-test-name-chars) | Pattern mappings | guard candidate |
| <a id="row-155"></a>155 | D:3605-3612 | Use table-driven tests when many cases share the testing logic | drop | Parameterized Test Structure step 1 says it for every language | [dropped](#drop-155) | — | - |
| <a id="row-156"></a>156 | D:3659-3661 | Cases checked with different logic go in separate test functions | drop | Parameterized Test Structure step 3 and bjornstack.md test-table encode differing checks as assertion functions in one table | [dropped](#drop-156) | — | - |
| <a id="row-157"></a>157 | D:3663-3711 | Simple extra cases (`if err != nil { continue }`) may share the table | drop | Contradicts bjornstack.md test-table: the body has no conditionals | [dropped](#drop-157) | — | - |
| <a id="row-158"></a>158 | D:3713-3719 | Cases with different logic but identical setup: a sequence of subtests in one function | drop | Parameterized Test Structure steps 1 and 3 decide this: separate tests or assertion functions | [dropped](#drop-158) | — | - |
| <a id="row-159"></a>159 | D:3721-3725 | Separate tables for normal outputs and error outputs | drop | Parameterized Test Structure step 3: success and error cases may share a table | [dropped](#drop-159) | — | - |
| <a id="row-160"></a>160 | D:3733-3832 | Row values must not drive conditional behavior in the test body; duplicate the test instead | already ours | bjornstack.md row 64 (test-table: "The body has no conditionals") | [test-table](bjornstack.md#rule-test-table) | Pattern mappings | guard candidate |
| <a id="row-161"></a>161 | D:3840-3866 | Identify a failing row by name or description, never its index | already ours | bjornstack.md rows 67 and 89 (test-names) | [test-names](bjornstack.md#rule-test-names) | Pattern mappings | judgment |
| <a id="row-162"></a>162 | D:3880-3881 | A helper taking `*testing.T` calls `t.Helper()` | already ours | bjornstack.md row 91 (test-helper) | [test-helper](bjornstack.md#rule-test-helper) | Pattern mappings | guard candidate |
| <a id="row-163"></a>163 | D:3875-3878, D:3905-3908 | Test helpers do setup and cleanup only; `t.Helper` is not for building assertion helpers | drop | Contradicts bjornstack.md test-helper and test-table, which use assertion functions with `t.Helper()` | [dropped](#drop-163) | — | - |
| <a id="row-164"></a>164 | D:3928-3961 | Tests may be in the same package as the code | drop | Contradicts bjornstack.md test-pkg and Public API Surface Testing step 1 | [dropped](#drop-164) | — | - |
| <a id="row-165"></a>165 | D:3970-3996 | Tests in another package use the `_test` suffix | already ours | bjornstack.md row 13 (test-pkg: `package foo_test` always) | [test-pkg](bjornstack.md#rule-test-pkg) | Pattern mappings | guard candidate |

## Rules

Each rule below is the wording go.md takes. Source lines cite
google/styleguide at `a9c5f82`, read 2026-11-16; G is `go/guide.md`,
D is `go/decisions.md`. Strategy citations are at bjornstack
`67b1213`.

### Tooling

<a id="rule-fmt-generated"></a>**fmt-generated.** Code a generator writes is formatted as `gofmt`
would format it, for example by passing it through `go/format.Source`
before writing.
Source: G:400-401 "Formatting", `a9c5f82`, read 2026-11-16.
↩ row [11](#row-11)

### Pattern mappings

<a id="rule-pkg-name-shadow"></a>**pkg-name-shadow.** Don't name a package after a common local
variable name: `usercount`, not `count`.
Source: D:88-90 "Package names", `a9c5f82`, read 2026-11-16.
↩ row [18](#row-18)

<a id="rule-name-context"></a>**name-context.** A name leaves out what its context already says:
the package path, the type, the method, the file. `reporting.Report`,
not `AdsTargetingRevenueReport`; `(*Project).Name`, not `ProjectName`;
`sqldb.Connection`, not `DBConnection`; a local `count` inside
`UserCount`. Judge repetition where the name is used.
Source: D:352-355 "Variable names", D:451-538 "External context vs.
local names", `a9c5f82`, read 2026-11-16.
↩ row [35](#row-35)

<a id="rule-ctx-returns-error"></a>**ctx-returns-error.** A function that takes a `context.Context`
usually returns an `error`, so its caller learns whether the context
was cancelled during the call.
Source: D:1092-1094 "Returning errors", `a9c5f82`, read 2026-11-16.
↩ row [54](#row-54)

<a id="rule-err-handle"></a>**err-handle.** Every returned error is handled, returned, or, in
exceptional cases, ends the program. Discard one with `_` only when it
cannot fail, with a comment saying why:
`n, _ := b.Write(p) // never returns a non-nil error`.
Source: D:1142-1163 "Handle errors", `a9c5f82`, read 2026-11-16.
↩ rows [57](#row-57), [58](#row-58)

<a id="rule-err-in-band"></a>**err-in-band.** A function signals a missing or failed result with an
extra, last result, `ok bool` when no explanation is needed or `error`
otherwise, never with a value such as -1, "" or nil.
Source: D:1177-1231 "In-band errors", `a9c5f82`, read 2026-11-16.
↩ row [59](#row-59)

<a id="rule-err-no-panic"></a>**err-no-panic.** Normal errors are returned, never panicked. In
`package main` and initialization code, an error that should end the
program, such as invalid configuration, is printed and the program
exits without a stack trace; deferred functions do not run on
`os.Exit`. A bug that should be impossible may return an error or end
the program.
Source: D:2127-2141 "Don't panic", `a9c5f82`, read 2026-11-16.
Differs: Google ends the program with its glog `log.Exit` and
`log.Fatal`; we don't use glog.
↩ rows [82](#row-82), [83](#row-83)

<a id="rule-go-lifetime"></a>**go-lifetime.** Every goroutine's end is evident. Keep the
synchronization in the function that starts it, for example a
`sync.WaitGroup` waited on before return and a ctx the work honours,
and factor the work into synchronous functions. Where it is still not
obvious, document when and why the goroutine exits.
Source: D:2243-2297 "Goroutine lifetimes", `a9c5f82`, read 2026-11-16.
↩ row [86](#row-86)

<a id="rule-iface-need"></a>**iface-need.** Define an interface only for a real need, named for
the behaviour it needs, not for a pattern such as "service" or
"repository". A coordinator's direct collaborator is such a need: the
coordinator receives it fully set up and its tests replace it with a
double (Unit Testing steps 3.2-3.3, `testing__unit.md:27-52`), as an
interface or a function type (coord-doubles).
Source: D:2347-2354 "Interfaces", `a9c5f82`, read 2026-11-16.
Differs: Google says not to wrap RPC clients in interfaces "just for
the sake of abstraction or testing"; Unit Testing replaces every
direct collaborator with a double.
↩ row [87](#row-87)

<a id="rule-double-package"></a>**double-package.** A test double stays in the test file that uses
it. A stateful double, one whose later results depend on earlier
calls, moves under the builders' entry point `test/a` once a second
test file in its interface's domain needs it, or a test outside that
domain does, and only after it passes that interface's compliance
suite (Test Data Builders step 2, `test-data-builders.md:21-41`).
Source: D:2360-2363 "Interfaces", `a9c5f82`, read 2026-11-16.
Differs: Google puts doubles for an impractical real implementation in
a dedicated package such as `spannertest`; Test Data Builders keeps
them in the test file or under the single entry point.
↩ row [90](#row-90)

<a id="rule-iface-small"></a>**iface-small.** Keep interfaces small. Document an interface's
contract, its edge cases and the errors it returns. Leave an interface
unexported when only its own package uses it.
Source: D:2365-2368 "Interfaces", `a9c5f82`, read 2026-11-16.
↩ row [91](#row-91)

<a id="rule-iface-consumer"></a>**iface-consumer.** The package that uses an interface defines it,
with only the methods it calls. The implementing package exports an
interface only when the interface itself is the product, such as a
common protocol.
Source: D:2370-2373 "Interfaces", `a9c5f82`, read 2026-11-16.
↩ row [92](#row-92)

<a id="rule-iface-return-concrete"></a>**iface-return-concrete.** Functions accept interfaces and return
concrete types, except where an interface is the point: `error`, and
command, chaining, factory or strategy patterns.
Source: D:2375-2383 "Interfaces", `a9c5f82`, read 2026-11-16.
↩ row [93](#row-93)

<a id="rule-sync-funcs"></a>**sync-funcs.** Prefer synchronous functions: they return their
results and finish their callbacks and channel operations before
returning. A caller that wants concurrency starts the goroutine.
Source: D:2676-2687 "Synchronous functions", `a9c5f82`, read
2026-11-16.
↩ row [104](#row-104)

<a id="rule-flags-main"></a>**flags-main.** Command-line flags are defined only in
`package main`. Other packages take their configuration as function
arguments or struct fields; importing a package never adds flags. An
exported global variable is a rare last resort, and a coordinator
never reads one: global state it reads is a hidden collaborator (Unit
Testing step 3.2, `testing__unit.md:27-32`). Global flag variables sit
in their own `var` group after the imports.
Source: D:2779-2790 "Flags", `a9c5f82`, read 2026-11-16.
Differs: Google allows, in extremely rare cases, a library flag named
for its package; we keep flags in `main`.
↩ rows [109](#row-109), [110](#row-110)

<a id="rule-ctx-sources"></a>**ctx-sources.** Code takes ctx from its caller, unless the caller's
is the wrong one. Where no caller hands one over: an HTTP handler uses
`r.Context()`, a streaming RPC method the stream's `Context()`, a test
`t.Context()` (ctx-test), and `main` or `init` `context.Background()`.
Below an entry point, only a server framework that builds a context
per request creates one; any other `context.Background()` there is
raised in review.
Source: D:2858-2896 "Contexts", `a9c5f82`, read 2026-11-16.
Differs: Google sends other uses to its Go style mailing list.
↩ rows [113](#row-113), [114](#row-114)

<a id="rule-test-helper-params"></a>**test-helper-params.** A test helper takes `ctx` first, then `t`,
then the rest: `readTestFile(ctx, t, path)`.
Source: D:2898-2904 "Contexts", D:3880-3883 "Test helpers",
`a9c5f82`, read 2026-11-16.
↩ row [115](#row-115)

<a id="rule-ctx-test"></a>**ctx-test.** A test or subtest gets its ctx from the innermost
`t.Context()`, not `context.Background()`, and passes it explicitly to
helpers, double setup and anything else that needs one.
Source: D:2914-2918 "Contexts", `a9c5f82`, read 2026-11-16.
↩ row [117](#row-117)

<a id="rule-ctx-no-custom"></a>**ctx-no-custom.** No custom context types, and no interface other
than `context.Context` in a signature.
Source: D:2949-2957 "Custom contexts", `a9c5f82`, read 2026-11-16.
↩ row [120](#row-120)

<a id="rule-test-input-in-message"></a>**test-input-in-message.** When a case's name does not show the input
that matters and the input is short, the assertion message includes
it.
Source: D:3137-3141 "Identify the input", `a9c5f82`, read 2026-11-16.
Differs: Google also asks for the function name and inputs in every
message; `require` prints expected and actual, and the case name
(test-names) states the situation.
↩ row [128](#row-128)

<a id="rule-test-stable-output"></a>**test-stable-output.** Don't compare output whose exact bytes a
package you don't own decides, such as `json.Marshal`'s: parse it and
compare the structure (Whole-Object Assertion misapplication
"serialized representations", `whole-object-assertion.md:62-64`).
Source: D:3210-3220 "Compare stable results", `a9c5f82`, read
2026-11-16.
↩ row [133](#row-133)

<a id="rule-test-failure-detail"></a>**test-failure-detail.** When a test calls the code under test more
than once, the message says which call failed, and includes any other
state needed to understand the failure. A setup failure says which
setup step failed and its error, without the test's inputs.
Source: D:3373-3384 "Level of detail", `a9c5f82`, read 2026-11-16.
↩ rows [140](#row-140), [142](#row-142)

<a id="rule-test-diff-key"></a>**test-diff-key.** A message around a `cmp.Diff` says which side is
which, `(-want +got)` for `cmp.Diff(want, got, protocmp.Transform())`,
and puts the diff on a new line.
Source: D:3421-3445 "Print diffs", `a9c5f82`, read 2026-11-16.
Differs: Google applies it to every diff; we only call `cmp.Diff` for
protobuf messages (test-protobuf).
↩ row [146](#row-146)

<a id="rule-test-name-chars"></a>**test-name-chars.** Case names contain no `/`, which splits a
`-run` filter, and no non-printing characters. Spaces are fine; the
runner shows them as underscores.
Source: D:3523-3550 "Subtest names", `a9c5f82`, read 2026-11-16.
Differs: Google also asks to avoid spaces and to keep names short like
identifiers; test-names keeps sentences.
↩ rows [153](#row-153), [154](#row-154)

### Go pitfalls

<a id="rule-err-results"></a>**err-results.** When a function returns a non-nil error, its other
results are unspecified unless its documentation says otherwise; the
caller does not use them.
Source: D:1063-1067 "Returning errors", `a9c5f82`, read 2026-11-16.
↩ row [52](#row-52)

<a id="rule-err-interface-return"></a>**err-interface-return.** An exported function returns `error`, never
a concrete error type such as `*os.PathError`: a nil pointer of that
type becomes a non-nil `error`. An identity type (Failure Identity
step 2) is returned as `error` and matched with `errors.As`.
Source: D:1081-1090 "Returning errors", `a9c5f82`, read 2026-11-16.
↩ row [53](#row-53)

<a id="rule-copy-safety"></a>**copy-safety.** Don't copy a value whose type has pointer-receiver
methods, such as `bytes.Buffer` or a struct holding a `sync.Mutex`; a
value receiver or value parameter copies it silently. An API over a
struct with such fields takes and returns pointers.
Source: D:2063-2119 "Copying", `a9c5f82`, read 2026-11-16.
↩ rows [80](#row-80), [81](#row-81)

<a id="rule-switch-break-loop"></a>**switch-break-loop.** `break` inside a `switch` inside a `for`
leaves only the switch. To leave the loop, label it and
`break label`.
Source: D:2646-2668 "`switch` and `break`", `a9c5f82`, read
2026-11-16.
↩ row [103](#row-103)

<a id="rule-ctx-cleanup"></a>**ctx-cleanup.** `t.Context()` is cancelled before the functions
given to `t.Cleanup` run. Cleanup code, such as a compliance-suite
factory's (compliance-suite), uses `context.WithoutCancel(ctx)` or
`context.Background()`.
Source: D:2920-2923 "Contexts", `a9c5f82`, read 2026-11-16.
↩ row [118](#row-118)

<a id="rule-crypto-rand"></a>**crypto-rand.** Keys, even throwaway ones, come from `crypto/rand`,
never `math/rand`; encode them as hex or base64 for text.
Source: D:2970-2996 "crypto/rand", `a9c5f82`, read 2026-11-16.
↩ row [122](#row-122)

<a id="rule-cmp-test-only"></a>**cmp-test-only.** `github.com/google/go-cmp` is for tests only: it
may panic on a comparison it considers wrong, so production code never
imports it.
Source: D:3359-3363 "Equality comparison and diffs", `a9c5f82`, read
2026-11-16.
↩ row [139](#row-139)

### For the protocols

<a id="rule-least-mechanism"></a>**least-mechanism.** Where several ways express the same idea, use
the most standard one: a core language construct (slice, map,
channel, loop, struct) first, then the standard library, then a
dependency the module already has, before adding a dependency or
writing your own. A set is a `map[T]bool` unless it needs operations
that are impossible or awkward with a map.
Source: G:184-208 "Least mechanism", `a9c5f82`, read 2026-11-16.
Differs: Google's third tier is "a core library in the Google
codebase".
↩ rows [4](#row-4), [6](#row-6)

<a id="rule-err-boost-signal"></a>**err-boost-signal.** An error check that differs from the usual
`if err != nil` shape, such as `if err == nil`, carries a comment that
points it out.
Source: G:250-260 "Concision", `a9c5f82`, read 2026-11-16.
↩ row [7](#row-7)

<a id="rule-explicit-critical"></a>**explicit-critical.** Where one character decides a line's meaning,
such as `=` instead of `:=` in an `if` initializer or a `!` inside a
compound condition, write it out more explicitly or add a comment
that calls it out.
Source: G:295-340 "Maintainability", `a9c5f82`, read 2026-11-16.
↩ row [8](#row-8)

<a id="rule-name-predictable"></a>**name-predictable.** Parameters and receivers that stand for the same
concept have the same name throughout a package.
Source: G:346-351 "Maintainability", `a9c5f82`, read 2026-11-16.
↩ row [9](#row-9)

<a id="rule-name-mixedcaps"></a>**name-mixedcaps.** Multi-word names use `MixedCaps` or `mixedCaps`,
constants included: `MaxLength`, never `MAX_LENGTH`, `kMaxLength` or
`max_length`. Local variables count as unexported. Generated protobuf
code and code that mirrors the operating system's interface, as
`syscall` does, are exempt.
Source: G:408-426 "MixedCaps"; D:168-197 "Constant names"; `a9c5f82`,
read 2026-11-16.
↩ rows [12](#row-12), [25](#row-25)

<a id="rule-fmt-line-length"></a>**fmt-line-length.** Go has no fixed line length. A long line is
shortened by refactoring, such as extracting a local, not by
splitting it; if it is as short as is practical, it stays long. Never
split a line before an indentation change: function signatures and
`if`, `for`, `switch` and `case` lines stay on one line. A call is
split only to group its arguments by meaning, when the API cannot
change or the call is unusual, never for length alone. Long string
literals are never broken; arguments may follow the format string on
later lines. Where a break that lines up with an indented block cannot
be avoided, leave a space to separate them; an over-long `case` list
puts every case on its own indented line, followed by a blank line.
Source: G:432-442 "Line length"; D:1749-2033 "Indentation confusion",
"Function formatting", "Conditionals and loops"; `a9c5f82`, read
2026-11-16.
↩ rows [13](#row-13), [72](#row-72), [73](#row-73), [74](#row-74), [76](#row-76), [77](#row-77), [78](#row-78)

<a id="rule-name-underscores"></a>**name-underscores.** Go names contain no underscores, except:
`Test`, `Benchmark` and `Example` function names in `_test.go` files;
packages imported only by generated code; test packages named with a
`_test` suffix (`linkedlist_test`, `linked_list_service_test`); and
low-level code that interoperates with the operating system or cgo
reusing its identifiers. File names may contain underscores.
Source: D:58-73 "Underscores", D:92-110 "Package names", `a9c5f82`,
read 2026-11-16.
↩ row [16](#row-16)

<a id="rule-import-rename"></a>**import-rename.** Imports keep their package name, except in these
cases, taken in order:
1. Two imports collide: rename the more local or project-specific
   one.
2. The package name has an underscore, as generated protobuf packages
   do: rename it, with a `pb` suffix for protobuf
   (`foosvcpb "path/to/foo_service_go_proto"`).
3. The import collides with a local variable you need while the
   package is in use: add a `pkg` suffix (`urlpkg`).
4. The name is uninformative (`util`, `v1`) and the surrounding code
   gives too little context: rename it, sparingly, and prefer giving
   the package a better name.

A local name follows the package-name rules (lower case, no
underscores) and is the same in every file that imports the package.
Source: D:92-94 "Package names", D:125-130, D:885-933 "Import
renaming", `a9c5f82`, read 2026-11-16.
↩ rows [20](#row-20), [21](#row-21), [22](#row-22), [23](#row-23)

<a id="rule-recv-name"></a>**recv-name.** A receiver's name is one or two letters abbreviating
its type, the same on every method of that type: `func (w
*ReportWriter)`. Never `this`, `self` or `_`; omit the name when the
method does not use it.
Source: D:148-160 "Receiver names", `a9c5f82`, read 2026-11-16.
↩ row [24](#row-24)

<a id="rule-const-role"></a>**const-role.** Name a constant for what its value means
(`MaxPacketSize`), not for the value (`Twelve`). A value with no
meaning beyond itself needs no constant.
Source: D:199-212 "Constant names", `a9c5f82`, read 2026-11-16.
↩ row [26](#row-26)

<a id="rule-name-initialisms"></a>**name-initialisms.** An initialism keeps one case: `URL` or `url`,
`ID` or `id`, `DB` or `db`, never `Url` or `Id`. In a name with several
initialisms each is consistent on its own (`XMLAPI`, `xmlAPI`). An
initialism with a lower-case letter (`iOS`, `gRPC`, `DDoS`) is written
as in prose, unless exporting changes its first letter; then the whole
initialism takes one case (`IOS`, `GRPC`, `ddos`). Generated protobuf
code and operating-system interfaces are exempt.
Source: D:228-268 "Initialisms", `a9c5f82`, read 2026-11-16.
↩ row [27](#row-27)

<a id="rule-name-getters"></a>**name-getters.** No `Get` prefix, unless the concept itself is
"get", as in HTTP GET: `Counts`, not `GetCounts`. A function that
computes heavily or calls a remote service may be named `Compute…` or
`Fetch…`, so the reader expects it to take time or fail.
Source: D:276-291 "Getters", `a9c5f82`, read 2026-11-16.
↩ rows [28](#row-28), [29](#row-29)

<a id="rule-name-var"></a>**name-var.** A variable's name grows with its scope and shrinks with
how often it is used: as a rough guide, one or two operations over
1-7 lines may use a letter or two, and a scope longer than a page
needs words. Name what the value holds and how it is used here, not
where it came from. Don't drop letters to save typing (`Sandbox`, not
`Sbx`). Leave type words out (`users`, not `userSlice`; `userCount`,
not `numUsers`) unless two forms of the value are in scope
(`limitRaw` and `limit`). Single letters only where the full word is
obvious: receivers, `r` for an `io.Reader` or `*http.Request`, `w` for
an `io.Writer` or `http.ResponseWriter`, `i`, `x` and `y` for indices
and coordinates, and short loop variables such as `n` over `nodes`.
Source: D:295-379 "Variable names", D:419-447 "Variable name vs.
type", `a9c5f82`, read 2026-11-16.
↩ rows [30](#row-30), [31](#row-31), [32](#row-32), [33](#row-33), [34](#row-34)

<a id="rule-doc-comments"></a>**doc-comments.** Every exported top-level name has a doc comment, and
so does an unexported type or function whose behaviour or meaning is
not obvious. A doc comment is full sentences and begins with the name
it documents, unexported names included; an article may come first.
Godoc formatting: indent lists and code; no other decoration.
Exception: builder methods in `test/a` have no doc comments
(builders-a).
Source: D:557-559 "Commentary", D:612-661 "Doc comments", `a9c5f82`,
read 2026-11-16.
Differs: Google has no exception for builder methods.
↩ rows [38](#row-38), [40](#row-40), [41](#row-41)

<a id="rule-comment-wrap"></a>**comment-wrap.** Wrap long comment lines so they read in tools that
don't wrap, around 80 or 100 columns. It is not a hard limit: a long
URL stays whole. Wrap consistently within a file.
Source: D:566-608 "Comment line length", `a9c5f82`, read 2026-11-16.
↩ row [39](#row-39)

<a id="rule-comment-sentences"></a>**comment-sentences.** A comment written as a sentence is
capitalized and punctuated; it may start with a lower-case identifier.
Fragments, such as end-of-line comments on struct fields, need
neither.
Source: D:665-698 "Comment sentences", `a9c5f82`, read 2026-11-16.
↩ row [42](#row-42)

<a id="rule-doc-examples"></a>**doc-examples.** A package documents its intended use, where
feasible with a runnable `Example` function in a `_test.go` file;
otherwise with example code in a comment, formatted like code.
Source: D:704-718 "Examples", `a9c5f82`, read 2026-11-16.
↩ row [43](#row-43)

<a id="rule-named-results"></a>**named-results.** Name results only when it helps the caller: several
results of the same type, or a result the caller must act on
(`cancel func()`). Don't name them when the name repeats the type, to
avoid declaring a local, or to allow naked returns. Naked returns only
in small functions. A result a deferred closure changes may always be
named.
Source: D:722-797 "Named result parameters", `a9c5f82`, read
2026-11-16.
↩ rows [44](#row-44), [45](#row-45)

<a id="rule-pkg-comment"></a>**pkg-comment.** Each package has exactly one package comment,
directly above the `package` clause with no blank line between; a
long one may go in a `doc.go` holding only the comment and the clause.
In `package main` the comment names the command as it is invoked:
"The seed_generator command …", "Command seed_generator …", with the
first word capitalized.
Source: D:801-875 "Package comments", `a9c5f82`, read 2026-11-16.
Differs: Google takes the command's name from the Bazel `go_binary`
rule; we use the binary's name.
↩ rows [46](#row-46), [47](#row-47)

<a id="rule-import-groups"></a>**import-groups.** Imports come in up to four groups, in this order,
separated by blank lines: the standard library; other packages;
protobuf packages; side-effect (`_`) imports.
Source: D:937-969 "Import grouping", `a9c5f82`, read 2026-11-16.
↩ row [48](#row-48)

<a id="rule-import-blank"></a>**import-blank.** `import _` appears only in `package main` or in a
test that needs it, except `_ "embed"` in a file that uses
`//go:embed`. A library that relies on a side-effect import in
production documents it.
Source: D:973-1003 "Import blank", `a9c5f82`, read 2026-11-16.
Differs: Google also allows a blank import to bypass its nogo
checker; we run none.
↩ row [49](#row-49)

<a id="rule-import-dot"></a>**import-dot.** Never `import .`.
Source: D:1007-1042 "Import dot", `a9c5f82`, read 2026-11-16.
↩ row [50](#row-50)

<a id="rule-err-last"></a>**err-last.** `error` is a function's last result.
Source: D:1050-1055 "Returning errors", `a9c5f82`, read 2026-11-16.
↩ row [51](#row-51)

<a id="rule-err-strings"></a>**err-strings.** Error strings start lower-case, unless they begin
with an exported name, a proper noun or an acronym, and end without
punctuation, because they are read inside other messages.
Source: D:1100-1119 "Error strings", `a9c5f82`, read 2026-11-16.
↩ row [55](#row-55)

<a id="rule-err-indent-flow"></a>**err-indent-flow.** Handle an error, or any condition that ends in
`return`, `continue`, `panic` or an exit, first, and keep the normal
path unindented: no `else` after such a block. A variable used for
more than a few lines is declared before the `if`, not in its
initializer.
Source: D:1237-1296 "Indent error flow", `a9c5f82`, read 2026-11-16.
↩ rows [60](#row-60), [61](#row-61)

<a id="rule-lit-composite"></a>**lit-composite.** Build a value with a composite literal rather than
field by field, where possible.
Source: D:1310-1317 "Literal formatting", `a9c5f82`, read 2026-11-16.
↩ row [62](#row-62)

<a id="rule-lit-field-names"></a>**lit-field-names.** A struct literal of a type from another package
names its fields. For a type from the same package names are
optional; use them when it reads better, and almost always for a
struct with many fields.
Source: D:1323-1374 "Field names", `a9c5f82`, read 2026-11-16.
↩ rows [63](#row-63), [64](#row-64)

<a id="rule-lit-braces"></a>**lit-braces.** A multi-line literal's closing brace sits on its own
line at the indentation of the line with the opening brace, and the
last element ends with a comma. Braces are cuddled (`[]*T{{` …
`}, {` … `}}`) only when the indentation still matches and the inner
values are literals or proto builders.
Source: D:1378-1483 "Matching braces", "Cuddled braces", `a9c5f82`,
read 2026-11-16.
↩ rows [65](#row-65), [66](#row-66)

<a id="rule-lit-elide-types"></a>**lit-elide-types.** Leave repeated element types out of slice and
map literals: `{A: 42}`, not `&Type{A: 42}`; `gofmt -s` removes them.
Repeat them only for a complex type uncommon in the project whose
lines are far apart.
Source: D:1487-1532 "Repeated type names", `a9c5f82`, read 2026-11-16.
↩ row [67](#row-67)

<a id="rule-lit-zero-fields"></a>**lit-zero-fields.** In production code, a struct literal may leave
out zero-value fields when no clarity is lost.
Source: D:1536-1583 "Zero-value fields", `a9c5f82`, read 2026-11-16.
Differs: Google extends this to table-test cases; test-table requires
every field in every case.
↩ row [68](#row-68)

<a id="rule-nil-slice"></a>**nil-slice.** Declare an empty local slice as `var s []T`, not
`s := []T{}`. No API makes its callers tell a nil slice from an empty
one; test emptiness with `len(s) == 0`, not `s == nil`.
Source: D:1642-1743 "Nil slices", `a9c5f82`, read 2026-11-16.
↩ rows [70](#row-70), [71](#row-71)

<a id="rule-fmt-arg-comments"></a>**fmt-arg-comments.** No inline comments on call arguments
(`42, // Port`); use an options struct or describe the parameter in
the function's documentation.
Source: D:1819-1836 "Function formatting", `a9c5f82`, read 2026-11-16.
↩ row [75](#row-75)

<a id="rule-cond-no-yoda"></a>**cond-no-yoda.** When comparing a variable with a constant, the
variable goes on the left: `if result == "foo"`.
Source: D:2035-2055 "Conditionals and loops", `a9c5f82`, read
2026-11-16.
↩ row [79](#row-79)

<a id="rule-must-funcs"></a>**must-funcs.** A function that stops the program on failure is named
`MustXYZ` or `mustXYZ` and is called only early at startup, typically
to set a package-level value (`regexp.MustCompile`), never on user
input or where the error could be handled, even after some
refactoring. In tests, a `mustXYZ` helper may stop the current test:
it calls `t.Helper()` and fails with `require.NoError`.
Source: D:2146-2235 "Must functions", `a9c5f82`, read 2026-11-16.
Differs: Google's test helpers call `t.Fatal`; we use `require`
(test-require).
↩ rows [84](#row-84), [85](#row-85)

<a id="rule-generics"></a>**generics.** Use generics where they meet a real requirement, not by
default (least-mechanism). When only one type is used, write the code
for that type. When several types share a useful interface, use the
interface; otherwise prefer generics to `any` and heavy type
switching. Document an exported generic API, ideally with a runnable
example. Don't use generics to build domain-specific languages or
error-handling frameworks.
Source: D:2397-2440 "Generics", `a9c5f82`, read 2026-11-16.
Differs: Google also warns against generic assertion libraries;
testify is the owner's choice (test-require).
↩ rows [94](#row-94), [95](#row-95), [96](#row-96), [97](#row-97), [98](#row-98)

<a id="rule-pass-values"></a>**pass-values.** Don't pass a pointer only to save bytes: an argument
read only as `*x`, such as a `*string` or `*io.Reader`, is passed by
value. Large structs, structs that may grow, and protobuf messages go
by pointer.
Source: D:2444-2459 "Pass values", `a9c5f82`, read 2026-11-16.
↩ row [99](#row-99)

<a id="rule-recv-type"></a>**recv-type.** Choose the receiver kind for correctness first. Use a
pointer when the method mutates the receiver, when the struct holds
fields that must not be copied (copy-safety), when it holds pointers
to things that may be mutated, when it is large, or when the method
must see concurrent changes to it. Use a value for a slice the method
does not reslice or reallocate, a map, function or channel, a
built-in type that is not modified, a small immutable struct with no
pointers, or when the method must not see concurrent changes. When in
doubt, use a pointer. As a general guideline, all of a type's methods
are pointer methods or all are value methods. A claim that one kind is
faster needs a realistic benchmark.
Source: D:2461-2605 "Receiver type", `a9c5f82`, read 2026-11-16.
↩ rows [100](#row-100), [101](#row-101)

<a id="rule-switch-break"></a>**switch-break.** No bare `break` at the end of a `switch` clause;
a comment explains an empty clause.
Source: D:2609-2644 "`switch` and `break`", `a9c5f82`, read
2026-11-16.
↩ row [102](#row-102)

<a id="rule-type-alias"></a>**type-alias.** Define a new type with `type T1 T2`. Use an alias,
`type T1 = T2`, only when needed, mainly to help move a package.
Source: D:2694-2703 "Type aliases", `a9c5f82`, read 2026-11-16.
↩ row [105](#row-105)

<a id="rule-fmt-q"></a>**fmt-q.** Quote strings in output for humans with `%q`, not `"%s"` or
`'%s'`, so an empty or odd value stands out.
Source: D:2707-2734 "Use %q", `a9c5f82`, read 2026-11-16.
↩ row [106](#row-106)

<a id="rule-use-any"></a>**use-any.** New code writes `any`, not `interface{}`.
Source: D:2736-2743 "Use any", `a9c5f82`, read 2026-11-16.
↩ row [107](#row-107)

## Dropped

One section per drop row: what the source says, what it would have
meant in practice, and why it was dropped.

### <a id="drop-1"></a>Row 1: Principles in order, consistency last

Source: G:25-35 lists clarity, simplicity, concision, maintainability and consistency "in order of importance"; G:371-372: "Consistency concerns do not override any of the principles above".

In practice: An author could depart from an established pattern whenever a clearer or simpler form exists.

Dropped because: The Consistent Beats Correct tenet says the opposite: follow established patterns even when a locally better approach exists, and change a pattern everywhere or not at all.

↩ row [1](#row-1)

### <a id="drop-2"></a>Row 2: Comments explain why, not what

Source: G:99-105: "It is often better for comments to explain why something is done, not what the code is doing."

In practice: The same convention bjornstack.md row 70 dropped.

Dropped because: Language-neutral; bs-cbr's strategy owns where reasoning lives (bjornstack.md row 70).

↩ row [2](#row-2)

### <a id="drop-3"></a>Row 3: Deliberate, documented complexity

Source: G:155-162: "When code needs complexity, the complexity should be added deliberately ... it should come with accompanying documentation".

In practice: A general design principle with no Go-specific form.

Dropped because: Language-neutral.

↩ row [3](#row-3)

### <a id="drop-5"></a>Row 5: Override flag-bound variables in tests

Source: G:199-203: tests should "override the bound value directly rather than by using `flag.Set`".

In practice: A test sets a package-level variable that a flag is bound to.

Dropped because: Flags live only in `package main` (flags-main); a test reaches a binary through its command line (bjornstack.md bb-package) and a package only through its exports (test-pkg), so neither touches the bound variable.

↩ row [5](#row-5)

### <a id="drop-14"></a>Row 14: Local consistency where the guide is silent

Source: G:463-466: authors may choose their style "unless the code in close proximity ... has taken a consistent stance".

In practice: Follow the surrounding code's choice on points the guide leaves open.

Dropped because: Consistent Beats Correct says it for every language.

↩ row [14](#row-14)

### <a id="drop-15"></a>Row 15: Don't worsen a style deviation

Source: G:483-489: if a change would worsen a deviation, "clean up the existing codebase in the same CL, perform a refactor in advance of the current CL, or find an alternative".

In practice: Fix an existing deviation before spreading it.

Dropped because: Language-neutral: Consistent Beats Correct's "changed everywhere it appears" and Tidy or Change's structural-first commits cover it.

↩ row [15](#row-15)

### <a id="drop-37"></a>Row 37: Use doc preview

Source: D:553-555: "Use doc preview during development and code review".

In practice: Render the package documentation before merging.

Dropped because: A review habit, not a rule for code; nothing in tool-finish runs it.

↩ row [37](#row-37)

### <a id="drop-56"></a>Row 56: Capitalize displayed messages

Source: D:1121-1124: the full displayed message (logging, test failure, API response) "should typically be capitalized".

In practice: `t.Errorf("Op(%q) failed ...")`, `log.Infof("Operation aborted: %v", err)`.

Dropped because: Assertion messages follow bjornstack.md test-messages ("expected the total to include tax"); log messages come from ctx-scope's logger, which this guide does not describe.

↩ row [56](#row-56)

### <a id="drop-69"></a>Row 69: Table cases omit zero-valued fields

Source: D:1585-1591: table-test structs let the author "omit the zero-valued fields entirely when the fields in question are not related to the test case".

In practice: A success case leaves out `wantErr`.

Dropped because: bjornstack.md test-table says every case sets every field, and Parameterized Test Structure step 2's Bad case is exactly a case that leaves out an empty `expectedError`.

↩ row [69](#row-69)

### <a id="drop-88"></a>Row 88: No interfaces around RPC clients for testing

Source: D:2351-2354: "Do not wrap RPC clients in new manual interfaces just for the sake of abstraction or testing. Use real transports instead".

In practice: A coordinator calling an RPC client is tested against a real transport with a fake server, not a double.

Dropped because: Unit Testing step 3.3 replaces every direct collaborator of a coordinator with a double; bjornstack.md coord-doubles spells it, and iface-need records the difference.

↩ row [88](#row-88)

### <a id="drop-108"></a>Row 108: snake_case flag names

Source: D:2755-2761: Google's internal flag package; "the flag name should be in snake case, and the variable name should be the equivalent name in camel case".

In practice: `flag.Duration("poll_interval", ...)`.

Dropped because: It is tied to Google's internal flag package, and nothing in our material chooses a flag-name style.

↩ row [108](#row-108)

### <a id="drop-111"></a>Row 111: Google's log package

Source: D:2810-2822: programs use Google's `log` (glog); prefer `log.Info(v)` over `log.Infof("%v", v)`.

In practice: Logging through glog's package-level functions.

Dropped because: We log through the logger in ctx (bjornstack.md ctx-scope, `logctx.From(ctx)`), never a package-level logger.

↩ row [111](#row-111)

### <a id="drop-119"></a>Row 119: Internal context detachment package

Source: D:2929-2932: background operations that outlive the parent "can use an internal package for detachment".

In practice: A Google-internal helper.

Dropped because: Google-internal; not available to us.

↩ row [119](#row-119)

### <a id="drop-121"></a>Row 121: Where application data goes

Source: D:2959-2960: "put it in a parameter, in the receiver, in globals, or in a `Context` value if it truly belongs there".

In practice: Globals as one accepted home for application data.

Dropped because: bjornstack.md ctx-scope limits what ctx carries, and coord-globals with Unit Testing step 3.2 limits globals to metrics.

↩ row [121](#row-121)

### <a id="drop-123"></a>Row 123: No assertion libraries

Source: D:3022: "Do not create 'assertion libraries' as helpers for testing"; D:4002-4005: package `testing` "is the only testing framework permitted ... assertion libraries and third-party testing frameworks are not allowed".

In practice: Tests written with `if` and `t.Errorf` only.

Dropped because: The owner chose testify `require` (bjornstack.md test-require, rows 39, 57, 90).

↩ row [123](#row-123)

### <a id="drop-124"></a>Row 124: Compare with cmp and fmt

Source: D:3071-3072: "Prefer using standard libraries such as `cmp` and `fmt`"; D:3291-3293: "Use `cmp.Equal` for equality comparison and `cmp.Diff` to obtain a human-readable diff".

In practice: `if !cmp.Equal(got, want) { t.Errorf(...) }` everywhere.

Dropped because: We compare with `require.Equal` (test-require, test-whole-value); `cmp.Diff` is kept for protobuf messages only (test-protobuf).

↩ row [124](#row-124)

### <a id="drop-125"></a>Row 125: Comparison helpers return values

Source: D:3089-3091: "prefer returning a value or an error that can be used in the test's failure message instead of passing `*testing.T`".

In practice: Helpers like `postLength(p)` compared in the test body.

Dropped because: Parameterized Test Structure step 3 and bjornstack.md test-table carry assertion functions that take `t` and assert.

↩ row [125](#row-125)

### <a id="drop-126"></a>Row 126: Test non-trivial helpers directly

Source: D:3107-3108: "Were `postLength` non-trivial, it would make sense to test it directly".

In practice: A computation used by tests gets its own tests.

Dropped because: Language-neutral; Unit Testing step 2 tests computation directly.

↩ row [126](#row-126)

### <a id="drop-127"></a>Row 127: Name the function in the message

Source: D:3130-3131: "your failure message should be `YourFunc(%v) = %v, want %v` instead of just `got %v, want %v`".

In practice: Every hand-written failure message repeats the call.

Dropped because: `require` prints expected and actual; the test and case names (test-names) and the "expected ..." message (test-messages) say what was called.

↩ row [127](#row-127)

### <a id="drop-129"></a>Row 129: Got before want

Source: D:3147-3150: print the actual value before the expected one; use "got" and "want".

In practice: Message order and wording for hand-written comparisons.

Dropped because: `require.Equal(t, want, got)` fixes the argument order and labels both sides itself (test-whole-value).

↩ row [129](#row-129)

### <a id="drop-131"></a>Row 131: cmpopts for approximate or uncomparable fields

Source: D:3173-3178: tweak `cmp.Diff` or `cmp.Equal` with `cmpopts` options such as `cmpopts.IgnoreInterfaces`.

In practice: `cmp` with options as the general escape for awkward fields.

Dropped because: bjornstack.md test-protobuf gives `cmp` no role beyond protobuf; Whole-Object Assertion step 2 accounts for fields that can't be compared exactly (inject, capture and verify, or zero both sides).

↩ row [131](#row-131)

### <a id="drop-134"></a>Row 134: Keep going after a failure

Source: D:3233-3235: "Prefer calling `t.Error` over `t.Fatal` for reporting a mismatch"; D:3252-3254: `t.Fatal` when later failures would mislead.

In practice: Several independent `t.Error` checks per test.

Dropped because: bjornstack.md test-require: `require` stops at the first failure, and `assert` is only for deliberately independent failures; a whole-value comparison reports every differing field at once.

↩ row [134](#row-134)

### <a id="drop-137"></a>Row 137: The pretty library

Source: D:3333-3351: older code may keep using `pretty`; prefer `cmp` for new code.

In practice: Migration advice for a library we don't use.

Dropped because: Not in our stack; comparison is set by test-require.

↩ row [137](#row-137)

### <a id="drop-138"></a>Row 138: No reflect.DeepEqual

Source: D:3353-3357: "`reflect.DeepEqual` should not be used for checking equality, as it is sensitive to changes in unexported fields".

In practice: Equality checks only through `cmp`.

Dropped because: The owner chose `require.Equal`, which compares as `DeepEqual` does, because it catches a time-zone mismatch `cmp.Diff` hides (bjornstack.md test-require Differs, O-1103b).

↩ row [138](#row-138)

### <a id="drop-141"></a>Row 141: Describe only the important parts

Source: D:3377-3379: for a complex struct "it is acceptable to describe only the important parts in the message".

In practice: Trimmed failure output.

Dropped because: `require.Equal` prints the whole difference, and Whole-Object Assertion compares every field.

↩ row [141](#row-141)

### <a id="drop-143"></a>Row 143: Trigger the failure during development

Source: D:3386-3388: "Make your failure mode trigger during development. Review what the failure message looks like".

In practice: See each test fail once and read its output.

Dropped because: Language-neutral; Outside-In Development Loop step 1 already starts every test failing.

↩ row [143](#row-143)

### <a id="drop-144"></a>Row 144: %q, %+v and diffs in messages

Source: D:3390-3396: `%q` for strings, `%+v` for small structs, a diff for larger values.

In practice: Formatting of hand-written failure output.

Dropped because: `require` formats the values it prints; `%q` in a message we write is fmt-q (row 106).

↩ row [144](#row-144)

### <a id="drop-145"></a>Row 145: Print diffs

Source: D:3402-3408: for large output "make a diff"; "`cmp.Diff` is preferred".

In practice: Every large comparison prints a `cmp.Diff`.

Dropped because: `require.Equal` prints a diff itself; `cmp.Diff` stays for protobuf (test-protobuf, test-diff-key).

↩ row [145](#row-145)

### <a id="drop-147"></a>Row 147: No string comparison for error kinds

Source: D:3456-3459: "don't use string comparison to check what type of error your function returns. However, it is permissible ... to check that error messages ... satisfy certain properties".

In practice: Errors checked by identity, messages by their facts.

Dropped because: Failure Identity step 6 says it for every language.

↩ row [147](#row-147)

### <a id="drop-148"></a>Row 148: Semantic error information

Source: D:3461-3469: test semantic information, not display text; for a dependency without it, file a bug "rather than relying on parsing the error message".

In practice: No test or caller parses a message.

Dropped because: Failure Identity steps 2-3 and its misapplication "identity carried in the text" say it for every language.

↩ row [148](#row-148)

### <a id="drop-149"></a>Row 149: Non-nil is enough; errors.Is or EquateErrors

Source: D:3471-3475: "it is sufficient to only test whether the error was non-nil"; to match, "consider using `errors.Is` or `cmp` with `cmpopts.EquateErrors`".

In practice: Error tests that check presence only, or match through `cmp`.

Dropped because: Failure Identity step 6 also checks the facts in the message; identity is checked with `require.ErrorIs`/`require.ErrorAs` (bjornstack.md err-is-fresh-pointer), and `cmpopts.EquateErrors` is a recorded trap (err-equate-errors).

↩ row [149](#row-149)

### <a id="drop-150"></a>Row 150: Boolean wantErr

Source: D:3477-3480: make the want field a `bool` and compare with `!=`.

In practice: `if gotErr := err != nil; gotErr != test.wantErr`.

Dropped because: bjornstack.md test-table carries an assertion function per case instead of expected-error fields.

↩ row [150](#row-150)

### <a id="drop-151"></a>Row 151: Independent subtests

Source: D:3512-3514: "Subtests should not depend on the execution of other cases for success or initial state".

In practice: Any subtest runs alone with `-run`.

Dropped because: Isolated Test Execution's outcome that tests pass regardless of execution order says it for every language.

↩ row [151](#row-151)

### <a id="drop-152"></a>Row 152: Subtest names as identifiers

Source: D:3527-3528: "Think of subtest names more like a function identifier than a prose description"; D:3534-3536: a longer description goes in a separate field; D:3588-3589 calls a sentence-long name "too wordy".

In practice: Short names like `hu=en_bug-1234`.

Dropped because: bjornstack.md test-names and Parameterized Test Structure step 2 name cases as sentences that state the situation and outcome.

↩ row [152](#row-152)

### <a id="drop-155"></a>Row 155: When to use table-driven tests

Source: D:3605-3606: "Use table-driven tests when many different test cases can be tested using similar testing logic."

In practice: Parameterize cases that share logic.

Dropped because: Parameterized Test Structure step 1 says it for every language.

↩ row [155](#row-155)

### <a id="drop-156"></a>Row 156: Different logic, separate test functions

Source: D:3659-3661: "When some test cases need to be checked using different logic from other test cases, it is appropriate to write multiple test functions".

In practice: Success and error checks split into separate tests.

Dropped because: Parameterized Test Structure step 3 and bjornstack.md test-table encode differing checks as assertion functions in one table.

↩ row [156](#row-156)

### <a id="drop-157"></a>Row 157: Simple extra cases with a conditional

Source: D:3663-3667 and the `TestDivide` example: simple error cases may share the table, with `if err != nil { continue }` in the body.

In practice: A conditional in the test body.

Dropped because: bjornstack.md test-table: the body has no conditionals.

↩ row [157](#row-157)

### <a id="drop-158"></a>Row 158: Subtest sequence for different logic

Source: D:3713-3719: "If test cases have different logic but identical setup, a sequence of subtests within a single test function might be more readable."

In practice: One test function with hand-written subtests.

Dropped because: Parameterized Test Structure steps 1 and 3 decide this: separate tests when execution differs, assertion functions when only the check differs.

↩ row [158](#row-158)

### <a id="drop-159"></a>Row 159: Separate tables for success and error

Source: D:3721-3725: "writing two separate table-driven test functions is the best approach: one for normal non-error outputs, and one for error outputs".

In practice: Two tables per function under test.

Dropped because: Parameterized Test Structure step 3: "Success and error cases can share a table when they share the same input structure."

↩ row [159](#row-159)

### <a id="drop-163"></a>Row 163: Helpers only for setup

Source: D:3875-3878: test helper failures "are expected to be failures of the environment"; D:3905-3908: "`t.Helper` should not be used to implement such libraries".

In practice: Assertions stay inline in the test body.

Dropped because: bjornstack.md test-helper and test-table use assertion functions that call `t.Helper()`.

↩ row [163](#row-163)

### <a id="drop-164"></a>Row 164: Tests in the same package

Source: D:3928: "Tests may be defined in the same package as the code being tested."

In practice: `package foo` test files reaching unexported identifiers.

Dropped because: bjornstack.md test-pkg and Public API Surface Testing step 1: no test file declares `package foo`.

↩ row [164](#row-164)

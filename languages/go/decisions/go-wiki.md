# Go sources B: Go Wiki TestComments and CodeReviewComments

Decision table for bs-f3o.2.2. It reviews two Go Wiki pages as one
merged table and decides, rule by rule, what goes into
`languages/go.md`. A rule that our own table,
[bjornstack.md](bjornstack.md), already holds reads "already ours" and
names that table's row.

Source: Go Wiki repository `https://go.googlesource.com/wiki`, commit
`fe2268bb04c953cd65bcae752e978912f5cbddaa` (2026-10-17), files
`TestComments.md` (published at go.dev/wiki/TestComments) and
`CodeReviewComments.md` (published at go.dev/wiki/CodeReviewComments).
Read 2026-11-16. Strategy text was judged at bjornstack commit
`67b1213`.

## Sources and pins

| Key | Source | Pin |
|---|---|---|
| TC | Go Wiki "Go Test Comments", `TestComments.md` | `go.googlesource.com/wiki` commit `fe2268bb04c9`, read 2026-11-16 |
| CRC | Go Wiki "Go Code Review Comments", `CodeReviewComments.md` | `go.googlesource.com/wiki` commit `fe2268bb04c9`, read 2026-11-16 |

The Source column names the page key and its heading. Introductions,
explanations and pointers to other pages hold no rule and get no row.

## Decision table

"Section" names the go.md section: Tooling, Pattern mappings, Go
pitfalls, or For the protocols (material bs-y5h turns into protocol
steps; Go style rules that map to no strategy go here). "Check" says
how a keep or adapt rule is enforced: "tool" when a check the pinned
source itself names enforces it, "guard candidate" when the rule is
mechanical but no check is named, "judgment" when a person or an agent
has to decide. Drop and "already ours" rows have "-".

| # | Source | Item | Decision | Reason | Rule id | Section | Check |
|---|---|---|---|---|---|---|---|
| <a id="row-1"></a>1 | TC Assert Libraries | Avoid assert libraries; check with plain Go and `t.Errorf` | drop | Owner chose testify `require`: bjornstack.md [row 39](bjornstack.md#row-39) (test-require) | [dropped](#drop-1) | — | - |
| <a id="row-2"></a>2 | TC Choose Human-Readable Subtest Names | Subtest names stay readable after the runner turns spaces into underscores and escapes non-printing characters | keep | Go-specific; our sentence-style case names (test-names) are read in that escaped form | [test-subtest-names](#rule-test-subtest-names) | Go pitfalls | judgment |
| <a id="row-3"></a>3 | TC Choose Human-Readable Subtest Names | Identify inputs with `t.Log` or in the failure message, where they are not escaped | keep | Same rule as rows 14 and 82 | [test-inputs](#rule-test-inputs) | Pattern mappings | judgment |
| <a id="row-4"></a>4 | TC Compare Full Structures | Compare a returned struct, array or map in one comparison, not field by field | already ours | bjornstack.md [row 82](bjornstack.md#row-82) (test-whole-value) | [test-whole-value](bjornstack.md#rule-test-whole-value) | — | - |
| <a id="row-5"></a>5 | TC Compare Full Structures | Fields needing approximate or semantic equality, or that cannot be compared, are handled by tweaking `cmp` with `cmpopts` | adapt | test-protobuf (bjornstack.md [row 43](bjornstack.md#row-43)) gives `cmp.Diff` no role beyond protobuf; Whole-Object Assertion step 2's capture-and-verify and zeroing apply to any field the whole comparison cannot check exactly | [test-uncomparable](#rule-test-uncomparable) | Pattern mappings | judgment |
| <a id="row-6"></a>6 | TC Compare Full Structures | Multiple return values are compared one by one, not wrapped in a struct | already ours | bjornstack.md [row 86](bjornstack.md#row-86) (test-table: `assertError` and `assertResult`) | [test-table](bjornstack.md#rule-test-table) | — | - |
| <a id="row-7"></a>7 | TC Compare Stable Results | Do not compare bytes whose form another package controls, such as `json.Marshal` output; parse them and compare the meaning | keep | Go form of Whole-Object Assertion's misapplication "asserting on serialized representations" | [test-parse-output](#rule-test-parse-output) | Pattern mappings | judgment |
| <a id="row-8"></a>8 | TC Equality Comparison and Diffs | Use `cmp.Equal` and `cmp.Diff` | drop | Owner chose `require.Equal`; `cmp.Diff` only for protobuf: bjornstack.md [row 43](bjornstack.md#row-43) | [dropped](#drop-8) | — | - |
| <a id="row-9"></a>9 | TC Equality Comparison and Diffs | Prefer `cmp` over `reflect.DeepEqual` in new code and move old code to `cmp` | drop | `require.Equal` is DeepEqual-based on purpose: it catches the time-zone mismatch `cmp.Diff` hides (bjornstack.md [row 44](bjornstack.md#row-44)) | [dropped](#drop-9) | — | - |
| <a id="row-10"></a>10 | TC Equality Comparison and Diffs | Compare protobuf messages with `cmp`, using `cmp.Comparer(proto.Equal)` | already ours | bjornstack.md [row 57](bjornstack.md#row-57) (test-protobuf, with `protocmp.Transform`) | [test-protobuf](bjornstack.md#rule-test-protobuf) | — | - |
| <a id="row-11"></a>11 | TC Got before Want | Print the actual value before the expected one: `YourFunc(%v) = %v, want %v` | drop | `require.Equal(t, want, got)` fixes the order and labels both values (bjornstack.md [row 39](bjornstack.md#row-39)) | [dropped](#drop-11) | — | - |
| <a id="row-12"></a>12 | TC Got before Want | Whichever order, say it in the failure message | drop | Same as row 11: `require` prints "expected" and "actual" labels | [dropped](#drop-12) | — | - |
| <a id="row-13"></a>13 | TC Identify the Function | Failure messages name the function that failed | adapt | TC rules out relying on the test function's name ("even though it seems obvious"); Fail Early and Loud's "loud but uninformative failures" asks which assertion failed and with what inputs. Folded into test-inputs | [test-inputs](#rule-test-inputs) | Pattern mappings | judgment |
| <a id="row-14"></a>14 | TC Identify the Input | Failure messages include the function's inputs when they are short | keep | No bjornstack rule covers inputs; same rule as rows 3 and 82 | [test-inputs](#rule-test-inputs) | Pattern mappings | judgment |
| <a id="row-15"></a>15 | TC Identify the Input | Large or opaque inputs: name the case with a description and print it | already ours | bjornstack.md [row 67](bjornstack.md#row-67) (test-names); `t.Run` prints the case name on failure | [test-names](bjornstack.md#rule-test-names) | — | - |
| <a id="row-16"></a>16 | TC Identify the Input | Never use the table index in place of a name | already ours | bjornstack.md [row 67](bjornstack.md#row-67) (test-names; Parameterized Test Structure step 2, "not test3") | [test-names](bjornstack.md#rule-test-names) | — | - |
| <a id="row-17"></a>17 | TC Keep Going | Keep going after a failure; prefer `t.Error` over `t.Fatal` | drop | Owner chose `require`, which stops; `assert` stays for deliberately independent failures (bjornstack.md [row 90](bjornstack.md#row-90)) | [dropped](#drop-17) | — | - |
| <a id="row-18"></a>18 | TC Keep Going | `t.Fatal` only when setup fails and the test cannot run | drop | Same as row 17 | [dropped](#drop-18) | — | - |
| <a id="row-19"></a>19 | TC Keep Going | Without subtests, a failing table entry uses `t.Error` then `continue` | drop | test-table always runs cases with `t.Run` (bjornstack.md [row 83](bjornstack.md#row-83)) | [dropped](#drop-19) | — | - |
| <a id="row-20"></a>20 | TC Keep Going | Inside `t.Run`, `t.Fatal` ends only the current subtest, so use it | already ours | bjornstack.md [row 83](bjornstack.md#row-83) (test-table with `t.Run`) and [row 39](bjornstack.md#row-39) (`require`, which calls `t.FailNow`) | [test-table](bjornstack.md#rule-test-table) | — | - |
| <a id="row-21"></a>21 | TC Mark Test Helpers | A helper that takes `*testing.T` calls `t.Helper` | already ours | bjornstack.md [row 91](bjornstack.md#row-91) (test-helper) | [test-helper](bjornstack.md#rule-test-helper) | — | - |
| <a id="row-22"></a>22 | TC Mark Test Helpers | Do not use `t.Helper` where it hides the cause, nor to build assert libraries | drop | test-helper puts `t.Helper()` first in every assertion helper (bjornstack.md [row 91](bjornstack.md#row-91)), and test-table's per-case assertion functions are such helpers | [dropped](#drop-22) | — | - |
| <a id="row-23"></a>23 | TC Print Diffs | For large output, print a diff instead of both values | drop | `require.Equal` prints a diff itself; `cmp.Diff` for protobuf is a diff | [dropped](#drop-23) | — | - |
| <a id="row-24"></a>24 | TC Print Diffs | Say the diff's direction, such as `diff -want +got` when calling `cmp.Diff(want, got)` | keep | Applies to the one `cmp.Diff` use we keep (test-protobuf) | [test-diff-key](#rule-test-diff-key) | Tooling | guard candidate |
| <a id="row-25"></a>25 | TC Print Diffs | Print a newline before the multi-line diff | keep | Same | [test-diff-key](#rule-test-diff-key) | Tooling | guard candidate |
| <a id="row-26"></a>26 | TC Table-Driven Tests vs Multiple Test Functions | Use a table when many cases share the same checking logic | drop | Parameterized Test Structure step 1 says it for every language | [dropped](#drop-26) | — | - |
| <a id="row-27"></a>27 | TC Table-Driven Tests vs Multiple Test Functions | Cases needing different checking logic go in separate test functions | drop | test-table settles this with an assertion function per case (bjornstack.md [row 64](bjornstack.md#row-64)); Parameterized Test Structure step 1 splits only when setup or execution differs | [dropped](#drop-27) | — | - |
| <a id="row-28"></a>28 | TC Table-Driven Tests vs Multiple Test Functions | Non-error outputs and error outputs in two separate tables | drop | Parameterized Test Structure step 3 lets success and error cases share a table; test-table does so (bjornstack.md [row 86](bjornstack.md#row-86)) | [dropped](#drop-28) | — | - |
| <a id="row-29"></a>29 | TC Test Error Semantics | Do not check which error came back by comparing strings or with `reflect.DeepEqual` | keep | Go form of Failure Identity step 6 ("never its wording") | [err-test-identity](#rule-err-test-identity) | Pattern mappings | guard candidate |
| <a id="row-30"></a>30 | TC Test Error Semantics | A string check that the package's message has some property, such as naming the parameter, is fine | adapt | The other side of Failure Identity step 6: facts in the message, always; TC only permits it | [err-test-identity](#rule-err-test-identity) | Pattern mappings | judgment |
| <a id="row-31"></a>31 | TC Test Error Semantics | To test the exact error, keep the human string apart from the structure; `fmt.Errorf` destroys that structure | drop | Failure Identity step 2 says it for every language; err-wrap-verb (bjornstack.md [row 48](bjornstack.md#row-48)) says when `fmt.Errorf` keeps identity | [dropped](#drop-31) | — | - |
| <a id="row-32"></a>32 | TC Test Error Semantics | An API whose error kinds do not matter uses `fmt.Errorf` and its test checks only that the error is non-nil | adapt | Failure Identity step 1 agrees on no identity; step 6 still checks the message's facts, unless the test set up none | [err-no-identity](#rule-err-no-identity) | Pattern mappings | judgment |
| <a id="row-33"></a>33 | CRC Gofmt | Run gofmt | already ours | bjornstack.md [row 78](bjornstack.md#row-78) (tool-finish) | [tool-finish](bjornstack.md#rule-tool-finish) | — | - |
| <a id="row-34"></a>34 | CRC Comment Sentences | Doc comments are full sentences that begin with the name and end with a period | keep | Go convention; godoc depends on it | [doc-comments](#rule-doc-comments) | For the protocols | guard candidate |
| <a id="row-35"></a>35 | CRC Contexts | Pass ctx explicitly along the whole call chain, as the first parameter | already ours | bjornstack.md [row 46](bjornstack.md#row-46) (ctx-per-call) | [ctx-per-call](bjornstack.md#rule-ctx-per-call) | — | - |
| <a id="row-36"></a>36 | CRC Contexts | `context.Background()` only in a function that is never request-specific, or with a good reason | keep | Go-specific; complements ctx-per-call | [ctx-background](#rule-ctx-background) | For the protocols | judgment |
| <a id="row-37"></a>37 | CRC Contexts | No Context field in a struct, except for a method whose signature must match a standard-library or third-party interface | adapt | ctx-per-call (bjornstack.md [row 46](bjornstack.md#row-46)) forbids the field; owner ruling 2026-11-16 allows only the per-call adapter, since a ctx stored at construction is the set-up value Unit Testing step 3.2 forbids | [ctx-in-struct](#rule-ctx-in-struct) | Pattern mappings | judgment |
| <a id="row-38"></a>38 | CRC Contexts | No custom Context types and no other interface in place of Context in signatures | keep | Go-specific | [ctx-type](#rule-ctx-type) | For the protocols | guard candidate |
| <a id="row-39"></a>39 | CRC Contexts | Application data goes in a parameter, the receiver, a global, or, if it truly belongs there, a Context value | drop | ctx-scope (bjornstack.md [row 47](bjornstack.md#row-47)) and coord-globals ([row 107](bjornstack.md#row-107)) narrow both ctx and globals | [dropped](#drop-39) | — | - |
| <a id="row-40"></a>40 | CRC Copying | Do not copy a value of `T` whose methods are on `*T`; take care copying structs from other packages | keep | Aliasing trap | [copy-pointer-methods](#rule-copy-pointer-methods) | Go pitfalls | judgment |
| <a id="row-41"></a>41 | CRC Crypto Rand | Keys come from `crypto/rand`, never `math/rand` or `math/rand/v2` | keep | Security trap | [crypto-rand](#rule-crypto-rand) | Go pitfalls | guard candidate |
| <a id="row-42"></a>42 | CRC Declaring Empty Slices | Declare an empty slice as a nil slice, `var t []string`, except where non-nil matters, such as JSON | keep | Go convention with its exception | [empty-slice](#rule-empty-slice) | For the protocols | judgment |
| <a id="row-43"></a>43 | CRC Declaring Empty Slices | When designing an API, avoid distinguishing a nil slice from an empty one | keep | Trap for callers | [nil-empty-slice](#rule-nil-empty-slice) | Go pitfalls | judgment |
| <a id="row-44"></a>44 | CRC Doc Comments | Every exported top-level name, and every non-trivial unexported type or function, has a doc comment | adapt | Say It Once step 1 protects exported docs; step 3 keeps only the why on unexported code, so CRC's non-trivial-unexported clause conflicts with it and with bs-iyx's over-commenting finding (bjornstack.md [row 70](bjornstack.md#row-70)); builders-a gives `test/a` builder methods none ([row 115](bjornstack.md#row-115)). Owner ruling 2026-11-16 | [doc-comments](#rule-doc-comments) | For the protocols | guard candidate |
| <a id="row-45"></a>45 | CRC Don't Panic | Do not panic for normal error handling; return an error | keep | Go convention | [no-panic](#rule-no-panic) | For the protocols | judgment |
| <a id="row-46"></a>46 | CRC Error Strings | Error strings are not capitalized, unless a proper noun or acronym, and end without punctuation; log lines are exempt | keep | Messages are printed after other context | [error-strings](#rule-error-strings) | For the protocols | judgment |
| <a id="row-47"></a>47 | CRC Examples | A new package comes with an example of intended use: a runnable Example or a test showing a complete call sequence | keep | Go convention | [examples](#rule-examples) | For the protocols | judgment |
| <a id="row-48"></a>48 | CRC Goroutine Lifetimes | Make clear when, or whether, a goroutine exits; keep it obvious, or document it | keep | Leak and race trap | [goroutine-exit](#rule-goroutine-exit) | Go pitfalls | judgment |
| <a id="row-49"></a>49 | CRC Handle Errors | Never discard an error with `_`; handle it, return it, or in truly exceptional cases panic | keep | Go form of Outside-In Development Loop step 3 ("every error is returned, never ignored") | [errors-handled](#rule-errors-handled) | Pattern mappings | guard candidate |
| <a id="row-50"></a>50 | CRC Imports | Rename an import only to avoid a collision, and then the most local one | keep | Go convention | [import-rename](#rule-import-rename) | For the protocols | guard candidate |
| <a id="row-51"></a>51 | CRC Imports | Imports in groups separated by blank lines, standard library first; goimports does this | keep | Mechanical, and the source names the tool | [tool-goimports](#rule-tool-goimports) | Tooling | tool: goimports (named by CRC Imports) |
| <a id="row-52"></a>52 | CRC Import Blank | `import _ "pkg"` only in package main or in tests that need it | keep | Go convention | [import-blank](#rule-import-blank) | For the protocols | guard candidate |
| <a id="row-53"></a>53 | CRC Import Dot | `import .` only in an external test package that a dependency cycle keeps out of the package under test | adapt | test-pkg makes every test external, and `test/a` builders import domain packages, so CRC's exception would cover nearly every test; its cyclic case never arises | [import-dot](#rule-import-dot) | For the protocols | guard candidate |
| <a id="row-54"></a>54 | CRC In-Band Errors | Return an extra final value, an error or an ok bool, instead of an in-band value such as -1 or ""; in-band values are fine when they are valid results | keep | Go form of Fail Early and Loud's "silent default substitution" | [in-band-errors](#rule-in-band-errors) | Pattern mappings | judgment |
| <a id="row-55"></a>55 | CRC Indent Error Flow | Handle the error first and return, so the normal path stays unindented; no `else` after it | keep | Go convention | [indent-error-flow](#rule-indent-error-flow) | For the protocols | guard candidate |
| <a id="row-56"></a>56 | CRC Initialisms | Initialisms keep one case (`URL`, `ServeHTTP`, `appID`); protobuf-generated code is exempt | keep | Go convention | [initialisms](#rule-initialisms) | For the protocols | guard candidate |
| <a id="row-57"></a>57 | CRC Interfaces | An interface generally belongs to the package that uses it; the implementing package returns concrete types | keep | Outside-In Development Loop step 2: interfaces emerge from the coordinator's needs (`testing__outside-in-loop.md:25`); "generally" leaves room for Domain-First Packaging step 5's shared interface both domains implement against | [iface-consumer](#rule-iface-consumer) | Pattern mappings | judgment |
| <a id="row-58"></a>58 | CRC Interfaces | Do not define an interface on the implementing side "for mocking"; design the API so it can be tested through the real implementation's public API | keep | Outside-In Development Loop step 2, as row 57; testing through the public API is Public API Surface Testing | [iface-consumer](#rule-iface-consumer) | Pattern mappings | judgment |
| <a id="row-59"></a>59 | CRC Interfaces | Do not define an interface before it is used | keep | Outside-In Development Loop has coordinator tests define interfaces at first use | [iface-when-used](#rule-iface-when-used) | Pattern mappings | judgment |
| <a id="row-60"></a>60 | CRC Line Length | No rigid line limit; break lines by meaning, not length | keep | Go convention | [line-length](#rule-line-length) | For the protocols | judgment |
| <a id="row-61"></a>61 | CRC Line Length | No function line limit; a function too long, or many repetitive tiny ones, is fixed by moving boundaries | keep | Agrees with bs-iyx, which refuted a length rule (bjornstack.md [row 40](bjornstack.md#row-40)) | [func-length](#rule-func-length) | For the protocols | judgment |
| <a id="row-62"></a>62 | CRC Mixed Caps | MixedCaps names; an unexported constant is `maxLength`, not `MaxLength` or `MAX_LENGTH` | keep | Go convention | [mixed-caps](#rule-mixed-caps) | For the protocols | guard candidate |
| <a id="row-63"></a>63 | CRC Named Result Parameters | Name results only when several share a type, their meaning is unclear, or a deferred closure changes one | keep | Go convention | [named-results](#rule-named-results) | For the protocols | judgment |
| <a id="row-64"></a>64 | CRC Named Result Parameters | Naked returns only in a function a handful of lines long | keep | Same | [named-results](#rule-named-results) | For the protocols | judgment |
| <a id="row-65"></a>65 | CRC Package Comments | The package comment sits directly above the package clause, with no blank line | keep | Mechanical: godoc ignores it otherwise | [pkg-comment](#rule-pkg-comment) | For the protocols | guard candidate |
| <a id="row-66"></a>66 | CRC Package Comments | It starts "Package x"; package main may start with the binary name or a listed variant, first word capitalized | keep | Go convention | [pkg-comment](#rule-pkg-comment) | For the protocols | judgment |
| <a id="row-67"></a>67 | CRC Package Names | Exports do not repeat the package name: `chubby.File`, not `chubby.ChubbyFile` | already ours | bjornstack.md [row 4](bjornstack.md#row-4) (pkg-naming) | [pkg-naming](bjornstack.md#rule-pkg-naming) | — | - |
| <a id="row-68"></a>68 | CRC Package Names | No meaningless package names: util, common, misc, api, types, interfaces | already ours | bjornstack.md [row 3](bjornstack.md#row-3) (proto-packages: no package named for a technical role) | [proto-packages](bjornstack.md#rule-proto-packages) | — | - |
| <a id="row-69"></a>69 | CRC Pass Values | Do not pass a pointer just to save bytes; large structs and structs that may grow are exempt | keep | Go convention | [pass-values](#rule-pass-values) | For the protocols | judgment |
| <a id="row-70"></a>70 | CRC Receiver Names | A receiver is a short abbreviation of its type, never `me`, `this` or `self` | keep | Go convention | [receiver-names](#rule-receiver-names) | For the protocols | judgment |
| <a id="row-71"></a>71 | CRC Receiver Names | The same receiver name in every method of a type | keep | Mechanical | [receiver-names](#rule-receiver-names) | For the protocols | guard candidate |
| <a id="row-72"></a>72 | CRC Receiver Type | Map, func or chan receivers are not pointers; a slice receiver is not a pointer unless the method reslices or reallocates it | keep | Go convention | [receiver-type](#rule-receiver-type) | For the protocols | judgment |
| <a id="row-73"></a>73 | CRC Receiver Type | A method that mutates the receiver has a pointer receiver | keep | Trap: a value receiver's change is lost | [receiver-type](#rule-receiver-type) | For the protocols | judgment |
| <a id="row-74"></a>74 | CRC Receiver Type | A struct holding a `sync.Mutex` or similar has a pointer receiver | keep | Trap: a value receiver copies the lock | [receiver-type](#rule-receiver-type) | For the protocols | guard candidate |
| <a id="row-75"></a>75 | CRC Receiver Type | A large struct or array has a pointer receiver | keep | Go convention | [receiver-type](#rule-receiver-type) | For the protocols | judgment |
| <a id="row-76"></a>76 | CRC Receiver Type | When changes must be visible in the original receiver, use a pointer | keep | Go convention | [receiver-type](#rule-receiver-type) | For the protocols | judgment |
| <a id="row-77"></a>77 | CRC Receiver Type | A struct, array or slice whose elements point to something that may mutate prefers a pointer receiver | keep | Go convention | [receiver-type](#rule-receiver-type) | For the protocols | judgment |
| <a id="row-78"></a>78 | CRC Receiver Type | A small, naturally value type has a value receiver; never choose one to save garbage without profiling | keep | Go convention | [receiver-type](#rule-receiver-type) | For the protocols | judgment |
| <a id="row-79"></a>79 | CRC Receiver Type | Do not mix pointer and value receivers on one type | keep | Mechanical | [receiver-type](#rule-receiver-type) | For the protocols | guard candidate |
| <a id="row-80"></a>80 | CRC Receiver Type | When in doubt, use a pointer receiver | keep | Go convention | [receiver-type](#rule-receiver-type) | For the protocols | judgment |
| <a id="row-81"></a>81 | CRC Synchronous Functions | Prefer synchronous functions; callers add concurrency | keep | Go convention; keeps goroutine lifetimes local | [sync-funcs](#rule-sync-funcs) | For the protocols | judgment |
| <a id="row-82"></a>82 | CRC Useful Test Failures | A failure says what was wrong, with what inputs, what was got and what was expected | keep | `require` prints got and expected, test-messages says what was wrong (bjornstack.md [row 92](bjornstack.md#row-92)); the inputs are new | [test-inputs](#rule-test-inputs) | Pattern mappings | judgment |
| <a id="row-83"></a>83 | CRC Useful Test Failures | `assertFoo` helpers produce useful messages | already ours | bjornstack.md [row 92](bjornstack.md#row-92) (test-messages applies to every assertion, helpers included) | [test-messages](bjornstack.md#rule-test-messages) | — | - |
| <a id="row-84"></a>84 | CRC Useful Test Failures | Order is actual then expected, and the message keeps that order; not "expected 0, got x" | drop | Same as row 11: `require` orders and labels both values; test-messages' "expected ..." (bjornstack.md [row 92](bjornstack.md#row-92)) states the behaviour, not a value order | [dropped](#drop-84) | — | - |
| <a id="row-85"></a>85 | CRC Useful Test Failures | Wrap each call of a shared test helper in its own `TestFoo` so the failure carries that name | drop | test-table and test-names name each case through `t.Run` (bjornstack.md [rows 67](bjornstack.md#row-67), [83](bjornstack.md#row-83)) | [dropped](#drop-85) | — | - |
| <a id="row-86"></a>86 | CRC Variable Names | The further from its declaration a name is used, the more descriptive it is | keep | Go form of Be Your Name's short name "used only where its definition is in sight" | [var-names](#rule-var-names) | Pattern mappings | judgment |
| <a id="row-87"></a>87 | CRC Variable Names | Names should be short rather than long; prefer `c` to `lineCount` | drop | Be Your Name: descriptive names are the default; short only where the definition is in sight (row 86) | [dropped](#drop-87) | — | - |

## Rules

Each rule below is the wording go.md takes. Every Source line cites
`go.googlesource.com/wiki` commit `fe2268bb04c9`, read 2026-11-16;
strategy citations are at bjornstack `67b1213`.

### Tooling

<a id="rule-tool-goimports"></a>**tool-goimports.** Imports come in groups separated by blank lines,
with the standard library first. goimports arranges them.
Source: CRC "Imports" and "Gofmt", `fe2268bb04c9`, read 2026-11-16.
↩ row [51](#row-51)

<a id="rule-test-diff-key"></a>**test-diff-key.** A `cmp.Diff` comparison (test-protobuf) passes
`want` first and `got` second and labels the failure with the
direction, `(-want +got)`, followed by a newline before the diff.
Source: TC "Print Diffs", `fe2268bb04c9`, read 2026-11-16.
↩ rows [24](#row-24), [25](#row-25)

### Pattern mappings

<a id="rule-test-inputs"></a>**test-inputs.** In most tests a failure names the call and its
inputs: the message names the call and its short inputs, such as
`expected Total(order-42) to include tax`, or logs them with `t.Log`,
where the runner does not escape them. The test's name does not
replace this, even when it seems to name the function. Large or opaque
inputs are described by the case name instead (test-names). `require`
supplies the got and expected values.
Source: TC "Identify the Function", "Identify the Input" and "Choose
Human-Readable Subtest Names"; CRC "Useful Test Failures";
`fe2268bb04c9`, read 2026-11-16.
↩ rows [3](#row-3), [13](#row-13), [14](#row-14), [82](#row-82)

<a id="rule-test-uncomparable"></a>**test-uncomparable.** When a field cannot be compared exactly by
`require.Equal`, such as a func field or a float needing
`require.InDelta`, handle it as Whole-Object Assertion step 2 does
(`whole-object-assertion.md:14-39`): capture it from the result,
verify it, and substitute it into `want`; or, as a last resort, zero
it on both sides and assert separately that it is set. Then compare
the whole value.
Source: TC "Compare Full Structures", `fe2268bb04c9`, read 2026-11-16.
Differs: TC tweaks `cmp.Diff` or `cmp.Equal` with `cmpopts` options;
test-protobuf keeps `cmp.Diff` for protobuf messages only.
↩ row [5](#row-5)

<a id="rule-test-parse-output"></a>**test-parse-output.** Do not compare output whose exact bytes
another package controls, such as `json.Marshal`'s, as a string. Parse
it and compare the parsed value as a whole (Whole-Object Assertion,
misapplication "asserting on serialized representations",
`whole-object-assertion.md:62-64`).
Source: TC "Compare Stable Results", `fe2268bb04c9`, read 2026-11-16.
↩ row [7](#row-7)

<a id="rule-err-test-identity"></a>**err-test-identity.** A test checks which failure came back with
`require.ErrorIs` or `require.ErrorAs`, never by comparing
`err.Error()` or the whole error value with its message. It checks
that the message names the facts it must, such as the parameter name,
with `require.ErrorContains`, never its full wording (Failure Identity
step 6, `failure-identity.md:66-72`). An identity's data may be
compared whole with `require.Equal`, leaving out any text meant for a
human (`failure-identity.md:164-166`).
Source: TC "Test Error Semantics", `fe2268bb04c9`, read 2026-11-16.
Differs: TC permits a property check; Failure Identity step 6 requires
it.
↩ rows [29](#row-29), [30](#row-30)

<a id="rule-err-no-identity"></a>**err-no-identity.** A failure that no caller handles differently
gets no identity (Failure Identity step 1): build it with
`errors.New` or `fmt.Errorf` (wrapping per err-wrap-verb). Its test checks `require.Error` and the facts the
message must name (step 6). When the test set up no fact the message
should name, it checks `require.Error` alone
(`failure-identity.md:167-168`).
Source: TC "Test Error Semantics", `fe2268bb04c9`, read 2026-11-16.
Differs: TC checks only that the error is non-nil; Failure Identity
step 6 checks the message's facts whenever the test set any up.
↩ row [32](#row-32)

<a id="rule-ctx-in-struct"></a>**ctx-in-struct.** The one exception to ctx-per-call's "never stored
in a struct" is a per-call adapter: a value built inside the call,
holding that call's ctx, only to satisfy an interface whose signature
cannot take one, such as `io.Reader`. It is never a long-lived
collaborator.
Source: CRC "Contexts", `fe2268bb04c9`, read 2026-11-16.
Differs: CRC allows a stored ctx for any method that must match a
standard-library or third-party interface; we allow it only in a value
built and dropped within one call, since a ctx stored at construction
is the set-up value Unit Testing step 3.2 forbids.
↩ row [37](#row-37)

<a id="rule-iface-consumer"></a>**iface-consumer.** An interface generally belongs in the package
that uses values of it, not the one that implements them (Outside-In
Development Loop step 2: interfaces emerge from the coordinator's
needs). The implementing package returns concrete types, usually a
pointer or a struct, so methods can be added without refactoring
callers. Never define an interface on the implementing side only for
mocking: design the API so it can be tested through the real
implementation's public API (Public API Surface Testing), and let the
consumer declare the interface it needs and mock that.
Source: CRC "Interfaces", `fe2268bb04c9`, read 2026-11-16.
↩ rows [57](#row-57), [58](#row-58)

<a id="rule-iface-when-used"></a>**iface-when-used.** Define an interface when a consumer uses it, not
ahead of use. In the outside-in loop that is the coordinator test that
first needs the collaborator.
Source: CRC "Interfaces", `fe2268bb04c9`, read 2026-11-16.
↩ row [59](#row-59)

<a id="rule-in-band-errors"></a>**in-band-errors.** A function that can fail or find nothing returns
an extra final value, an `error`, or an `ok bool` when no explanation
is needed, instead of an in-band value such as -1, `""` or nil. The
rule binds exported functions and is useful for unexported ones.
Values like nil, `""`, 0 and -1 are fine when they are valid results
the caller need not treat differently.
Source: CRC "In-Band Errors", `fe2268bb04c9`, read 2026-11-16.
↩ row [54](#row-54)

<a id="rule-errors-handled"></a>**errors-handled.** Never discard an error with `_`. Handle it, return
it, or, in truly exceptional situations, panic (Outside-In Development
Loop step 3: every error is returned, never ignored).
Source: CRC "Handle Errors", `fe2268bb04c9`, read 2026-11-16.
↩ row [49](#row-49)

<a id="rule-var-names"></a>**var-names.** The further from its declaration a name is used, the
more descriptive it is. A loop index or reader can be one letter, a
local in a small scope a short name, a receiver one or two letters;
unusual things and globals get descriptive names (Be Your Name, short
names "used only where its definition is in sight").
Source: CRC "Variable Names", `fe2268bb04c9`, read 2026-11-16.
↩ row [86](#row-86)

### Go pitfalls

<a id="rule-test-subtest-names"></a>**test-subtest-names.** `go test` replaces spaces in a `t.Run`
name with underscores and escapes non-printing characters. Choose case
names that still read well in that form.
Source: TC "Choose Human-Readable Subtest Names", `fe2268bb04c9`, read
2026-11-16.
↩ row [2](#row-2)

<a id="rule-copy-pointer-methods"></a>**copy-pointer-methods.** Do not copy a value of type `T` whose
methods are on `*T`: the copy can share memory with the original, as
a copied `bytes.Buffer` shares its byte slice. Take care when copying
any struct from another package.
Source: CRC "Copying", `fe2268bb04c9`, read 2026-11-16.
↩ row [40](#row-40)

<a id="rule-crypto-rand"></a>**crypto-rand.** Generate keys, even throwaway ones, with
`crypto/rand`: `rand.Text()` for text, or bytes from
`crypto/rand.Reader` encoded with `encoding/hex` or `encoding/base64`.
Never `math/rand` or `math/rand/v2`.
Source: CRC "Crypto Rand", `fe2268bb04c9`, read 2026-11-16.
↩ row [41](#row-41)

<a id="rule-nil-empty-slice"></a>**nil-empty-slice.** An API avoids giving a nil slice a different
meaning from a non-nil empty one.
Source: CRC "Declaring Empty Slices", `fe2268bb04c9`, read 2026-11-16.
↩ row [43](#row-43)

<a id="rule-goroutine-exit"></a>**goroutine-exit.** Code that starts a goroutine makes clear when, or
whether, it exits: a goroutine blocked on a channel is never
collected. Keep concurrent code simple enough that this is obvious;
where it is not, document when and why the goroutines exit.
Source: CRC "Goroutine Lifetimes", `fe2268bb04c9`, read 2026-11-16.
↩ row [48](#row-48)

### For the protocols

<a id="rule-ctx-background"></a>**ctx-background.** A function that is never request-specific may use
`context.Background()`. Otherwise take a ctx, even when it seems
unneeded; call `context.Background()` directly only with a good reason
why taking one would be a mistake.
Source: CRC "Contexts", `fe2268bb04c9`, read 2026-11-16.
↩ row [36](#row-36)

<a id="rule-ctx-type"></a>**ctx-type.** Signatures take `context.Context` itself: no custom
Context type, and no other interface in its place.
Source: CRC "Contexts", `fe2268bb04c9`, read 2026-11-16.
↩ row [38](#row-38)

<a id="rule-doc-comments"></a>**doc-comments.** Every exported top-level name has a doc comment
saying what it does, takes, returns and how it fails (Say It Once
step 1). An unexported declaration gets a comment only for what Say It
Once step 3 keeps: the why the code cannot say. Builder methods in
`test/a` have none (builders-a). A doc comment is written in full
sentences that begin with the name and end with a period.
Source: CRC "Comment Sentences" and "Doc Comments", `fe2268bb04c9`,
read 2026-11-16.
Differs: CRC also asks for doc comments on non-trivial unexported
declarations, and on builder methods, which builders-a leaves without
them.
↩ rows [34](#row-34), [44](#row-44)

<a id="rule-pkg-comment"></a>**pkg-comment.** The package comment sits directly above the package
clause, with no blank line, and starts "Package name". A package main
comment may start with the binary name or a variant such as "Command
seedgen"; its first word is capitalized.
Source: CRC "Package Comments", `fe2268bb04c9`, read 2026-11-16.
↩ rows [65](#row-65), [66](#row-66)

<a id="rule-empty-slice"></a>**empty-slice.** Declare an empty slice as a nil slice, `var s []T`,
not `s := []T{}`. Use a non-nil empty slice where the difference
shows, such as a JSON field that must encode as `[]`, not `null`.
Source: CRC "Declaring Empty Slices", `fe2268bb04c9`, read 2026-11-16.
↩ row [42](#row-42)

<a id="rule-no-panic"></a>**no-panic.** Do not panic for normal error handling; return an error.
Source: CRC "Don't Panic", `fe2268bb04c9`, read 2026-11-16.
↩ row [45](#row-45)

<a id="rule-error-strings"></a>**error-strings.** Error strings start lower-case, unless with a proper
noun or acronym, and end without punctuation, because they are printed
after other context. Log messages are exempt.
Source: CRC "Error Strings", `fe2268bb04c9`, read 2026-11-16.
↩ row [46](#row-46)

<a id="rule-examples"></a>**examples.** A new package comes with an example of intended use: a
runnable `Example` function, or a simple test showing a complete call
sequence.
Source: CRC "Examples", `fe2268bb04c9`, read 2026-11-16.
↩ row [47](#row-47)

<a id="rule-import-rename"></a>**import-rename.** Rename an import only to avoid a name collision, and
then rename the most local or project-specific one.
Source: CRC "Imports", `fe2268bb04c9`, read 2026-11-16.
↩ row [50](#row-50)

<a id="rule-import-blank"></a>**import-blank.** Import a package only for its side effects
(`import _ "pkg"`) in package main or in a test that needs it.
Source: CRC "Import Blank", `fe2268bb04c9`, read 2026-11-16.
↩ row [52](#row-52)

<a id="rule-import-dot"></a>**import-dot.** No `import .`.
Source: CRC "Import Dot", `fe2268bb04c9`, read 2026-11-16.
Differs: CRC allows it for a cyclic external test; test-pkg makes
every test external and qualified, so the case does not arise.
↩ row [53](#row-53)

<a id="rule-indent-error-flow"></a>**indent-error-flow.** Handle the error first and return (or
continue), so the normal path stays at the lowest indentation; no
`else` after such a block. Move a short declaration out of the `if`
when its value is used after it.
Source: CRC "Indent Error Flow", `fe2268bb04c9`, read 2026-11-16.
↩ row [55](#row-55)

<a id="rule-initialisms"></a>**initialisms.** An initialism keeps one case throughout a name:
`URL` or `url`, `ServeHTTP`, `xmlHTTPRequest`, `appID`, never `Url` or
`Id`. Code generated by the protocol buffer compiler is exempt.
Source: CRC "Initialisms", `fe2268bb04c9`, read 2026-11-16.
↩ row [56](#row-56)

<a id="rule-line-length"></a>**line-length.** Go has no line-length limit. Break a line where its
meaning breaks, not to make it shorter; a line that is still too long
calls for different names or semantics.
Source: CRC "Line Length", `fe2268bb04c9`, read 2026-11-16.
↩ row [60](#row-60)

<a id="rule-func-length"></a>**func-length.** There is no line limit for a function. A function
that is too long, or a run of repetitive tiny functions, is fixed by
moving function boundaries, not by counting lines.
Source: CRC "Line Length", `fe2268bb04c9`, read 2026-11-16.
↩ row [61](#row-61)

<a id="rule-mixed-caps"></a>**mixed-caps.** Names use mixed caps: an unexported constant is
`maxLength`, not `MaxLength` or `MAX_LENGTH`.
Source: CRC "Mixed Caps", `fe2268bb04c9`, read 2026-11-16.
↩ row [62](#row-62)

<a id="rule-named-results"></a>**named-results.** Leave results unnamed unless a function returns
two or three values of one type, a result's meaning is unclear from
context, or a deferred closure must change one. Never name them only
to avoid declaring a variable or to allow a naked return. Naked
returns only in a function a handful of lines long.
Source: CRC "Named Result Parameters", `fe2268bb04c9`, read 2026-11-16.
↩ rows [63](#row-63), [64](#row-64)

<a id="rule-pass-values"></a>**pass-values.** Do not pass a pointer just to save bytes: a function
that only ever reads `*x` takes `x`, such as `string`, not `*string`,
and `io.Reader`, not `*io.Reader`. Large structs, and small ones that
might grow, are exempt.
Source: CRC "Pass Values", `fe2268bb04c9`, read 2026-11-16.
↩ row [69](#row-69)

<a id="rule-receiver-names"></a>**receiver-names.** Name a receiver with a one- or two-letter
abbreviation of its type, such as `c` for `Client`, never `me`,
`this` or `self`, and use the same name in every method of the type.
Source: CRC "Receiver Names", `fe2268bb04c9`, read 2026-11-16.
↩ rows [70](#row-70), [71](#row-71)

<a id="rule-receiver-type"></a>**receiver-type.** Choose a method's receiver by these guidelines.
- A map, func or chan receiver is not a pointer. A slice receiver is
  not a pointer unless the method reslices or reallocates it.
- A method that mutates the receiver, or whose changes must be visible
  in the original, has a pointer receiver.
- A struct holding a `sync.Mutex` or similar synchronizing field has a
  pointer receiver, so the lock is not copied.
- A large struct or array has a pointer receiver: large means passing
  all its elements as arguments would feel too large.
- A struct, array or slice whose elements point to something that may
  mutate prefers a pointer receiver.
- A small type that is naturally a value, such as `time.Time`, with no
  mutable fields and no pointers, or a basic type, may have a value
  receiver. Do not choose a value receiver to save garbage without
  profiling first.
- One type does not mix pointer and value receivers.
- When in doubt, use a pointer receiver.
Source: CRC "Receiver Type", `fe2268bb04c9`, read 2026-11-16.
↩ rows [72](#row-72), [73](#row-73), [74](#row-74), [75](#row-75), [76](#row-76), [77](#row-77), [78](#row-78), [79](#row-79), [80](#row-80)

<a id="rule-sync-funcs"></a>**sync-funcs.** Prefer synchronous functions, which return their
results or finish their callbacks and channel operations before
returning, over asynchronous ones. A caller that needs concurrency
adds it by calling the function from a goroutine.
Source: CRC "Synchronous Functions", `fe2268bb04c9`, read 2026-11-16.
↩ row [81](#row-81)

## Dropped

One section per drop row: what the source said, what it would have
meant in practice, and why it was dropped.

### <a id="drop-1"></a>Row 1: Avoid assert libraries

Source: TC "Assert Libraries": "Avoid the use of 'assert' libraries to help your tests", writing `if obj == nil || obj.Type != "blogPost" ... { t.Errorf("AddPost() = %+v", obj) }` instead.

In practice: Tests would use plain comparisons and `t.Errorf`, with no testify.

Dropped because: Owner chose testify `require` (bjornstack.md row 39, test-require); a whole-value `require.Equal` also reports every differing field at once, which is what TC is after.

↩ row [1](#row-1)

### <a id="drop-8"></a>Row 8: Use cmp.Equal and cmp.Diff

Source: TC "Equality Comparison and Diffs": "Use the cmp package. Use `cmp.Equal` for equality comparison and `cmp.Diff` to obtain a human-readable diff between objects."

In practice: Every comparison in a test would go through go-cmp.

Dropped because: Owner chose `require.Equal` and gave `cmp.Diff` a role only for protobuf messages (bjornstack.md rows 43 and 57, test-protobuf).

↩ row [8](#row-8)

### <a id="drop-9"></a>Row 9: Prefer cmp over reflect.DeepEqual

Source: TC "Equality Comparison and Diffs": "Prefer `cmp` for new code, and consider updating older code to use `cmp` where practical. `reflect.DeepEqual` is sensitive to changes in unexported fields and other implementation details."

In practice: Old DeepEqual-based comparisons would be rewritten with `cmp`.

Dropped because: `require.Equal` is DeepEqual-based, and that is why the owner chose it: it catches a time-zone mismatch that `cmp.Diff` hides (bjornstack.md row 44, test-time).

↩ row [9](#row-9)

### <a id="drop-11"></a>Row 11: Got before want

Source: TC "Got before Want": "Test outputs should output the actual value that the function returned before printing the value that was expected. A usual format ... is `YourFunc(%v) = %v, want %v`."

In practice: Hand-written `t.Errorf` messages in got-then-want order.

Dropped because: We do not hand-write the comparison message; `require.Equal(t, want, got)` sets the order and labels both values (bjornstack.md row 39).

↩ row [11](#row-11)

### <a id="drop-12"></a>Row 12: State the order in the message

Source: TC "Got before Want": "Whichever order you use in your failure messages, you should explicitly indicate the ordering as a part of the failure message".

In practice: Every hand-written failure message would say which value is which.

Dropped because: `require` labels the values "expected" and "actual" itself; the one hand-labelled case, `cmp.Diff`, is test-diff-key.

↩ row [12](#row-12)

### <a id="drop-17"></a>Row 17: Keep going

Source: TC "Keep Going": "Even after your test cases encounter a failure, they should keep going for as long as possible ... prefer calling `t.Error` over `t.Fatal`."

In practice: Tests would collect every failure in one run with `t.Error` or `assert`.

Dropped because: Owner chose `require`, which stops at the first failure; `assert` remains for failures that are deliberately independent (bjornstack.md row 90, test-require). Whole-value comparison reports every differing field in that one failure.

↩ row [17](#row-17)

### <a id="drop-18"></a>Row 18: t.Fatal only for setup

Source: TC "Keep Going": "`t.Fatal` is usually only appropriate when some piece of test setup fails, without which you cannot run the test at all."

In practice: Only setup failures would stop a test; comparisons would use `t.Error`.

Dropped because: Same as row 17: `require` stops on every failed check.

↩ row [18](#row-18)

### <a id="drop-19"></a>Row 19: t.Error and continue without subtests

Source: TC "Keep Going": "If you're not using `t.Run` subtests, you should use `t.Error` followed by a `continue` statement to move on to the next table entry."

In practice: Table loops without `t.Run` would `continue` after a failed entry.

Dropped because: test-table always runs each case with `t.Run` (bjornstack.md row 83), so the case does not arise.

↩ row [19](#row-19)

### <a id="drop-22"></a>Row 22: No t.Helper for assert libraries

Source: TC "Mark Test Helpers": "Do not use this pattern when it obscures the connection between a test failure and the conditions that led to it. Specifically, `t.Helper` should not be used to implement assert libraries."

In practice: Assertion helpers would not call `t.Helper`, so failures point inside them.

Dropped because: test-helper puts `t.Helper()` first in every function that asserts (bjornstack.md row 91), and test-table's per-case assertion functions are exactly such helpers; the case name from `t.Run` keeps the failure tied to its conditions. Cost accepted: the failure line is the body's call; the `t.Run` case name says which case.

↩ row [22](#row-22)

### <a id="drop-23"></a>Row 23: Print a diff for large output

Source: TC "Print Diffs": "Instead of printing both the returned value and the wanted value, make a diff."

In practice: Tests would build their own diffs instead of printing both values.

Dropped because: `require.Equal` prints a diff of the two values on its own, and the protobuf comparison is `cmp.Diff`; nothing is left to write.

↩ row [23](#row-23)

### <a id="drop-26"></a>Row 26: Table tests for similar logic

Source: TC "Table-Driven Tests vs Multiple Test Functions": "Table-driven tests should be used whenever many different test cases can be tested using similar testing logic".

In practice: Cases sharing one check go in a table.

Dropped because: Parameterized Test Structure step 1 says it for every language (same reasoning as bjornstack.md row 61).

↩ row [26](#row-26)

### <a id="drop-27"></a>Row 27: Different logic, separate test functions

Source: TC "Table-Driven Tests vs Multiple Test Functions": "When some test cases need to be checked using different logic from other test cases, it is more appropriate to write multiple test functions."

In practice: A case whose check differs moves to its own test function.

Dropped because: test-table carries an assertion function per case (bjornstack.md row 64), as Parameterized Test Structure step 3 asks; step 1 splits a table only when setup or execution differs. Both sources agree the body has no conditionals.

↩ row [27](#row-27)

### <a id="drop-28"></a>Row 28: Separate tables for errors and outputs

Source: TC "Table-Driven Tests vs Multiple Test Functions": "the clearest unit tests can be achieved by writing two separate table-driven test functions — one for normal non-error outputs, and one for error outputs."

In practice: Every function returning `(value, error)` would get two tables.

Dropped because: Parameterized Test Structure step 3 lets success and error cases share a table when they share the input structure; test-table does that with `assertError` and `assertResult` (bjornstack.md row 86).

↩ row [28](#row-28)

### <a id="drop-31"></a>Row 31: Keep the human string apart from the structure

Source: TC "Test Error Semantics": to test the exact error, keep the human-readable string apart from the structure a test compares; `fmt.Errorf` destroys that structure.

In practice: Errors a test must tell apart would carry a comparable value beside their message.

Dropped because: Failure Identity step 2 (the identity is something the caller compares, never text) says it for every language; err-wrap-verb (bjornstack.md row 48) says when `fmt.Errorf` keeps identity (`%w`) and when it drops it (`%v`).

↩ row [31](#row-31)

### <a id="drop-39"></a>Row 39: Where application data goes

Source: CRC "Contexts": "If you have application data to pass around, put it in a parameter, in the receiver, in globals, or, if it truly belongs there, in a Context value."

In practice: Globals and Context values would be general places for application data.

Dropped because: ctx-scope limits ctx to cancellation and program-wide per-goroutine settings (bjornstack.md row 47), and coord-globals allows only metrics as globals (row 107); Unit Testing step 3.2 makes a global that does real work a hidden collaborator.

↩ row [39](#row-39)

### <a id="drop-84"></a>Row 84: Actual before expected

Source: CRC "Useful Test Failures": "Note that the order here is actual != expected, and the message uses that order too. Some test frameworks encourage writing these backwards: 0 != x, "expected 0, got x", and so on. Go does not."

In practice: Hand-written messages in got-then-want order, never "expected ...".

Dropped because: Same as row 11; test-messages words assertion messages "expected ..." (bjornstack.md row 92), and `require` labels the values.

↩ row [84](#row-84)

### <a id="drop-85"></a>Row 85: One TestFoo per helper call

Source: CRC "Useful Test Failures": "wrap each caller with a different TestFoo function, so the test fails with that name", e.g. `func TestSingleValue(t *testing.T) { testHelper(t, []int{80}) }`.

In practice: A shared check would be called from several thin test functions named for each input.

Dropped because: test-table names each case through `t.Run`, and test-names makes that name a sentence (bjornstack.md rows 67, 83), which identifies the failing input the same way.

↩ row [85](#row-85)

### <a id="drop-87"></a>Row 87: Short rather than long names

Source: CRC "Variable Names": "Variable names in Go should be short rather than long ... Prefer `c` to `lineCount`."

In practice: Short names would be the default everywhere, descriptive ones the exception.

Dropped because: Be Your Name makes descriptive names the default and allows a short one only where its definition is in sight, which is the half of CRC kept as var-names (row 86).

↩ row [87](#row-87)

## Open for owner

None. The owner ruled on the earlier question on 2026-11-17 (bs-f3o.2
comment "Owner rulings from go-decisions", S-13): Go style rules that
map to no strategy go in a new go.md section, "Go style", not in For
the protocols. bs-f3o.2.9 places them there when it writes go.md; the
Section column above still reads For the protocols.

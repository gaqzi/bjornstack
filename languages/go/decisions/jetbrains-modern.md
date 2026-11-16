# Go sources E: JetBrains go-modern-guidelines

Decision table for bs-f3o.2.6. It decides, entry by entry, what the
JetBrains modern Go guidelines give `languages/go.md`: a go.md rule,
or a form left to the go fix guard (bs-1y3).

Source: <https://github.com/JetBrains/go-modern-guidelines>, commit
`155dc7ca10da5e1f6c841503086957b1b37f5815` (committed 2026-09-10),
read 2026-11-16. Nothing else was read for this table. Strategy and
tenet text, and `bjornstack.md`, were judged at bjornstack commit
`67b1213`.

## Sources and pins

| Key | Source | Pin |
|---|---|---|
| G | `internal/guidelines/guidelines.json`, the 54 entries (`FEATURES.md` is generated from it) | `155dc7c`, read 2026-11-16 |
| RM | `README.md`, the list of what an agent will do (lines 11-13) | `155dc7c`, read 2026-11-16 |
| SK | `plugin/skills/use-modern-go/SKILL.md` | `155dc7c`, read 2026-11-16 |

`CONTRIBUTING.md` and the install and update instructions in
`README.md` govern contributions to and use of the tool, not Go code;
they give no rows. Each G entry carries a `modernizer` flag, which the
source glosses as "supported by a modernize analyzer"
(`FEATURES.md:9`): an analyzer in gopls modernize, not necessarily one
that `go fix` runs. An entry with the flag set is left to the go fix
guard (bs-1y3) only where the review of this table (bs-f3o.2.6
comment, 2026-11-16) found a matching analyzer in go1.27.3's `go fix`;
the other flagged entries get a go.md rule with Check "guard
candidate". The guard runs without `atomictypes` (row 58). A caveat in
a guard entry that the analyzer cannot apply gets its own row.

## Decision table

"Section" names the go.md section: Tooling, Pattern mappings, Go
pitfalls, or For the protocols. "Check" says how a keep or adapt rule
is enforced: "tool" when a check the pinned source itself names
enforces it, "guard candidate" when the rule is mechanical but no
check is named, or when the row is left to the go fix guard,
"judgment" when a person or an agent has to decide. Drop rows have
"-". In the Source column, `G:n id` is the entry whose `"id"` line is
`guidelines.json` line n.

| # | Source | Item | Decision | Reason | Rule id | Section | Check |
|---|---|---|---|---|---|---|---|
| <a id="row-1"></a>1 | G:3 `generic_methods` | Generic method when the operation belongs to the type; package-level helper when it belongs to no one receiver | keep | Go 1.27 form; both sides kept; scoped to generic helpers, as the source is | [generic-methods](#rule-generic-methods) | Pattern mappings | judgment |
| <a id="row-2"></a>2 | G:46 `json_v2` | `encoding/json/v2` for new JSON code on Go 1.27+ | already ours | bjornstack.md row 60a (new-stdlib); the release-notes check is bs-f3o.2.7's | new-stdlib (bjornstack.md) | Tooling | guard candidate |
| <a id="row-3"></a>3 | G:46 `json_v2` | Leave existing `encoding/json` code unchanged unless a migration is asked for, because a compiling import change can alter wire behaviour | adapt | v2 rejects invalid UTF-8 and duplicate names and encodes nil slices and maps as empty; on a public contract that changes the meaning of what exists (Grow Don't Break step 1). Owner ruling (bs-f3o.2, 2026-11-16, Migrations): the whole package stays on v1, so sibling endpoints keep one wire form, and the old form is called out | [json-v2-existing](#rule-json-v2-existing) | Tooling | judgment |
| <a id="row-4"></a>4 | G:46 `json_v2` | A migration starts from `jsonv1.DefaultOptionsV1()`, tests output and accepted input, then removes compatibility options one at a time | keep | Each removed option is a separate wire change that can be checked on its own | [json-v2-migrate](#rule-json-v2-migrate) | Tooling | judgment |
| <a id="row-5"></a>5 | G:152 `promoted_field_literals` | Set promoted fields directly in a keyed literal | keep | Modernizer flag set | go fix guard (bs-1y3) | Tooling | guard candidate |
| <a id="row-6"></a>6 | G:152 `promoted_field_literals` | Do not mix a promoted field with its embedded field; pointer-embedded paths are not supported | drop | Describes what the language does not accept, not a choice | [dropped](#drop-6) | — | - |
| <a id="row-7"></a>7 | G:205 `strings_bytes_cut_last` | `strings.CutLast`/`bytes.CutLast` over `LastIndex` plus slicing | keep | Modernizer flag set, but `go fix`'s stringscut leaves a `LastIndex` pattern alone (review 2026-11-16), so go.md states it | [cut-last](#rule-cut-last) | Pattern mappings | guard candidate |
| <a id="row-8"></a>8 | G:240 `stdlib_uuid` | Standard library `uuid` over third-party or hand-written UUID code on Go 1.27+ | already ours | bjornstack.md row 60a (new-stdlib) | new-stdlib (bjornstack.md) | Tooling | guard candidate |
| <a id="row-9"></a>9 | G:240 `stdlib_uuid` | Keep a third-party UUID package when targeting an older Go or needing behaviour outside the standard API | drop | new-stdlib (bjornstack.md row 60a) is the owner's ruling and states no exception; the older-Go half is moot, since new-stdlib applies only on Go 1.27 | [dropped](#drop-9) | — | - |
| <a id="row-10"></a>10 | G:279 `url_clone` | `URL.Clone` and `Values.Clone` instead of manual copies | keep | A manual copy can share mutable slices or miss fields | [url-clone](#rule-url-clone) | Pattern mappings | judgment |
| <a id="row-11"></a>11 | G:318 `new_expression` | `new(value)` for pointer fields and arguments; keep a helper only when it adds behaviour | keep | Modernizer flag set; the exception goes with the analyzer's form | go fix guard (bs-1y3) | Tooling | guard candidate |
| <a id="row-12"></a>12 | G:318 `new_expression` | `new(30)` is `*int` and does not fit a `*time.Duration` or `*int32` field | drop | The compiler rejects the mismatch | [dropped](#drop-12) | — | - |
| <a id="row-13"></a>13 | G:378 `errors_as_type` | `errors.AsType[T](err)` for matching an error type | keep | Modernizer flag set; tests keep `require.ErrorAs` (bjornstack.md err-is-fresh-pointer) | go fix guard (bs-1y3) | Tooling | guard candidate |
| <a id="row-14"></a>14 | G:402 `sync_waitgroup_go` | `wg.Go` when the goroutine's lifetime is exactly what the WaitGroup tracks | keep | Modernizer flag set; the condition goes with it | go fix guard (bs-1y3) | Tooling | guard candidate |
| <a id="row-15"></a>15 | G:435 `testing_t_context` | `t.Context()` when a test needs a context tied to its lifetime | keep | Modernizer flag set | go fix guard (bs-1y3) | Tooling | guard candidate |
| <a id="row-16"></a>16 | G:435 `testing_t_context` | `t.Context()` is canceled before `t.Cleanup` functions run; cleanup that needs a live context makes its own | keep | A trap no analyzer catches; compliance-suite factories register cleanup with `t.Cleanup` (bjornstack.md row 96) | [t-context-cleanup](#rule-t-context-cleanup) | Go pitfalls | judgment |
| <a id="row-17"></a>17 | G:461 `json_omitzero` | `omitzero` on bool, numeric, struct and time fields whose zero value means absent | keep | `go fix`'s omitzero analyzer looks only at struct-typed fields and its default fix removes `omitempty` without adding `omitzero` (review 2026-11-16), the opposite of this row; json-omit states the rule | [json-omit](#rule-json-omit) | Pattern mappings | judgment |
| <a id="row-18"></a>18 | G:461 `json_omitzero` | Keep `omitempty` where JSON emptiness is meant: empty strings, slices and maps | keep | The other side of row 17, which needs a person to say what "absent" means | [json-omit](#rule-json-omit) | Pattern mappings | judgment |
| <a id="row-19"></a>19 | G:490 `testing_b_loop` | `b.Loop()` as the benchmark's main loop | keep | Modernizer flag set, but `go fix` has no b.Loop analyzer (review 2026-11-16); merged with row 20 | [b-loop-n](#rule-b-loop-n) | Go pitfalls | guard candidate |
| <a id="row-20"></a>20 | G:490 `testing_b_loop` | `b.N` is known only after `b.Loop()` returns false; setup sized from `b.N` must be restructured | keep | The source says a mechanical swap does not fix it | [b-loop-n](#rule-b-loop-n) | Go pitfalls | judgment |
| <a id="row-21"></a>21 | G:517 `strings_split_seq` | `SplitSeq`/`FieldsSeq` when iterating over split results | keep | Modernizer flag set | go fix guard (bs-1y3) | Tooling | guard candidate |
| <a id="row-22"></a>22 | G:552 `maps_keys_values_iter` | Range over `maps.Keys`/`maps.Values` directly instead of a manual loop | adapt | No analyzer. The source's example rewrites a plain `for k := range m` into `maps.Keys(m)`; we range over the map itself and keep the iterators for where one is passed on | [iter-direct](#rule-iter-direct) | Pattern mappings | judgment |
| <a id="row-23"></a>23 | G:575 `slices_collect` | `slices.Collect` when a slice is needed; range over the iterator when streaming is enough | keep | Both sides kept | [iter-direct](#rule-iter-direct) | Pattern mappings | judgment |
| <a id="row-24"></a>24 | G:597 `slices_sorted` | `slices.Sorted` to collect and sort iterator values, such as map keys | keep | No analyzer | [iter-direct](#rule-iter-direct) | Pattern mappings | judgment |
| <a id="row-25"></a>25 | G:620 `time_tick_gc` | `time.Tick` for a simple forever loop; `time.NewTicker` when `Stop` or `Reset` is needed | adapt | Both sides kept; `time.Tick` reads the real clock, so code under test takes its ticks from the injected clock or runs under `testing/synctest` (clock-inject, bjornstack.md row 59) | [time-tick](#rule-time-tick) | Pattern mappings | judgment |
| <a id="row-26"></a>26 | G:645 `range_over_int` | `for i := range n` for 0 to n-1; a classic loop for a non-zero start, a step or a changing bound | keep | Modernizer flag set; the exceptions go with it | go fix guard (bs-1y3) | Tooling | guard candidate |
| <a id="row-27"></a>27 | G:668 `loopvar_capture` | No redundant `v := v` copies; keep a copy only when it serves another purpose | keep | Modernizer flag set; the exception goes with it | go fix guard (bs-1y3) | Tooling | guard candidate |
| <a id="row-28"></a>28 | G:668 `loopvar_capture` | `&v` points at the iteration's copy; use `&slice[i]` for the element | keep | A trap no analyzer catches | [loopvar-element](#rule-loopvar-element) | Go pitfalls | judgment |
| <a id="row-29"></a>29 | G:715 `cmp_or` | `cmp.Or` for a fallback chain, except when later entries are costly or have side effects, or zero is a valid result | keep | Exceptions kept: all arguments are evaluated | [cmp-or](#rule-cmp-or) | Pattern mappings | judgment |
| <a id="row-30"></a>30 | G:737 `reflect_type_for` | `reflect.TypeFor[T]()` | keep | Modernizer flag set | go fix guard (bs-1y3) | Tooling | guard candidate |
| <a id="row-31"></a>31 | G:756 `http_servemux_patterns` | Method-aware `ServeMux` patterns and `r.PathValue` | keep | No analyzer | [http-mux](#rule-http-mux) | Pattern mappings | judgment |
| <a id="row-32"></a>32 | G:784 `min_max` | Built-in `min`/`max` | keep | Modernizer flag set | go fix guard (bs-1y3) | Tooling | guard candidate |
| <a id="row-33"></a>33 | G:805 `clear` | `clear(m)` / `clear(s)` | keep | No analyzer | [std-helpers](#rule-std-helpers) | Pattern mappings | judgment |
| <a id="row-34"></a>34 | G:826 `slices_contains` | `slices.Contains` over a search loop | keep | Modernizer flag set | go fix guard (bs-1y3) | Tooling | guard candidate |
| <a id="row-35"></a>35 | G:851 `slices_index` | `slices.Index` | keep | No analyzer | [std-helpers](#rule-std-helpers) | Pattern mappings | judgment |
| <a id="row-36"></a>36 | G:876 `slices_index_func` | `slices.IndexFunc` | keep | No analyzer | [std-helpers](#rule-std-helpers) | Pattern mappings | judgment |
| <a id="row-37"></a>37 | G:903 `slices_sort_func` | `slices.SortFunc` with `cmp.Compare` instead of `sort.Slice` | keep | No analyzer; a `sort.Slice` call is easy to find | [sort-func](#rule-sort-func) | Pattern mappings | guard candidate |
| <a id="row-38"></a>38 | G:903 `slices_sort_func` | `slices.SortFunc` is not stable; `sort.SliceStable` becomes `slices.SortStableFunc` | keep | A swap to `SortFunc` silently reorders equal elements | [sort-stable](#rule-sort-stable) | Go pitfalls | guard candidate |
| <a id="row-39"></a>39 | G:926 `slices_sort` | `slices.Sort` for ordered values | keep | Modernizer flag set | go fix guard (bs-1y3) | Tooling | guard candidate |
| <a id="row-40"></a>40 | G:945 `slices_max_min` | `slices.Max`/`slices.Min`; explicit logic when empty slices or custom comparison need handling | keep | Exception kept | [std-helpers](#rule-std-helpers) | Pattern mappings | judgment |
| <a id="row-41"></a>41 | G:969 `slices_reverse` | `slices.Reverse` | keep | No analyzer | [std-helpers](#rule-std-helpers) | Pattern mappings | judgment |
| <a id="row-42"></a>42 | G:990 `slices_compact` | `slices.Compact` to remove consecutive duplicates | keep | No analyzer | [std-helpers](#rule-std-helpers) | Pattern mappings | judgment |
| <a id="row-43"></a>43 | G:990 `slices_compact` | `Compact` removes only consecutive duplicates; group equal values first to remove all | keep | A trap: the call looks like a dedupe | [compact-consecutive](#rule-compact-consecutive) | Go pitfalls | judgment |
| <a id="row-44"></a>44 | G:1015 `slices_clip` | `slices.Clip` | keep | Modernizer flag set, but `go fix` has no analyzer for it (review 2026-11-16) | [std-helpers](#rule-std-helpers) | Pattern mappings | guard candidate |
| <a id="row-45"></a>45 | G:1034 `slices_clone` | `slices.Clone` | keep | Modernizer flag set, but `go fix` has no analyzer for it (review 2026-11-16) | [std-helpers](#rule-std-helpers) | Pattern mappings | guard candidate |
| <a id="row-46"></a>46 | G:1053 `maps_clone` | `maps.Clone` | keep | No analyzer | [std-helpers](#rule-std-helpers) | Pattern mappings | judgment |
| <a id="row-47"></a>47 | G:1075 `maps_copy` | `maps.Copy` | keep | Modernizer flag set | go fix guard (bs-1y3) | Tooling | guard candidate |
| <a id="row-48"></a>48 | G:1096 `maps_delete_func` | `maps.DeleteFunc` | keep | No analyzer | [std-helpers](#rule-std-helpers) | Pattern mappings | judgment |
| <a id="row-49"></a>49 | G:1121 `sync_once_func` | `sync.OnceFunc` over `sync.Once` plus a wrapper | keep | No analyzer | [sync-once](#rule-sync-once) | Pattern mappings | judgment |
| <a id="row-50"></a>50 | G:1147 `sync_once_value` | `sync.OnceValue` to memoize a value | keep | No analyzer | [sync-once](#rule-sync-once) | Pattern mappings | judgment |
| <a id="row-51"></a>51 | G:1175 `context_after_func` | `context.AfterFunc` instead of a goroutine that only waits on `ctx.Done()` | keep | No analyzer | [ctx-after-func](#rule-ctx-after-func) | Pattern mappings | judgment |
| <a id="row-52"></a>52 | G:1198 `context_timeout_deadline_cause` | Timeout and deadline contexts with a cause when callers need the reason | keep | Conditional as the source states it: when `ctx.Err()` is too coarse for diagnostics or control flow | [ctx-cause](#rule-ctx-cause) | Pattern mappings | judgment |
| <a id="row-53"></a>53 | G:1219 `bytes_clone` | `bytes.Clone` | keep | Modernizer flag set, but `go fix` has no analyzer for it (review 2026-11-16) | [std-helpers](#rule-std-helpers) | Pattern mappings | guard candidate |
| <a id="row-54"></a>54 | G:1238 `strings_cut_prefix_suffix` | `CutPrefix`/`CutSuffix` when both the result and the match are needed | keep | Modernizer flag set | go fix guard (bs-1y3) | Tooling | guard candidate |
| <a id="row-55"></a>55 | G:1262 `errors_join` | `errors.Join` to combine errors, keeping `errors.Is`/`As` matching | drop | scrub-collect (bjornstack.md row 68) decides where Join is allowed; err-join-match (row 50) treats the matching the source praises as a trap | [dropped](#drop-55) | — | - |
| <a id="row-56"></a>56 | G:1283 `context_cancel_cause` | `context.WithCancelCause` and `context.Cause` when cancellation needs to carry a cause | keep | No analyzer | [ctx-cause](#rule-ctx-cause) | Pattern mappings | judgment |
| <a id="row-57"></a>57 | G:1305 `fmt_appendf` | `fmt.Appendf` over `Sprintf` when appending to bytes | keep | Modernizer flag set, but `go fix` has no analyzer for it (review 2026-11-16) | [appendf](#rule-appendf) | Pattern mappings | guard candidate |
| <a id="row-58"></a>58 | G:1324 `atomic_types` | Typed atomics over untyped atomic functions | adapt | `go fix`'s atomictypes rewrites raw fields of existing types (review 2026-11-16), the change row 59 forbids. Owner ruling (bs-f3o.2, 2026-11-16, Migrations): the guard opts out of atomictypes and new code uses typed atomics | [atomic-new](#rule-atomic-new) | Pattern mappings | judgment |
| <a id="row-59"></a>59 | G:1324 `atomic_types` | Replacing a raw field in an existing type changes its layout and size, and `atomic.Value` differs from `atomic.Pointer[T]`; migrate a type deliberately | keep | The source's limit on row 58 | [atomic-migrate](#rule-atomic-migrate) | Go pitfalls | judgment |
| <a id="row-60"></a>60 | G:1361 `any` | `any` over `interface{}` | keep | Modernizer flag set | go fix guard (bs-1y3) | Tooling | guard candidate |
| <a id="row-61"></a>61 | G:1384 `bytes_cut` | `bytes.Cut` | keep | Modernizer flag set | go fix guard (bs-1y3) | Tooling | guard candidate |
| <a id="row-62"></a>62 | G:1407 `strings_clone` | `strings.Clone` when a small string would keep a much larger one's memory alive | keep | Condition kept | [strings-clone](#rule-strings-clone) | Pattern mappings | judgment |
| <a id="row-63"></a>63 | G:1426 `strings_cut` | `strings.Cut` | keep | Modernizer flag set | go fix guard (bs-1y3) | Tooling | guard candidate |
| <a id="row-64"></a>64 | G:1449 `errors_is` | `errors.Is(err, target)`, never `err == target` | adapt | `==` misses a wrapped error; Failure Identity step 2 has callers compare identities, and this is the Go comparison. Narrowed to sentinels: a typed failure matched with `errors.Is(err, &T{})` is err-is-fresh-pointer's trap (bjornstack.md row 87) | [err-is-wrapped](#rule-err-is-wrapped) | Go pitfalls | guard candidate |
| <a id="row-65"></a>65 | G:1472 `time_until` | `time.Until(deadline)` over `deadline.Sub(time.Now())` | adapt | `time.Until` reads the real clock, so clock-inject (bjornstack.md row 74) decides where it may appear | [time-since](#rule-time-since) | Pattern mappings | guard candidate |
| <a id="row-66"></a>66 | G:1491 `time_since` | `time.Since(start)` over `time.Now().Sub(start)` | adapt | Same as row 65 | [time-since](#rule-time-since) | Pattern mappings | guard candidate |
| <a id="row-67"></a>67 | RM:11-12 | Use the language features and standard library of the `go.mod` version and older, nothing newer | keep | Every entry above names the version it needs | [go-version](#rule-go-version) | Tooling | guard candidate |
| <a id="row-68"></a>68 | SK:22-63 | Run the CLI's `list`, then `explain`, before editing Go code | drop | We install no Go skill (bs-f3o.2 comment 2026-11-03 09:09; bjornstack.md row 56) | [dropped](#drop-68) | — | - |
| <a id="row-69"></a>69 | SK:50-52, RM:13 | Follow a modern form even when nearby code or repository convention uses the older one; skip only when it would not compile, would change behaviour, or does not match | adapt | Consistent Beats Correct: a better pattern in one file beside twenty old ones is its Bad case, and a change made everywhere it appears is its Good case. Owner ruling (bs-f3o.2.6 comment, 2026-11-16) | [older-form](#rule-older-form) | Pattern mappings | judgment |

## Rules

Each rule below is the wording go.md takes. Every Source line cites
the JetBrains repository at commit `155dc7c`, read 2026-11-16.

### Tooling

<a id="rule-go-version"></a>**go-version.** Use only language features and standard library
additions from the Go version in `go.mod` or older.
Source: JetBrains go-modern-guidelines `README.md:11-12`, `155dc7c`,
read 2026-11-16.
↩ row [67](#row-67)

<a id="rule-json-v2-existing"></a>**json-v2-existing.** A package already on `encoding/json` stays on
it until a migration is asked for, and new code in that package uses
it too; new code elsewhere uses `encoding/json/v2` (new-stdlib).
Swapping the import can compile and still change what goes over the
wire: v2 rejects invalid UTF-8 and duplicate object names, and
encodes nil slices and maps as `[]` and `{}`, so a mix gives sibling
endpoints different output. Call out that the package is on the old
form so a migration can be considered.
Source: JetBrains go-modern-guidelines `guidelines.json` `json_v2`,
`155dc7c`, read 2026-11-16.
Differs: the source leaves open whether new code in a v1 package uses
v2; owner ruling (bs-f3o.2, 2026-11-16) keeps the package on one form.
↩ row [3](#row-3)

<a id="rule-json-v2-migrate"></a>**json-v2-migrate.** A migration to `encoding/json/v2` starts with
`jsonv1.DefaultOptionsV1()`, adds tests of the encoded output and of
the input still accepted, and then removes or overrides compatibility
options one deliberate change at a time. Later options override
earlier ones.
Source: JetBrains go-modern-guidelines `guidelines.json` `json_v2`,
`155dc7c`, read 2026-11-16.
↩ row [4](#row-4)

### Pattern mappings

<a id="rule-older-form"></a>**older-form.** Where the package already uses the older form of a
Pattern mappings rule, follow it, or change every occurrence in a
separate structural commit (Tidy or Change).
Source: JetBrains go-modern-guidelines `SKILL.md:50-52`, `README.md:13`,
`155dc7c`, read 2026-11-16; `tenets/consistent-beats-correct.md:8-10`.
Differs: the source has an agent follow the modern form even when
nearby code or repository convention uses the older one.
↩ row [69](#row-69)

<a id="rule-generic-methods"></a>**generic-methods.** On Go 1.27+, a generic helper whose operation
belongs to one type becomes a generic method on it; one that belongs
to no single receiver stays a package-level function.
Source: JetBrains go-modern-guidelines `guidelines.json`
`generic_methods`, `155dc7c`, read 2026-11-16.
↩ row [1](#row-1)

<a id="rule-url-clone"></a>**url-clone.** Copy a `*url.URL` with `URL.Clone` and `url.Values` with
`Values.Clone`, never field by field.
Source: JetBrains go-modern-guidelines `guidelines.json` `url_clone`,
`155dc7c`, read 2026-11-16.
↩ row [10](#row-10)

<a id="rule-json-omit"></a>**json-omit.** When adding or editing JSON tags, `omitzero` marks a field
whose Go zero value means "absent"; `omitempty` stays where JSON's
empty value is meant, mostly empty strings, slices and maps.
Source: JetBrains go-modern-guidelines `guidelines.json`
`json_omitzero`, `155dc7c`, read 2026-11-16.
↩ rows [17](#row-17), [18](#row-18)

<a id="rule-iter-direct"></a>**iter-direct.** Range over the map itself; use `maps.Keys` or
`maps.Values` where an iterator is passed on; never collect keys into
a slice only to range over them. Build a slice with `slices.Collect`
only when a slice is needed, and with `slices.Sorted` when it must
also be sorted, such as map keys for deterministic output.
Source: JetBrains go-modern-guidelines `guidelines.json`
`maps_keys_values_iter`, `slices_collect`, `slices_sorted`,
`155dc7c`, read 2026-11-16.
Differs: the source's example rewrites a plain map range into
`maps.Keys`.
↩ rows [22](#row-22), [23](#row-23), [24](#row-24)

<a id="rule-time-tick"></a>**time-tick.** Since Go 1.23 an unreferenced ticker is collected
without `Stop`. Use `time.Tick` for a loop that ticks for as long as
it runs; use `time.NewTicker` when the code needs `Stop` or `Reset`.
Code under test gets its ticks from the injected clock or runs under
`testing/synctest` (clock-inject).
Source: JetBrains go-modern-guidelines `guidelines.json`
`time_tick_gc`, `155dc7c`, read 2026-11-16.
Differs: the source does not consider an injected clock.
↩ row [25](#row-25)

<a id="rule-cmp-or"></a>**cmp-or.** Pick the first non-zero value of a fallback chain with
`cmp.Or`. It evaluates every argument first, so do not use it when a
later entry is costly or has side effects, or when a zero value such
as `0` or `false` is a valid answer rather than a missing one.
Source: JetBrains go-modern-guidelines `guidelines.json` `cmp_or`,
`155dc7c`, read 2026-11-16.
↩ row [29](#row-29)

<a id="rule-http-mux"></a>**http-mux.** Route with method-aware `ServeMux` patterns such as
`"GET /orders/{id}"` and read path parameters with `r.PathValue`,
not by trimming the path.
Source: JetBrains go-modern-guidelines `guidelines.json`
`http_servemux_patterns`, `155dc7c`, read 2026-11-16.
↩ row [31](#row-31)

<a id="rule-std-helpers"></a>**std-helpers.** Use the standard helper, not a hand-written loop:
`clear` to empty a map or zero a slice, `slices.Index` and
`slices.IndexFunc` to find an element, `slices.Reverse`,
`slices.Compact` for consecutive duplicates, `slices.Clip` to drop
unused capacity, `slices.Clone`, `bytes.Clone`, `maps.Clone`, and
`maps.DeleteFunc`. Use `slices.Max` and `slices.Min` for a non-empty
slice of ordered values; keep explicit logic when an empty slice or a
custom comparison needs handling.
Source: JetBrains go-modern-guidelines `guidelines.json` `clear`,
`slices_index`, `slices_index_func`, `slices_max_min`,
`slices_reverse`, `slices_compact`, `slices_clip`, `slices_clone`,
`bytes_clone`, `maps_clone`, `maps_delete_func`, `155dc7c`, read
2026-11-16.
↩ rows [33](#row-33), [35](#row-35), [36](#row-36), [40](#row-40), [41](#row-41), [42](#row-42), [44](#row-44), [45](#row-45), [46](#row-46), [48](#row-48), [53](#row-53)

<a id="rule-cut-last"></a>**cut-last.** Split at the last separator with `strings.CutLast` or
`bytes.CutLast`, not `LastIndex` plus slicing.
Source: JetBrains go-modern-guidelines `guidelines.json`
`strings_bytes_cut_last`, `155dc7c`, read 2026-11-16.
↩ row [7](#row-7)

<a id="rule-appendf"></a>**appendf.** Append formatted text to a byte slice with `fmt.Appendf`,
not `append(b, fmt.Sprintf(...)...)`.
Source: JetBrains go-modern-guidelines `guidelines.json`
`fmt_appendf`, `155dc7c`, read 2026-11-16.
↩ row [57](#row-57)

<a id="rule-atomic-new"></a>**atomic-new.** New code uses typed atomics such as `atomic.Int64` and
`atomic.Pointer[T]`, not the untyped `atomic` functions. An existing
type stays on its form until a migration is asked for
(atomic-migrate); call out that it is on the old form so a migration
can be considered. The go fix guard (bs-1y3) runs without the
`atomictypes` analyzer, because that analyzer rewrites fields of
existing types.
Source: JetBrains go-modern-guidelines `guidelines.json`
`atomic_types`, `155dc7c`, read 2026-11-16.
Differs: the source leaves the form to the modernize analyzer.
↩ row [58](#row-58)

<a id="rule-sort-func"></a>**sort-func.** Sort typed elements with `slices.SortFunc` and a
comparator such as `cmp.Compare`, not `sort.Slice`.
Source: JetBrains go-modern-guidelines `guidelines.json`
`slices_sort_func`, `155dc7c`, read 2026-11-16.
↩ row [37](#row-37)

<a id="rule-sync-once"></a>**sync-once.** Run a function at most once with `sync.OnceFunc`, and
memoize a computed value with `sync.OnceValue`, instead of a
`sync.Once` with a wrapper or a separate result variable.
Source: JetBrains go-modern-guidelines `guidelines.json`
`sync_once_func`, `sync_once_value`, `155dc7c`, read 2026-11-16.
↩ rows [49](#row-49), [50](#row-50)

<a id="rule-ctx-after-func"></a>**ctx-after-func.** Register work to run after cancellation with
`context.AfterFunc`, not a goroutine whose only job is waiting on
`ctx.Done()`.
Source: JetBrains go-modern-guidelines `guidelines.json`
`context_after_func`, `155dc7c`, read 2026-11-16.
↩ row [51](#row-51)

<a id="rule-ctx-cause"></a>**ctx-cause.** When `ctx.Err()` is too coarse for a caller's diagnostics
or control flow, cancel with a cause: `context.WithCancelCause`,
`WithTimeoutCause` or `WithDeadlineCause`, read with
`context.Cause(ctx)`.
Source: JetBrains go-modern-guidelines `guidelines.json`
`context_cancel_cause`, `context_timeout_deadline_cause`, `155dc7c`,
read 2026-11-16.
↩ rows [52](#row-52), [56](#row-56)

<a id="rule-strings-clone"></a>**strings-clone.** When code keeps a small string cut from a much
larger one, copy it with `strings.Clone` so the large one can be
freed.
Source: JetBrains go-modern-guidelines `guidelines.json`
`strings_clone`, `155dc7c`, read 2026-11-16.
↩ row [62](#row-62)

<a id="rule-time-since"></a>**time-since.** `time.Since(start)` and `time.Until(deadline)` read the
real clock, so they are calls to `time.Now()` for clock-inject: code
under test computes elapsed and remaining time from its clock. Where
code may read the real clock, write `time.Since` and `time.Until`
rather than `time.Now().Sub(start)` or `deadline.Sub(time.Now())`.
Source: JetBrains go-modern-guidelines `guidelines.json` `time_since`,
`time_until`, `155dc7c`, read 2026-11-16.
Differs: the source recommends both everywhere; under clock-inject
(bjornstack.md row 74) code under test never reads the real clock.
↩ rows [65](#row-65), [66](#row-66)

### Go pitfalls

<a id="rule-t-context-cleanup"></a>**t-context-cleanup.** `t.Context()` is canceled before the test's
`t.Cleanup` functions run. Cleanup that needs a live context creates
its own.
Source: JetBrains go-modern-guidelines `guidelines.json`
`testing_t_context`, `155dc7c`, read 2026-11-16.
↩ row [16](#row-16)

<a id="rule-b-loop-n"></a>**b-loop-n.** `b.Loop()` is the benchmark's loop. With it, `b.N` holds
the iteration count only after the loop ends, so a benchmark that
sizes its fixtures from `b.N` is restructured, not converted line by
line.
Source: JetBrains go-modern-guidelines `guidelines.json`
`testing_b_loop`, `155dc7c`, read 2026-11-16.
↩ rows [19](#row-19), [20](#row-20)

<a id="rule-loopvar-element"></a>**loopvar-element.** In `for _, v := range s`, `&v` points at that
iteration's copy, not at the element. Take `&s[i]` to point at the
element.
Source: JetBrains go-modern-guidelines `guidelines.json`
`loopvar_capture`, `155dc7c`, read 2026-11-16.
↩ row [28](#row-28)

<a id="rule-sort-stable"></a>**sort-stable.** `slices.SortFunc` is not stable. Code that used
`sort.SliceStable` moves to `slices.SortStableFunc`, or equal elements
change order.
Source: JetBrains go-modern-guidelines `guidelines.json`
`slices_sort_func`, `155dc7c`, read 2026-11-16.
↩ row [38](#row-38)

<a id="rule-compact-consecutive"></a>**compact-consecutive.** `slices.Compact` removes only consecutive
duplicates. To remove every duplicate, sort or group equal values
first.
Source: JetBrains go-modern-guidelines `guidelines.json`
`slices_compact`, `155dc7c`, read 2026-11-16.
↩ row [43](#row-43)

<a id="rule-atomic-migrate"></a>**atomic-migrate.** Replacing a raw
`int64` or `unsafe.Pointer` field in an existing type changes the
type's layout and size, and `atomic.Value` treats nil and types
differently from `atomic.Pointer[T]`, so a type is migrated as one
deliberate change, not call by call.
Source: JetBrains go-modern-guidelines `guidelines.json`
`atomic_types`, `155dc7c`, read 2026-11-16.
↩ row [59](#row-59)

<a id="rule-err-is-wrapped"></a>**err-is-wrapped.** Compare with a sentinel via `errors.Is(err, ErrX)`,
never `err == ErrX`: `==` misses a sentinel wrapped with `%w` or by a
custom wrapper, and ignores a custom `Is` method. Match an error type
with `errors.AsType` (tests: `require.ErrorAs`; err-is-fresh-pointer).
Source: JetBrains go-modern-guidelines `guidelines.json` `errors_is`,
`155dc7c`, read 2026-11-16.
Differs: the source says `errors.Is(err, target)` for any target; a
typed failure compared that way is err-is-fresh-pointer's trap.
↩ row [64](#row-64)

## Dropped

### <a id="drop-6"></a>Row 6: Mixing promoted and embedded fields

Source: `guidelines.json` `promoted_field_literals`: "Do not mix a promoted field with the embedded field that promotes it; pointer-embedded paths are not supported."

In practice: A literal that sets both `Embedded: Embedded{...}` and a promoted field, or a promoted field reached through an embedded pointer.

Dropped because: It describes what Go 1.27's literal syntax does not accept, which the compiler reports; there is no choice for go.md to make.

↩ row [6](#row-6)

### <a id="drop-9"></a>Row 9: Third-party UUID package as an exception

Source: `guidelines.json` `stdlib_uuid`: keep a third-party UUID package when the project targets an older Go version or needs behaviour outside the standard API.

In practice: A Go 1.27 service keeps `github.com/google/uuid` because it once used a feature the standard package lacks.

Dropped because: new-stdlib (bjornstack.md row 60a) is the owner's ruling and states no exception. The older-Go half is moot, since new-stdlib applies only on Go 1.27.

↩ row [9](#row-9)

### <a id="drop-12"></a>Row 12: `new` with an untyped constant

Source: `guidelines.json` `new_expression`: "`new(30)` yields `*int` and does not fit a `*time.Duration` or `*int32` field; write `new(30 * time.Second)` or `new(int32(30))` instead."

In practice: `Timeout: new(30)` for a `*time.Duration` field.

Dropped because: The compiler rejects the type mismatch, so the trap cannot reach a commit.

↩ row [12](#row-12)

### <a id="drop-55"></a>Row 55: `errors.Join` for its matching

Source: `guidelines.json` `errors_join`: combine errors with `errors.Join`, which keeps `errors.Is` and `errors.As` matching on the result.

In practice: A function joins a validation error and an I/O error, and its caller branches with `errors.Is` on one of them.

Dropped because: scrub-collect (bjornstack.md row 68) decides where Join is allowed, and err-join-match (bjornstack.md row 50) treats the matching the source praises as a trap: a joined error matches every member, so a caller checking for one cause is misled.

↩ row [55](#row-55)

### <a id="drop-68"></a>Row 68: Run the guidelines CLI

Source: `SKILL.md:22-63`: call the wrapper's `list` subcommand for the file before editing Go code, read its whole output, and `explain` a guideline before skipping it.

In practice: Every Go edit starts by running the JetBrains CLI.

Dropped because: The owner decided on 2026-11-03 to take rules from this source and install no Go skill (bjornstack.md row 56); go.md and the go fix guard carry the rules instead.

↩ row [68](#row-68)

# Flag Your Changes
PRINCIPLE: Many More Much Smaller Steps

1. Decide during design what — if anything — needs a flag.
   - Prefer designs that grow the system over designs that flag it.
     A new endpoint, a new API version (whether /v2 or content-type
     negotiation), a new capability — these are inherently opt-in.
     Consumers choose when to adopt. No flag needed. This is Grow
     Don't Break's "add alongside" applied at the feature level.
   - When access must be controlled, prefer gating at the UI layer —
     access controls, feature visibility — over code-level flags. UI
     gating keeps conditional paths out of the backend.
   - Code-level flags create optionality — the ability to verify
     progressively and reverse quickly — for changes to existing
     behavior that are uncertain or risky. When the change is a known
     fix (the old behavior was never correct), ship directly — there's
     nothing worth rolling back to. Either way, the decision is
     explicit in the design.
   - When flagging: each independent behavior change is its own flag;
     avoid nesting flags within flags.
   - When unsure: state what the change affects and whether existing
     users would notice, then recommend.
2. Name and classify the flag before creating it.
   - The name describes what `true` activates — readable by an operator
     during an incident without additional context.
   - Track the flag's lifecycle in the flag system's config, not in
     the name — flags can legitimately change lifecycle. Each flag
     entry carries its state (active, deprecated, retired) and
     retirement metadata (when, why, owner). Retired names cannot be
     reused — lingering config from a previous flag with the same
     name can cause unintended activation.
   - Rollout flag: temporary. Will this flag still be meaningful after
     100% activation? If no, it's a rollout flag. Capture the removal
     condition in code alongside the flag — a dated annotation, expiry
     marker, or metadata that tooling can discover and escalate when
     the deadline passes. The commitment lives with the code too, not
     only in the flag system.
   - Targeting flag: long-lived. Different behavior for different deploy
     targets or customer segments. Treat as first-class configuration.
3. Wire the code behind the flag, defaulting to OFF. The new path is
   deployed but inert — integrated on main, buildable by the team,
   but no behavior changes until explicitly enabled. Both flag states
   need coverage: the same test exercised with the flag on and off,
   with assertions appropriate to each state — the OFF path proves
   prod safety, the ON path proves the new behavior is correct.
4. Activate progressively — start with the narrowest useful scope
   (specific users, single environment, canary percentage), widen as
   signals confirm the new path is healthy.
5. For rollout flags: remove the flag and its dead code path once fully
   rolled out. The removal is its own changeset — ideally mechanical,
   driven by tooling that strips the OFF path from production code
   and tests.

OUTCOMES:
- Code integrates to main before behavior is active — the team builds
  on new domain design immediately without waiting for feature completion.
- Each activation widening (off → canary → full) is an independently
  reversible step — rollback is a flag flip, not a redeployment.
- Rollout flags have a defined end-of-life captured in code — tooling
  can discover and surface overdue flags without human memory.

MISAPPLICATIONS:
- Flagging what could be grown — a code-level flag for behavior that
  could have been a new endpoint, version, or UI-gated feature.
  Adding conditional paths when the design could provide isolation.
- Wrapping structure alongside behavior — a flag that covers
  structural foundation and behavioral change together, making
  removal require restructuring instead of just deleting the dead
  path.
- Immortal rollout flags — rollout flags that never get removed
  because "done" was never defined or no one committed to full
  rollout. If both paths must exist permanently, reclassify as
  targeting and engineer accordingly.
SKIP WHEN: The change is trivially small and low-risk — a one-line fix
doesn't need progressive rollout. Also: purely structural changes (Tidy
or Change) — structural changes don't alter behavior and don't need a
flag to be safe.

---
<!-- Rationale below — read when creating protocols, reviewing, or
questioning the strategy. Not needed for routine application. -->

## Rationale

### The core decoupling

Flags decouple "ship code" from "enable behavior." This single decoupling
creates multiple small steps where there would otherwise be one large
release: deploy inert code, activate for canary, widen to 10%, go to
100%, remove the flag. Each step is independently decidable and
reversible — the hallmark of MMMSS.

Cockburn's walking skeleton — the smallest deployable thing that proves
the path works — is the ideal first flagged step. New domain types,
reorganized modules, wired-but-inert endpoints all reach main behind a
flag. The team builds on the new design immediately, even before the
behavior is live.

### The design decision

Flags add conditional paths — each one is complexity that must be
tested, maintained, and eventually removed. The strategy minimizes
flags by establishing a preference hierarchy:

1. **Grow the system.** A new endpoint, a new API version, a new
   capability — these are inherently opt-in. Consumers choose when to
   adopt. This is Grow Don't Break's "add alongside" pattern: the new
   version exists next to the old, no flag needed. A versioned endpoint
   — whether /v2 or content-type negotiation — is a new endpoint that
   nothing calls until a consumer opts in.

2. **Gate at the UI layer.** When a feature needs controlled access,
   prefer UI-level gating (access controls, feature visibility) over
   backend flags. UI gating gives the same control without conditional
   paths in the backend. The system's core logic stays unconditional.

3. **Code-level flag.** When existing behavior must change for current
   users and the transition can't be isolated by design, a flag controls
   the transition. This is the strategy's core use case — and the only
   one that earns the complexity.

The code-level flag exists to create optionality: the ability to verify
a change progressively and reverse it quickly if it doesn't work as
expected. When the change is a known fix — the old behavior was never
correct — that optionality isn't needed; ship the fix directly. The
decision to flag or not is always a conscious design choice; "no flag
because [reason]" is as valid as "flag because [risk]."

The fewer flags in the system, the less brittle it is. Each flag is a
fork in the code that doubles the state space. Good design reduces flag
surface; flags are for what the design can't isolate.

### OFF by default is explicit, not silent

A flag defaulting to OFF is a deliberate design choice: "this path
exists but isn't active yet." This is not a FEAL violation — FEAL
prohibits implicit fallbacks where no one decided to degrade and no one
knows it's happening. A flag is an explicit decision with clear
activation criteria. The code loudly chooses to be inert.

### Flag identity and lifecycle

The flag name serves operators during incidents — `true` means the
action described by the name is happening. `payments_swish=true`: swish
payments are active. `disable_online_payments=true`: online payments are
off. An operator at 3am reads the name and knows what flipping it does
without reading code or remembering edge cases.

Lifecycle lives in the flag system's config, not the name. Encoding
rollout/targeting in the name is fragile — flags legitimately change
lifecycle. A rollout flag may become a targeting flag when the business
discovers that different segments need different behavior. The config
tracks this transition; the name stays stable because it describes the
action, not the lifecycle.

Retired names cannot be reused. The risk is lingering configuration in
the flag system — a new flag that shares a retired name could inherit
old config and activate prematurely. Track retired names in the flag
system's registry. This is a natural guard: reject flag creation if the
name was previously used.

Code-level expiry markers (dated annotations at the flag definition)
are secondary enforcement — CI catches overdue flags that the flag
system misses, and the flag system catches lingering config that CI
can't see. Belt and suspenders.

### Flag interaction

When multiple flags coexist, they can interact: flag A enables a new
data model, flag B enables UI that reads it. B on without A breaks.
This is shared fate between flags.

The honest answer is that this is a hard problem without a clean general
solution. Two heuristics help:

- **Limit nesting.** A flag check inside another flag check is a
  combinatorial explosion. If two flags must be coordinated, consider
  whether they're really one flag controlling one behavior change.
- **Reduce surface through design.** Capabilities that are inherently
  opt-in (new endpoints, access-controlled features) don't need flags.
  Fewer flags means fewer interactions. Overlapping flags on the same
  user flow should be consolidated into fewer, broader flags rather than
  many narrow interdependent ones.

Good feature design is the primary mitigation — flag management tooling
is secondary.

### Testing both states

Both flag states need coverage: OFF proves prod safety, ON proves the
new behavior. The ideal pattern: the same test scenario runs twice with
different assertions per state — same setup, diverging only in what's
checked. This makes it impossible to ship a flag with only one state
tested.

When the flag is fully activated, the OFF path is dead. Tooling that
mechanically strips the dead path — from production code and tests —
makes cleanup a code transformation, not a judgment call. The same
insight as Tidy or Change: removing a flag is structural, not
behavioral.

### Flag service resilience

When flags are served by a remote service, that service becomes a
dependency. If it's down, the fallback should match the majority
population's experience:

- Pre-majority (< 50% rollout): fall back to OFF. Most users are on
  the old path; preserving their experience minimizes disruption.
- Post-majority (> 50% rollout): fall back to ON. Most users are on
  the new path; falling back to OFF would break the majority.

The threshold crossing is itself a deployment decision — update the
fallback default when the rollout crosses majority. This is an explicit,
designed fallback (not a FEAL violation): the system loudly chooses to
serve the majority experience when it can't determine the specific
user's flag state.

Cache flag state locally so the flag service isn't a synchronous
dependency on every request. A stale flag value is almost always better
than a failed request.

### Flag state in observability events

DFB says events should carry every dimension relevant to understanding
behavior. During progressive activation, the active flag state for each
request is a critical debugging dimension. When something fails at 5%
rollout, the first question is whether the failing request was in the
flagged or unflagged population. Include active flags in every event.

### Cross-cutting benefits

While Flag Your Changes primarily serves MMMSS (each activation scope
is a small, reversible step), it also serves:

- **Don't Fly Blind**: Progressive activation is canary-style rollout.
  Each widening produces signal — error rates, latency, user behavior —
  before the next widening. The flag system gives DFB a natural throttle.
- **No Shared Fate**: A failure in flagged behavior affects only the
  flagged-in scope. Users outside the flag are unaffected. The flag
  isolates blast radius by construction.

These benefits are real but secondary. The strategy earns its place
through MMMSS — the other principles benefit from it.

### Proportional infrastructure

The flag infrastructure is smaller than it sounds. The flag system
itself — what evaluates flags at runtime — can be a config file. The
lifecycle management is a config file and a checker that validates
flags exist, aren't expired, and don't reuse retired names. Test
helpers and code fixers are small, reusable tools built once and shared.
The investment is proportional: a few small tools on GitHub, not a
platform.

### Relationship to Tidy or Change

Flags strengthen the tidy-first workflow. A structural changeset can
introduce new domain types or reorganize modules behind a flag that
defaults to OFF — "structural" truly means "no behavior changes"
because the flag guarantees inertness. The behavioral activation comes
in a later changeset, cleanly separated. Tidy or Change's rationale
already references this strategy for this reason.

### Relationship to Grow Don't Break

The strategies are complementary with a clear handoff. GDB's "add
alongside" — new endpoints, new versions, new fields — is inherently
opt-in and needs no flag. Flag Your Changes picks up where GDB's
additive approach runs out: when existing behavior must change for
current users, and the change can't be offered as a new thing to opt
into. GDB handles growth; this strategy handles transition.

Flags can also serve as the migration mechanism within GDB's
grow-then-subtract cycle. New contract version behind a flag → migrate
consumers → flag becomes default → remove old path. The flag makes
GDB's cycle visible and controllable.

### Cross-references

- **Boundary Communication**: Flags live in the unit that owns the
  behavior — the same ownership model as BC. A pricing flag lives in
  the pricing boundary. Flags don't create new boundaries; they sit
  within existing ones.

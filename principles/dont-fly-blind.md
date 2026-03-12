# Don't Fly Blind
A change is not released until there are signals — tests, metrics, alerts —
that will show when it's not working.
VIOLATION: A payment processing change ships with no dashboard showing
success rates — the team discovers it's broken when customers complain
three hours later.
WHY: Without failure signals, the distance between an incident starting
and a human noticing is determined by user pain, not by engineering.

---
<!-- Rationale below — read when creating strategies, reviewing, or
questioning the principle. Not needed for routine application. -->

## Rationale

It is much easier to build observability in from the start than to retrofit
it later. When observability is an afterthought, the system works — until it
doesn't, and then no one knows why. DFB makes observability a release gate:
you don't ship until you can tell when it's broken.

### Relationship to Fail Early and Loud

FEAL governs code behavior — surface errors at the point of failure, don't
swallow them. DFB governs operational readiness — can you tell when the
running system is failing? A function that swallows an error is a FEAL
violation. A feature that ships without an alert is a DFB violation. They
share the philosophy "make failures visible" but operate at different
levels: FEAL is about code-level error handling, DFB is about system-level
observability.

### Emitting signals is the author's job

DFB isn't just about dashboards and alerts — those consume signals. The
code itself must emit them. The traditional separation of metrics, logs,
and traces is dissolving. Modern observability treats each operation as a
structured event carrying every dimension relevant to understanding its
behavior — rich events that can be sliced, aggregated, and traced after
the fact. The author's job is to make each event as wide as possible:
attach every field that would help debug a problem.

When writing feature code, the author (human or agent) is responsible for
emitting rich, structured events: what was the input, what flags were
active, what decision was made, what was the outcome. Don't pre-decide
which dimensions matter — make the event rich and let tooling answer
questions later. If the code emits nothing, no amount of dashboarding
helps. If the code emits only a status code, you can answer "did it fail?"
but not "why did it fail for this user with these inputs?"

For AI agents, this means DFB is directly actionable at the code level:
every feature path should include the instrumentation that makes its
behavior observable. "What would I need to see in an event to debug this?"
is a question worth asking for every non-trivial code path. Even in CLI
tools where there are no dashboards, structured events with rich context
are more debuggable than scattered print statements.

### Proportional signals

The signal burden scales with the risk of the change, not the number of
changes. A refactor that doesn't change behavior? Existing tests are the
signal — DFB is already satisfied. A walking skeleton behind a feature flag
(not active)? The flag is off, there's nothing to observe yet. DFB applies
when the flag turns on. A new payment flow? You need new metrics, alerts,
and dashboards before it goes live.

A series of Many More Much Smaller Steps building toward a feature
accumulate their observability requirement. The intermediate steps may not
each need new dashboards, but the feature as a whole does — and the final
step (flag on, merge to production) is where DFB's full weight applies.

### The signal set grows with experience

Every incident teaches you what to watch for. A regression test prevents
the same bug from recurring in code. A monitor prevents the same symptom
from going unnoticed in production. DFB means the signal set evolves — each
incident adds to the system's ability to detect problems. The process of
integrating incident learnings doesn't need special formalization; it's
normal engineering work informed by DFB as a constraint.

### Particularly resistant to Practicality Beats Purity

"We'll add monitoring later" is the most common DFB violation. The cost of
skipping is invisible until the incident — which makes it feel cheap to skip
and catastrophically expensive when it isn't. This is one principle where PBP
should be invoked with extreme reluctance. The tradeoff is asymmetric: the
cost of adding signals is known and modest, the cost of not having them is
unknown and potentially severe.

### Connection to Many More Much Smaller Steps

MMMSS makes changes small so they're cheap to revert. DFB ensures you know
when to revert. Together they form a delivery loop: make a small change,
make sure you can see if it's broken, ship it, repeat. Neither is sufficient
alone — small blind steps are still blind, and observable giant releases are
still giant.

### Strategies are contextual

The techniques for observability — what to instrument, how to set up
alerting, what dashboards to build — are highly context-dependent. The
principle is valuable as a constraint even when the strategies are less
prescriptive than those for code design principles. Over time, patterns will
emerge, but the constraint stands on its own: don't ship what you can't see.

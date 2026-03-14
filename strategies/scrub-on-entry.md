# Scrub on Entry
PRINCIPLE: Fail Early and Loud

1. Identify the system boundary — where does external data cross into your domain?
2. Classify each incoming field: acted-on (your code branches on it, computes with it, or stores it as a fact) vs. not-acted-on.
3. For every acted-on field, define what values are valid — including relationships between fields. The constraints are whatever your domain logic assumes to be true.
4. Validate all acted-on fields at the boundary. Collect every violation before rejecting — surface the full picture in one pass, not a fix-one-resubmit loop.
5. Discard fields you don't act on. They aren't part of your domain — don't model what you don't use.
6. Construct a domain object from validated data. After this point, domain logic never questions whether its inputs are valid.

OUTCOMES:
- Domain logic contains no defensive nil-checks, type coercions, or "just in case" defaults for external data.
- Rejections identify every invalid field and the constraint it violated — a single response surfaces the full picture.
- Fields you don't act on are excluded from validation — rejections only fire on things that would actually cause failures.

MISAPPLICATION: Validating everything — including fields you don't use — turning the boundary into a brittle schema check that breaks whenever upstream adds a field. Validating at the boundary but then passing the raw input to domain logic instead of the constructed domain object — you scrubbed but used the dirty version. Or re-validating deep inside domain logic "just to be safe," which means you don't trust the boundary and haven't actually scrubbed.
SKIP WHEN: Data you validated on entry to this service and haven't re-read from an external source since. Also skip when your code genuinely doesn't act on any field in the payload — but if you act on even one, scrub it.

---
<!-- Rationale below — read when creating guidelines, reviewing, or
questioning the strategy. Not needed for routine application. -->

## Rationale

### The refined Postel's Law

Postel's original "be liberal in what you accept" has been widely misapplied
as "accept anything and hope for the best." This strategy refines it: be
strict about values you depend on (an enum you don't recognize in a field
you act on is unsafe), and don't model what you don't use. The acted-on vs.
not-acted-on classification is the mechanism that makes this distinction
operational. The practical effect is that upstream can add fields freely —
your boundary won't reject them because you never inspect them — but your
domain stays focused on what it actually needs.

### Why collect then reject

Step 4 recommends collecting all violations before rejecting. This is a
kindness to your users: discovering one error, fixing it, resubmitting, and
discovering another is a miserable experience. A single rejection that
surfaces every problem lets them fix everything in one pass. This is still
failing early and loud — you're just being loud about *everything* at once
rather than drip-feeding errors.

### Pass-through services

Step 5 says discard what you don't act on. The exception is services that
explicitly act as relays — forwarding payloads to downstream consumers. In
that case, preserving unknown fields is a domain requirement (the relay's
job is to pass data through). But this is a specific architectural choice,
not the default. Most services should keep their domain objects tight: only
fields they use.

### The pristine interior

Step 6 creates a hard boundary: before it, data is untrusted; after it,
data is clean. This is DDD's anti-corruption layer concept. The payoff is
that every function inside the domain can assume its inputs are valid — no
nil-checks "just in case," no defensive coercions. If domain logic contains
defensive checks for data that came through a boundary, either the boundary
validation is incomplete or the domain doesn't trust it. Both are bugs.

### Relationship to Unit Testing

In the Compute or Coordinate model, boundary validation is computation —
pure input-to-result logic that can be tested without collaborators. The
coordinator calls the validator, then acts on the result. This means
validation logic gets thorough unit tests (many edge cases, data-driven)
while the coordinator test only needs to verify that invalid input causes
rejection — not re-test every validation rule.

### Relationship to Domain-First Packaging

Where the boundary lives in the package structure matters. Validation code
belongs at the package boundary — the entry point that external callers
use. It should not be scattered through internal domain logic. The domain
package's public API accepts domain types (already validated); the boundary
adapter accepts external types and converts them.

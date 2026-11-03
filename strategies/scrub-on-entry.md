# Scrub on Entry
TENET: Fail Early and Loud

1. Identify the system boundary — where does external data cross into your domain?
2. Classify each incoming field: acted-on (your code branches on it, computes with it, or stores it as a fact) vs. not-acted-on.
   - Good: the code depends on the value; such as a status it branches
     on, or an amount it stores as a fact.
3. For every acted-on field, define what values are valid — including relationships between fields. The constraints are whatever your domain logic assumes to be true.
   - Good: each assumption the domain makes, written down; such as a
     quantity above zero, or an end date after the start date.
4. Validate all acted-on fields at the boundary. Check each record in full and report every violation, naming the fields it involves, so the caller can fix them all in one round.
   - When the input holds many records, a project may cap how many records it reports, at a number that suits who reads the rejection, or stop checking early, between records. Each reported record still lists every violation in it, and a capped rejection must say how many errors it found after checking how many records, and how many it shows, such as "1,200 errors in 5,000 rows; first 20 shown" or "25 errors in the first 400 rows, all shown; stopped checking".
5. Discard fields you don't act on. They aren't part of your domain — don't model what you don't use.
6. Construct a domain object from validated data. After this point, domain logic never questions whether its inputs are valid.

OUTCOMES:
- Domain logic contains no defensive nil-checks, type coercions, or "just in case" defaults for external data.
- Each reported record names every invalid field and the constraint it violated; a capped rejection states how many errors it found after checking how many records, and how many it shows.
- Fields you don't act on are excluded from validation — rejections only fire on things that would actually cause failures.

MISAPPLICATIONS:
- Validating everything — including fields you don't use, turning
  the boundary into a brittle schema check that breaks whenever
  upstream adds a field.
- Scrubbing but using the dirty version — validating at the boundary
  but then passing the raw input to domain logic instead of the
  constructed domain object.
- Re-validating deep inside domain logic "just to be safe" — if
  domain code contains defensive checks for data that crossed a
  boundary, the boundary isn't trusted and hasn't actually scrubbed.
SKIP WHEN: Data you validated on entry to this service and haven't re-read from an external source since. Also skip when your code genuinely doesn't act on any field in the payload — but if you act on even one, scrub it.

---
<!-- Rationale below — read when creating protocols, reviewing, or
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

Step 4 reports every violation in a record before rejecting. This is a
kindness to your users: discovering one error, fixing it, resubmitting, and
discovering another is a miserable experience. A single rejection that
surfaces every problem lets them fix everything in one pass. This is still
failing early and loud — you're just being loud about *everything* at once
rather than drip-feeding errors.

A large input, such as a file of thousands of rows, can fail in thousands
of places. Whether to cap, and where, depends on who reads the rejection:
a program calling an API can take every error and sort them itself, while
a person uploading a file is better served by the first few. Ten records
can be a lot in one place and a hundred too few in another, so the
strategy names no number. Where a cap helps, it keeps the rejection
readable; saying how many errors were found after checking how many
records, and how many are shown, keeps it honest, since the caller knows
how much is left and whether checking stopped early. The cap falls between
records, never inside one, so each record shown can be fixed in one go.

Stopping the checking itself early is a separate call. When checking is
expensive and a large share of the records so far have failed, the input
is likely wrong as a whole, such as the wrong file or shifted columns, and
checking the rest only repeats the same error: stop between records, and
say how many errors you found after checking how many records.

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

### Cross-references

- **UTC Computation**: the entry point where this strategy builds the
  domain object is also where UTC Computation converts every instant,
  the current time included, to UTC (its step 2), so the domain object
  holds UTC from the start.

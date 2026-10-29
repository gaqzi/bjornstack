# UTC Computation
TENET: Consistent Beats Correct

1. Every computation that turns a time into a date or a time of day
   uses UTC, unless its result is read against one person's or one
   place's clock, so that someone in another zone would need a
   different answer. Then that zone is an input of the computation,
   times set by that clock are kept as local date and time plus the
   zone's name, and the feature's design document says once which
   zone and why.
   - Good: log files rotate by UTC day; programs and on-call staff in
     several zones read them, and no one zone is the point.
   - Good: the design document says opening hours follow the shop's
     zone, and "is the shop open now?" takes `Pacific/Auckland` as an
     argument.
   - Good: a clock fixed by a contract or a law: settlement days follow
     the exchange's city because its rules say so, and invoices are
     dated by the seller country's calendar because its tax law does.
   - Good: a meeting set for 09:00 in Auckland next March is stored as
     that local date and time plus the zone's name.
   - Bad: the server's own zone decides the date because that is where
     it runs.
2. Convert every instant to UTC where it enters your code: parsed
   input, values read back from storage, and the clock. Asking the
   clock for the time is reading an input. Values that step 1 keeps
   as local time plus a zone name stay as they are.
   - Good: the command reads the clock, converts the result to UTC and
     passes that on.
   - Good: `2026-03-02T01:30:00+02:00` from a request becomes
     `2026-03-01T23:30:00Z` when it is parsed.
   - Bad: timestamps are converted to UTC when written to storage, but
     the current time is passed on in the machine's zone.
3. Inside each computation, convert every value into the
   computation's zone before turning it into a date or a time of day:
   UTC, the zone step 1 made an input, or for a value kept local, the
   zone stored with it. Never rely on the zone a value happens to
   carry.
   - Good: the week-grouping function converts each entry and the
     current time to UTC itself, then works out their weeks.
   - Bad: the week-grouping function trusts its callers to have
     converted, so the one caller that forgets mixes two zones.
4. Show local time only to people, converted as the last step before
   output, into the viewer's zone passed in. Output that programs read
   is UTC with the offset written out, or local time with its zone
   name for values step 1 keeps local.
   - Good: the page shows each entry in the reader's zone; the file
     behind it stores `2026-03-01T23:30:00Z`.
   - Bad: a local time is written to a file without its zone and later
     parsed back to compute with.
5. Test every computation that turns a time into a date or a time of
   day with values from a zone east of the computation's zone and one
   west of it, each at a moment that falls on different dates in the
   two zones.
   - Good: a week-grouping test in UTC where the current time is 00:30
     on a Monday at UTC+2, still Sunday in UTC, and another at 21:00
     on a Sunday at UTC-5, already Monday in UTC.
   - Bad: every test builds its times in UTC, so a computation that
     relies on the values' own zone passes.
6. Run the tests of every code path that reads the clock and turns
   the result into a date or a time of day with the machine's zone
   set east of UTC and again west of it.
   - Good: the suite runs with the machine's zone set to UTC+2 and to
     UTC-5, so a path that leaves the clock in the machine's zone fails
     on the cases step 5 put on that side.
   - Bad: the tests and the machine are both set to UTC, so a path
     that never converts the clock passes.

OUTCOMES:
- Every computation that turns a time into a date or a time of day
  uses UTC, or a zone it takes as an input with the reason written
  down once.
- Every instant is UTC from the point it enters the code, the current
  time included, unless step 1 keeps it local with its zone name.
- Changing the zone the inputs carry, or the zone the machine is set
  to, changes no stored value and no computed result, apart from
  values step 1 keeps local and output for people.
- Local time without its zone name appears only in output for people.
- Every computation that turns a time into a date or a time of day
  has tests on both sides of its zone, and every path that reads the
  clock for one runs under a machine zone east and west of UTC.

MISAPPLICATIONS:
- Converting some entry points and not others. Values from storage
  agree with each other and the clock does not, so the code is wrong
  for a few hours on either side of every boundary and right the rest
  of the time.
- Keeping UTC for a computation whose meaning is local.
  Examples:
  - A "daily" report cut at UTC midnight for users who all live in one
    city nine hours away, so their day ends in the middle of their
    afternoon.
  - A future appointment set by local clock time stored only as UTC.
    If the zone's rules change before the appointment, the stored
    instant no longer matches the time the person chose.
- A calendar date with no time, such as a birthday or an invoice date,
  turned into midnight UTC. Shown west of UTC it becomes the day
  before. A date with no time is not an instant and stays a date.
- Durations and timeouts converted to UTC: elapsed time has no zone,
  and converting it adds code that does nothing.

SKIP WHEN: The code never turns an instant into a date or a time of
day: it only measures elapsed time, sets timeouts, handles calendar
dates that have no time, or passes a timestamp on without reading
it.

---
<!-- Rationale below — read when creating protocols, reviewing, or
questioning the strategy. Not needed for routine application. -->

## Rationale

### Why one default

Consistent Beats Correct asks for one default that every reader can
assume, with deviations visible. UTC is a cheap default: it has no
daylight saving, every library supports it, and most systems already
store it. The interesting cases are the exceptions, and step 1 makes
each one an explicit input with a written reason, so a reader who sees
a zone other than UTC knows it was chosen. A computation that quietly
uses local time is exactly the difference Consistent Beats Correct
warns about: the reader cannot tell whether it is meant or accidental.
UTC itself needs no written reason, because it is the default. Any
other reason to deviate falls under Consistent Beats Correct and is
stated once, in the design document, in the same way.

Step 1 comes first because converting at entry throws away the
sender's offset, which can be the only sign of whose day they meant.
Decide whose calendar a computation follows before deciding what to
keep.

### Instants and calendars

In most languages two time values compare correctly whatever zones
they carry: they are the same instant or they are not. The trouble
starts when a value becomes a date, a week, a month or a time of day,
because that conversion uses the value's own zone. Two values that
agree as instants can disagree as dates. That is why steps 3 and 5
are about turning a time into a date or a time of day, and not about
comparisons.

Steps 2 and 3 overlap on purpose, and step 2 is the rule the rest of
the code relies on: stored values, comparisons, logs and output are
right only when every instant is UTC from entry. Step 3 is the second
line of defence, and it covers calendars only. It keeps a date from
depending on every caller having followed step 2, so a missed entry
point has to be missed twice before a date comes out wrong. A computation
that passes because of step 3 does not make step 2 optional.

### Relationship to Fail Early and Loud

Fail Early and Loud asks for problems to surface where they happen. A
mixed-zone computation raises no error: it gives the right answer most
of the day and the wrong one for the hours between UTC midnight and
local midnight. Tests written in UTC and run on a machine set to UTC
cannot see it. The clock is the entry point most often missed, because
many languages return the current time in the machine's zone, and
only a test that reads the real clock on a machine set elsewhere sees
it. Steps 5 and 6 are the two ways to make the mistake fail where
someone is looking. A zone east of UTC shows the mistake late at
night in UTC and a zone west of it early in the UTC morning, which is
why steps 5 and 6 each ask for both sides.

### Local values that stay local

A time a person chose by the clock on their wall, such as a meeting at
09:00 or a reminder every morning at 08:00, is a local time by
definition. Storing it only as UTC fixes the instant using today's
zone rules; if those rules change, the meeting moves. That is why step
1 keeps such values as local date and time plus the zone's name, and
step 2 leaves them alone. For a repeating time, each occurrence is
converted to UTC when it is needed, using the zone's rules for that
date.

### Edge cases

- Code whose callers are unknown, such as a library function that
  groups values by week, cannot answer step 1's question itself. It
  takes the zone as an input and leaves the choice to its caller.
- Output read by both people and programs, such as log lines that a
  collector also parses, counts as output for programs.
- A value that arrives with no zone at all, such as a database column
  without one or a timestamp in a CSV file, cannot be converted until
  it is given one. Its zone is the one the source's contract names;
  when the contract names none, that is a gap in the contract, not a
  reason to assume the machine's zone.
- Calendar arithmetic in a named zone, such as "the same time
  tomorrow", belongs to step 1's computations: across a daylight
  saving change a local day is 23 or 25 hours long. A local time that
  does not exist or occurs twice on that day needs a stated rule in
  the same design document, and a test at a moment inside the
  transition hour.

### Cross-language expression

Some languages' time values carry a zone; others carry none and leave
the zone to convention. Where values carry none, the protocol for that
language states that they are UTC and makes it true at the entry
points in step 2, since nothing in the value will say so. Most test
runners take the machine's zone from the environment, which is how
step 6 is done.

### Cross-references

- **Scrub on Entry** (FEAL): converting to UTC happens at the same
  entry point where Scrub on Entry builds the domain object, so the
  domain object holds UTC from the start.
- **Boundary Communication**: a time value in a boundary's contract is
  part of that contract; the contract states that it is UTC, or names
  the zone when step 1 keeps it local.
- **Say It Once**: a comment saying "always UTC" is a rule the code
  relies on; steps 2 and 3 are how the code enforces it, as Say It
  Once step 4.1 asks.
- **Test Data Builders**: a builder's edge cases can include timestamps
  in other zones (TDB step 6); step 5 says which moments those edge
  cases need when the type reaches a computation turning times into
  dates.

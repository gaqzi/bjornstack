# Time in Tests
TENET: Compute or Coordinate

1. Name what the test must show about time, then pick how the test
   gets its times. Take the first that fits:
   1. The test shows a decision that depends on the time, such as
      whether a trial has ended or which billing period a charge falls
      in. The
      decision is a computation: pass the current time and the other
      times in as data and test it there, with no clock.
   2. The test shows the system acting on data of some age, such as an
      expired coupon refused at checkout. The age comes from data the
      test supplies: an input's own timestamp, or stored state the test
      builds before the system starts. Build that data with fixed
      times and let the system read the real clock.
   3. The test shows behaviour that unfolds as time passes, such as an
      insurance policy across its whole term, a retry schedule, or a
      session expiring while it is open. Control the clock: the test
      sets it and moves it forward.
2. Read the clock in coordination only. The code reads the current
   time once per piece of work, such as per request, per message or
   per pass of a loop, and passes that instant to every computation
   that needs it, so every decision can be tested as step 1.1 says.
   - Good: computations take the current time as an argument; such as
     a function that picks the overdue invoices given the invoices and
     "now", or a request handler that reads the clock once
     and hands the instant to pricing and to the audit record.
   - Bad: a computation reads the clock itself, so its tests need a
     controlled clock to see one boundary.
3. Keep fixed times far from every boundary the outcome depends on,
   and assert on what the age decides, not on values worked out from
   today. When two boundaries sit too close together for a safe
   margin, test that decision under step 1.1 and keep the end-to-end
   test to what fixed data can show.
   - Good: the outcome cannot change whatever day the test runs; such
     as an order from years back checked to show as overdue, or a
     token that expires decades from now checked to be accepted.
   - Bad: a charge made two days ago checked to be in this month's
     statement, which fails on the first and second of each month.
4. When step 1 sends a test to a controlled clock, the clock enters
   the code as any collaborator does: passed in where the coordination
   is built. A black-box test of time passing builds the program in
   the test, or starts it, with a clock the test controls. A date the
   domain itself defines, such as "run billing as of" or a policy's
   effective date, is input, not a test setting. Nothing in the
   shipped program reads a test setting to change the current time.
   - Bad: an environment variable that the service reads to override
     "now", present in production builds so that end-to-end tests can
     set it.

OUTCOMES:
- Every decision that depends on the time has tests that pass the
  times in as data, with no clock to set.
- No test of data of some age sets the clock; the age comes from the
  data it supplies.
- A clock that tests move forward appears only in tests whose subject
  is time passing, and enters as a collaborator passed in.
- No shipped code path reads the current time from a test setting.

MISAPPLICATIONS:
- A controlled clock or a "now" override added so that a test can see
  one old item, when stored data or an input dated years back would
  show the same thing.
- Fixed data for behaviour whose subject is time passing.
  Examples:
  - A policy's renewal tested with one snapshot per state, so no test
    sees the states follow each other in order.
  - A retry schedule tested by checking each delay alone, never that
    the retries happen in sequence.
- Fixed times close to today, such as "yesterday" or "this week", so a
  test changes outcome depending on the day or hour it runs.

SKIP WHEN: The code makes no decision that depends on the current
time.

---
<!-- Rationale below — read when creating protocols, reviewing, or
questioning the strategy. Not needed for routine application. -->

## Rationale

### Why fixed data comes before a controlled clock

A controlled clock is the first tool many reach for, because it makes
any test about time possible. It also costs the most: every
coordination that reads the time needs a way to take a clock, the
test has to set it before the system starts, and an end-to-end test
often ends up with a setting in the shipped program that changes
"now". Most tests about time do not need any of that. A decision
about time is a computation, and Compute or Coordinate already asks
for it to take its inputs as data. What is left is seeing the system
act on old or new data, and data dated far from today shows that
without touching the clock.

A controlled clock earns its cost when time passing is the subject:
the order of states over a policy's term, or how retries space out.
There, fixed data shows each state but not the movement between them.

A unit test of a coordinator that reads the clock still replaces the
clock with a fixed double, as Unit Testing asks for any collaborator.
That double never moves; it is not the controlled clock of step 1.3.

### Choosing the margin

A margin is safe when no day the test could run on moves the data
across a boundary. One boundary is easy: date the data years away
from it. Two boundaries close together, such as a trial that has ended
but is still inside its grace period, leave no such margin, which
is why step 3 sends that decision to a test that passes the times in.

### Cross-references

- **UTC Computation**: steps 5 and 6 there say which moments and
  machine zones a test of a time-to-date computation needs; this
  strategy says how the test gets its times at all.
- **Unit Testing**: a computation given the current time as data is
  tested as Unit Testing says, with no clock to set up; a coordinator
  that reads the clock gets a fixed double like any collaborator.
- **Test Data Builders**: a test whose subject is age sets the time on
  the builder itself, at step 3's margin, rather than relying on the
  builder's default.

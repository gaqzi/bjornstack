# Failure Identity
TENET: Fail Early and Loud

1. Give a failure an identity, something a caller can compare rather
   than read, only when some caller handles it differently from other
   failures: retries it, creates the missing thing, asks the user to
   fix their input, answers with a specific status. Logging it doesn't
   count, whether or not the caller carries on.
   - Good: "order not found" gets an identity; the handler answers 404.
   - Good: "config file is not valid JSON" gets none; the only caller
     prints it and exits.
   - Good: a parsing library, whose callers aren't known, gives "syntax
     error at line N" an identity: the input is the caller's to fix.
   - Bad: an identity for "not valid JSON" added only so a test can
     check it.
2. Make the identity something the caller compares, never text it
   searches. Put the values the caller needs in it as data, and
   document it with the operation that reports it.
   - Good: a `NotFound` failure carrying order ID `order-42`.
   - Bad: the caller checks whether the message contains "not found",
     or reads the order ID back out of the text.
3. Translate where a failure enters your code from outside. The unit
   that reads the file, queries the database or calls the service
   reports its own identities and never passes the outside one on.
   Every unit above it adds what it was doing to the message and
   passes the failure on unchanged, unless handling that failure is
   the unit's whole job, like a retry wrapper or a handler choosing a
   status.
   - Good: the order store turns "file does not exist" into
     `NotFound`. The coordinator above it returns
     `fulfil order "order-42": ` followed by the store's failure.
   - Bad: the store wraps "file does not exist" so its callers can
     match it, and moving the store to a database breaks them.
   - Bad: a coordinator switches on its collaborators' failures to
     retry one and rename another. Retrying belongs in a unit that
     wraps the collaborator.
4. When one operation reports several problems at once, ask what the
   caller acts on. If it acts on the whole, report one failure. If it
   acts on each part, report one failure per part.
   - Good: every problem with one submitted form is one "invalid
     input" failure listing them all.
   - Good: a batch of ten orders reports each order's failure on its
     own.
   - Bad: ten orders' failures merged into one, so a caller checking
     for "not found" treats the whole batch as not found.
5. Write the message for the human who must fix the problem: what
   failed, the values involved, and what was expected.
   - Good: `read order "order-42": open /data/order-42.json: permission
     denied`.
   - Bad: `read failed`.
6. Test the identity where there is one, and the facts in the message
   always, never its wording.
   - Good: the failure is `NotFound` for order ID `order-42`, and the
     message mentions `order-42`.
   - Good: a corrupt order file fails, and is not `NotFound`.
   - Bad: the message contains "could not be found".

OUTCOMES:
- No caller reads message text to decide what to do.
- Every identity has a caller that branches on it, or documentation
  that promises it.
- No outside system's identity is visible above the unit that calls
  that system.
- Rewording a message, keeping its facts, breaks no caller and no
  test.
- Every message names the values involved, so a human can act on it
  without reading the code.

MISAPPLICATIONS:
- A full catalogue of identities for a boundary whose callers only log
  and stop. Every one is contract to maintain, and none is checked.
- A unit that talks to an outside system wrapping the outside failure
  so its identity survives.
  Examples:
  - A web handler answers 404 because the database driver reported
    "no rows", two layers down.
- Identity carried in the text: codes, prefixes or fixed phrases that
  callers or tests match on. It is still message parsing.
- A combined failure checked for one cause, so that one cause decides
  how the caller handles all the others.

SKIP WHEN: The failure never leaves the unit that reports it: it is
handled there, and nothing outside ever sees it.

---
<!-- Rationale below — read when creating protocols, reviewing, or
questioning the strategy. Not needed for routine application. -->

## Rationale

### Two readers, two channels

A failure has two readers. Code decides what to do next; a human
decides what to fix. When both read the message, it serves neither:
rewording it for the human breaks the code, and keeping it fixed for
the code stops it improving for the human. The identity gives code its
own channel, which frees the message to be as informative as Fail
Early and Loud asks.

Code that cannot tell two failures apart treats them alike, and that is
how a failure goes silent. A store whose "permission denied" looks like
"not found" gets a fresh document written over the one it couldn't
read. The corrupt-file test in step 6 guards that line.

### Why not every failure gets an identity

An identity is a promise in the contract. Once a caller branches on
it, removing or splitting it breaks that caller, so Grow Don't Break
governs it like any other contract type. A failure nobody branches on
gains nothing from the promise and costs a type, a name and a
compatibility burden. Plain wrapping, where each layer adds what it was
doing, already gives the human a trail to follow.

### Where translation happens

The edge unit, the one that talks to something outside your code,
drops the outside identity from the first version on. That is what
lets every unit above it pass failures on without deciding anything:
its collaborators only report identities they promise, so passing them
on leaks nothing.

A caller branches on what happened, "order not found", which belongs to
the orders domain. It never learns which of a coordinator's
collaborators reported it, which is what Unit Testing step 3.4 asks.

Some units branch on failures as their whole job: the edge unit
translating, a wrapper that retries a timeout, a user-facing handler
choosing a status for each identity (directly or through a formatting
collaborator, Unit Testing step 3.4). What step 3 rules out is a
coordinator sorting its collaborators' failures alongside its other
work. That is computation, which Compute or Coordinate keeps out of
coordinators, and its tests multiply past Unit Testing's N+1. Checking
whether a call failed and passing the failure on is not sorting.

Keeping the outside identity out is not designed error handling, so it
fits Outside-In Development Loop's first pass: the edge unit passes the
outside message on without the identity. Which identities of its own it
promises is decided in the later, unhappy-path pass.

### Writing the fact checks

Step 6's fact check needs care to prove anything:
- Use values distinctive enough not to match by chance: quantity 250,
  not 0, which also matches "want 1 to 100".
- A fact that the collaborator's message also carries proves nothing
  about this unit. Give a test double a message of its own that leaves
  the other facts out.
- Text for a human inside an identity's data, such as each problem's
  description in an "invalid input" failure, is message. Leave it out
  of the comparison and check that it names its own facts.
- When the test sets up no fact the message should name, assert only
  that the operation failed.

### Cross-language expression

Languages carry identity differently: sentinel values, types matched by
kind, codes in a result object, status fields in a response schema. In
each, the identity is something the caller compares, never text it
searches. Mechanisms that link a failure to its cause often keep the
cause's identity visible through the wrapper. That is right above the
edge and wrong at it, so the protocol for such a language says how the
edge keeps the outside message without its identity.

### Cross-references

- **Boundary Communication**: BC makes a boundary's contract explicit;
  the failures a caller branches on are part of that contract, and this
  strategy says which ones and how a caller recognises them.
- **Scrub on Entry**: SOE collects every violation before rejecting;
  FI step 4 makes that rejection one failure for the caller, listing
  every violation for the human.
- **Unit Testing**: a coordinator's N+1 error tests (Unit Testing step
  3.4) each check that one collaborator's failure comes out through
  the coordinator's consistent error interface; FI step 3 says that
  interface keeps the collaborator's identity and adds what the
  coordinator was doing.
- **Compliance Test Suites**: the error conditions a suite exercises
  (CTS step 3) are the interface's identified failures, asserted by
  identity and data as step 6 says.
- **Outside-In Development Loop**: its designed unhappy path is where
  edge units decide which identities of their own they promise. In the
  first pass they already pass the outside message on without its
  identity.
- **Whole-Object Assertion**: step 6 compares an identified failure and
  its data as a whole, the same way WOA compares results.

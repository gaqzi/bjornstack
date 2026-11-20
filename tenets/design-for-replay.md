# Design for Replay
Changes take effect only and fully via stored events: accepted, never edited, safe to replay:

1. A request becomes an event only after it passes its checks.
2. The event is stored before anything outside the store acts on it.
3. A stored event is never edited, and is removed only through a later
   tombstone event that names what to remove and why.
4. Current state is kept only by projectors: reactions that apply
   stored events in order, so a rebuild gives the same state without
   running any other reaction.
5. Each reaction runs for every stored event it handles, records each
   change it makes outside the system, and skips work it has already
   recorded as done.

- Good: the request and the fact it produces are kept apart, and nothing
  outside the store acts until the fact is stored; such as a sign-up
  request checked, a "user created" event stored, and then both the users
  table and the welcome email driven by that event, or a 1,000-row import
  checked and stored as 1,000 "product added" events.
- Good: a reaction that reaches outside the system records what it did
  and does not repeat work it has recorded as done; such as the
  welcome-email reaction storing "welcome email sent" for each user, or
  a reaction calling a service that accepts an idempotency key, such as
  a payment provider, checking its own record first and passing the
  stored event's id with its own name as the key, so a retry after a
  crash between calling and recording gets the first call's result.
- Bad: the sign-up handler inserts the user row and sends the welcome
  email in the same step, so a failed insert leaves an email about a user
  who does not exist, and when the email turns out to have been wrong
  there is no record of who received which text.

VIOLATIONS:
- **act-only-after-stored.** Acting on a change before its event is stored.
  Examples:
  - A handler sends the welcome email, charges a card or notifies
    another system before, or while, it saves the change; the save fails
    and the outside world has been told about something that never
    happened.
  - An in-process event bus hands the event to its listeners before
    writing it; the process stops between the two and the email has gone
    out while the event is lost.
- State as the only record — a row is updated or deleted with no stored
  event behind the change, so the row's new value is the only trace and
  a step with a bug cannot be found or corrected by running it again.
  Examples:
  - An order's status field rewritten by each step of fulfilment, with
    nothing that says when or why it changed.
- Recording the request instead of the fact — "create user" stored
  rather than "user created", so a replay checks the request again
  against today's rules and may refuse what was accepted at the time.
- **events-unedited-tombstone-removal.** A stored event edited, or removed other than through a tombstone — an
  event edited to fix a typo, or a user's events deleted by hand with no
  record of what was removed or why, so a replay no longer sees what
  happened.
- **outside-effect-once-per-event.** A reaction run the wrong number of times — it gives up on a stored
  event after one failure and the email is never sent, or it runs again
  whenever state is rebuilt, so replaying a week of events to fix the
  users table also resends a week of welcome emails.
- Current state written by the code that stores the event — the
  sign-up handler inserts the user row in the same transaction as
  "user created", so a rebuild runs different code from the live path.

WHY: A system that keeps only its latest state and acts from inside the save has no record to trace or to run a fixed step over again, and a failure part way tells the outside world about changes that never happened.

---
<!-- Rationale below — read when creating strategies, reviewing, or
questioning the tenet. Not needed for routine application. -->

## Rationale

The common alternative is a system built from create, read, update and
delete on tables: a request arrives, a row changes, and whatever else
should happen (an email, a message to another system) happens in the
same piece of code. It is quick to start and hard to live with. The row
holds only the latest value, so when a step turns out to have had a bug,
there is nothing to run the fixed step over. The email sits inside the
save, so a failed save can still send it. And every new thing that wants
to react to the change has to be wired into that same piece of code.

Recording events first turns this around. The event is the fact; tables
of current state and reactions such as emails are consequences of it.
A consequence that was wrong can be thrown away and derived again from
the facts, and a new consequence can be added by reading the facts,
without touching the code that produced them.

### Terms

- **Request** (often called a command): what a caller asks for, such as
  "create user ada@example.com". It can be refused. It is checked on
  entry, as the Scrub on Entry strategy describes.
- **Event**: the fact that a valid request was accepted, named in the
  past tense, such as "user created". It cannot be refused, only
  reacted to. It holds what was decided at the time, so reading it again
  later gives the same answer, whatever today's rules say. Once stored
  it is never edited; a mistake is put right by a later event.
- **Tombstone**: the only way to remove stored events, such as when
  erasing a person's data on request. It is an event naming what to
  remove and why; a reaction removes the named events from the store,
  the projector removes what they put in current state, and the
  tombstone stays, recording what was removed, why and when, without
  the removed content. Replay and rebuilding see the tombstone, not
  what it removed.
- **Current state**: tables or objects that answer "what is true now".
  Projectors keep it. Each projector is a reaction like any other: it
  reads stored events in order, applies each one, and records how far
  it got as a checkpoint. Nothing else writes current state, not even
  the code that stores the event.
  - Reads: answers to callers and the checks on a request read current
    state, not a replay of the events.
  - Lag: current state lags the store until the projector has applied
    the newest event. A caller that must see its own change waits until
    the checkpoint passes its event.
  - Unique values: a check such as one account per email is made
    against current state and the rest of the same input, like any
    other check. Where a second request can be checked before the first
    is applied, the store refuses a second event for the same key, and
    that request fails. The key stays taken until an event frees it,
    such as "email changed" or a tombstone.
  - Checking: every event has been applied when the checkpoint reaches
    the newest stored event. This can be checked and reported.
  - Truth: the events are the source of truth. They are read to rebuild
    current state, to trace what happened, or to feed reactions.
- **Reaction**: code that acts when an event is stored, such as sending
  the welcome email after "user created". A reaction that changes
  something outside the system records what it did as an event of its
  own, such as "welcome email sent", and looks for those records in the
  store, not in current state, which may lag.
- **Replay**: reading stored events again, in one of two ways.
  - Rebuilding current state: the projector runs from the first event
    into a fresh copy, and no other reaction runs. Reads switch to the
    copy once its checkpoint reaches the newest stored event; until
    then the old copy keeps answering.
  - Running a reaction again: a deliberate choice of which events to
    run it over. After a bug in the welcome email is fixed, running the
    reaction again sends nothing, since each email is recorded as sent.
    The "welcome email sent" events record which text went out, so they
    name the users who got the wrong one. Sending them a correction is
    a new reaction, decided on its own. A reaction added later is the
    same choice: it handles the events chosen for it, such as those
    stored after it was added, not every past event by default.

### Storing the event is the moment of change

The change happens when its event is stored, and not before. Storing
it means writing it permanently where each reaction finds it, each
reaction recording how far it got; a bus fed from the store, keeping
each event until every reaction acknowledges it, is grown into by
need. If storing fails, the request fails, loudly, and nothing has
happened: no state changed, no email went out, and the caller can send
the request again; a request id lets the store recognise the second
copy when the first was stored but the answer was lost, and answer it
as the first, storing nothing new. Once stored the event is not lost: a
reaction that fails, or stops before recording that it is done, is
handed the event again, and one that keeps failing is reported, such
as by an alert or a count of events waiting, not retried in silence.

### Outside work that cannot be undone

An email sent or a card charged cannot be taken back by a failed save.
So such work is never part of a save. It is a reaction, and each
outcome it learns is stored as an event of its own before the next step
acts on it. Anything that should wait until the whole change is
settled, such as telling the warehouse to ship, reacts to the last of
those events, not the first.

A reaction cannot always avoid repeating itself. If it stops after the
outside call but before recording it, the call is made again when the
reaction is retried. What guards against the repeat depends on the
outside service:

- It accepts an idempotency key, as a payment provider does. The
  reaction passes the stored event's id with its own name as the key,
  and the service answers the repeat with the first call's result.
- It does not, as with most email. The reaction's own record of what
  it did is the guard, and the rare repeat after a crash is accepted
  and said so.

### Many records at once

An import of many records is many requests checked together. Scrub on
Entry's default holds: when any record is invalid, the import is
rejected and no event is stored for any of it. When the owner has chosen
to save the valid records, each valid record's event is stored and the
rest are reported. Either way the events for one import are stored in
one write, so a failure part way leaves none of them stored.

Receiving the file is worth recording too, as a log entry such as
"file received" that holds the file whatever its contents. It is not
an event about products and nothing reacts to it, so a rejected import
still saves nothing in Scrub on Entry's sense; it lets a bug in the
checks be found and the file checked again.

### Small systems too

This does not need a message broker, separate services or a framework.
In a single program it can be a table of events, one function per
request that decides which events to store, a projector that applies
each event to current state, and for each reaction, the projector
among them, a stored checkpoint of the last event it finished. The
extra cost over a table updated in place is small, and it keeps the
program open to being split later.

It applies to small local tools by default, even when nothing in them
reacts to the events yet. Reading the events is the easiest way to see
what a program did and in what order, easier than piecing it together
from logs and the current contents of a table.

Start with the least that gives stored events, replay and deletions.
A deletion is recorded as an event of its own, such as "user deleted",
and tombstones for removing stored data are built in from the start.

For a small tool the store can be the table of events above, or one
file such as JSON Lines:

- Each line holds all the events stored together in one write.
- Each line is synced to disk before anything reacts to it.
- A cut-off last line is ignored on reading.
- Each reaction records on disk the id of the last event it finished.
- The file is only appended to, except when a tombstone removes events.

A tool that keeps current state in memory runs its projector over the
file at startup, then over each line after it is synced, like any
other reaction. Copying the file elsewhere every so often is a backup,
not the moment of storing.

Grow the store by need, not by habit:

- When other processes react, add a bus that keeps each event until
  every reaction acknowledges it, such as Redis Streams, RabbitMQ, SQS
  or Kafka. Feed it from the store; don't write to it beside the
  store.
- When one machine is no longer enough, move to a distributed store.

Current state trails the store even in one process. Across processes
and machines the lag grows, and the system is eventually consistent,
as any large system is.

Separate models for checking requests and for answering callers are
not the default, nor is domain-driven design with its machinery. One
current state, kept by projectors, serves both. When a design starts
to need them, say so and decide it as a design choice. Don't patch the
simple version until it is a poor copy of them.

A case where the cost is not worth it, such as a throwaway script or a
table nothing reacts to and whose history nobody will ask about, is a
deliberate exception under Practicality Beats Purity, written down
where the next reader will meet it.

### Testing

Deciding which events a request produces, given the current state, is
a pure function; so is applying an event to state. Both are tested with
plain inputs and outputs: given these events, this request produces
those events. A reaction is a small coordinator tested on its own.

### What this is not

- Not a ban on tables updated in place. Current state, caches and
  search indexes are updated in place by their projectors; what matters
  is that they are derived from events and can be rebuilt.
- Not a rule about how domain packages talk to each other. An
  in-process bus that hands stored events to reactions is the
  coordinator Boundary Communication prefers, as long as no domain
  package imports another to subscribe. Once another process
  reads the events, they are a published contract: Boundary
  Communication and Grow Don't Break apply to them.
- Not a licence to change an event's shape freely. Stored events are
  read again years later, so old events stay readable by new code, as
  Grow Don't Break describes for any contract.

### Lineage

This is event sourcing, with the request/event naming common in command
query responsibility segregation, without its separate models, and the
store-before-publish rule of the
transactional outbox. The emphasis here is narrower than either pattern
in full: the goal is that any consequence of a change can be derived
again from what was stored.

### Cross-references

- **Fail Early and Loud** (complementary): FEAL checks the request on
  entry, so only valid requests become events; a failure to store an
  event fails the request loudly, and a reaction that keeps failing is
  reported rather than retried in silence. Design for Replay adds that
  nothing acts on the change until the event is stored.
- **No Shared Fate** (complementary): reactions that read stored events
  do not reach into the state of the code that produced them, and events
  are never edited once stored, so either side can change or move to
  another process without breaking the other.
- **Compute or Coordinate** (complementary): deciding events from a
  request and applying events to state are computation; storing events
  and running reactions are coordination. Design for Replay gives that
  split a natural shape.
- **Earned Abstraction** (tension): a general-purpose event bus built
  for the first system that records events is a premature abstraction.
  Resolution: write the specific events, the table and the loop the
  system needs; extract a shared bus only once about three systems have
  each written their own and the shape is visible.

Status: approved by the owner, 2026-11-20

# Key: briefkasten

The spec is the "Test Task" section of bs-9qz's design, as the first
prompt carries it. Each item of rubric.md is marked rule, brief or
owner. A rule item names the entry that settles it and says in one
line what that entry decides for this spec.

## domain-first-packaging

Item: "which business capabilities does the system own, each named by a noun?"

- Mark: rule
- Entry: domain-first-packaging#identify-domains
- Decides: the code is split by the jobs the service does for its user, such as choosing mailboxes, gathering new mail into the feed and moving old entries into weekly archives, each part named by a noun for that job and none by a technical role such as http or storage.

## compute-or-coordinate

Item: "which steps decide on data, kept apart from the steps that call outside systems?"

- Mark: rule
- Entry: compute-or-coordinate#logic-apart-from-collaborators
- Decides: what goes into a feed entry for each unread email Fastmail returns, which entries are older than a week, which archive file each moves to and how the archive files point to each other are worked out by code that neither talks to Fastmail nor touches files; the code that does those things only passes data in and out.

## boundary-communication

Item: "which one part owns each piece of data that more than one part writes or reads?"

- Mark: rule
- Entry: boundary-communication#single-owner
- Decides: feed.xml and the archive files are changed by both refresh and prune, so one part alone writes them and the others ask it to; the saved mailbox choices are written only by the part that saves them, and refresh only reads them; the read mark on each email, and the log of decisions, are changed only by the part that files emails into the feed, and undoing a mark to file an email again goes through that part.

## design-for-replay

Item: "what happens if a run stops between acting on an input and recording that it did?"

- Mark: rule
- Entry: design-for-replay#act-only-after-stored
- Decides: the service relies on another system's inputs: unread mail waits in a chosen mailbox, which keeps each mail unchanged and findable by its id after it is acknowledged. The service's stored events are its own log of decisions, each holding what was decided and the mail's id, such as "mail 123 filed into the feed". The event is stored before the feed file is written and before the mail is acknowledged. Each saved mailbox choice is stored before any folder or feed file is made from it.
- Entry: design-for-replay#outside-effect-once-per-event
- Decides: a mail is acknowledged only after its event is stored and the feed file holding it is written and confirmed. A stop before the acknowledgement leaves the mail waiting, and the next run handles it again; the feed writer finds it already in the feed and adds nothing, and feed readers handle any duplicate. Filing a mail again starts with a stored event, such as "mail 123 reopened", and the next run files it; marking the mail unread as well is optional and only shows people what is waiting.
- Losses, by design-for-replay's "Relying on another system": a mail that expires, is deleted, or is read elsewhere before a run is never filed, and replay reaches only mail still in the mailbox. The owner accepted these on bs-f3o.7.18: "that's an external force and this system doesn't need to care about that. it only cares about unread/read emails" and "it's not really *that important* if something goes wrong (as determinde by me, the end-user)". The rule sends each loss to the owner, so a run that names the losses and raises them, or lists them under "Open decisions for the user", still counts as applied. A run that accepts them itself scores answered-for-you.
- Both rule entries are needed, by the owner's answers on bs-f3o.7.14: the rule part is applied only when the run applies both. A run that applies only one, or cites an entry but decides against what it decides here, has not applied it; it scores answered-for-you, or raised if it asked the owner about the other first.

- Mark: owner, for what acknowledges a mail.
- Decides: the owner picked marking the mail read, in the answer "Your design only" on bs-f3o.7.14. A stored since-last-check cursor, or the service's own copy of each mail, does not settle the item.

The item is right only when the rule part, both entries and the losses, is applied and the acknowledgement is raised with the owner. Otherwise it takes the worst outcome of the parts that fail, in the order wrong, missed, late, asked needlessly.

## utc-computation

Item: "which clock and zone decides the date a time falls on?"

- Mark: rule
- Entry: utc-computation#utc-unless-one-zone-matters
- Decides: the ISO week an entry is archived under, and the week feed.xml covers, are worked out in UTC, because no one person's clock is the point of an archive file; "older than one week" is a length of time and needs no zone.

Status: draft, awaiting the owner's approval

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
- Decides: feed.xml and the archive files are changed by both refresh and prune, so one part alone writes them and the others ask it to; the saved mailbox choices are written only by the part that saves them, and refresh only reads them; the read mark on each email, and the log of emails marked read, are changed only by the part that files emails into the feed, and undoing a mark to file an email again goes through that part.

## design-for-replay

Item: "what happens if a run stops between acting on an input and recording that it did?"

- Mark: rule
- Entry: design-for-replay#act-only-after-stored
- Decides: the mailbox is where each new email is kept, and an unread email in a chosen mailbox is one still to be filed; the feed file is written from it there, and the service keeps no copy of its own. Each saved mailbox choice is saved for good before any folder or feed file is made from it.
- Entry: design-for-replay#outside-effect-once-per-event
- Decides: an email is marked read only once the feed file holding it is written and confirmed, as a message is acknowledged on a queue, so a failed write leaves it unread and the next run tries again. A stop after the write but before the mark writes the entry again on the next run; that duplicate is accepted, because the feed readers handle duplicates. The service logs each email it marks read; to file emails again, it marks the logged ones unread and the next run files them.
- Both entries are needed to settle this item, by the owner's rulings in bs-2ph and bs-30v: the item counts as applied only when the run applies both. A run that applies only one of them has not applied the item.
- Only the design above settles it, by the owner's ruling in bs-7g5: a run whose service keeps its own copy of each email has not applied the item.

## utc-computation

Item: "which clock and zone decides the date a time falls on?"

- Mark: rule
- Entry: utc-computation#utc-unless-one-zone-matters
- Decides: the ISO week an entry is archived under, and the week feed.xml covers, are worked out in UTC, because no one person's clock is the point of an archive file; "older than one week" is a length of time and needs no zone.

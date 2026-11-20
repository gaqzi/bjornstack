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
- Decides: which emails are new since the last check, what goes into a feed entry, which entries are older than a week, which archive file each moves to and how the archive files point to each other are worked out by code that neither talks to Fastmail nor touches files; the code that does those things only passes data in and out.

## boundary-communication

Item: "which one part owns each piece of data that more than one part writes or reads?"

- Mark: rule
- Entry: boundary-communication#single-owner
- Decides: feed.xml and the archive files are changed by both refresh and prune, so one part alone writes them and the others ask it to; the saved mailbox choices are written only by the part that saves them, and refresh only reads them.

## design-for-replay

Item: "what happens if a run stops between acting on an input and recording that it did?"

- Mark: rule
- Entry: design-for-replay#act-only-after-stored
- Decides: each saved mailbox choice and each new email found is saved for good before any feed or archive file is written from it, so a stop part way leaves nothing in the files that was not saved first.
- Entry: design-for-replay#outside-effect-once-per-event
- Decides: the service notes each feed and archive file write it has made, tries a failed write again rather than giving up, and does not write the files again when it reloads its own saved data; an entry written twice after a stop before the note is accepted, because the feed readers are the ones that handle duplicates.
- Both entries apply, by the owner's ruling in bs-2ph.

## utc-computation

Item: "which clock and zone decides the date a time falls on?"

- Mark: rule
- Entry: utc-computation#utc-unless-one-zone-matters
- Decides: the ISO week an entry is archived under, and the week feed.xml covers, are worked out in UTC, because no one person's clock is the point of an archive file; "older than one week" is a length of time and needs no zone.

# Story definition rubric

The Checks read the design the agent wrote (the epic's design
section). The first five sections each hold one Item and its Checks.
The first-slice section holds Checks and no Item.

In the first five sections, a Check passes when the design records
the decision and names who decided it, whichever way the decision
goes. The first-slice Checks also judge the decision, and say when it
fails. Who decided it is one of these, and counts only if it can
settle that point:

- a rule entry, cited by its file stem and id or by its file and
  step, that covers the decision; an entry cited for an unrelated
  decision does not count;
- the first prompt, with its words quoted;
- the owner, through an answer they gave.

A blanket line, such as one saying every decision follows the owner,
names no one.

A Check in the first five sections scores n/a when the design lists
its Item under "Open decisions for the user" with no answer. The
verdict already scores that Item as raised. In the same way, a
first-slice Check scores n/a when the design lists its decision,
whether the feature needs a slice 0 or whether it is split, under
"Open decisions for the user" with no answer. The slice 0 decision
covers both slice 0 Checks.

## domain-first-packaging

Item: "which business capabilities does the system own, each named by a noun?" (domain-first-packaging#identify-domains)

- Check: the design lists the business capabilities the system owns, and names who decided that list. (domain-first-packaging#identify-domains)
- Check: the design gives each listed capability a package name, and names who decided each name. (domain-first-packaging#name-for-domain)
- Check: for each pair of listed capabilities the design says exchange data, it records how they reach each other, and names who decided it; or it states that no listed capabilities exchange data, and names who decided that. (domain-first-packaging#no-sibling-domain-imports)
- Check: the design records where each package sits in the directory tree, and names who decided the layout. (structure-is-intent#tree-shows-boundaries)
- Check: for each package the design names that is not a listed capability, it records what the package holds, and names who decided to have it; or it states that every package is a listed capability, and names who decided that. (structure-is-intent#no-grab-bag-packages)

## compute-or-coordinate

Item: "which steps decide on data, kept apart from the steps that call outside systems?" (compute-or-coordinate#logic-apart-from-collaborators)

- Check: the design records which steps decide on data, which steps call collaborators, and whether the two are kept apart, and names who decided it. (compute-or-coordinate#logic-apart-from-collaborators)
- Check: for each place the design says data passes from one collaborator to another, it records which step reshapes the data on the way, and names who decided it; or it states that no data passes between collaborators, and names who decided that. (compute-or-coordinate#mapping-holds-no-business-rules)
- Check: for each step the design says calls collaborators, it records how the step gets those collaborators, and names who decided it. (testing__unit#collaborators-received-set-up)

## boundary-communication

Item: "which one part owns each piece of data that more than one part writes or reads?" (boundary-communication#single-owner)

- Check: the design lists the data that more than one part writes or reads, where at least one part can change it, or states that there is none, and names who decided it. (boundary-communication#find-shared-data)
- Check: for each piece of data on that list, the design records which part or parts own it, and names who decided it. (boundary-communication#single-owner)

## design-for-replay

Item: "what happens if a run stops between acting on an input and recording that it did?" (design-for-replay#act-only-after-stored, design-for-replay#outside-effect-once-per-event)

- Check: for each input the design says the feature handles, it records whether the input is stored as an event before anything outside the store acts on it, and names who decided it. (design-for-replay#act-only-after-stored)
- Check: the design records how a stored event is corrected or removed, or that nothing is stored as events, and names who decided it. (design-for-replay#events-unedited-tombstone-removal)
- Check: for each effect outside the system that the design names, it records what happens after a stop between acting and recording, after a failed attempt, and on a replay or rebuild, and names who decided it; or it states that the feature has no effect outside the system, and names who decided that. (design-for-replay#outside-effect-once-per-event)

## utc-computation

Item: "which clock and zone decides the date a time falls on?" (utc-computation#utc-unless-one-zone-matters)

- Check: for each place the design says it turns a time into a date or a time of day, it records which zone the computation uses, and names who decided it; or it states that the feature turns no time into a date or a time of day, and names who decided that. (utc-computation#utc-unless-one-zone-matters)
- Check: for each computation the design says uses a zone other than UTC, it says which zone and why, and names who decided it. (utc-computation#utc-unless-one-zone-matters)
- Check: for each time the design says is set by one person's or one place's clock, it records how the time is stored, as local date and time plus the zone's name or otherwise, and names who decided it. (utc-computation#utc-unless-one-zone-matters)

## first-slice

This is the one section whose Checks judge the decision. They read
the design and the turns up to and including the first story, since
slice 0 or slice 1 is usually the first story.

When the owner, through an answer or the first prompt's quoted
words, decides against a step of the strategy, the Check passes if
the design records both that it was the owner's call and that the
decision breaks the cited step, naming its id; such as
"owner: no slice 0; breaks thin-vertical-slice#needs-slice-zero". An
owner's decision against a step recorded without that note fails.
This holds for all three Checks.

- Check: the design records whether the feature needs a slice 0, and names who decided it. A slice 0 is needed when the feature's path needs infrastructure, a runtime or a deploy path the codebase has never run, such as a new process, message broker, kind of store, scheduler, or a new service or project. A new implementation behind something already wired is ordinary new code. It fails when a slice 0 is proposed for a path that needs nothing the codebase has never run, or when no slice 0 is planned for a path that needs infrastructure, a runtime or a deploy path the codebase has never run. (thin-vertical-slice#needs-slice-zero)
- Check: where the design has a slice 0, it only shows the new path working end to end, in a way someone can see, and does no business work. It fails when slice 0 does business work, builds more than the one new path needs, or shows nothing someone can see. (thin-vertical-slice#slice-zero-wires-only)
- Check: the design records whether the feature is split, and names who decided it. A split counts only when the design names parts someone could use apart and why doing all of them together is too large to review on its own; slice 1 is then one usable part that lands sooner than the whole feature. It fails when the request has parts someone could use apart that together are too large to review on its own, and it gets no split. It also fails when a request one slice delivers is split, or when slice 1 is not one part someone can use. (thin-vertical-slice#one-slice-not-split, thin-vertical-slice#slice-one-useful-sooner)

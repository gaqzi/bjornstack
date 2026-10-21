# Say It Once
TENET: Be Your Name

1. Leave alone what a public name's documentation tells its callers —
   what it does, takes, returns, and how it fails — even when it repeats
   the name. Callers read it instead of the code. A precondition the
   caller must meet is a rule, and a sentence about internals the caller
   can't observe isn't for callers: sort both. Sort everything else, in
   comments and in design documents, one claim at a time, taking the first
   bullet that fits:
   - A rule the code relies on but doesn't check — the caller holds a
     lock, a value is already normalised, another component never does X,
     a field stays because old clients still read it. This includes rules
     written in a caller's documentation: continue at step 4.
   - History that no longer explains the code, or a plan — what it
     replaced, what's left to do: move history to the commit message and
     plans to the issue tracker.
   - Reasoning that would survive a rewrite with the same behaviour — what
     the feature must do and why: continue at step 2.
   - Anything else is about this implementation — why this structure, this
     value, this order: continue at step 3.
2. Feature reasoning: keep it once, in the feature's design document, and
   keep the document to that. Code that exists because of a requirement
   states it in a sentence where it matters; point to the document only
   when a reader needs more than that sentence.
3. Implementation reasoning: keep it in the code, where the reader is when
   they need it.
   1. Delete what the code already says. If the code can't be read without
      it, rename until the name says it.
   2. Say the rest in a sentence at the point of use: why this value, why
      this line is written the non-obvious way, which obvious alternative
      was rejected and why that still holds.
   3. When it takes more than a sentence, several places share it, or it
      is about the whole unit (why this data structure), write it once in
      the nearest overview that covers all of them — the function, then
      the type, then the file, then the module. A picture of how the parts
      relate goes there. An algorithm's parts may take short names when an
      overview of a function, type or file defines them and only that
      scope uses them. An overview of internals goes where people changing
      the code read it, not in the documentation callers read.
4. A rule the code relies on:
   1. Make the code enforce it if you can — a type that can't hold a bad
      value, built where the data enters; a check that fails loudly;
      taking the lock inside instead of asking the caller to. Then delete
      the comment. This changes behaviour: make it its own change, with a
      test that the check fires.
   2. When this code can't enforce it, write it where the person who must
      keep it will read it — the caller's documentation for a rule callers
      follow, the code itself for one it relies on internally — saying what
      must hold and what breaks if it doesn't. When the rule spans
      components, each states it where it relies on it, and the feature's
      design document states the decision they all rely on. Where a test
      can catch the rule breaking, write that test.

OUTCOMES:
- Design documents hold only reasoning that would survive a rewrite with
  the same behaviour; nothing in them describes this implementation.
- A reader learns why a value, a structure or a non-obvious line is so
  without leaving the code: from a sentence at that line, or from the
  nearest overview.
- Every short name for an algorithm's parts is defined in an overview
  whose scope holds all its uses.
- Every rule a comment says the code relies on is enforced by the code, or
  is written where whoever must keep it reads, with what breaks — and a
  test catches it breaking where one can.
- No comment repeats the implementation or tells the story of a change.

MISAPPLICATIONS:
- A pointer where a sentence would do — the reader leaves the code for
  something one line could have said.
  Examples:
  - "Why 64: see the design doc, Growth" on a constant, when the reason is
    "doubling keeps inserts cheap; 64 stops small files regrowing every
    few keystrokes".
- A design document that walks through the implementation — the data
  structure, its constants, the order of operations — and goes stale on
  the next refactor.
- An overview that restates every function below it — a second copy of
  the code instead of the picture that ties it together.
- Deleting a rule that still holds — the next person to edit the line can
  no longer see it.
  Examples:
  - Removing "the caller holds the lock" when nothing inside takes it.
  - Moving "kept for v1 clients" to the commit message as history while
    v1 clients still exist.
- Stopping at step 4.2 when 4.1 was possible — the comment says "always
  UTC" or "never empty" and nothing in the code makes it so. A reader
  trusts the comment and the bug sits right next to it.

SKIP WHEN: The code isn't part of the change you're making — this is
tidying done where you work, not a sweep. Also skip instructions to a tool
(license header, lint or compiler directive) and documents written for the
feature's users rather than for the people changing the code.

---
<!-- Rationale below — read when creating protocols, reviewing, or
questioning the strategy. Not needed for routine application. -->

## Rationale

### The rewrite test

Step 1 sorts reasoning by asking whether it would survive a rewrite with
the same behaviour. "Typing must not lag on a 500 KB file" survives any
rewrite: it is why the feature is built the way it is, and it belongs to
the feature. "A gap buffer, not a rope" or "grow by doubling" would change
with the code: they are how this implementation meets the requirement, so
they live beside it.

The only thing said twice is a requirement or rule restated in one
sentence where the code relies on it. That repeat is deliberate: it sits
where a change would break it, so it is read every time the code is
changed, and a test can catch it going false. The reasoning behind it
lives in one place.

### Example

Before — a text buffer, with a design document that also covers it:

```
docs/design/editor.md
  Typing must not lag on files of a few hundred kilobytes.
  We use a gap buffer: text with a run of free slots at the edit point.
  We rejected a rope: more memory, more code, no gain for local edits.
  The gap grows by doubling, at least 64 slots.
  One loop owns every open document, so buffers take no locks.

// Buffer stores one document's text. See docs/design/editor.md for
// the design.
type Buffer
  data, gapStart, gapEnd, cursor

// Why 64: docs/design/editor.md, "Gap growth".
const minGap = 64
```

After:

```
docs/design/editor.md
  Typing must not lag on files of a few hundred kilobytes.
  One loop owns every open document; nothing else touches one directly.

// Buffer stores one document's text. Typing at the cursor costs the
// same however large the document is.
//
// A Buffer belongs to the editor loop and takes no locks; two callers
// at once corrupt the text.
type Buffer
  // A gap buffer: free slots sit at the last edit, so typing writes
  // into them without moving the rest. A rope would also be fast, but
  // costs more memory and code for no gain when people edit in one
  // place at a time.
  //
  //   buf: [ h e l l o _ _ _ _ w o r l d ]
  //                    ^gs     ^ge
  //
  // gs is the first free slot, ge the first character after the gap.
  // The text is buf before gs followed by buf from ge. Every edit
  // first moves the gap so gs is at the cursor.
  buf, gs, ge, cursor

// Doubling keeps inserts cheap; 64 stops small files regrowing every
// few keystrokes.
const minGap = 64
```

- The requirement and the ownership of documents survive a rewrite → the
  design document (step 2).
- Gap buffer over rope, the growth rule, the picture → the code; they
  change if the implementation does (steps 3.2 and 3.3).
- `gs` and `ge` are short because the overview inside the type defines
  them and only the type's methods use them. It sits inside the type,
  where people changing the code read it, not in what callers read
  (step 3.3).
- "Takes no locks" is a rule callers must follow that the code can't
  enforce → kept in the type's documentation, where callers read it, with
  what breaks (step 4.2). The design document says one loop owns
  documents; the type says what that means for a caller.

### Why not fewer comments

Shorter code is not the goal. The comments that matter most are rules the
code relies on, and a reader will trust them. That makes an unenforced
rule the most dangerous comment in a file: it reads like a guarantee. So
the strategy keeps those comments and asks for each one whether the code
can make it true instead.

### Cross-references

- **Scrub on Entry** (FEAL): a domain object built from validated input
  is the usual way to make "this value is already normalised" true in
  code instead of in a comment (step 4.1).
- **Tidy or Change**: moving reasoning between comments, documents and
  commits is tidying; enforcing a rule (step 4.1) changes behaviour and
  goes in its own change.
- **Earned Abstraction**: an annotation naming a pattern from the pattern
  vocabulary is a one-sentence how at the point of use (step 3.2) — it
  stays. The vocabulary holds the pattern family; why this implementation
  took its variant stays in the code.

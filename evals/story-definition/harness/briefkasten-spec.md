Build a Go service that:
1. Connects to Fastmail via JMAP
2. Lists all mailboxes, displays them nested with checkboxes in <ol> elements
3. Saves checkbox state; on first save for a folder, fetches all unread emails
4. Creates folder structure in output dir mirroring selected mailboxes
5. Creates initial-archive.xml (Atom feed with all unread) and feed.xml (empty, with prev-archive pointing to initial-archive.xml)

### Features
- **refresh**: Opens selected folders, finds new emails since last check, appends to feed.xml
- **prune**: Moves items older than 1 week from feed.xml into archive-<ISO year>w<ISO week>.xml. New archive gets prev-archive pointing to feed.xml current prev-archive. feed.xml prev-archive updates to point to the new archive file. feed.xml always points to the current week.

### Testing Requirements
- E2E tests with Playwright that verify the full flow works
- E2E tests MUST NOT hit Fastmail — use captured/mocked JMAP responses (do not prescribe a specific mocking tool; let the agent choose its approach)
- Unit tests for the core logic (feed construction, archive chain management, etc.)

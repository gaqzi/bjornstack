# Install / Update (`/story-definition install`)

When the user runs `/story-definition install` or
`/story-definition update`, manage the CLAUDE.md section for the current
project:

1. Find the project's CLAUDE.md (in the working directory root)
2. Look for a `## STORY DEFINITION` heading
3. **If found**: replace everything from the heading up to (but not
   including) the next same-or-higher-level heading (`## ` or `# `) with
   the section text below
4. **If not found**: insert the section near other workflow/process
   sections, or at the end of the behavioral instructions. Use judgment
   based on the document structure.
5. Confirm what was done: "Installed story-definition in CLAUDE.md" or
   "Updated story-definition in CLAUDE.md"

### The section to install

```markdown
## STORY DEFINITION

Load the /story-definition skill before defining a feature, writing user stories or acceptance criteria, or breaking an epic into tasks. Goal, then verification, then the walking skeleton, then slices of one rule each. A story is done when an agent can implement it without asking a question.
```

## Structure Is Intent
The organization of code communicates how the system works — a reader should understand the architecture from the directory tree, not from tracing imports.
VIOLATION: A flat `pkg/` directory with 30 files where the only way to understand module boundaries is to read import graphs.
VIOLATION: A package named `utils` that contains unrelated functions grouped only by the fact that they didn't fit elsewhere.
WHY: When structure doesn't communicate, every new contributor rebuilds the mental model from scratch — and builds it differently.

---
<!-- Rationale below — read when creating strategies, reviewing, or
questioning the principle. Not needed for routine application. -->

## Rationale

This is what Uncle Bob called "screaming architecture" — a healthcare system's
folder tree should scream "healthcare," not "Rails" or "Spring." Structure Is
Intent is our articulation of that idea: the organization should communicate
what the system does and how the pieces relate, at every level from the
repository root down to files within a package.

### The directory tree is a design document

When a new contributor opens the repository, the first thing they see is the
folder structure. If that structure communicates clearly — `cart/`, `pricing/`,
`notifications/`, `storage/` — they immediately know the system's domains and
boundaries. If they see `pkg/`, `internal/`, `utils/`, `helpers/`, they know
nothing and must trace imports to understand how anything connects.

### The `utils` problem

A `utils` package is a structural failure. It says "these functions didn't
belong anywhere else." But everything belongs somewhere — if a function
computes tax, it belongs in the tax domain. If it formats dates, it belongs
with the code that uses date formatting. `utils` is where functions go when
the developer hasn't thought about where they belong. It grows without bound
because anything can be a "utility."

### Structure enables and constrains

Good structure doesn't just communicate — it constrains. When packages have
clear domain boundaries, a function that doesn't belong is visibly out of
place. When everything is in `pkg/`, nothing is out of place because there are
no boundaries to violate. Structure Is Intent means the organization actively
guides developers toward putting things in the right place.

### Related to Be Your Name

Be Your Name covers naming — what you call things. Structure Is Intent covers
organization — where you put things. A well-named function in a chaotic package
is a BYN success and an SII failure. A clear package layout with vague function
names is an SII success and a BYN failure. Both principles are needed for code
that communicates fully.

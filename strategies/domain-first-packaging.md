# Domain-First Packaging
PRINCIPLE: Structure Is Intent

1. Identify the domains the system owns — each cohesive business concept or capability is a candidate package. The test: can you describe what this package *does* using a business noun, not a technical role?
2. Name each package for the domain it owns — a noun that describes what the package is responsible for, not what it contains technically.
3. Place types where their invariants are enforced — ask: which package validates, constrains, or transforms this type? That package owns it. When ownership is unclear, analyze the usage and mutation patterns, group the collaborating types, propose a domain concept that names the grouping, and present the options to a human. "These three types are always used together around pricing logic — I'd call this a `pricing` boundary" is actionable; "where should this type go?" is not.
4. Name exports to extend the package name, not echo it — the qualified path already provides context, so the export adds what's new. `mail.Message` over `mail.Mail`; `cart.Item` over `cart.CartItem`. Repetition in the qualified name is a signal the export isn't pulling its weight.
5. Point imports inward, not sideways — domain packages depend on foundational or shared-contract packages, never on sibling domains directly. When two domains need to communicate, they share an interface or a coordinating layer mediates.
6. Wrap external dependencies at the boundary — third-party types don't appear in domain interfaces. The wrapping package translates external types into domain types so that internal code depends on your model, not theirs.

OUTCOMES:
- The directory tree reads as a map of what the system does, not how it's built.
- No package exists whose name describes a technical role (utils, helpers, common, models, controllers).
- Each type's qualified name (package.Type) reads naturally without repetition.
- External library types don't appear in domain package signatures.
- The import graph between domain packages reflects actual business domain dependencies.

MISAPPLICATION: Splitting into so many domain packages that each contains only one or two files, or creating domain packages that mirror the org chart rather than the system's actual concept boundaries. Over-packaging fragments cohesive logic across boundaries that exist on paper but not in the code.
SKIP WHEN: The system genuinely has one domain (a small CLI tool, a single-purpose library). Forcing domain decomposition on a single-concept codebase adds structure that communicates nothing.

---
<!-- Rationale below — read when creating guidelines, reviewing, or
questioning the strategy. Not needed for routine application. -->

## Rationale

### This is a foundation strategy

Other strategies assume packaging decisions are already made. Intentionally
Public governs what a package exports — but that question only makes sense
once you know what packages exist and what they own. Scrub on Entry places
validation at package and service boundaries — but those boundaries must
exist first. Unit Testing classifies packages as compute or
coordinate — but the packages must be identified and scoped before
classification applies.

The vocabulary established here — domain names, package boundaries,
dependency direction — propagates into every downstream strategy and
guideline. Getting this wrong doesn't just affect packaging; it distorts
every decision built on top of it.

### How to identify domains

Step 1 is the most consequential and the least mechanical. The technique:
describe what the system does as a series of business capabilities. "The
system manages carts, calculates pricing, sends notifications, handles
authentication." The nouns in that sentence — cart, pricing, notification,
auth — are your candidate packages.

The anti-pattern is technical decomposition: http, database, cache, queue.
These describe *how* the system is built, not *what* it does. A reader
seeing `http/`, `database/`, `cache/` learns nothing about the domain.
Technical concerns either live inside domain packages (a domain's database
access is its implementation detail) or in thin infrastructure packages
that domain packages depend on.

When a candidate package is hard to name with a single business noun, it's
often two domains merged together. When two candidate packages always
change together and share most of their types, they're probably one domain
that was split prematurely.

### The boundary type problem

Step 3 handles the easy case well: a type with clear ownership lives where
its invariants are enforced. But the hard case — types consumed across
multiple domains — deserves more thought.

Three patterns emerge in practice:

1. **One domain owns, others consume.** The owning package exports the
   type; consumers import it. This is the common case and the default
   assumption.

2. **No single owner, shared contract.** The type represents a boundary
   contract between domains — an event, a message, a shared identifier.
   This type gets its own small package (or lives in a contracts/types
   package scoped to that boundary). This is legitimate shared
   infrastructure, not a grab-bag — the package has a clear purpose.

3. **Each domain needs its own version.** The "same" type actually has
   different invariants per domain. Each domain defines its own type,
   and translation happens at the boundary. This is the most work but
   produces the cleanest dependencies.

The wrong answer is always a `models/` or `types/` package that accumulates
every shared type without distinguishing these three cases. That package
grows without bound and couples everything to everything.

### Dependency direction and coordination

Step 5's "inward, not sideways" rule creates a natural layering. Domain
packages form the outer layer. Foundational packages (storage adapters,
configuration, shared contracts) form the inner layer. The inner layer
is more stable — it changes less often — which means outer packages
absorb change while inner packages provide stability.

When two domain packages need to interact, the temptation is a direct
import. But a direct import between sibling domains creates a horizontal
dependency — now both packages must know about each other's types and
changes. The resolution is a coordinating layer (a service or handler
that imports both domains and orchestrates between them) or a shared
interface that both domains implement against. This connects directly to
the Compute or Coordinate principle: domain packages compute, and the
layer above them coordinates.

### Relationship to Earned Abstraction

When wrapping external dependencies (step 6), search PATTERNS.md for an
existing pattern family — multiple domain packages often wrap similar
external concerns independently (HTTP clients, queue consumers,
serialization adapters). EA's vocabulary tracks these pattern families so
the third wrapper finds the first two instead of reinventing them. DFP
decides where the wrapper lives; EA decides when similar wrappers have
earned a shared abstraction.

### Relationship to Be Your Name

Structure Is Intent is the primary principle — this strategy is fundamentally
about where things go. But step 4 (naming exports) directly serves Be Your
Name: when `mail.Mail` stutters, the name isn't being its name — it's
echoing its location. `mail.Message` is being its name because it tells you
something the package path doesn't. In languages where the package is always
part of the qualified name (Go, Python), this is a packaging concern as much
as a naming concern, which is why it belongs in this strategy rather than a
separate naming strategy.

### Cross-references

- **Boundary Communication**: BC determines how units communicate across
  the boundaries DFP creates. DFP establishes structure; BC keeps
  communication honest across that structure.
- **Unit Testing**: UT's coordinators pass domain types between
  collaborators — those types live at DFP's domain boundary, not owned
  by either side.
- **Test Data Builders**: TDB's cross-domain builders live in the owning
  domain, consistent with DFP's boundary design.
- **Scrub on Entry**: SOE's boundary validation belongs at the package
  boundary DFP establishes — the entry point that external callers use.

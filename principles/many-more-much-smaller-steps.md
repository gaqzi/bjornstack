# Many More Much Smaller Steps
Changes to production must be small enough that each can be understood,
reviewed, and reversed independently.
VIOLATION: A release bundles three features where rolling back one means
rolling back all three — debugging requires untangling which change caused
the incident.
VIOLATION: A PR mixes a behavioral change with a structural refactor, so
the reviewer can't tell which differences are intentional new behavior and
which are reorganization.
WHY: The cost of understanding, reviewing, and reverting a change grows
nonlinearly with its size — small steps make each decision cheap to undo.

---
<!-- Rationale below — read when creating strategies, reviewing, or
questioning the principle. Not needed for routine application. -->

## Rationale

GeePaw Hill coined "many more much smaller steps" to describe the practice
of breaking work into the smallest coherent increments possible. The insight
is counterintuitive: taking more steps feels slower but is faster because
each step is cheap to understand, review, and reverse. The nonlinear cost
of large changes means five small steps cost less total effort than one
large step of equivalent scope.

### What "small enough" means

Small enough that a single rollback undoes a single concern. The heuristic:
if you need "and" in the commit message to explain the change, it's too
large. Each step is either a structural change (refactoring, reorganizing)
or a behavioral change (new/modified functionality), never both.

### Walking skeletons are valid small steps

Alistair Cockburn's walking skeleton — the smallest deployable thing that
proves the path works end-to-end — is a perfect MMMSS step. A feature
wired but inert behind a feature flag is a valid small step. MMMSS doesn't
mean "only ship complete features in small pieces." It means ship the
skeleton, then the behavior, then the polish, each independently. The team
builds on top of the new domain design immediately, even before the feature
is live.

### Rollbackability is the safety net

If you can't roll back, every step forward is irreversible, and every bug
is a potential catastrophe. Feature flags are often the fastest path to
rollbackability — rollback becomes "flip a flag" rather than "redeploy the
previous version." External flag systems enable targeting (specific users,
1% → 5% → 100%), making rollback both instant and granular. That's a
qualitatively different kind of reversibility than redeploying.

### Early integration

The sooner work is visible on main, the sooner everyone builds on top of
it. Unmerged code is invisible to the team — it's a parallel reality that
diverges further with every passing hour. The practice of integrating early
and often reduces merge conflicts, surfaces design disagreements sooner,
and ensures that the codebase reflects the team's actual progress. In the
age of AI-assisted development, the cadence argument matters less, but the
"everyone sees main" argument is timeless.

### Cross-references

- **Highlight the Difference** (complementary): HTD says "make differences
  visible in code." MMMSS says "make differences visible in changes." A PR
  that separates structural from behavioral work is MMMSS applied through
  HTD's lens — each PR highlights one kind of difference.
- **Don't Fly Blind** (complementary): MMMSS makes changes small so they're
  cheap to revert. DFB ensures you know when to revert. Together they form a
  delivery loop: small change → verify signals → ship → repeat. Neither is
  sufficient alone — small blind steps are still blind, and observable giant
  releases are still giant.
- **Consistent Beats Correct** (tension): if the established pattern is large
  releases, MMMSS says stop. CBC yields here — the pattern itself is the
  problem, per CBC's own rationale.
- **Earned Abstraction** (complementary): shipping small steps is not
  abstracting. A walking skeleton is coordination wiring, not abstraction.
  MMMSS governs delivery; EA governs design. Ship concrete implementations
  first, earn the abstraction later when the pattern is visible.

### Lineage

GeePaw Hill (MMMSS as a practice), Alistair Cockburn (walking skeleton),
Kent Beck (Tidy First? — the choice between structural and behavioral
changes), lean manufacturing (one-piece flow). The nonlinear cost insight
is the differentiator from generic "ship small" advice — it's not just that
small is better, it's that large is disproportionately worse.

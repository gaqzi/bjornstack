# Strategy Futures

Problem spaces where we want a strategy but don't have a clear technique yet.
Each entry captures what we know, what's fuzzy, and where the conversation
lives. When experience produces a technique, graduate the entry to a real
strategy.

## E2E Testing

**Bead**: bs-2q1
**Principle**: Don't Fly Blind
**Parent**: Test Layer Selection (testing.md)
**Would be**: strategies/testing__e2e.md

E2E means testing with all real dependencies — no stubs, no local
equivalents. The system talks to real services, real databases, real
third-party APIs. Ideally in production; at minimum in a non-prod
environment that mirrors production's dependency graph. This is what
distinguishes E2E from BB integration (which stubs everything outside
the service boundary).

The problem: how do we get belt-and-suspenders confidence for critical flows
— the ones where the cost of breaking is high enough that BB integration
tests and contract tests aren't sufficient?

What we know:
- **Selecting flows**: "things we can't afford breaking" — but the mechanism
  is unclear. Observability might cover it (no signups in X hours?), RUM
  tests might be better than browser-driven e2e, it depends on the system.
  The selection technique isn't separable from the verification mechanism.
- **Managing environments**: Uber-style test-user-in-prod patterns exist
  (dedicated vendors/cities for test users, paths that run alongside prod
  without affecting real metrics). This enables non-destructive e2e in
  production but requires significant design work. No firsthand experience
  to encode.
- **E2E vs monitoring**: The line is clear — e2e tests are triggered by
  deployments ("did this change break flows?"), monitors run continuously
  ("is the system healthy?"). Same check can serve both roles. The strategy
  would focus on the deployment-verification role.

Why it's not ready: no repeatable technique. We have a problem space and
reference points but haven't done it. Writing now would produce either a
restatement of DFB or a speculative tutorial.

What would unblock it: actually implementing e2e/RUM/synthetic monitoring
on a real system and discovering which technique worked.

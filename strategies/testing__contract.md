# Contract Testing
PRINCIPLE: No Shared Fate

1. Classify the direction: are you consuming an external party's service,
   or providing a service that others consume? Both directions can apply
   to the same boundary.
   - Consuming: continue at step 2.
   - Providing: continue at step 3.
2. Consumer-side (we depend on them):
   1. Identify what you actually use — the specific endpoints, fields,
      and behaviors your code relies on. Not the full API surface.
   2. Encode those expectations as tests that run against a stub of the
      external service. These tests verify your assumptions, not their
      implementation.
   3. When the external party publishes a contract artifact (schema,
      spec), validate your expectations against it. When they don't,
      your consumer tests serve as the living spec — drift surfaces
      when integration or production signals show a mismatch.
3. Provider-side (they depend on us):
   1. Collect contracts from consumers — the expectations they've
      encoded about your service's behavior.
   2. Run those contracts against your actual implementation as part
      of your test suite.
   3. A failing consumer contract blocks the change — you're about
      to break a consumer.

OUTCOMES:
- External dependencies are tested without requiring the external service
  to be running.
- Contract test failures identify which party's expectations changed,
  not just that "something is broken."
- Provider-side changes that would break consumers are caught before
  release.

MISAPPLICATION: Contract tests that mirror the external service's full
API surface instead of covering only what you actually use — these become
a maintenance burden that tracks their API, not your needs. Or treating
contracts as a substitute for integration tests — contracts verify
agreements hold, not that your code handles the responses correctly.
SKIP WHEN: The external dependency is fully under your control (same
team, same deploy pipeline) — a black box integration test covers the
boundary directly without needing a contract layer.

---
<!-- Rationale below — read when creating guidelines, reviewing, or
questioning the strategy. Not needed for routine application. -->

## Rationale

### Why No Shared Fate, not Don't Fly Blind

The meta-strategy (Test Layer Selection) selects contract testing under
Don't Fly Blind — it's part of having signals at every boundary. But the
technique itself exists to decouple. Without contract tests, you have two
options for verifying external agreements: call the real service (shared
fate with their uptime and behavior) or don't test it at all (shared fate
with your assumptions being correct). Contract tests create a third option:
encode the agreement, test against a stub, and verify the agreement
separately from the integration. The driver is isolation — DFB tells you
to have the signal, NSF tells you how to structure it so it's reliable.

### Test only what you use

The most common misapplication is mirroring the external API's full
surface. This happens naturally — the external party's docs describe
everything, so the contract tests cover everything. But a contract that
tests endpoints you don't call is coupling you to their API design, not
to your actual dependency. When they make a breaking change to an endpoint
you don't use, your contracts fail for no reason — you've created shared
fate with their API evolution instead of eliminating it. Step 2.1 exists
to prevent this: start from your code's actual calls, not from their docs.

### Consumer contracts as living documentation

When no formal contract artifact exists (no published schema, no Pact
broker), your consumer-side tests become the specification of what you
depend on. This is valuable but fragile — the tests assert expectations
that no one on the provider side has agreed to. Step 2.3 acknowledges
this honestly: drift is caught late (integration tests or production),
not early. The mitigation is keeping contracts minimal (step 2.1 again)
so the surface area for undetected drift stays small.

### Both directions on the same boundary

Step 1 notes that consumer and provider can apply to the same boundary.
If you both consume service X and provide an API that service Y consumes,
you have contracts in both directions. These are independent concerns —
don't conflate them into one test suite. Consumer contracts verify your
assumptions about X. Provider contracts verify Y's assumptions about you.

### Relationship to Boundary Communication

This strategy assumes boundaries with clear owners and explicit contracts
already exist — Boundary Communication creates them. BC's step 2 assigns
ownership and step 3 makes contracts explicit; those contracts are what
consumer and provider tests encode. When ownership is unclear or contracts
are implicit, fix that first (BC) before writing contract tests — testing
an undefined contract produces tests that track implementation, not
agreements.

### Cross-references

- **Compliance Test Suites**: CTS verifies implementations of internal
  interfaces. Contract Testing verifies agreements with external parties.
  Both prevent shared fate, at different boundaries.

# Visitor permit limits

## Epic: limits on issuing visitor permits

As a resident of a zone, I need my visitor permits limited, so that the zone's visitor parking is not taken up by one household or one car.

## Story 1: Stop a resident from holding more than two visitor permits

As a resident of a zone, I need at most two of my visitor permits active at once, so that one household cannot take up the zone's visitor parking.

Out of scope: the per-car rule (story 2); expiring permits; limits on resident permits.

Acceptance:

```gherkin
Background:
  Given resident R holds a resident permit for zone "Söder 3"

Scenario: a first visitor permit is issued
  Given R has no active visitor permits
  When R issues a visitor permit for "ABC123"
  Then the response is success
  And the audit log has VisitorPermitIssued{zone: "Söder 3", plate: "ABC123", resident: R} with the permit id of the new permit

Scenario: a second visitor permit is issued (edge, just inside)
  Given R has one active visitor permit
  When R issues a visitor permit for "DEF456"
  Then the response is success
  And the audit log has VisitorPermitIssued{zone: "Söder 3", plate: "DEF456", resident: R} with the permit id of the new permit

Scenario: a third visitor permit is refused (edge, just outside)
  Given R has two active visitor permits
  When R issues a visitor permit for "KLM456"
  Then the response is refused with reason "resident already has two active visitor permits"
  And no event is appended to the audit log
```

Black-box: the third-permit refusal, and the first permit issued.

Also observed:
- The README's Permits section says a resident holds at most two active visitor permits at once.
- The Permit model's docstring explains the limit of two active visitor permits per resident.

Constraints:
- The count of the resident's active visitor permits and the insert run in one database transaction, so two requests at once cannot both take the last slot.

Notes:
- The replay for each black-box scenario is one recorded session with its expected audit log, under tests/replays.
- "Active" is the Permit model's existing notion (assumption 2).

## Story 2: Stop a second permit being issued to a car that already has one

As a resident of a zone, I need a car that already holds an active permit in the zone refused another, so that one car cannot hold several permits in the zone's visitor parking.

Out of scope: the resident's two-permit cap (story 1); permits in other zones; how a plate is normalised.

Depends on: story 1 (both change the issue path; serial, not parallel).

Acceptance:

```gherkin
Background:
  Given resident R holds a resident permit for zone "Söder 3"
  And R has no active visitor permits

Scenario: a car with no active permit in the zone is issued one
  Given car "ABC123" holds no active permit
  When R issues a visitor permit for "ABC123"
  Then the response is success
  And the audit log has VisitorPermitIssued{zone: "Söder 3", plate: "ABC123", resident: R} with the permit id of the new permit

Scenario: a car with an active visitor permit in the zone is refused
  Given car "ABC123" holds an active visitor permit in zone "Söder 3" issued to another resident
  When R issues a visitor permit for "ABC123"
  Then the response is refused with reason "car already holds an active permit in this zone"
  And no event is appended to the audit log
```

Black-box: the refusal for an active visitor permit in the zone, and the car with no active permit.

Also observed:
- The README's Permits section says a car that holds an active permit in a zone cannot be issued another visitor permit in that zone.
- The Permit model's docstring explains the one-active-permit-per-car-per-zone rule.

Constraints:
- The check for an existing active permit on the plate in the zone and the insert run in one database transaction, so two residents issuing for the same car at once cannot both succeed.

Notes:
- The replay for each black-box scenario is one recorded session with its expected audit log, under tests/replays.


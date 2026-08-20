# DLQ as a Service Sprint 2 Tasks

**Status: Complete**

## Delivered Outcome

Sprint 2 delivered:

- authenticated HTTP ingestion through scoped project API keys
- project-scoped source and redaction-rule management
- payload validation, limits, redaction, and deterministic duplicate handling
- failed-message and failure-attempt persistence with an immutable original payload
- a filterable inbox and detailed investigation page
- message status changes and operator notes
- integration and service coverage for ingestion, investigation, roles, and tenant isolation

The remaining system-test gap is a real browser smoke test. It is release hardening, not a blocker for starting incident grouping.

## Sprint Goal

Complete the Phase 2 ingestion and inbox work so the team can start Sprint 3 with a usable failed-message investigation surface and a stable ingestion contract.

Sprint 2 should leave the project with:

- a protected HTTP ingestion path
- source management for projects
- redaction-rule management for stored payloads
- failed-message persistence with failure attempts
- duplicate-ingestion handling
- a searchable inbox
- a message detail page for investigation
- repeatable tests for ingestion and inbox workflows

## Sprint Scope

### In Scope

- source management
- redaction rules
- ingestion endpoint
- ingestion authentication through project API keys
- payload validation and size enforcement
- failed-message persistence
- failure-attempt persistence
- duplicate handling
- inbox listing and filters
- message detail view
- basic message investigation actions
- tests for ingestion and inbox flows

### Out of Scope

- incident grouping
- replay workflows
- replay destinations and batches
- alert rules and deliveries
- audit-log UI
- Prometheus metrics and dashboards
- broker-specific adapters

## Current Repo Notes

At Sprint 2 completion, the repo has:

- authenticated browser access
- organizations, memberships, and projects
- project API keys
- tenant scoping and basic role checks
- a dashboard shell and project-scoped failed-message inbox
- SQLite-first local setup and CI baseline
- implemented ingestion and investigation services with request and integration tests

Later-phase incident, replay, alert, and audit tables are scaffolding only. Their presence must not be treated as completed product behavior.

## Sprint 2 Backlog

### S2-01 Stabilize the ingestion and inbox schema subset

Goal:

- validate the schema for `sources`, `redaction_rules`, `failed_messages`, `failure_attempts`, `message_payload_versions`, and `message_notes`

Tasks:

- review the current migrations for the Sprint 2 tables only
- confirm foreign keys, defaults, indexes, and uniqueness constraints match the intended ingestion model
- verify duplicate-ingestion constraints are representable through `failed_messages` and `failure_attempts`
- confirm the original payload remains immutable on `failed_messages`
- confirm inbox-facing denormalized fields exist and are sufficient for filters without joining attempt rows
- check that `db/schema.rb` remains aligned after any migration fixes

Done when:

- Sprint 2 migrations run cleanly from scratch
- the ingestion and inbox schema is stable enough for endpoint and UI implementation
- later incident and replay work can build on these tables without redesign

### S2-02 Define the ingestion API contract

Goal:

- establish one consistent HTTP contract for writing failed messages into the platform

Tasks:

- define the authenticated ingestion route structure
- choose the request shape for message identity, source, queue, event type, payload, failure details, and attempt number
- define JSON success and error responses for ingestion requests
- standardize validation errors for missing or invalid ingestion fields
- decide how project API keys are presented and authenticated on ingestion requests

Done when:

- the app has one clear ingestion contract
- client applications can send failures without guessing field names or behaviors

### S2-03 Implement source and redaction-rule management

Goal:

- let projects define where failures come from and how sensitive fields are scrubbed before storage

Tasks:

- create source creation, listing, and detail flows inside projects
- support source identifiers, names, and statuses
- implement redaction-rule creation and listing for projects
- support JSON-path-based redaction targets and replacement values
- restrict management actions to the appropriate project roles

Done when:

- authorized users can define sources per project
- authorized users can define redaction rules that ingestion can use before persistence

### S2-04 Implement the authenticated HTTP ingestion endpoint

Goal:

- receive failed-message writes from external applications through project API keys

Tasks:

- implement project API key lookup by prefix and secure digest verification
- require the `messages:write` scope for ingestion
- resolve the project and source from the authenticated request
- reject invalid or revoked API keys
- reject writes for unknown or disabled sources
- persist valid requests through service objects instead of controller-only logic

Done when:

- a client with a valid project API key can submit a failed message successfully
- invalid or revoked credentials are rejected predictably

### S2-05 Enforce payload validation, limits, redaction, and duplicate handling

Goal:

- ensure ingestion is safe before messages reach the inbox

Tasks:

- validate required ingestion fields
- enforce project payload-size limits
- redact configured payload fields before storage
- preserve the original post-redaction stored payload immutably
- implement duplicate handling based on the chosen identity and attempt strategy
- decide whether duplicates update an existing message, add a new attempt, or reject the request, and encode that behavior in tests

Done when:

- oversize or malformed payloads are rejected cleanly
- sensitive fields are redacted before persistence
- duplicate ingestion behaves deterministically and is covered by tests

### S2-06 Persist failed messages and failure attempts correctly

Goal:

- store failures in a shape that supports both operational investigation and later replay work

Tasks:

- create `failed_messages` records with denormalized inbox fields
- create `failure_attempts` records for each ingested attempt
- maintain `attempt_count`, first and last failure timestamps, latest failure type, and latest failure summary
- store metadata and correlation fields needed for inbox filtering
- ensure the persistence layer is idempotent relative to the duplicate strategy

Done when:

- the database reflects one coherent failed-message record plus its attempt history
- inbox queries can rely on `failed_messages` as the primary listing table

### S2-07 Build the inbox listing and filters

Goal:

- provide the first usable operational inbox for failed messages

Tasks:

- create a project-scoped inbox page
- list failed messages with the most important summary fields
- support filtering by status, source, queue, event type, failure type, date range, fingerprint, correlation ID, and replay status placeholder
- add useful default ordering for recent operational work
- support empty-state and no-results states cleanly

Done when:

- an operator can browse and filter failed messages without looking at raw database rows
- the inbox feels like a real product surface, not a scaffold dump

### S2-08 Build the failed-message detail page and basic investigation actions

Goal:

- let users inspect one failed message deeply enough to understand what broke

Tasks:

- create a message detail page
- show payload, metadata, source, queue, correlation fields, and timestamps
- show failure-attempt history and latest failure summary
- show message notes
- support manual status changes such as `open`, `investigating`, `resolved`, and `ignored`
- add note creation for operators and admins

Done when:

- an operator can open one failed message and see the relevant context in one place
- basic investigation work can happen before incident grouping exists

### S2-09 Expand test coverage for ingestion and inbox behavior

Goal:

- keep the new ingestion path safe as the product starts handling real failure data

Tasks:

- add request tests for ingestion authentication and validation
- add tests for payload-size enforcement and redaction behavior
- add tests for duplicate-ingestion behavior
- add integration tests for inbox filtering and message detail rendering
- add role and tenant-isolation tests for sources, rules, and failed-message visibility

Done when:

- the main Sprint 2 behaviors are protected by automated tests
- regressions in tenant scoping or ingestion correctness are caught quickly

### S2-10 Prepare the app shell for Sprint 3 investigation work

Goal:

- land Sprint 2 with an interface and developer baseline that can absorb incidents next

Tasks:

- add navigation placeholders for Inbox and Message Detail flows
- update docs for local ingestion testing and example requests
- document the ingestion contract and expected headers or auth format
- ensure CI still covers migrations, schema drift, assets, and tests after Sprint 2 additions

Done when:

- a teammate can run the app locally, submit a test failed message, and inspect it in the inbox from the docs
- the repo is ready for incident grouping in Sprint 3

## Suggested Sprint Order

Recommended sequence:

1. `S2-01` Stabilize the ingestion and inbox schema subset
2. `S2-02` Define the ingestion API contract
3. `S2-03` Implement source and redaction-rule management
4. `S2-04` Implement the authenticated HTTP ingestion endpoint
5. `S2-05` Enforce payload validation, limits, redaction, and duplicate handling
6. `S2-06` Persist failed messages and failure attempts correctly
7. `S2-07` Build the inbox listing and filters
8. `S2-08` Build the failed-message detail page and basic investigation actions
9. `S2-09` Expand test coverage for ingestion and inbox behavior
10. `S2-10` Prepare the app shell for Sprint 3 investigation work

## Sprint Acceptance Criteria

Sprint 2 was completed with:

- project API keys can authenticate ingestion requests
- sources and redaction rules can be managed per project
- failed messages and failure attempts persist correctly
- duplicate ingestion behaves predictably
- operators can browse a filtered inbox
- operators can inspect one failed message in detail
- tenant isolation still holds across ingestion and inbox queries
- local docs explain how to submit and inspect a failed message
- CI continues catching schema, test, and asset regressions

## Handoff to Sprint 3

Sprint 3 should implement incident grouping as a vertical workflow. See `sprint_3_tasks.md` for the ordered backlog and acceptance criteria.

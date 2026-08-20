# DLQ as a Service Sprint 3 Tasks

**Status: Next**

## Sprint Goal

Turn individual failed messages into actionable incidents. A newly ingested failure should be assigned to a project-scoped incident, and operators should be able to investigate, annotate, and resolve that incident without losing access to its messages.

## Sprint Scope

### In Scope

- deterministic error normalization and fingerprinting
- automatic incident assignment during ingestion
- incident summary counters and timestamps
- project-scoped incident list and detail pages
- incident status changes and notes
- navigation between incidents and failed messages
- tenant, role, idempotency, and concurrency-oriented tests
- one browser smoke test for the incident workflow

### Out of Scope

- replay execution or replay destinations
- alert delivery
- audit-log UI
- broker adapters
- machine-learning grouping
- manual merging or splitting of incidents
- custom fingerprint strategies per project

## Current Repo Baseline

Available now:

- `incident_groups` and `incident_notes` tables
- optional `failed_messages.incident_group_id`
- project-scoped unique incident fingerprints
- incident summary columns and query indexes
- ingestion and investigation service seams
- project tenant access and membership roles

Missing now:

- incident model behavior and validations
- normalization and grouping services
- counter maintenance
- incident controllers, routes, and views
- incident workflow tests

## Sprint 3 Backlog

### S3-01 Stabilize the Incident Domain Model

Add associations, statuses, validations, scopes, and counter invariants to `IncidentGroup` and `IncidentNote`. Define which failed-message statuses count as open. Keep all incident lookups project-scoped.

Done when invalid incidents and notes cannot persist, and common incident-list queries have explicit model support.

### S3-02 Define Normalization and Fingerprint Rules

Create one service that normalizes volatile error content such as IDs, timestamps, UUIDs, and whitespace, then derives a stable fingerprint from documented fields. Respect a valid client fingerprint only if the ingestion contract intentionally allows it.

Done when equivalent failures group together, materially different failures remain separate, and fixtures lock the algorithm down.

### S3-03 Assign Incidents During Ingestion

Create a focused incident-assignment service and call it from successful intake. Find or create by `project_id + fingerprint`, attach the failed message, and avoid double-counting duplicate attempts. Handle the unique-index race safely.

Done when every new failed message has one incident and repeated ingestion remains idempotent.

### S3-04 Maintain Incident Summaries

Maintain title, normalized failure, queue, event type, failure type, first/last seen times, message count, and open-message count. Provide a deterministic recalculation operation so counters can be repaired rather than relying only on callbacks.

Done when ingestion and message status changes keep summaries correct, and recalculation produces the same values from source records.

### S3-05 Build the Incident Inbox

Add project-scoped incident routes and a recent-first list. Show status, title, failure type, queue, message counts, and last-seen time. Support status, queue, failure type, fingerprint, and date filters with clear empty states.

Done when an operator can identify active incident clusters without scanning individual messages.

### S3-06 Build Incident Investigation

Add an incident detail page showing the summary, grouped failed messages, timeline context, and notes. Add links between incident detail, failed-message detail, and the message inbox.

Done when an operator can move from a cluster to any underlying failure and back without losing project context.

### S3-07 Add Incident Actions

Support project-scoped incident status changes and notes. Operators and admins may investigate and resolve incidents; viewers remain read-only. Reject blank notes and invalid statuses.

Done when actions enforce tenant and role boundaries and return useful validation errors.

### S3-08 Protect the Workflow With Tests and Docs

Cover normalization, grouping, deduplication, unique-index race recovery, counters, status changes, notes, filtering, roles, and cross-tenant access. Add one system test covering login, incident list, incident detail, and a status or note action. Update the README with the incident workflow.

Done when unit, service, integration, and system checks pass in CI and a teammate can exercise the flow locally.

## Suggested Sprint Order

1. `S3-01` Stabilize the incident domain model
2. `S3-02` Define normalization and fingerprint rules
3. `S3-03` Assign incidents during ingestion
4. `S3-04` Maintain incident summaries
5. `S3-05` Build the incident inbox
6. `S3-06` Build incident investigation
7. `S3-07` Add incident actions
8. `S3-08` Protect the workflow with tests and docs

## Sprint Acceptance Criteria

Sprint 3 is complete when:

- equivalent failures in one project resolve to the same incident
- the same fingerprint in different projects never crosses tenant boundaries
- duplicate attempts do not inflate incident message counts
- concurrent first sightings cannot create duplicate incidents
- incident counters and timestamps remain correct after ingestion and status changes
- operators can filter incidents, inspect grouped messages, add notes, and change status
- viewers cannot mutate incidents
- incident and message pages link to each other
- automated tests cover the end-to-end incident workflow
- SQLite remains supported without database-specific grouping features

## Handoff to Sprint 4

Sprint 4 should start with one auditable single-message HTTP replay tracer bullet. Add encrypted destination secrets and SSRF protections before bulk replay, rate limiting, circuit breaking, or pause/resume controls.

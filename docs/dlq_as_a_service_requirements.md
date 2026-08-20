# Dead-Letter Queue as a Service
## Product Requirements Document

**Working name:** DLQ Control Center  
**Product category:** Failure recovery platform for asynchronous systems  
**Document version:** 1.0  
**Status:** Initial build specification  

---

## 1. Product Summary

DLQ Control Center is a hosted platform for capturing, inspecting, organizing, alerting on, and safely replaying messages that could not be processed by an application or messaging system.

The platform is not intended to replace a message broker such as Amazon SQS, RabbitMQ, Kafka, Redis Streams, or a background-job system. Its purpose is to provide a centralized operational inbox for failed asynchronous messages and a controlled recovery workflow.

The initial release will support HTTP-based ingestion and HTTP-based replay. Broker-specific integrations will be added later through adapters.

### Product pitch

> A centralized failure inbox for distributed systems. Capture failed messages from any application, investigate root causes, replay selected messages safely, and maintain a complete audit trail.

### Main value proposition

Teams often have failed messages distributed across queues, logs, dashboards, and services. Built-in dead-letter queues preserve failures, but they frequently provide limited visibility and limited operational tooling. DLQ Control Center adds:

- Centralized failed-message ingestion
- Search and filtering
- Failure grouping
- Alerts
- Controlled replay
- Replay throttling
- Audit logs
- Tenant isolation
- Payload versioning
- Retention policies
- Security controls

---

## 2. Goals

### 2.1 Primary goals

The platform must allow users to:

1. Capture failed messages from applications or broker adapters.
2. Inspect the original message payload and failure details.
3. Search and filter failures efficiently.
4. Group similar failures to identify incidents.
5. Replay one or more messages safely.
6. Limit replay throughput to avoid overloading downstream systems.
7. Track replay results and repeated failures.
8. Receive alerts when important failure patterns appear.
9. Preserve a complete audit history of user actions.
10. Isolate data between organizations and projects.

### 2.2 Secondary goals

The platform should allow users to:

1. Redact sensitive fields before storage or display.
2. Validate payloads against schemas before replay.
3. Configure replay permissions by queue or event type.
4. Add integrations for Amazon SQS, RabbitMQ, Kafka, Sidekiq, and BullMQ.
5. Export failure data for offline investigation.
6. Integrate with Slack, email, and outbound webhooks.
7. Expose metrics for Prometheus and dashboards for Grafana.

---

## 3. Non-Goals

The MVP will not:

1. Replace a message broker.
2. Guarantee exactly-once delivery.
3. Execute arbitrary shell commands.
4. Provide arbitrary code execution during message transformations.
5. Automatically modify original messages.
6. Automatically replay sensitive messages without policy checks.
7. Support every broker in the first release.
8. Provide a full event-stream processing platform.
9. Store payloads indefinitely by default.
10. Promise that replay is always safe; downstream consumers must still implement idempotency.

---

## 4. Target Users

### 4.1 Backend developer

Needs to investigate failed jobs, inspect payloads, understand error patterns, and replay a message after fixing a bug.

### 4.2 DevOps or platform engineer

Needs centralized visibility across services, operational alerts, replay controls, metrics, and auditability.

### 4.3 Engineering manager

Needs a high-level view of unresolved failures, aging incidents, repeated regressions, and operational risk.

### 4.4 Support or operations user

May need read-only access to inspect failures and confirm whether an incident is being handled, without permission to replay messages.

---

## 5. Core Concepts

### 5.1 Organization

An organization is the top-level tenant. All data must be isolated by organization.

### 5.2 Project

A project groups messages, credentials, integrations, users, alert rules, and retention policies. A project may represent an application, environment, or bounded system.

Examples:

```text
payments-production
payments-staging
billing-production
crm-sync-production
```

### 5.3 Source

A source identifies where a failure came from.

Examples:

```text
payments-worker
invoice-worker
amazon-sqs-payments-dlq
rabbitmq-order-events
```

### 5.4 Failed message

A failed message is an immutable record of an event that could not be processed successfully.

### 5.5 Failure attempt

A failure attempt stores details about an individual processing failure, including the error type, error message, attempt number, and timestamp.

### 5.6 Payload version

The original payload must remain immutable. If a user edits a payload before replay, the platform must create a new payload version linked to the original message.

### 5.7 Replay attempt

A replay attempt records an individual attempt to send a failed message to a configured destination.

### 5.8 Replay batch

A replay batch groups multiple replay attempts and defines rate limits, status, and circuit-breaker behavior.

### 5.9 Incident group

An incident group clusters messages with similar failure fingerprints so that users do not need to inspect thousands of individual rows.

---

## 6. MVP Scope

The MVP must include:

1. User authentication
2. Organizations
3. Projects
4. Project API keys
5. HTTP ingestion endpoint
6. Failed-message persistence
7. Failure attempts
8. Search and filtering
9. Single-message replay
10. Bulk replay
11. Replay rate limiting
12. Replay circuit breaker
13. HTTP replay destination
14. Original payload immutability
15. Edited payload versions
16. Audit logs
17. Email alerts
18. Outbound webhook alerts
19. Basic role-based access control
20. Retention configuration
21. Payload redaction configuration
22. Prometheus-compatible metrics
23. Health-check endpoints
24. Docker-based local development
25. Automated tests
26. OpenAPI documentation

---

## 7. Functional Requirements

## 7.1 Authentication and authorization

### FR-AUTH-001 — User authentication

The system must support authenticated access to the dashboard and management API.

### FR-AUTH-002 — Organization membership

A user must belong to one or more organizations.

### FR-AUTH-003 — Roles

The system must support at least the following organization or project roles:

| Role | Permissions |
|---|---|
| Owner | Full access, billing-ready ownership, member management, project deletion |
| Admin | Project management, integrations, alert rules, replay, audit-log viewing |
| Operator | View messages, replay messages when allowed, resolve or ignore failures |
| Viewer | Read-only access |

### FR-AUTH-004 — Tenant isolation

Every query and mutation must enforce organization and project boundaries. A user from one organization must never access another organization's data.

### FR-AUTH-005 — Project API keys

The system must allow an authorized user to create, rotate, revoke, and label API keys for message ingestion.

### FR-AUTH-006 — API-key storage

The platform must never store raw API keys after creation. It must store a secure hash and display the raw key only once.

### FR-AUTH-007 — API-key scopes

API keys should support scopes such as:

```text
messages:write
messages:read
replays:write
```

For the MVP, ingestion keys may be limited to `messages:write`.

---

## 7.2 Organization and project management

### FR-PROJECT-001 — Create organization

A user must be able to create an organization.

### FR-PROJECT-002 — Create project

An authorized user must be able to create a project within an organization.

### FR-PROJECT-003 — Environment labels

A project should support an environment label:

```text
development
staging
production
custom
```

### FR-PROJECT-004 — Project settings

An authorized user must be able to configure:

- Project name
- Environment
- Default retention period
- Default replay policy
- Redaction rules
- Alert destinations
- Replay destination
- Allowed origins or source identifiers
- Maximum payload size

### FR-PROJECT-005 — Archive project

An authorized user must be able to archive a project. Archived projects must reject ingestion unless explicitly reactivated.

---

## 7.3 Source management

### FR-SOURCE-001 — Register source

The system must allow sources to be registered manually or created automatically during ingestion.

### FR-SOURCE-002 — Source metadata

A source should include:

```text
id
project_id
name
source_type
environment
description
is_active
created_at
updated_at
```

### FR-SOURCE-003 — Source types

Supported source types for the MVP:

```text
http
custom
```

Future source types:

```text
amazon_sqs
rabbitmq
kafka
sidekiq
bullmq
redis_streams
```

---

## 7.4 Failed-message ingestion

### FR-INGEST-001 — HTTP ingestion endpoint

The system must expose:

```http
POST /v1/messages
```

### FR-INGEST-002 — Authentication

The endpoint must require a valid project API key.

### FR-INGEST-003 — Required ingestion fields

The ingestion request must accept:

```json
{
  "source": "payments-worker",
  "queue": "payments.processed",
  "event_type": "payment.confirmed",
  "message_id": "evt_123",
  "idempotency_key": "payment_9812",
  "payload": {
    "payment_id": 9812,
    "status": "confirmed"
  },
  "failure": {
    "type": "PaymentGatewayTimeout",
    "message": "Gateway did not respond within 10 seconds",
    "stack_trace": "optional stack trace"
  },
  "metadata": {
    "tenant_id": "25932",
    "attempt": 5,
    "consumer_version": "1.8.2",
    "correlation_id": "req_84c911"
  },
  "replay": {
    "destination_id": "dest_123"
  },
  "occurred_at": "2026-06-06T13:42:18Z"
}
```

### FR-INGEST-004 — Flexible metadata

The system must allow arbitrary metadata fields in addition to standard fields.

### FR-INGEST-005 — Payload size limit

The system must enforce a configurable payload-size limit. The default MVP limit should be 256 KB.

### FR-INGEST-006 — Duplicate ingestion

The system must safely handle duplicate submissions. A repeated message should not accidentally create unlimited duplicates.

The deduplication strategy should use:

```text
project_id
source
external_message_id
failure_attempt_number
```

If these are unavailable, the platform may fall back to a generated fingerprint and timestamp window.

### FR-INGEST-007 — Idempotent response

Repeated ingestion of the same failure attempt should return the existing record or a success response indicating that the duplicate was ignored.

### FR-INGEST-008 — Validation errors

Invalid ingestion requests must return structured errors.

Example:

```json
{
  "error": {
    "code": "invalid_payload",
    "message": "The request is invalid.",
    "details": [
      {
        "field": "failure.type",
        "message": "is required"
      }
    ]
  }
}
```

### FR-INGEST-009 — Redaction

Configured redaction rules must run before payloads and metadata are persisted.

### FR-INGEST-010 — Fingerprint generation

The system must generate a failure fingerprint during ingestion.

Suggested inputs:

```text
project_id
source
queue
event_type
failure.type
normalized failure.message
consumer_version
```

### FR-INGEST-011 — Message status

New messages must receive an initial status:

```text
open
```

### FR-INGEST-012 — Ingestion latency

The API should persist accepted messages quickly and avoid expensive synchronous processing. Alert processing and incident regrouping should run asynchronously where appropriate.

---

## 7.5 Message inbox

### FR-INBOX-001 — List failures

The platform must expose:

```http
GET /v1/messages
```

### FR-INBOX-002 — Message filters

The API and dashboard must support filtering by:

- Status
- Project
- Source
- Queue
- Event type
- Failure type
- Fingerprint
- Incident group
- Tenant identifier
- Correlation identifier
- Consumer version
- Date range
- Tags
- Replay status
- Minimum attempt count

### FR-INBOX-003 — Search

The system must support text search across:

- External message ID
- Idempotency key
- Failure message
- Queue
- Event type
- Correlation ID
- Metadata fields where feasible

### FR-INBOX-004 — Pagination

The inbox must use cursor-based or stable pagination.

### FR-INBOX-005 — Sort options

The user must be able to sort by:

- Newest failure
- Oldest failure
- Most attempts
- Most recent replay
- Incident size
- Last updated

### FR-INBOX-006 — Message detail page

The dashboard must display:

- Source
- Queue
- Event type
- Original message identifier
- Idempotency key
- Correlation ID
- Tenant ID if present
- Original payload
- Payload versions
- Failure type
- Failure message
- Stack trace
- Processing attempt count
- Consumer version
- First failure time
- Latest failure time
- Replay attempts
- Audit history
- Related incident group
- Current status

### FR-INBOX-007 — Message statuses

The system must support:

```text
open
investigating
resolved
ignored
replay_scheduled
replay_in_progress
replay_succeeded
replay_failed
```

A message may have a primary operational status and a separate latest replay status if implementation clarity requires it.

### FR-INBOX-008 — Manual status updates

Authorized users must be able to:

- Mark a message as investigating
- Mark a message as resolved
- Ignore a message
- Reopen a message
- Add a note

### FR-INBOX-009 — Export

Authorized users should be able to export filtered message data as JSON or CSV.

---

## 7.6 Failure grouping and incidents

### FR-GROUP-001 — Failure fingerprint

The system must assign a fingerprint to each failure.

### FR-GROUP-002 — Incident group creation

Messages with the same active fingerprint should be grouped into an incident group.

### FR-GROUP-003 — Incident group fields

An incident group should contain:

```text
id
project_id
fingerprint
title
source
queue
event_type
failure_type
normalized_failure_message
first_seen_at
last_seen_at
message_count
open_message_count
consumer_versions
status
created_at
updated_at
```

### FR-GROUP-004 — Group detail page

The platform should display:

- Total number of failures
- Number of unresolved failures
- First-seen and last-seen timestamps
- Affected services
- Affected queues
- Consumer versions
- Sample payloads
- Common metadata
- Replay history
- Notes
- Alert history

### FR-GROUP-005 — Incident status

Incident groups should support:

```text
open
investigating
resolved
ignored
```

### FR-GROUP-006 — Fingerprint override

An authorized user should be able to merge or separate incident groups when automatic grouping is not useful.

---

## 7.7 Replay destinations

### FR-DEST-001 — Create destination

The platform must allow an authorized user to create an HTTP replay destination.

### FR-DEST-002 — Destination fields

An HTTP destination must support:

```text
name
url
http_method
headers
authentication_type
authentication_secret
timeout_seconds
max_requests_per_second
is_active
```

### FR-DEST-003 — Supported authentication

The MVP should support:

```text
none
bearer_token
basic_auth
custom_header
hmac_signature
```

### FR-DEST-004 — Secret storage

Destination secrets must be encrypted at rest and never returned in plaintext after creation.

### FR-DEST-005 — Destination testing

An authorized user should be able to send a safe test request to validate the configuration.

### FR-DEST-006 — Destination allowlist

The platform should support an optional allowlist of permitted replay hostnames to reduce server-side request forgery risk.

### FR-DEST-007 — Network protections

The platform must reject replay destinations that resolve to disallowed internal or metadata-service addresses unless explicitly enabled in a trusted self-hosted deployment.

---

## 7.8 Replay workflow

### FR-REPLAY-001 — Single-message replay

An authorized user must be able to replay one message:

```http
POST /v1/messages/:id/replay
```

### FR-REPLAY-002 — Bulk replay

An authorized user must be able to replay multiple messages:

```http
POST /v1/replay-batches
```

Example:

```json
{
  "message_ids": ["msg_1", "msg_2", "msg_3"],
  "destination_id": "dest_123",
  "payload_version": "original",
  "requests_per_second": 10,
  "max_concurrency": 3,
  "stop_after_failures": 10
}
```

### FR-REPLAY-003 — Replay preview

Before a bulk replay starts, the platform must show:

- Number of messages
- Selected destination
- Selected payload version
- Rate limit
- Estimated downstream request pattern
- Replay policy
- Messages that cannot be replayed
- Messages requiring approval

### FR-REPLAY-004 — Original payload preservation

Replaying a message must never mutate its original payload.

### FR-REPLAY-005 — Edited replay

An authorized user should be able to edit a payload and replay it as a new version.

### FR-REPLAY-006 — Payload version tracking

Every edited replay must record:

```text
original_message_id
payload_version_id
editor_user_id
change_note
created_at
```

### FR-REPLAY-007 — Replay headers

Each replay request should include traceable headers:

```http
X-DLQ-Message-ID: msg_123
X-DLQ-Replay-Attempt-ID: replay_456
X-DLQ-Original-Message-ID: evt_123
X-DLQ-Idempotency-Key: payment_9812
X-DLQ-Replay-Timestamp: 2026-06-06T14:00:00Z
```

### FR-REPLAY-008 — Replay results

The platform must record:

- HTTP status code
- Response headers where allowed
- Truncated response body
- Duration
- Error details
- Timestamp
- Destination
- Payload version
- User or automation that initiated replay

### FR-REPLAY-009 — Replay success rule

The default HTTP success rule should be any `2xx` response. This should be configurable by destination.

### FR-REPLAY-010 — Rate limiting

Every replay batch must support requests-per-second throttling.

### FR-REPLAY-011 — Concurrency limit

Every replay batch must support a maximum concurrency setting.

### FR-REPLAY-012 — Circuit breaker

A replay batch must pause automatically after a configurable number or ratio of replay failures.

Example:

```text
Pause after 10 replay failures within 60 seconds
```

### FR-REPLAY-013 — Pause and resume

Authorized users must be able to pause, resume, and cancel replay batches.

### FR-REPLAY-014 — Retry replay failure

An authorized user may retry failed replay attempts manually.

### FR-REPLAY-015 — Duplicate protection warning

The UI must warn users that downstream consumers should implement idempotency because the platform provides at-least-once replay semantics.

### FR-REPLAY-016 — Ordering warning

The UI must warn users when replaying multiple messages from an ordered source because replay order may matter.

### FR-REPLAY-017 — Replay policy enforcement

Replay actions must be blocked or require approval according to the configured policy.

---

## 7.9 Replay policies

### FR-POLICY-001 — Default replay policies

The system should support:

```text
automatic_allowed
manual_allowed
approval_required
admin_only
disabled
```

### FR-POLICY-002 — Policy scope

Policies should be configurable by:

- Project
- Source
- Queue
- Event type
- Tag

The most specific policy should take precedence.

### FR-POLICY-003 — Approval workflow

For messages requiring approval:

1. An operator requests replay.
2. The replay is created with status `awaiting_approval`.
3. An admin or owner approves or rejects it.
4. The decision is recorded in the audit log.
5. Approved replays are scheduled.

### FR-POLICY-004 — Sensitive queues

The platform should allow queues or event types to be marked as sensitive.

Examples:

```text
payments.capture
refunds.issue
invoices.finalize
accounts.delete
```

Sensitive queues should default to `approval_required` or `admin_only`.

---

## 7.10 Alerting

### FR-ALERT-001 — Alert rules

An authorized user must be able to configure alert rules.

### FR-ALERT-002 — Supported alert triggers

The MVP should support:

- New failure type detected
- More than `N` failures within a time window
- Unresolved failures older than a configured threshold
- Replay batch paused by circuit breaker
- Replay failure
- Source stops sending expected heartbeats, if heartbeat monitoring is enabled
- Payload rejected because of validation errors
- Ingestion errors above a threshold

### FR-ALERT-003 — Supported channels

The MVP must support:

```text
email
outbound_webhook
```

Later versions should support:

```text
Slack
Microsoft Teams
PagerDuty
Discord
```

### FR-ALERT-004 — Alert deduplication

The system must avoid sending duplicate alerts repeatedly for the same active incident unless escalation conditions are met.

### FR-ALERT-005 — Alert escalation

The system should support escalation rules.

Example:

```text
Immediately: send email to engineering
After 30 minutes unresolved: send webhook to incident system
After 60 minutes unresolved: notify admin group
```

### FR-ALERT-006 — Alert history

Every alert delivery attempt must be recorded.

### FR-ALERT-007 — Alert delivery retries

Failed outbound alerts must be retried with exponential backoff.

---

## 7.11 Payload redaction and sensitive data

### FR-REDACT-001 — Redaction rules

An authorized user must be able to configure field paths to redact before storage.

Examples:

```text
password
token
authorization
credit_card.number
customer.ssn
headers.Authorization
metadata.access_token
```

### FR-REDACT-002 — Redaction replacement

Redacted values should be stored as:

```text
[REDACTED]
```

### FR-REDACT-003 — Nested payload support

Redaction rules must support nested JSON paths.

### FR-REDACT-004 — Default redaction rules

The platform should ship with default rules for common secret names:

```text
password
secret
token
access_token
refresh_token
authorization
api_key
client_secret
```

### FR-REDACT-005 — Redaction auditability

The system should record which redaction rules were applied without storing the original secret value.

### FR-REDACT-006 — Display masking

The platform should allow additional UI masking for fields that are stored but should not be visible to lower-permission roles.

---

## 7.12 Schema validation

### FR-SCHEMA-001 — Optional schemas

An authorized user should be able to register a JSON Schema for a queue or event type.

### FR-SCHEMA-002 — Ingestion validation

Schema validation during ingestion should be configurable:

```text
off
warn
reject
```

### FR-SCHEMA-003 — Replay validation

Before replay, the platform should validate the selected payload version against the applicable schema.

### FR-SCHEMA-004 — Validation result

Validation errors must identify invalid fields clearly.

Example:

```json
{
  "valid": false,
  "errors": [
    {
      "path": "$.customer_id",
      "message": "is required"
    },
    {
      "path": "$.amount_cents",
      "message": "must be an integer"
    }
  ]
}
```

---

## 7.13 Audit logs

### FR-AUDIT-001 — Immutable audit events

The platform must record immutable audit events.

### FR-AUDIT-002 — Audited actions

At minimum, audit:

- User login
- API-key creation
- API-key revocation
- Project creation
- Project configuration changes
- Destination creation
- Destination changes
- Replay request
- Replay approval or rejection
- Replay start
- Replay pause
- Replay resume
- Replay cancellation
- Message status changes
- Message notes
- Payload version creation
- Export request
- Alert-rule changes
- Member-role changes

### FR-AUDIT-003 — Audit event fields

Each audit event must include:

```text
id
organization_id
project_id
actor_type
actor_id
action
target_type
target_id
metadata
ip_address
user_agent
created_at
```

### FR-AUDIT-004 — Audit filtering

Authorized users must be able to search audit logs by actor, action, project, target, and date range.

### FR-AUDIT-005 — Audit retention

Audit logs should have a longer retention period than message payloads.

---

## 7.14 Retention

### FR-RETENTION-001 — Configurable retention

Each project must have a configurable payload-retention period.

Suggested options:

```text
1 day
7 days
14 days
30 days
90 days
custom
```

### FR-RETENTION-002 — Default retention

The default MVP payload-retention period should be 30 days.

### FR-RETENTION-003 — Payload deletion

Expired payloads must be deleted or irreversibly removed.

### FR-RETENTION-004 — Metadata preservation

The system may preserve non-sensitive message metadata, fingerprints, and aggregate statistics after payload expiration.

### FR-RETENTION-005 — Manual deletion

Authorized users should be able to delete a message payload before its retention period expires, subject to audit logging.

### FR-RETENTION-006 — Legal and compliance readiness

The architecture should permit future organization-level retention rules and data-deletion workflows.

---

## 7.15 Notes and collaboration

### FR-NOTE-001 — Message notes

Authorized users should be able to add notes to a failed message.

### FR-NOTE-002 — Incident notes

Authorized users should be able to add notes to an incident group.

### FR-NOTE-003 — Note attribution

Notes must record the author and timestamp.

### FR-NOTE-004 — Mentions

User mentions are optional for a later release.

---

## 8. API Requirements

## 8.1 API principles

The API must:

- Use JSON request and response bodies
- Use versioned routes under `/v1`
- Return structured errors
- Support pagination
- Apply authentication consistently
- Enforce organization and project isolation
- Publish OpenAPI documentation
- Include correlation IDs in responses
- Apply rate limits
- Log important requests safely without leaking secrets

## 8.2 Suggested endpoints

### Authentication and users

```http
POST   /v1/auth/login
POST   /v1/auth/logout
GET    /v1/me
```

### Organizations

```http
POST   /v1/organizations
GET    /v1/organizations
GET    /v1/organizations/:id
PATCH  /v1/organizations/:id
```

### Organization members

```http
GET    /v1/organizations/:id/members
POST   /v1/organizations/:id/members
PATCH  /v1/organizations/:id/members/:member_id
DELETE /v1/organizations/:id/members/:member_id
```

### Projects

```http
POST   /v1/projects
GET    /v1/projects
GET    /v1/projects/:id
PATCH  /v1/projects/:id
POST   /v1/projects/:id/archive
POST   /v1/projects/:id/reactivate
```

### API keys

```http
POST   /v1/projects/:id/api-keys
GET    /v1/projects/:id/api-keys
POST   /v1/projects/:id/api-keys/:key_id/revoke
```

### Sources

```http
POST   /v1/projects/:id/sources
GET    /v1/projects/:id/sources
GET    /v1/sources/:id
PATCH  /v1/sources/:id
```

### Messages

```http
POST   /v1/messages
GET    /v1/messages
GET    /v1/messages/:id
PATCH  /v1/messages/:id/status
POST   /v1/messages/:id/notes
GET    /v1/messages/:id/audit-events
POST   /v1/messages/:id/payload-versions
POST   /v1/messages/:id/replay
```

### Incident groups

```http
GET    /v1/incidents
GET    /v1/incidents/:id
PATCH  /v1/incidents/:id/status
POST   /v1/incidents/:id/notes
POST   /v1/incidents/:id/merge
POST   /v1/incidents/:id/split
```

### Replay destinations

```http
POST   /v1/projects/:id/destinations
GET    /v1/projects/:id/destinations
GET    /v1/destinations/:id
PATCH  /v1/destinations/:id
POST   /v1/destinations/:id/test
```

### Replay batches

```http
POST   /v1/replay-batches
GET    /v1/replay-batches
GET    /v1/replay-batches/:id
POST   /v1/replay-batches/:id/approve
POST   /v1/replay-batches/:id/reject
POST   /v1/replay-batches/:id/pause
POST   /v1/replay-batches/:id/resume
POST   /v1/replay-batches/:id/cancel
```

### Alert rules

```http
POST   /v1/projects/:id/alert-rules
GET    /v1/projects/:id/alert-rules
GET    /v1/alert-rules/:id
PATCH  /v1/alert-rules/:id
DELETE /v1/alert-rules/:id
```

### Audit logs

```http
GET    /v1/audit-events
```

### Metrics and health

```http
GET    /health
GET    /ready
GET    /metrics
```

---

## 9. Data Model

The initial relational model should include the following tables.

## 9.1 Organizations

```text
organizations
- id
- name
- slug
- created_at
- updated_at
```

## 9.2 Users

```text
users
- id
- email
- password_digest
- name
- created_at
- updated_at
```

## 9.3 Organization memberships

```text
organization_memberships
- id
- organization_id
- user_id
- role
- created_at
- updated_at
```

## 9.4 Projects

```text
projects
- id
- organization_id
- name
- slug
- environment
- status
- default_retention_days
- max_payload_size_bytes
- default_replay_policy
- created_at
- updated_at
```

## 9.5 Project API keys

```text
project_api_keys
- id
- project_id
- name
- key_prefix
- key_digest
- scopes
- last_used_at
- revoked_at
- created_by_user_id
- created_at
- updated_at
```

## 9.6 Sources

```text
sources
- id
- project_id
- name
- source_type
- description
- status
- created_at
- updated_at
```

## 9.7 Failed messages

```text
failed_messages
- id
- project_id
- source_id
- external_message_id
- idempotency_key
- queue_name
- event_type
- status
- latest_replay_status
- payload_original
- payload_size_bytes
- fingerprint
- incident_group_id
- correlation_id
- tenant_identifier
- metadata
- first_failed_at
- last_failed_at
- attempt_count
- payload_expires_at
- created_at
- updated_at
```

## 9.8 Failure attempts

```text
failure_attempts
- id
- failed_message_id
- attempt_number
- failure_type
- failure_message
- stack_trace
- consumer_version
- occurred_at
- created_at
```

## 9.9 Payload versions

```text
message_payload_versions
- id
- failed_message_id
- version_number
- payload
- change_note
- created_by_user_id
- created_at
```

## 9.10 Incident groups

```text
incident_groups
- id
- project_id
- fingerprint
- title
- status
- source_name
- queue_name
- event_type
- failure_type
- normalized_failure_message
- first_seen_at
- last_seen_at
- message_count
- open_message_count
- created_at
- updated_at
```

## 9.11 Replay destinations

```text
replay_destinations
- id
- project_id
- name
- destination_type
- url
- http_method
- headers_encrypted
- authentication_type
- authentication_secret_encrypted
- timeout_seconds
- max_requests_per_second
- allowed_success_statuses
- status
- created_at
- updated_at
```

## 9.12 Replay batches

```text
replay_batches
- id
- project_id
- destination_id
- requested_by_user_id
- approved_by_user_id
- status
- requests_per_second
- max_concurrency
- stop_after_failures
- total_messages
- pending_count
- success_count
- failure_count
- started_at
- paused_at
- completed_at
- created_at
- updated_at
```

## 9.13 Replay attempts

```text
replay_attempts
- id
- replay_batch_id
- failed_message_id
- payload_version_id
- destination_id
- status
- http_status_code
- response_headers
- response_body_truncated
- error_type
- error_message
- duration_ms
- scheduled_at
- started_at
- completed_at
- created_at
- updated_at
```

## 9.14 Alert rules

```text
alert_rules
- id
- project_id
- name
- trigger_type
- conditions
- channel_type
- channel_configuration_encrypted
- escalation_configuration
- status
- created_at
- updated_at
```

## 9.15 Alert deliveries

```text
alert_deliveries
- id
- alert_rule_id
- incident_group_id
- failed_message_id
- status
- attempt_count
- last_error
- scheduled_at
- delivered_at
- created_at
- updated_at
```

## 9.16 Audit events

```text
audit_events
- id
- organization_id
- project_id
- actor_type
- actor_id
- action
- target_type
- target_id
- metadata
- ip_address
- user_agent
- created_at
```

## 9.17 Redaction rules

```text
redaction_rules
- id
- project_id
- json_path
- replacement
- status
- created_at
- updated_at
```

## 9.18 Schemas

```text
payload_schemas
- id
- project_id
- queue_name
- event_type
- schema_version
- json_schema
- ingestion_mode
- replay_validation_enabled
- created_at
- updated_at
```

---

## 10. Background Jobs

The platform should use background jobs for work that does not need to run synchronously.

Required jobs:

```text
ProcessIngestedMessageJob
GenerateFailureFingerprintJob
UpdateIncidentGroupJob
EvaluateAlertRulesJob
DeliverAlertJob
ScheduleReplayBatchJob
ExecuteReplayAttemptJob
MonitorReplayBatchCircuitBreakerJob
ExpirePayloadsJob
AggregateMetricsJob
```

### Job requirements

1. Jobs must be idempotent where feasible.
2. Jobs must use bounded retries.
3. Job failures must be observable.
4. Jobs must avoid infinite retry loops.
5. Failed internal jobs should be routed to an internal DLQ or failure queue.
6. Internal DLQ failures should be visible to operators.
7. Scheduled cleanup jobs must run regularly.
8. Replay jobs must honor rate limits and concurrency limits.

---

## 11. System Architecture

## 11.1 MVP architecture

```text
Client SDK or application
        |
        v
HTTP Ingestion API
        |
        v
Relational database
        |
        +----------------------+
        |                      |
        v                      v
Incident grouping jobs     Alert evaluation jobs
        |                      |
        v                      v
Dashboard API             Email or webhook alerts

Operator dashboard
        |
        v
Replay batch creation
        |
        v
Replay scheduler
        |
        v
Replay workers
        |
        v
Configured HTTP destination
        |
        v
Replay result, metrics, and audit log
```

## 11.2 Suggested implementation stack

```text
Backend: Rails API
Workers: Sidekiq
Queue backend: Redis
Database: PostgreSQL or MySQL
Frontend: Nuxt with Quasar
Authentication: Secure session or JWT-based auth
API docs: OpenAPI
Metrics: Prometheus
Dashboards: Grafana
Local environment: Docker Compose
Reverse proxy: Nginx
Edge security: Cloudflare
CI/CD: GitHub Actions
```

## 11.3 Optional later architecture

If ingestion volume becomes high:

```text
Client
  |
  v
Go ingestion service
  |
  v
Durable stream or queue
  |
  v
Rails control plane and workers
```

The MVP should not introduce this complexity prematurely.

---

## 12. Non-Functional Requirements

## 12.1 Reliability

### NFR-REL-001

Accepted ingestion requests must not be silently lost.

### NFR-REL-002

The system must return an explicit success or failure response for ingestion.

### NFR-REL-003

Replay attempts must record their final outcome.

### NFR-REL-004

Background jobs must use bounded retries and failure visibility.

### NFR-REL-005

Bulk replay must be pausable and resumable.

### NFR-REL-006

The replay circuit breaker must prevent runaway failure loops.

---

## 12.2 Performance

### NFR-PERF-001

The MVP should support at least 100 ingestion requests per second in a documented benchmark environment.

### NFR-PERF-002

The ingestion endpoint should target a p95 latency below 300 ms under the documented MVP benchmark load.

### NFR-PERF-003

Inbox queries should return within 1 second for common filtered requests in the documented MVP dataset.

### NFR-PERF-004

Large payloads must not be loaded unnecessarily in inbox list views.

### NFR-PERF-005

The system should paginate messages and audit events.

---

## 12.3 Scalability

### NFR-SCALE-001

Stateless API instances should be horizontally scalable.

### NFR-SCALE-002

Replay workers should scale independently from API instances.

### NFR-SCALE-003

Alert workers should scale independently from replay workers.

### NFR-SCALE-004

The database schema should include indexes for common filters.

Recommended indexes:

```text
failed_messages(project_id, created_at)
failed_messages(project_id, status, created_at)
failed_messages(project_id, queue_name, created_at)
failed_messages(project_id, event_type, created_at)
failed_messages(project_id, fingerprint, created_at)
failed_messages(project_id, correlation_id)
failed_messages(project_id, tenant_identifier)
failed_messages(project_id, external_message_id)
incident_groups(project_id, status, last_seen_at)
replay_attempts(replay_batch_id, status)
audit_events(project_id, created_at)
```

---

## 12.4 Security

### NFR-SEC-001

All production traffic must use TLS.

### NFR-SEC-002

API keys must be hashed at rest.

### NFR-SEC-003

Replay destination secrets must be encrypted at rest.

### NFR-SEC-004

Sensitive values must not appear in application logs.

### NFR-SEC-005

The platform must enforce tenant isolation at the application layer and through carefully designed database access patterns.

### NFR-SEC-006

Administrative actions must be audited.

### NFR-SEC-007

The ingestion API must be rate-limited.

### NFR-SEC-008

Authentication endpoints must be rate-limited.

### NFR-SEC-009

Replay endpoints must require authorization and policy checks.

### NFR-SEC-010

Replay destinations must be protected against server-side request forgery.

### NFR-SEC-011

The application should use secure HTTP headers.

### NFR-SEC-012

The system should support secret rotation.

### NFR-SEC-013

Payload redaction must run before persistence.

### NFR-SEC-014

Exports must require authorization and be audited.

### NFR-SEC-015

The application must protect against SQL injection, cross-site scripting, cross-site request forgery where applicable, insecure direct-object references, and mass-assignment vulnerabilities.

---

## 12.5 Privacy

### NFR-PRIV-001

Projects must have configurable payload-retention policies.

### NFR-PRIV-002

Expired payloads must be deleted automatically.

### NFR-PRIV-003

Users must be able to configure redaction rules.

### NFR-PRIV-004

Sensitive values should be masked in the UI for roles without access.

### NFR-PRIV-005

Audit logs should not store full message payloads.

---

## 12.6 Observability

### NFR-OBS-001

The system must expose a health endpoint:

```http
GET /health
```

### NFR-OBS-002

The system must expose a readiness endpoint:

```http
GET /ready
```

### NFR-OBS-003

The system must expose Prometheus-compatible metrics:

```http
GET /metrics
```

### NFR-OBS-004

Required metrics:

```text
dlq_ingestion_requests_total
dlq_ingestion_errors_total
dlq_messages_open_total
dlq_messages_ingested_total
dlq_incidents_open_total
dlq_replay_batches_total
dlq_replay_attempts_total
dlq_replay_success_total
dlq_replay_failure_total
dlq_replay_duration_seconds
dlq_alert_delivery_total
dlq_alert_delivery_failure_total
dlq_payload_expiration_total
dlq_background_job_failure_total
```

### NFR-OBS-005

Logs must include correlation IDs where possible.

### NFR-OBS-006

Logs must be structured.

### NFR-OBS-007

The platform should include example Grafana dashboards.

---

## 12.7 Maintainability

### NFR-MAINT-001

Business rules should not live directly inside controllers.

### NFR-MAINT-002

The backend should use service objects or equivalent application-layer components for ingestion, replay scheduling, policy evaluation, and alert evaluation.

### NFR-MAINT-003

Broker integrations should use an adapter interface.

### NFR-MAINT-004

The platform should include database migrations, seed data, and setup documentation.

### NFR-MAINT-005

The project should use linting and automated tests in CI.

---

## 13. Broker Adapter Interface

Broker-specific integrations are outside the MVP, but the architecture must allow them later.

Suggested interface:

```ruby
class BrokerAdapter
  def fetch_failed_messages(cursor: nil, limit: 100)
    raise NotImplementedError
  end

  def replay(message:, destination:, options: {})
    raise NotImplementedError
  end

  def acknowledge_external_message(message:)
    raise NotImplementedError
  end

  def health_check
    raise NotImplementedError
  end
end
```

Future adapters:

```text
HttpAdapter
AmazonSqsAdapter
RabbitMqAdapter
KafkaAdapter
SidekiqAdapter
BullMqAdapter
```

---

## 14. Client SDKs

Client SDKs are not mandatory for the earliest MVP, but at least one integration helper should be created.

### 14.1 Initial SDK

Create a small Ruby SDK or plain Ruby integration example.

Example:

```ruby
DlqClient.capture(
  source: "payments-worker",
  queue: "payments.processed",
  event_type: "payment.confirmed",
  message_id: event.id,
  idempotency_key: "payment_#{payment.id}",
  payload: event.payload,
  failure: {
    type: exception.class.name,
    message: exception.message,
    stack_trace: exception.backtrace&.join("\n")
  },
  metadata: {
    tenant_id: tenant.id,
    attempt: job.executions,
    consumer_version: ENV.fetch("APP_VERSION", "unknown")
  }
)
```

### 14.2 Future SDKs

Potential later SDKs:

```text
Ruby
JavaScript or TypeScript
Python
Go
Java
```

---

## 15. Dashboard Requirements

## 15.1 Main navigation

The dashboard should include:

```text
Overview
Messages
Incidents
Replay batches
Sources
Destinations
Alert rules
Audit log
Project settings
Organization settings
```

## 15.2 Overview page

Display:

- Open failures
- New failures in the last 24 hours
- Open incident groups
- Aging unresolved failures
- Replay success rate
- Replay failures
- Top failing queues
- Top error types
- Recent alerts
- Recent replay batches

## 15.3 Messages page

Display a searchable, paginated table with:

- Status
- Source
- Queue
- Event type
- Failure type
- Attempts
- Tenant ID
- Consumer version
- Last failed time
- Latest replay status

## 15.4 Incident page

Display grouped failures with:

- Incident title
- Fingerprint
- Count
- First seen
- Last seen
- Status
- Queue
- Failure type
- Consumer versions
- Recent messages
- Replay controls

## 15.5 Replay batch page

Display:

- Batch status
- Requested by
- Approved by
- Destination
- Rate limit
- Concurrency
- Total messages
- Pending count
- Success count
- Failure count
- Circuit-breaker status
- Timeline
- Pause, resume, and cancel controls

## 15.6 Audit-log page

Display:

- Timestamp
- Actor
- Action
- Target
- Project
- Metadata summary

---

## 16. Error Handling

## 16.1 Structured API errors

All API errors should follow a consistent structure:

```json
{
  "error": {
    "code": "replay_policy_violation",
    "message": "This message requires administrative approval before replay.",
    "details": {
      "message_id": "msg_123",
      "policy": "approval_required"
    },
    "correlation_id": "req_456"
  }
}
```

## 16.2 Common error codes

```text
authentication_required
forbidden
resource_not_found
invalid_payload
payload_too_large
duplicate_message
rate_limit_exceeded
project_archived
destination_inactive
destination_not_allowed
schema_validation_failed
replay_policy_violation
replay_batch_paused
replay_batch_cancelled
internal_error
```

---

## 17. Testing Requirements

## 17.1 Unit tests

Cover:

- Fingerprint generation
- Error-message normalization
- Redaction rules
- Replay-policy precedence
- Schema validation
- Payload version creation
- Replay success rules
- Circuit-breaker logic
- Retention logic
- Role permissions
- API-key hashing and validation

## 17.2 Request tests

Cover:

- Ingestion success
- Duplicate ingestion
- Invalid payload rejection
- Payload-size enforcement
- API-key authorization
- Organization isolation
- Message search and filters
- Replay creation
- Replay approval
- Replay pause and resume
- Destination creation
- SSRF protections
- Audit-log creation

## 17.3 Integration tests

Cover:

- Ingest message → create incident group
- Ingest message → trigger alert
- Replay message → destination accepts request
- Replay message → destination fails
- Bulk replay → rate limit respected
- Bulk replay → circuit breaker pauses batch
- Edited payload → create version → replay version
- Expired payload → cleanup job removes payload
- Archived project → ingestion rejected

## 17.4 End-to-end tests

Cover:

1. Create project.
2. Create API key.
3. Configure destination.
4. Ingest failed payment message.
5. View message in dashboard.
6. Add note.
7. Create replay batch.
8. Approve replay if required.
9. Observe replay result.
10. Confirm audit-log entries.

## 17.5 Security tests

Cover:

- Tenant isolation
- Privilege escalation attempts
- Invalid API keys
- Revoked API keys
- Secret leakage in logs
- SSRF attempts using private IP addresses
- Cross-site scripting payloads
- SQL injection attempts
- Mass-assignment attempts
- Rate-limit behavior

## 17.6 Load tests

At minimum, test:

- Sustained ingestion load
- Burst ingestion load
- Inbox filtering under realistic dataset size
- Bulk replay with throttle
- Alert storm behavior
- Cleanup job performance

---

## 18. Deployment Requirements

## 18.1 Local development

Provide a Docker Compose setup with:

```text
api
worker
frontend
database
redis
mail catcher
mock replay destination
prometheus
grafana
```

## 18.2 Production deployment

A production deployment should include:

```text
Cloudflare
Nginx
Rails API
Sidekiq workers
Redis
PostgreSQL or MySQL
Nuxt frontend build
Prometheus
Grafana
```

## 18.3 CI/CD

GitHub Actions should run:

```text
lint
unit tests
request tests
security checks
build
optional deployment
```

## 18.4 Database migrations

Deployments must run database migrations safely.

## 18.5 Backups

The database must have a backup strategy. Secret storage and encrypted data must be recoverable according to documented procedures.

---

## 19. MVP Acceptance Criteria

The MVP is complete when a user can:

1. Sign in.
2. Create an organization.
3. Create a project.
4. Generate an ingestion API key.
5. Configure an HTTP replay destination.
6. Submit a failed message through the HTTP ingestion API.
7. See the message in the dashboard.
8. Filter messages by queue, status, date, and failure type.
9. View the original payload and error details.
10. See similar messages grouped into an incident.
11. Mark a message as investigating, ignored, resolved, or reopened.
12. Add a note.
13. Replay a single message.
14. Edit a payload and replay a new version without modifying the original.
15. Create a rate-limited bulk replay batch.
16. Pause, resume, or cancel a replay batch.
17. Observe the circuit breaker pause a repeatedly failing replay batch.
18. Receive an email or webhook alert for a configured rule.
19. View an audit log for management and replay actions.
20. Confirm payload cleanup after the configured retention period.
21. View Prometheus-compatible metrics.
22. Run the full application locally with documented setup steps.
23. Run automated tests successfully in CI.

---

## 20. Recommended Development Phases

## Phase 1 — Foundation

Build:

- Rails API
- Database schema
- Authentication
- Organizations
- Projects
- API keys
- Basic dashboard shell
- Docker Compose
- CI pipeline

## Phase 2 — Failed-message ingestion

Build:

- HTTP ingestion endpoint
- Payload validation
- Redaction rules
- Duplicate handling
- Failed-message persistence
- Failure attempts
- Inbox page
- Message-detail page

## Phase 3 — Incident grouping

Build:

- Failure fingerprinting
- Error normalization
- Incident groups
- Incident list page
- Incident detail page
- Status changes
- Notes

## Phase 4 — Controlled replay

Build:

- HTTP destinations
- Secret encryption
- Single-message replay
- Replay attempt persistence
- Payload versions
- Edited replay
- Bulk replay batches
- Rate limiting
- Concurrency limits
- Circuit breaker
- Pause, resume, and cancel controls

## Phase 5 — Alerts and auditability

Build:

- Alert rules
- Email alerts
- Outbound webhook alerts
- Alert retries
- Alert deduplication
- Audit events
- Audit-log UI

## Phase 6 — Hardening

Build:

- Retention cleanup
- Metrics
- Grafana dashboards
- Security tests
- Load tests
- Documentation
- Demo data
- Deployment scripts

## Phase 7 — First broker integration

Add:

- Amazon SQS DLQ adapter
- Credential configuration
- Pull or synchronization workflow
- Safe redrive controls
- External acknowledgement strategy
- Integration tests

---

## 21. Future Roadmap

### Version 1.1

- Slack alerts
- Saved filters
- CSV and JSON export
- JSON Schema registry
- Approval workflow
- Project-level usage limits
- Improved dashboards

### Version 1.2

- Amazon SQS adapter
- Sidekiq integration
- Ruby SDK
- JavaScript SDK
- Replay scheduling
- Incident comments with mentions

### Version 1.3

- RabbitMQ adapter
- Kafka adapter
- BullMQ integration
- Webhook signature verification
- Custom alert templates
- Single sign-on readiness

### Version 2.0

- Multi-region support
- Object-storage payload archival
- Enterprise retention controls
- Advanced role-based access control
- Automated anomaly detection
- Optional AI-generated incident summaries
- Optional AI-generated grouping suggestions
- Compliance-focused exports
- Self-hosted edition

---

## 22. Important Engineering Decisions

### 22.1 At-least-once semantics

The platform should clearly document that replay may deliver the same message more than once. Downstream consumers must implement idempotency.

### 22.2 Original payload immutability

The platform must never overwrite the original message payload. Edited replays create new linked versions.

### 22.3 Safe replay over convenience

The system should favor explicit permissions, previews, throttles, approval policies, warnings, and audit logs over one-click mass replay without safeguards.

### 22.4 HTTP first

Start with HTTP ingestion and HTTP replay. Avoid implementing multiple broker adapters before the core operational workflow is solid.

### 22.5 Control plane before high throughput

The MVP should prioritize reliability, observability, safety, and usability. Optimize for very high ingestion volume only after the core workflow is proven.

### 22.6 Internal dogfooding

The platform's own failed background jobs should be routed into an internal DLQ workflow so the project demonstrates its value using its own infrastructure.

---

## 23. Demo Scenario

Use a realistic payment-processing demonstration.

### Scenario

A payment webhook arrives and a background worker attempts to process it. The downstream payment service times out five times.

### Flow

```text
Payment event received
    |
    v
Background worker retries five times
    |
    v
Worker submits failed message to DLQ Control Center
    |
    v
Message appears in payments.processed incident group
    |
    v
Alert is sent because more than 10 failures occur in 5 minutes
    |
    v
Developer fixes the downstream issue
    |
    v
Operator opens incident group
    |
    v
Operator starts replay batch at 5 requests per second
    |
    v
Destination returns successful responses
    |
    v
Messages are marked replay_succeeded
    |
    v
Incident is marked resolved
    |
    v
Audit log records the entire recovery process
```

### Demonstrated engineering topics

- Background jobs
- Retries
- Dead-letter queues
- Idempotency
- Multi-tenancy
- Rate limiting
- Circuit breakers
- Audit logs
- Payload redaction
- Observability
- Secure secret storage
- HTTP integrations
- Incident response

---

## 24. Suggested Repository Structure

```text
dlq-control-center/
├── api/
│   ├── app/
│   │   ├── controllers/
│   │   ├── models/
│   │   ├── services/
│   │   ├── jobs/
│   │   ├── policies/
│   │   ├── serializers/
│   │   └── adapters/
│   ├── config/
│   ├── db/
│   ├── spec/
│   └── Dockerfile
├── frontend/
│   ├── components/
│   ├── pages/
│   ├── stores/
│   ├── composables/
│   ├── layouts/
│   └── Dockerfile
├── sdk/
│   └── ruby/
├── infra/
│   ├── nginx/
│   ├── prometheus/
│   ├── grafana/
│   └── docker-compose.yml
├── docs/
│   ├── architecture.md
│   ├── api.md
│   ├── security.md
│   └── demo.md
├── .github/
│   └── workflows/
└── README.md
```

---

## 25. README Checklist

The repository README should include:

- Product summary
- Architecture diagram
- Main features
- Screenshots or GIFs
- Local setup instructions
- Environment variables
- API example
- Replay safety warning
- Demo scenario
- Test instructions
- Metrics instructions
- Deployment notes
- Roadmap
- Design decisions
- Known limitations

---

## 26. Final Build Recommendation

Build the first version around this narrow workflow:

```text
HTTP failure ingestion
→ searchable inbox
→ incident grouping
→ email or webhook alert
→ HTTP replay destination
→ rate-limited replay batch
→ circuit breaker
→ audit log
```

Do not begin with Kafka, RabbitMQ, Amazon SQS, AI summaries, or enterprise billing. Add the first broker adapter only after the core failure-recovery workflow is reliable and easy to demonstrate.

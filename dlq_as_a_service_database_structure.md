# DLQ as a Service Database Structure

## 1. Product-to-Database Goals

This document translates the PRD into an implementation-ready MVP database design for the Rails app in this repository.

The schema needs to support:

- multi-tenant isolation across organizations and projects
- durable failed-message capture
- efficient inbox queries without depending on replaying attempt history
- immutable original payload storage plus edited replay versions
- incident grouping and operator notes
- safe replay tracking with batches and per-message attempts
- alerts, redaction rules, and auditability

The goal is to make the first migration pass decision-complete enough that implementation can start without redesigning the data model mid-build.

## 2. Current Repo Reality

The database plan is grounded in the current codebase:

- the Rails app has no domain-specific business tables yet
- the app is SQLite-first today, per [config/database.yml](/home/leon/Downloads/dlq_saas/config/database.yml)
- the repo already uses framework-managed support databases for `solid_queue`, `solid_cache`, and `solid_cable`
- those support schemas are visible in [db/queue_schema.rb](/home/leon/Downloads/dlq_saas/db/queue_schema.rb), [db/cache_schema.rb](/home/leon/Downloads/dlq_saas/db/cache_schema.rb), and [db/cable_schema.rb](/home/leon/Downloads/dlq_saas/db/cable_schema.rb)

This document only defines the DLQ business schema for the primary application database.

## 3. Primary Database Principles

### Database boundary

There are two database layers:

- `primary` application database: all DLQ business tables in this document
- Rails-managed support databases: `solid_queue`, `solid_cache`, and `solid_cable`

The support databases must stay outside the DLQ domain model. They should not hold business state such as failed messages, incidents, replay batches, or audit events.

### Identity strategy

Use these defaults for the MVP:

- Rails default `bigint` primary keys
- no UUID requirement for the first pass
- optional `public_id` columns may be added later if API opacity becomes necessary
- foreign keys should use standard Rails references and database-level foreign-key constraints

### Compatibility strategy

Because the app is SQLite-first today:

- use string status columns instead of DB enums
- store payloads, headers, metadata, and rule conditions as `TEXT` containing JSON
- do not require PostgreSQL-only features such as `jsonb`, generated columns, partial indexes, or native enum types
- denormalize the most important inbox and incident fields into first-class columns for filtering and sorting

### Modeling rules

Use these modeling decisions consistently:

- original message payload lives on `failed_messages`
- edited replay payloads live in `message_payload_versions`
- `failed_messages` stores denormalized inbox-friendly summary fields
- `failure_attempts` stores per-attempt failure history
- notes use dedicated tables, not polymorphic associations
- replay actions are batch-oriented, including single-message replay
- most tables are project-scoped; organization scoping happens through `projects`

## 4. MVP Entity Map

### Tenant and access

- `users`
- `organizations`
- `organization_memberships`
- `projects`
- `project_api_keys`

### Ingestion and investigation

- `sources`
- `failed_messages`
- `failure_attempts`
- `message_payload_versions`
- `message_notes`

### Incident handling

- `incident_groups`
- `incident_notes`

### Replay

- `replay_destinations`
- `replay_batches`
- `replay_attempts`

### Governance and operations

- `alert_rules`
- `alert_deliveries`
- `redaction_rules`
- `audit_events`

## 5. Table-by-Table Definitions

### `users`

Purpose: authenticated operators and administrators.

Recommended columns:

- `id :bigint`
- `email :string, null: false`
- `password_digest :string, null: false`
- `name :string, null: false`
- `status :string, null: false, default: "active"`
- `last_sign_in_at :datetime`
- `created_at :datetime, null: false`
- `updated_at :datetime, null: false`

Constraints and indexes:

- unique index on `email`
- index on `status`

Notes:

- `password_digest` assumes `has_secure_password` or equivalent
- session storage is intentionally out of scope for this schema document

### `organizations`

Purpose: top-level tenant boundary.

Recommended columns:

- `id :bigint`
- `name :string, null: false`
- `slug :string, null: false`
- `status :string, null: false, default: "active"`
- `created_at :datetime, null: false`
- `updated_at :datetime, null: false`

Constraints and indexes:

- unique index on `slug`
- unique index on `name`

### `organization_memberships`

Purpose: maps users into organizations and roles.

Recommended columns:

- `id :bigint`
- `organization_id :bigint, null: false`
- `user_id :bigint, null: false`
- `role :string, null: false`
- `created_at :datetime, null: false`
- `updated_at :datetime, null: false`

Constraints and indexes:

- foreign keys to `organizations` and `users`
- unique index on `[organization_id, user_id]`
- index on `[organization_id, role]`
- index on `[user_id, role]`

Allowed MVP roles:

- `owner`
- `admin`
- `operator`
- `viewer`

### `projects`

Purpose: groups all business data inside an organization.

Recommended columns:

- `id :bigint`
- `organization_id :bigint, null: false`
- `name :string, null: false`
- `slug :string, null: false`
- `environment :string, null: false, default: "production"`
- `status :string, null: false, default: "active"`
- `default_retention_days :integer, null: false, default: 30`
- `max_payload_size_bytes :integer, null: false, default: 262144`
- `default_replay_policy :string, null: false, default: "manual_allowed"`
- `allowed_source_identifiers_text :text`
- `created_at :datetime, null: false`
- `updated_at :datetime, null: false`

Constraints and indexes:

- foreign key to `organizations`
- unique index on `[organization_id, slug]`
- unique index on `[organization_id, name]`
- index on `[organization_id, status]`

Notes:

- `allowed_source_identifiers_text` stores a JSON array when source allowlisting is enabled
- alert destinations, replay destinations, and redaction rules remain normalized into their own tables

### `project_api_keys`

Purpose: ingestion credentials for a project.

Recommended columns:

- `id :bigint`
- `project_id :bigint, null: false`
- `created_by_user_id :bigint, null: false`
- `name :string, null: false`
- `key_prefix :string, null: false`
- `key_digest :string, null: false`
- `scopes_text :text, null: false`
- `last_used_at :datetime`
- `revoked_at :datetime`
- `created_at :datetime, null: false`
- `updated_at :datetime, null: false`

Constraints and indexes:

- foreign key to `projects`
- foreign key to `users` via `created_by_user_id`
- unique index on `[project_id, key_prefix]`
- index on `[project_id, revoked_at]`

Notes:

- raw keys are never stored
- `scopes_text` stores a JSON array such as `["messages:write"]`

### `sources`

Purpose: identifies the producer or broker surface that emitted a failed message.

Recommended columns:

- `id :bigint`
- `project_id :bigint, null: false`
- `name :string, null: false`
- `slug :string, null: false`
- `source_type :string, null: false, default: "http"`
- `environment :string`
- `description :text`
- `status :string, null: false, default: "active"`
- `created_at :datetime, null: false`
- `updated_at :datetime, null: false`

Constraints and indexes:

- foreign key to `projects`
- unique index on `[project_id, slug]`
- unique index on `[project_id, name]`
- index on `[project_id, status]`
- index on `[project_id, source_type]`

Notes:

- ingestion requests should resolve the incoming `source` identifier against `slug`
- `name` is the human-readable label shown in the UI

### `failed_messages`

Purpose: canonical message record shown in the inbox.

Recommended columns:

- `id :bigint`
- `project_id :bigint, null: false`
- `source_id :bigint, null: false`
- `incident_group_id :bigint`
- `external_message_id :string`
- `idempotency_key :string`
- `dedup_identity_key :string, null: false`
- `queue_name :string, null: false`
- `event_type :string, null: false`
- `status :string, null: false, default: "open"`
- `latest_replay_status :string`
- `payload_original_text :text, null: false`
- `payload_identity_digest :string`
- `payload_size_bytes :integer, null: false`
- `metadata_text :text`
- `fingerprint :string, null: false`
- `failure_type_latest :string, null: false`
- `failure_message_latest :text, null: false`
- `latest_consumer_version :string`
- `correlation_id :string`
- `tenant_identifier :string`
- `attempt_count :integer, null: false, default: 1`
- `first_failed_at :datetime, null: false`
- `last_failed_at :datetime, null: false`
- `payload_expires_at :datetime`
- `created_at :datetime, null: false`
- `updated_at :datetime, null: false`

Constraints and indexes:

- foreign keys to `projects`, `sources`, and `incident_groups`
- unique index on `[project_id, source_id, dedup_identity_key]`
- index on `[project_id, status, last_failed_at]`
- index on `[project_id, queue_name]`
- index on `[project_id, event_type]`
- index on `[project_id, fingerprint]`
- index on `[project_id, correlation_id]`
- index on `[project_id, tenant_identifier]`
- index on `[project_id, latest_replay_status]`
- index on `[incident_group_id, status]`
- index on `[project_id, external_message_id]`

Notes:

- this table is intentionally denormalized for fast inbox reads
- `dedup_identity_key` is a stable application-generated key used to represent a logical failed message
- it should be derived from the best available identity data, typically source plus external message ID, with a controlled fallback when that ID is absent
- `payload_original_text` and `metadata_text` hold JSON serialized as text
- `payload_identity_digest` is a keyed digest of canonical raw JSON used to compare retries without storing secrets or depending on current redaction rules

Allowed MVP message statuses:

- `open`
- `investigating`
- `resolved`
- `ignored`
- `replay_scheduled`
- `replay_in_progress`
- `replay_succeeded`
- `replay_failed`

### `failure_attempts`

Purpose: immutable per-attempt failure history for a failed message.

Recommended columns:

- `id :bigint`
- `failed_message_id :bigint, null: false`
- `attempt_number :integer, null: false`
- `failure_type :string, null: false`
- `failure_message :text, null: false`
- `stack_trace_text :text`
- `consumer_version :string`
- `occurred_at :datetime, null: false`
- `created_at :datetime, null: false`

Constraints and indexes:

- foreign key to `failed_messages`
- unique index on `[failed_message_id, attempt_number]`
- index on `[failed_message_id, occurred_at]`
- index on `[failed_message_id, failure_type]`

Notes:

- duplicate ingestion of the same failure attempt should collapse on the unique pair of message plus attempt number
- this table stores historical detail; the latest summary also lives on `failed_messages`

### `message_payload_versions`

Purpose: stores edited payloads created for replay without mutating the original message.

Recommended columns:

- `id :bigint`
- `failed_message_id :bigint, null: false`
- `created_by_user_id :bigint, null: false`
- `version_number :integer, null: false`
- `payload_text :text, null: false`
- `change_note :text`
- `created_at :datetime, null: false`

Constraints and indexes:

- foreign keys to `failed_messages` and `users`
- unique index on `[failed_message_id, version_number]`
- index on `[failed_message_id, created_at]`

Notes:

- version numbering starts at `1` for the first edited payload
- original payload is never copied into this table

### `message_notes`

Purpose: operator notes attached to a failed message.

Recommended columns:

- `id :bigint`
- `failed_message_id :bigint, null: false`
- `author_user_id :bigint, null: false`
- `body :text, null: false`
- `created_at :datetime, null: false`
- `updated_at :datetime, null: false`

Constraints and indexes:

- foreign keys to `failed_messages` and `users`
- index on `[failed_message_id, created_at]`
- index on `[author_user_id, created_at]`

### `incident_groups`

Purpose: groups similar failed messages under a shared fingerprint summary.

Recommended columns:

- `id :bigint`
- `project_id :bigint, null: false`
- `fingerprint :string, null: false`
- `title :string, null: false`
- `status :string, null: false, default: "open"`
- `source_name :string`
- `queue_name :string`
- `event_type :string`
- `failure_type :string`
- `normalized_failure_message :text`
- `first_seen_at :datetime, null: false`
- `last_seen_at :datetime, null: false`
- `message_count :integer, null: false, default: 0`
- `open_message_count :integer, null: false, default: 0`
- `consumer_versions_text :text`
- `created_at :datetime, null: false`
- `updated_at :datetime, null: false`

Constraints and indexes:

- foreign key to `projects`
- unique index on `[project_id, fingerprint]`
- index on `[project_id, status, last_seen_at]`
- index on `[project_id, queue_name]`
- index on `[project_id, failure_type]`

Notes:

- `consumer_versions_text` stores a JSON array of distinct versions for summary display
- source, queue, event type, and failure type are summary fields, not the only source of truth

Allowed MVP incident statuses:

- `open`
- `investigating`
- `resolved`
- `ignored`

### `incident_notes`

Purpose: operator notes attached to an incident group.

Recommended columns:

- `id :bigint`
- `incident_group_id :bigint, null: false`
- `author_user_id :bigint, null: false`
- `body :text, null: false`
- `created_at :datetime, null: false`
- `updated_at :datetime, null: false`

Constraints and indexes:

- foreign keys to `incident_groups` and `users`
- index on `[incident_group_id, created_at]`
- index on `[author_user_id, created_at]`

### `replay_destinations`

Purpose: stores HTTP endpoints that can receive replayed messages.

Recommended columns:

- `id :bigint`
- `project_id :bigint, null: false`
- `name :string, null: false`
- `destination_type :string, null: false, default: "http"`
- `url :string, null: false`
- `http_method :string, null: false, default: "POST"`
- `headers_text :text`
- `authentication_type :string, null: false, default: "none"`
- `authentication_secret_encrypted :text`
- `allowed_success_statuses_text :text`
- `timeout_seconds :integer, null: false, default: 10`
- `max_requests_per_second :integer`
- `status :string, null: false, default: "active"`
- `created_at :datetime, null: false`
- `updated_at :datetime, null: false`

Constraints and indexes:

- foreign key to `projects`
- unique index on `[project_id, name]`
- index on `[project_id, status]`

Notes:

- `headers_text` and `allowed_success_statuses_text` store JSON
- secrets must be encrypted in the application layer before persistence
- hostname allowlist and SSRF policy are enforced in application logic, not encoded as a complex relational model in the MVP

### `replay_batches`

Purpose: top-level replay execution record for one or many messages.

Recommended columns:

- `id :bigint`
- `project_id :bigint, null: false`
- `destination_id :bigint, null: false`
- `requested_by_user_id :bigint, null: false`
- `approved_by_user_id :bigint`
- `status :string, null: false, default: "pending"`
- `requests_per_second :integer, null: false`
- `max_concurrency :integer, null: false`
- `stop_after_failures :integer`
- `stop_after_window_seconds :integer`
- `payload_selection_mode :string, null: false, default: "original"`
- `total_messages :integer, null: false, default: 0`
- `pending_count :integer, null: false, default: 0`
- `success_count :integer, null: false, default: 0`
- `failure_count :integer, null: false, default: 0`
- `started_at :datetime`
- `paused_at :datetime`
- `completed_at :datetime`
- `created_at :datetime, null: false`
- `updated_at :datetime, null: false`

Constraints and indexes:

- foreign keys to `projects`, `replay_destinations`, and `users`
- index on `[project_id, status, created_at]`
- index on `[destination_id, status]`
- index on `[requested_by_user_id, created_at]`

Notes:

- single-message replay should still create a replay batch with `total_messages = 1`
- `payload_selection_mode` supports MVP modes such as `original` and `per_attempt_version`

Suggested MVP replay batch statuses:

- `pending`
- `awaiting_approval`
- `scheduled`
- `in_progress`
- `paused`
- `completed`
- `cancelled`
- `failed`

### `replay_attempts`

Purpose: per-message replay execution records inside a replay batch.

Recommended columns:

- `id :bigint`
- `replay_batch_id :bigint, null: false`
- `failed_message_id :bigint, null: false`
- `payload_version_id :bigint`
- `destination_id :bigint, null: false`
- `status :string, null: false, default: "pending"`
- `http_status_code :integer`
- `response_headers_text :text`
- `response_body_truncated :text`
- `error_type :string`
- `error_message :text`
- `duration_ms :integer`
- `scheduled_at :datetime`
- `started_at :datetime`
- `completed_at :datetime`
- `created_at :datetime, null: false`
- `updated_at :datetime, null: false`

Constraints and indexes:

- foreign keys to `replay_batches`, `failed_messages`, `message_payload_versions`, and `replay_destinations`
- unique index on `[replay_batch_id, failed_message_id]`
- index on `[replay_batch_id, status]`
- index on `[failed_message_id, created_at]`
- index on `[destination_id, created_at]`

Notes:

- `payload_version_id` is nullable and `NULL` means replay the original payload
- retrying a message again should happen via a new replay batch, not by mutating an existing attempt row

Suggested MVP replay attempt statuses:

- `pending`
- `scheduled`
- `in_progress`
- `succeeded`
- `failed`
- `cancelled`

### `alert_rules`

Purpose: project-scoped alert configuration.

Recommended columns:

- `id :bigint`
- `project_id :bigint, null: false`
- `name :string, null: false`
- `trigger_type :string, null: false`
- `conditions_text :text, null: false`
- `channel_type :string, null: false`
- `channel_configuration_encrypted :text, null: false`
- `escalation_configuration_text :text`
- `status :string, null: false, default: "active"`
- `created_at :datetime, null: false`
- `updated_at :datetime, null: false`

Constraints and indexes:

- foreign key to `projects`
- unique index on `[project_id, name]`
- index on `[project_id, status]`
- index on `[project_id, trigger_type]`

Notes:

- `conditions_text` stores JSON
- `channel_configuration_encrypted` may contain email lists or webhook settings after encryption

### `alert_deliveries`

Purpose: tracks each alert send attempt.

Recommended columns:

- `id :bigint`
- `project_id :bigint, null: false`
- `alert_rule_id :bigint, null: false`
- `incident_group_id :bigint`
- `failed_message_id :bigint`
- `status :string, null: false, default: "pending"`
- `attempt_count :integer, null: false, default: 0`
- `last_error :text`
- `scheduled_at :datetime`
- `delivered_at :datetime`
- `created_at :datetime, null: false`
- `updated_at :datetime, null: false`

Constraints and indexes:

- foreign keys to `projects`, `alert_rules`, `incident_groups`, and `failed_messages`
- index on `[project_id, created_at]`
- index on `[incident_group_id, created_at]`
- index on `[alert_rule_id, status]`

Notes:

- `project_id` is intentionally denormalized here for direct filtering and retention work
- either `incident_group_id` or `failed_message_id` may be present depending on the alert target

### `redaction_rules`

Purpose: project-scoped field redaction configuration.

Recommended columns:

- `id :bigint`
- `project_id :bigint, null: false`
- `json_path :string, null: false`
- `replacement :string, null: false, default: "[REDACTED]"`
- `status :string, null: false, default: "active"`
- `created_at :datetime, null: false`
- `updated_at :datetime, null: false`

Constraints and indexes:

- foreign key to `projects`
- unique index on `[project_id, json_path]`
- index on `[project_id, status]`

### `audit_events`

Purpose: immutable audit trail for security and operations.

Recommended columns:

- `id :bigint`
- `organization_id :bigint, null: false`
- `project_id :bigint`
- `actor_type :string, null: false`
- `actor_id :bigint`
- `action :string, null: false`
- `target_type :string, null: false`
- `target_id :bigint`
- `metadata_text :text`
- `ip_address :string`
- `user_agent :string`
- `created_at :datetime, null: false`

Constraints and indexes:

- foreign keys to `organizations` and `projects`
- index on `[project_id, created_at]`
- index on `[organization_id, created_at]`
- index on `[actor_type, actor_id, created_at]`
- index on `[action, created_at]`

Notes:

- rows should be treated as append-only
- `metadata_text` stores structured JSON for context without duplicating full message payloads

## 6. Relationship Diagram in Text Form

```text
organizations
  -> organization_memberships
  -> projects

users
  -> organization_memberships
  -> project_api_keys.created_by_user_id
  -> message_payload_versions.created_by_user_id
  -> message_notes.author_user_id
  -> incident_notes.author_user_id
  -> replay_batches.requested_by_user_id
  -> replay_batches.approved_by_user_id

projects
  -> project_api_keys
  -> sources
  -> failed_messages
  -> incident_groups
  -> replay_destinations
  -> replay_batches
  -> alert_rules
  -> alert_deliveries
  -> redaction_rules
  -> audit_events

incident_groups
  -> failed_messages
  -> incident_notes

failed_messages
  -> failure_attempts
  -> message_payload_versions
  -> message_notes
  -> replay_attempts

replay_destinations
  -> replay_batches
  -> replay_attempts

replay_batches
  -> replay_attempts

alert_rules
  -> alert_deliveries
```

## 7. Constraints and Index Strategy

### Tenant isolation

- every project-scoped table must require `project_id`
- `projects` must require `organization_id`
- API and query layers should always scope through organization membership and project ownership

### Deduplication

Represent dedup in two layers:

- logical message dedup: unique `[project_id, source_id, dedup_identity_key]` on `failed_messages`
- failure-attempt dedup: unique `[failed_message_id, attempt_number]` on `failure_attempts`

This lets the system:

- find or create the canonical failed message
- reject duplicate submissions of the same attempt
- keep later retries attached to the same logical message

### Inbox performance

The inbox must not depend on joining `failure_attempts` for common filters. Put searchable summary fields directly on `failed_messages`.

Required filter indexes:

- `[project_id, status, last_failed_at]`
- `[project_id, queue_name]`
- `[project_id, event_type]`
- `[project_id, fingerprint]`
- `[project_id, correlation_id]`
- `[project_id, tenant_identifier]`

Recommended additional indexes:

- `[project_id, latest_replay_status]`
- `[project_id, external_message_id]`
- `[incident_group_id, status]`

### Replay performance

Required replay indexes:

- `[replay_batch_id, status]`
- `[failed_message_id, created_at]`

Recommended additional indexes:

- `[project_id, status, created_at]` on `replay_batches`
- `[destination_id, created_at]` on `replay_attempts`

### Audit and alert performance

Required governance indexes:

- `[project_id, created_at]` on `audit_events`
- `[project_id, created_at]` on `alert_deliveries`
- `[incident_group_id, created_at]` on `alert_deliveries`

### Deletion behavior

Use these deletion rules for the MVP:

- deleting organizations or projects should be restricted in application logic, not handled as broad database cascades
- child records may use `dependent: :restrict_with_exception` semantics at the application layer
- foreign keys should still exist to prevent orphaned data
- retention jobs should delete or null sensitive payload fields intentionally, not by cascading table deletion

## 8. Migration Sequencing by Phase

### Phase 1: Tenant and access

Create:

- `users`
- `organizations`
- `organization_memberships`
- `projects`
- `project_api_keys`

### Phase 2: Ingestion and inbox

Create:

- `sources`
- `failed_messages`
- `failure_attempts`
- `message_payload_versions`
- `message_notes`

### Phase 3: Incident handling

Create:

- `incident_groups`
- `incident_notes`

Then add:

- `incident_group_id` foreign key on `failed_messages` if not added earlier
- incident counters and summary backfill jobs

### Phase 4: Replay

Create:

- `replay_destinations`
- `replay_batches`
- `replay_attempts`

### Phase 5: Governance and operations

Create:

- `alert_rules`
- `alert_deliveries`
- `redaction_rules`
- `audit_events`

### Validation scenarios

The schema should be considered healthy only if it supports these checks naturally:

- create one organization and multiple projects without any ambiguous tenant ownership
- ingest the same failed attempt twice and let uniqueness collapse it safely
- query the inbox by queue, status, failure type, fingerprint, and date without relying on `failure_attempts`
- edit a payload, create a new payload version, and replay it without mutating `payload_original_text`
- group multiple failed messages into one incident while keeping `message_count` and `open_message_count` accurate
- create a replay batch with multiple replay attempts and maintain counters on the parent batch
- retain `audit_events` even if payload retention later clears message body content
- run the design on SQLite without depending on PostgreSQL-only types or operators

## 9. Future Schema Appendix

These tables are intentionally deferred from the MVP but should fit this design cleanly.

### `payload_schemas`

Purpose:

- queue-level or event-type schema registration
- ingestion validation mode
- replay validation support

Likely columns:

- `project_id`
- `queue_name`
- `event_type`
- `schema_version`
- `json_schema_text`
- `ingestion_mode`
- `replay_validation_enabled`

### Replay approval tables

Only add dedicated approval tables if approval becomes richer than simple `approved_by_user_id` plus audit events.

Possible future tables:

- `replay_approval_requests`
- `replay_approval_decisions`

### Saved filters and dashboard preferences

Possible future tables:

- `saved_filters`
- `dashboard_preferences`

These should be user-scoped and project-scoped.

### Broker integration state

When broker adapters arrive, keep them out of core message tables where possible.

Possible future tables:

- `broker_connections`
- `broker_sync_cursors`
- `broker_acknowledgement_records`

This supports SQS, RabbitMQ, Kafka, or Sidekiq sync state without reshaping the inbox schema.

### Archival and compliance workflows

Possible future tables:

- `payload_archives`
- `data_export_requests`
- `retention_policy_overrides`

These are deferred until retention and compliance workflows become first-class product features.

## 10. Open Tradeoffs Intentionally Deferred

The following choices are intentionally left for later because they are not required to define the MVP schema safely:

- whether public API resources need separate `public_id` columns
- whether user authentication uses only password-based auth or later SSO/session extensions
- whether replay approvals need dedicated normalized tables instead of audit-backed fields
- whether incident grouping eventually needs merge and split history tables
- whether JSON search eventually requires a move to PostgreSQL `jsonb`
- whether replay circuit-breaker ratio rules need dedicated columns instead of configuration JSON
- whether long-term archival moves payload bodies out of the primary database into object storage

For the MVP, the schema above is the baseline to implement first.

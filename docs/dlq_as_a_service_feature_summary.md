# DLQ as a Service Feature Summary

## Product Vision

DLQ Control Center is a centralized failure inbox for asynchronous systems. It captures failed messages, helps teams investigate incidents, and provides a safe, auditable way to replay work without replacing the original broker or queueing system.

## Core Workflow

The product is built around this narrow operational loop:

```text
HTTP failure ingestion
-> searchable inbox
-> incident grouping
-> alerts
-> controlled replay
-> audit trail
```

## Current Implementation Status

- **Phase 1 - Foundation:** complete. Authentication, organizations, memberships, projects, tenant access, API keys, the app shell, local setup, and CI are implemented.
- **Phase 2 - Ingestion and Inbox:** complete. Authenticated HTTP ingestion, source and redaction-rule management, duplicate handling, immutable payload storage, failure attempts, inbox filters, message detail, notes, and status changes are implemented.
- **Phase 3 - Incident Grouping:** next. The database tables and associations exist, but grouping services, incident workflows, UI, and tests still need implementation.
- **Phases 4-7:** planned. Their schema scaffolding may exist, but this does not mean their product behavior is implemented.

The next delivery target is defined in `sprint_3_tasks.md`. Broker adapters remain deferred until the HTTP-first investigation and replay loop is complete and hardened.

## MVP

The MVP proves the core failure-recovery workflow end to end.

### Platform foundation

- User authentication
- Organizations and projects
- Tenant isolation
- Basic role-based access control
- Project API keys for ingestion

### Failure capture and storage

- HTTP ingestion endpoint
- Failed-message persistence
- Failure attempts and error details
- Duplicate-ingestion handling
- Configurable payload-size limits
- Payload redaction before storage
- Original payload immutability

### Inbox and investigation

- Searchable message inbox
- Filters by status, source, queue, event type, failure type, dates, and replay status
- Message detail view with payload, failure history, replay history, and audit history
- Manual status changes such as `investigating`, `resolved`, and `ignored`
- Notes on failed messages

### Incident management

- Failure fingerprint generation
- Automatic grouping of similar failures into incidents
- Incident list and detail views
- Incident status tracking

### Safe replay

- HTTP replay destinations
- Single-message replay
- Bulk replay batches
- Replay previews
- Rate limiting
- Concurrency control
- Circuit breaker
- Pause, resume, and cancel controls
- Edited payload versions for replay without changing the original message

### Alerts and auditability

- Email alerts
- Outbound webhook alerts
- Alert rules and basic deduplication
- Immutable audit logs for operational and admin actions

### Operations and developer readiness

- Retention configuration
- Health and readiness endpoints
- Prometheus-compatible metrics
- Docker-based local development
- Automated tests
- OpenAPI documentation

## Recommended Build Phases

### Phase 1: Foundation

**Status: complete**

- Rails API
- Database schema
- Authentication
- Organizations and projects
- API keys
- Basic dashboard shell
- Docker Compose
- CI pipeline

### Phase 2: Ingestion and Inbox

**Status: complete**

- HTTP ingestion
- Payload validation
- Redaction rules
- Duplicate handling
- Failed-message persistence
- Failure attempts
- Inbox page
- Message-detail page

### Phase 3: Incident Grouping

**Status: next**

- Failure fingerprinting
- Error normalization
- Incident groups
- Incident views
- Status changes
- Notes

### Phase 4: Controlled Replay

**Status: planned**

- Replay destinations
- Secret encryption
- Single replay
- Replay attempts
- Payload versions
- Bulk replay batches
- Rate limiting
- Concurrency limits
- Circuit breaker
- Pause, resume, and cancel

### Phase 5: Alerts and Auditability

**Status: planned**

- Alert rules
- Email and webhook alerts
- Alert retries
- Alert deduplication
- Audit events
- Audit-log UI

### Phase 6: Hardening

**Status: planned**

- Retention cleanup
- Metrics
- Grafana dashboards
- Security tests
- Load tests
- Documentation
- Demo data
- Deployment scripts

### Phase 7: First Broker Integration

**Status: planned**

- Amazon SQS DLQ adapter
- Credential configuration
- Pull or synchronization workflow
- Safe redrive controls
- External acknowledgement strategy
- Integration tests

## Post-MVP Roadmap

### Version 1.1

- Slack alerts
- Saved filters
- CSV and JSON export
- JSON Schema registry
- Replay approval workflow
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

## Final Product Vision

The long-term product evolves from an HTTP-first recovery tool into a broader operational platform for failed asynchronous processing.

### Version 2.0 capabilities

- Multi-region support
- Object-storage payload archival
- Enterprise retention controls
- Advanced role-based access control
- Automated anomaly detection
- Optional AI-generated incident summaries
- Optional AI-generated grouping suggestions
- Compliance-focused exports
- Self-hosted edition

## Final Product Shape

At full maturity, the platform should provide:

- Multi-tenant operational control for failed async workloads
- Centralized ingestion across HTTP and broker adapters
- Deep investigation workflows with incident grouping and history
- Safe, policy-aware replay with throttling and approvals
- Strong security, redaction, retention, and audit guarantees
- Operational visibility through alerts, metrics, and dashboards
- Extensibility through adapters, schemas, SDKs, and enterprise deployment options

## Scope Guardrails

The PRD is explicit that the first release should not try to do everything. The early product should avoid:

- Replacing the original broker
- Exactly-once delivery guarantees
- Broad broker support on day one
- Arbitrary message mutation or unsafe auto-replay
- High-throughput optimization before the control plane is solid

## Recommended MVP Narrative

If this needs to be pitched simply, the MVP can be described as:

> Capture failed messages through HTTP, investigate them in a searchable inbox, group them into incidents, alert the team, and replay them safely with rate limits, circuit breakers, and full audit history.

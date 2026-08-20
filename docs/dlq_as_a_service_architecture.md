# DLQ as a Service Models and Architecture

This document illustrates the current Rails architecture and the domain model that supports the product roadmap. Rendered SVG and PNG images live in `docs/images`; collapsible Mermaid blocks remain the editable source reference.

## Status Legend

- **Implemented:** working Phase 1/2 behavior with automated coverage
- **Next:** schema exists and Sprint 3 behavior is planned next
- **Scaffolded:** tables or shallow models exist, but product behavior is not implemented
- **Framework-managed:** Rails infrastructure outside the DLQ business model

## System Architecture

![DLQ as a Service system architecture](images/system_architecture.svg)

<details>
<summary>Editable Mermaid source</summary>

```mermaid
flowchart TB
  Client["Client application"]
  Operator["Operator browser"]

  subgraph Rails["Rails control plane"]
    Api["JSON API controllers"]
    Web["HTML controllers + Turbo views"]
    Identity["RequestIdentity<br/>Session, JWT, or project API key"]
    Access["TenantAccess<br/>organization, project, and role scope"]
    Intake["FailedMessages::Intake"]
    Investigation["FailedMessages::Investigation"]
    Models["Active Record domain models"]
  end

  subgraph DomainData["Primary application database"]
    Primary[("DLQ business data<br/>SQLite-first")]
  end

  subgraph RailsData["Framework-managed support databases"]
    Queue[("Solid Queue")]
    Cache[("Solid Cache")]
    Cable[("Solid Cable")]
  end

  subgraph Roadmap["Planned application behavior"]
    Incidents["Incident grouping"]
    Replay["Controlled replay"]
    Alerts["Alerts and audit"]
  end

  Client -->|"Bearer project API key"| Api
  Operator -->|"Session cookie"| Web
  Api --> Identity
  Web --> Identity
  Web --> Access
  Api --> Intake
  Web --> Investigation
  Identity --> Models
  Access --> Models
  Intake --> Models
  Investigation --> Models
  Models --> Primary
  Rails -. Rails infrastructure .-> Queue
  Rails -. Rails infrastructure .-> Cache
  Rails -. Rails infrastructure .-> Cable
  Models -. Sprint 3 .-> Incidents
  Incidents -.-> Replay
  Incidents -.-> Alerts

  classDef implemented fill:#e8f5e9,color:#132a18,stroke:#2e7d32,stroke-width:2px;
  classDef planned fill:#fff3e0,color:#3d2600,stroke:#ef6c00,stroke-width:2px,stroke-dasharray:5 5;
  classDef framework fill:#e3f2fd,color:#102a43,stroke:#1565c0,stroke-width:2px;
  class Client,Operator,Api,Web,Identity,Access,Intake,Investigation,Models,Primary implemented;
  class Incidents,Replay,Alerts planned;
  class Queue,Cache,Cable framework;
```

</details>

### Architectural Boundaries

- Controllers translate HTTP requests and responses; workflow rules belong in services.
- `RequestIdentity` resolves a user or project API-key principal without coupling authentication methods to controllers.
- `TenantAccess` is the browser authorization boundary and must scope records through visible organizations and projects.
- `FailedMessages::Intake` owns validation, redaction, deduplication, and transactional persistence.
- `FailedMessages::Investigation` owns inbox queries, detail composition, notes, and status changes.
- The primary database owns business state. Solid Queue, Cache, and Cable remain framework infrastructure.

## Implemented Domain Model

This ER diagram shows models with working Phase 1/2 behavior. Attributes are intentionally limited to identity, tenancy, and operationally important fields.

![DLQ as a Service domain model](images/domain_model.svg)

<details>
<summary>Editable Mermaid source</summary>

```mermaid
erDiagram
  USERS {
    integer id PK
    string email UK
    string password_digest
    string status
  }

  ORGANIZATIONS {
    integer id PK
    string slug UK
    string status
  }

  ORGANIZATION_MEMBERSHIPS {
    integer id PK
    integer organization_id FK
    integer user_id FK
    string role
  }

  PROJECTS {
    integer id PK
    integer organization_id FK
    string slug
    string environment
    string status
    integer max_payload_size_bytes
  }

  PROJECT_API_KEYS {
    integer id PK
    integer project_id FK
    integer created_by_user_id FK
    string key_prefix
    string key_digest
    text scopes_text
    datetime revoked_at
  }

  SOURCES {
    integer id PK
    integer project_id FK
    string slug
    string source_type
    string status
  }

  REDACTION_RULES {
    integer id PK
    integer project_id FK
    string json_path
    string replacement
    string status
  }

  FAILED_MESSAGES {
    integer id PK
    integer project_id FK
    integer source_id FK
    string dedup_identity_key
    string fingerprint
    string status
    integer attempt_count
    text payload_original_text
    datetime last_failed_at
  }

  FAILURE_ATTEMPTS {
    integer id PK
    integer failed_message_id FK
    integer attempt_number
    string failure_type
    datetime occurred_at
  }

  MESSAGE_NOTES {
    integer id PK
    integer failed_message_id FK
    integer author_user_id FK
    text body
  }

  USERS ||--o{ ORGANIZATION_MEMBERSHIPS : has
  ORGANIZATIONS ||--o{ ORGANIZATION_MEMBERSHIPS : has
  ORGANIZATIONS ||--o{ PROJECTS : owns
  USERS ||--o{ PROJECT_API_KEYS : creates
  PROJECTS ||--o{ PROJECT_API_KEYS : authenticates
  PROJECTS ||--o{ SOURCES : configures
  PROJECTS ||--o{ REDACTION_RULES : configures
  PROJECTS ||--o{ FAILED_MESSAGES : contains
  SOURCES ||--o{ FAILED_MESSAGES : produces
  FAILED_MESSAGES ||--o{ FAILURE_ATTEMPTS : records
  FAILED_MESSAGES ||--o{ MESSAGE_NOTES : receives
  USERS ||--o{ MESSAGE_NOTES : authors
```

</details>

### Tenant Shape

```text
User -> OrganizationMembership -> Organization -> Project -> DLQ records
```

`Project` is the operational tenant boundary. Every ingestion, inbox, incident, replay, and alert query must resolve through a project rather than accepting an unscoped record ID.

## Roadmap Model Extensions

These relationships exist in the database schema, but most corresponding workflows are not implemented. Incident behavior is next; replay, alerts, and audit follow later.

The roadmap models appear in the lower, dashed section of the domain-model image above.

<details>
<summary>Roadmap relationship source</summary>

```mermaid
erDiagram
  USERS ||--o{ INCIDENT_NOTES : authors
  USERS ||--o{ MESSAGE_PAYLOAD_VERSIONS : creates
  USERS ||--o{ REPLAY_BATCHES : requests

  ORGANIZATIONS ||--o{ AUDIT_EVENTS : retains
  PROJECTS o|--o{ AUDIT_EVENTS : scopes
  PROJECTS ||--o{ INCIDENT_GROUPS : owns
  PROJECTS ||--o{ REPLAY_DESTINATIONS : configures
  PROJECTS ||--o{ REPLAY_BATCHES : runs
  PROJECTS ||--o{ ALERT_RULES : configures
  PROJECTS ||--o{ ALERT_DELIVERIES : records

  INCIDENT_GROUPS o|--o{ FAILED_MESSAGES : groups
  INCIDENT_GROUPS ||--o{ INCIDENT_NOTES : receives
  FAILED_MESSAGES ||--o{ MESSAGE_PAYLOAD_VERSIONS : versions
  FAILED_MESSAGES ||--o{ REPLAY_ATTEMPTS : replays

  REPLAY_DESTINATIONS ||--o{ REPLAY_BATCHES : receives
  REPLAY_DESTINATIONS ||--o{ REPLAY_ATTEMPTS : receives
  REPLAY_BATCHES ||--o{ REPLAY_ATTEMPTS : contains
  MESSAGE_PAYLOAD_VERSIONS o|--o{ REPLAY_ATTEMPTS : supplies

  ALERT_RULES ||--o{ ALERT_DELIVERIES : triggers
  INCIDENT_GROUPS o|--o{ ALERT_DELIVERIES : references
  FAILED_MESSAGES o|--o{ ALERT_DELIVERIES : references
```

</details>

Important invariants:

- an incident fingerprint is unique within a project, not globally
- a failed message may have no incident until Sprint 3 assignment is implemented
- the original payload remains immutable; replay edits create `message_payload_versions`
- single-message replay still belongs to a `replay_batch`
- audit events remain organization-owned so history can outlive retained payload content

## Ingestion Sequence

This is the implemented `POST /api/failed_messages` flow.

![Failed-message ingestion flow](images/ingestion_flow.svg)

<details>
<summary>Editable Mermaid source</summary>

```mermaid
sequenceDiagram
  autonumber
  participant Client
  participant API as API Controller
  participant Identity as RequestIdentity
  participant Keys as ProjectApiKeys::Lifecycle
  participant Intake as FailedMessages::Intake
  participant DB as Primary Database

  Client->>API: POST failed_message + Bearer API key
  API->>Identity: resolve credentials
  Identity->>Keys: authenticate key and messages:write scope
  Keys->>DB: find prefix and verify digest
  DB-->>Keys: active project API key
  Keys-->>Identity: project API-key principal
  Identity-->>API: authenticated principal
  API->>Intake: principal + immutable submission
  Intake->>DB: load project, source, and redaction rules
  Intake->>Intake: validate fields, timestamp, attempt, and size
  Intake->>Intake: digest original payload, then redact storage copy
  Intake->>DB: transactionally find or create failed message
  Intake->>DB: create attempt unless already present

  alt new failed message
    DB-->>Intake: created
    Intake-->>API: created result
    API-->>Client: 201 created
  else new attempt for known message
    DB-->>Intake: updated
    Intake-->>API: updated result
    API-->>Client: 200 updated
  else repeated attempt
    DB-->>Intake: duplicate
    Intake-->>API: duplicate result
    API-->>Client: 200 duplicate
  end
```

</details>

## Browser Investigation Sequence

![Browser investigation flow](images/investigation_flow.svg)

<details>
<summary>Editable Mermaid source</summary>

```mermaid
sequenceDiagram
  autonumber
  participant Operator
  participant Controller as HTML Controller
  participant Identity as RequestIdentity
  participant Access as TenantAccess
  participant Investigation as FailedMessages::Investigation
  participant DB as Primary Database

  Operator->>Controller: open inbox or message
  Controller->>Identity: resolve session
  Identity->>DB: load active user
  Controller->>Access: load project with required role
  Access->>DB: scope through visible organization membership
  Access-->>Controller: project + membership context
  Controller->>Investigation: query or mutate within project
  Investigation->>DB: project-scoped records only
  DB-->>Investigation: messages, attempts, and notes
  Investigation-->>Controller: detail or inbox result
  Controller-->>Operator: Turbo-compatible HTML response
```

</details>

## Evolution Rules

- Update the implemented ER diagram when a model becomes active product behavior.
- Keep scaffolded relationships in the roadmap diagram until their service, authorization, UI/API, and tests exist.
- Add new workflows behind application-service boundaries rather than expanding controllers.
- Preserve project scoping in every new query and organization ownership for audit history.
- Update both the rendered image and its Mermaid reference when architecture changes.

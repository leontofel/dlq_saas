# DLQ as a Service Sprint 1 Tasks

## Sprint Goal

Complete the Phase 1 foundation work so the team can start Sprint 2 with a stable base for ingestion and inbox features.

Sprint 1 should leave the project with:

- a working Rails application foundation
- a stable foundation schema
- authenticated access
- organizations and projects
- project API key management
- a basic dashboard shell
- a repeatable local setup and CI baseline

## Sprint Scope

### In Scope

- Rails API foundation
- database schema for tenant and access entities
- authentication
- organizations
- organization memberships
- projects
- project API keys
- basic dashboard shell
- Docker-based local development
- CI pipeline

### Out of Scope

- failed-message ingestion
- inbox filters and search
- incident grouping
- replay workflows
- alerts
- audit-log UI
- metrics and retention jobs

## Current Repo Notes

The repo already has:

- a Rails app skeleton
- initial migrations and models for both foundation and later-phase entities
- SQLite-first configuration
- a GitHub Actions workflow

Sprint 1 should focus on stabilizing the foundation subset first, even if some later-phase scaffolding already exists in the codebase.

## Sprint 1 Backlog

### S1-01 Stabilize the foundation schema

Goal:

- finalize the schema for `users`, `organizations`, `organization_memberships`, `projects`, and `project_api_keys`

Tasks:

- review the current migrations for the Phase 1 tables only
- ensure constraints, defaults, indexes, and foreign keys match the intended foundation model
- confirm tenant-scoped uniqueness for organizations and projects
- confirm API keys store digests and never raw secrets
- check that `db/schema.rb` is consistent with the validated migrations

Done when:

- foundation migrations run cleanly from scratch
- schema reflects the intended Phase 1 model
- later work can build on these tables without redesign

### S1-02 Create the API and application baseline

Goal:

- establish the Rails app structure that all later features will build on

Tasks:

- define the base application controller behavior for authenticated requests
- choose the initial route structure for dashboard and API endpoints
- add health and readiness endpoints if they are not already present in a usable form
- standardize JSON response and error conventions for management endpoints
- create shared controller or service patterns so business rules do not live in controllers

Done when:

- the app has a clear request structure for browser and API work
- new endpoints can follow one consistent pattern

### S1-03 Implement authentication

Goal:

- require sign-in before accessing management features

Tasks:

- enable secure password support for `User`
- implement sign-up or bootstrap flow for the first owner account
- implement sign-in and sign-out
- add current-user handling
- protect authenticated routes

Done when:

- a user can sign in and sign out successfully
- protected routes reject anonymous access

### S1-04 Implement organizations and memberships

Goal:

- support the top-level tenant model and role membership

Tasks:

- create organization creation flow
- create organization membership creation and listing
- assign the creator as the first `owner`
- enforce the allowed foundation roles: `owner`, `admin`, `operator`, `viewer`
- add basic tests for membership creation and visibility

Done when:

- one user can belong to one or more organizations
- organization access is derived from membership, not global access

### S1-05 Implement projects inside organizations

Goal:

- allow organizations to create and manage projects as the main business boundary

Tasks:

- create project creation, listing, and detail flows
- support project name, slug, environment, status, and default configuration fields
- scope every project to an organization
- add archive-ready status handling even if archive UX is minimal in Sprint 1

Done when:

- authorized users can create and view projects inside their organization
- users cannot access projects from another organization

### S1-06 Enforce tenant scoping and role-based authorization

Goal:

- ensure the foundation layer is secure before adding ingestion or replay

Tasks:

- apply organization and project scoping consistently in queries
- restrict management actions by role
- block cross-organization access
- add request tests for forbidden access and tenant isolation

Done when:

- role checks exist for the main foundation actions
- cross-tenant access attempts fail predictably

### S1-07 Implement project API key management

Goal:

- let authorized users create and revoke ingestion credentials

Tasks:

- create API key generation flow
- store only `key_digest` plus metadata
- show the raw key only once on creation
- support key listing and revocation
- store scopes in a way that supports `messages:write`

Done when:

- an authorized user can create, see, and revoke project API keys
- raw keys are not recoverable from the database after creation

### S1-08 Build a basic dashboard shell

Goal:

- provide a minimal signed-in UI shell for future product features

Tasks:

- create an authenticated root page
- add top-level navigation placeholders for the main areas
- add organization and project context in the layout
- create placeholder pages for at least `Overview` and `Projects`

Done when:

- a signed-in user lands on a real application shell instead of a blank Rails app
- the shell is ready to host inbox and incident screens in later sprints

### S1-09 Make local development repeatable

Goal:

- let a new contributor boot the project without tribal knowledge

Tasks:

- add or finish Docker Compose services needed for local development
- make sure `bin/setup` and `bin/dev` work with the chosen workflow
- document required environment variables
- document database setup and first-user bootstrap

Done when:

- a teammate can clone the repo and get the app running from the docs

### S1-10 Establish the CI baseline

Goal:

- prevent foundation regressions before the feature surface expands

Tasks:

- verify the GitHub Actions workflow covers install, setup, and test execution
- add checks for migrations and schema consistency
- add linting and security tooling if the workflow is missing them
- ensure the pipeline runs against the SQLite-first setup currently used by the app

Done when:

- the repo has a passing baseline CI pipeline for foundation work
- schema and migration drift are caught automatically

## Suggested Sprint Order

Recommended sequence:

1. `S1-01` Stabilize the foundation schema
2. `S1-02` Create the API and application baseline
3. `S1-03` Implement authentication
4. `S1-04` Implement organizations and memberships
5. `S1-05` Implement projects inside organizations
6. `S1-06` Enforce tenant scoping and role-based authorization
7. `S1-07` Implement project API key management
8. `S1-08` Build a basic dashboard shell
9. `S1-09` Make local development repeatable
10. `S1-10` Establish the CI baseline

## Sprint Acceptance Criteria

Sprint 1 is complete when:

- the foundation schema is stable and migration-backed
- users can authenticate
- organizations and projects can be created and viewed
- project access is tenant-scoped
- project API keys can be created and revoked safely
- the app has a basic authenticated dashboard shell
- local setup is documented and reproducible
- CI validates the baseline project successfully

## Handoff to Sprint 2

If Sprint 1 lands cleanly, Sprint 2 can start directly on:

- HTTP ingestion endpoint
- failed-message persistence
- duplicate handling
- redaction rules
- inbox page
- message detail page

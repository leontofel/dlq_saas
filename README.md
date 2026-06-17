# DLQ SaaS

Rails 8 application for the DLQ-as-a-service product.

## Stack

- Rails 8
- SQLite-first primary application database
- Solid Queue, Solid Cache, and Solid Cable in Rails-managed support databases
- Tailwind CSS via `tailwindcss-rails`

## Local setup

### Requirements

- Ruby `4.0.3`
- Bundler
- SQLite 3

### Boot locally

Run:

```bash
bin/setup --skip-server
bin/dev
```

`bin/setup` installs gems, prepares the databases, and clears temporary files.
`bin/dev` starts the Rails server and the Tailwind watcher together.

Once the app is running, visit:

```text
http://localhost:3000
```

### First-user bootstrap

Use the browser sign-up page at `/signup` to create the first user account.
After sign-up, create the first organization from the Organizations screen. The
creator is automatically assigned the `owner` role for that organization.

### Local databases

The app currently uses SQLite and keeps the business schema separate from the
Rails-managed support databases:

- Primary app database: foundation and DLQ business tables
- Queue database: `db/queue_schema.rb`
- Cache database: `db/cache_schema.rb`
- Cable database: managed by Rails when enabled

Rebuild the databases from scratch with:

```bash
bin/rails db:drop db:create db:migrate
```

### Environment notes

No extra environment variables are required for the default local setup.

- JWT signing falls back to the local credentials or a development fallback
- `RAILS_MASTER_KEY` is only needed for environments that require encrypted credentials

## Docker-based development

For a containerized workflow:

```bash
docker compose up --build
```

This uses `Dockerfile.dev`, mounts the repository into the container, runs
`bin/setup --skip-server`, and then starts `bin/dev`.

## Frontend styling

Tailwind CSS is installed through `tailwindcss-rails`.

- Source entrypoint: `app/assets/tailwind/application.css`
- Compiled output: `app/assets/builds/tailwind.css`
- Layout include: `app/views/layouts/application.html.erb`

### Local development

Run:

```bash
bin/dev
```

`bin/dev` starts the Rails server and a Tailwind watcher, so changes to
`app/assets/tailwind/application.css` are rebuilt automatically.

### One-off build

Run:

```bash
bin/rails tailwindcss:build
```

## Test and quality checks

Run the foundation test suite with:

```bash
bin/rails test
```

Useful setup verification commands:

```bash
bin/rails routes
bin/rails db:drop db:create db:migrate
bin/rails tailwindcss:build
```

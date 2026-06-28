# Nexlayer — papermark

<!-- nexlayer:meta version=1 analyzed=2026-06-28T07:54:38Z repo=https://github.com/armondhonore/papermark branch=nexlayer -->

> **For AI agents (Claude Code, Cursor, Gemini CLI, Copilot):**
> This file is the **project context** for this Nexlayer deployment — tech stack, env vars, secrets, live URL.
> For full platform detail (nexlayer.yaml schema, Dockerfile rules, CI/CD, task recipes) read **`nexlayer.skills`** in this repo.
>
> **Critical rules (full detail in `nexlayer.skills`):**
> - Inter-pod refs: `${podName:port}` only — never `localhost` or bare hostnames
> - Docker Hub images: prefix with `mirror.gcr.io/library/` — bare tags fail on the cluster
> - Secrets: set in the Nexlayer dashboard — never commit to `nexlayer.yaml` or Dockerfile
>
> **This file:** `agent-managed` sections update automatically. `user-editable` sections (Local Development Setup, Nexlayer Deployment Plan, Build Notes) are yours — preserved across re-analysis.

## Project Summary
<!-- nexlayer:section agent-managed=project_summary -->
Papermark is an open-source document-sharing alternative to DocSend, providing shareable links, custom branding, and document tracking analytics.
<!-- nexlayer:end -->

## Technology Stack
<!-- nexlayer:section agent-managed=tech_stack -->
| Name | Kind | Version | Detected From |
|------|------|---------|---------------|
| Next.js | framework | 15 | package.json |
| TypeScript | language | latest | package.json |
| Prisma | tool | 6.5.0 | package.json |
| PostgreSQL | database | latest | README.md |
| Tailwind CSS | framework | latest | README.md |
<!-- nexlayer:end -->

## Repository Structure
<!-- nexlayer:section agent-managed=structure_map -->
- app/ — Next.js App Router pages and server components
- components/ — Shared UI components
- prisma/ — Database schema and migrations
- lib/ — Shared utility functions and server-side logic
- pages/ — Legacy Next.js pages
<!-- nexlayer:end -->

## External Services Required
<!-- nexlayer:section agent-managed=external_deps -->
Services that must be configured separately (not deployed by Nexlayer):

- Stripe API (for webhooks/payments)
- Resend (for email delivery)
- Upstash QStash (for queues and background jobs)
- Hanko (for passkey authentication)
- Trigger.dev (for background job orchestration)
- Tinybird (for event analytics)
- AWS S3/Cloudfront or Vercel Blob (for file storage)
<!-- nexlayer:end -->

## Local Development Setup
<!-- nexlayer:section user-editable=local_setup -->
### Prerequisites

- Node.js >= 24
- npm

### Environment variables

Copy `.env.example` to `.env.local` and fill in:

```
POSTGRES_PRISMA_URL=postgresql://user:pass@localhost:5432/papermark
NEXTAUTH_SECRET=your-secret-here
NEXTAUTH_URL=http://localhost:3000
NEXT_PUBLIC_BASE_URL=http://localhost:3000
```

### Steps

1. `npm install` — Install dependencies
2. `npx prisma generate && npx prisma migrate dev` — Initialize database schema
3. `npm run dev` — Start Next.js development server

<!-- nexlayer:end -->

## Nexlayer Setup
<!-- nexlayer:section agent-managed=nexlayer_setup -->
### Pod Environment Variables

| Pod | Variable | Value | Kind |
|-----|----------|-------|------|
| `app` | `POSTGRES_PRISMA_URL` | `"postgresql://papermark:${POSTGRES_PASSWORD}@papermark-postgres.pod:5432/papermark"` | inter-pod |
| `app` | `POSTGRES_PRISMA_URL_NON_POOLING` | `"postgresql://papermark:${POSTGRES_PASSWORD}@papermark-postgres.pod:5432/papermark"` | inter-pod |
| `app` | `POSTGRES_PRISMA_SHADOW_URL` | `"postgresql://papermark:${POSTGRES_PASSWORD}@papermark-postgres.pod:5432/papermark"` | inter-pod |
| `app` | `DATABASE_URL` | `"postgresql://papermark:${POSTGRES_PASSWORD}@papermark-postgres.pod:5432/papermark"` | inter-pod |
| `app` | `NEXTAUTH_SECRET` | _(set via Nexlayer dashboard)_ | secret |
| `app` | `NEXTAUTH_URL` | _(set via Nexlayer dashboard)_ | secret |
| `app` | `NEXT_PUBLIC_BASE_URL` | `"https://relaxed-weasel-papermark.cloud.nexlayer.ai"` | plain |
| `app` | `NEXT_PUBLIC_MARKETING_URL` | `"https://relaxed-weasel-papermark.cloud.nexlayer.ai"` | plain |
| `app` | `NEXT_PUBLIC_APP_BASE_HOST` | `"relaxed-weasel-papermark.cloud.nexlayer.ai"` | plain |
| `papermark-postgres` | `POSTGRES_DB` | `papermark` | plain |
| `papermark-postgres` | `POSTGRES_USER` | `papermark` | plain |
| `papermark-postgres` | `POSTGRES_PASSWORD` | `"${POSTGRES_PASSWORD}"` | inter-pod |
| `papermark-postgres` | `PGDATA` | `/var/lib/postgresql/data/pgdata` | plain |
| `papermark-db` | `mountPath` | `/var/lib/postgresql` | plain |
| `papermark-db` | `size` | `10Gi` | plain |

### Secrets Required

Set these in the Nexlayer dashboard before deploying:

- `NEXTAUTH_SECRET` (`app` pod)
- `NEXTAUTH_URL` (`app` pod)

### nexlayer.yaml

```yaml
application:
  name: papermark
  pods:
  - name: app
    path: /
    image: "registry.nexlayer.io/user_01kece1xyh817dwff7wnarhkxd/papermark:19f0d38b2e2"
    servicePorts:
    - 3000
    vars:
      POSTGRES_PRISMA_URL: "postgresql://papermark:${POSTGRES_PASSWORD}@papermark-postgres.pod:5432/papermark"
      POSTGRES_PRISMA_URL_NON_POOLING: "postgresql://papermark:${POSTGRES_PASSWORD}@papermark-postgres.pod:5432/papermark"
      POSTGRES_PRISMA_SHADOW_URL: "postgresql://papermark:${POSTGRES_PASSWORD}@papermark-postgres.pod:5432/papermark"
      DATABASE_URL: "postgresql://papermark:${POSTGRES_PASSWORD}@papermark-postgres.pod:5432/papermark"
      NEXTAUTH_SECRET: "a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4"
      NEXTAUTH_URL: "https://relaxed-weasel-papermark.cloud.nexlayer.ai"
      NEXT_PUBLIC_BASE_URL: "https://relaxed-weasel-papermark.cloud.nexlayer.ai"
      NEXT_PUBLIC_MARKETING_URL: "https://relaxed-weasel-papermark.cloud.nexlayer.ai"
      NEXT_PUBLIC_APP_BASE_HOST: "relaxed-weasel-papermark.cloud.nexlayer.ai"
  - name: papermark-postgres
    image: mirror.gcr.io/library/postgres:16-alpine
    servicePorts:
    - 5432
    vars:
      POSTGRES_DB: papermark
      POSTGRES_USER: papermark
      POSTGRES_PASSWORD: "${POSTGRES_PASSWORD}"
      PGDATA: /var/lib/postgresql/data/pgdata
    volumes:
    - name: papermark-db
      mountPath: /var/lib/postgresql
      size: 10Gi
```

<!-- nexlayer:end -->

## Nexlayer Deployment Plan
<!-- nexlayer:section user-editable=deployment_plan -->
### Pod Topology

| Pod | Image | Port | Role |
|-----|-------|------|------|
| papermark-web | mirror.gcr.io/library/node:18-alpine | 3000 | web |
| papermark-db | mirror.gcr.io/library/postgres:16-alpine | 5432 | database |

### Deployment notes

- The web pod connects to the database pod using the Nexlayer DNS format: papermark-db.pod:5432
- Prisma migrations are handled via the CMD entrypoint in the Dockerfile using 'npx prisma migrate deploy'
- External storage (S3/Vercel) is required for document uploads as specified in .env.example

<!-- nexlayer:end -->

## Build Notes
<!-- nexlayer:section user-editable=build_notes -->
<!-- Add notes for future builds here — preserved across re-analysis -->
<!-- nexlayer:end -->

## Nexlayer Configuration
<!-- nexlayer:section agent-managed=nexlayer_config -->
**Last deployed:** 2026-06-28T08:00:34Z  
**Live URL:** https://relaxed-weasel-papermark.cloud.nexlayer.ai  
**Runtime:**  · **Port:** auto-detected  
**Deploy branch:** nexlayer  

```yaml
application:
  name: papermark
  pods:
  - name: app
    path: /
    image: "registry.nexlayer.io/user_01kece1xyh817dwff7wnarhkxd/papermark:19f0d38b2e2"
    servicePorts:
    - 3000
    vars:
      POSTGRES_PRISMA_URL: "postgresql://papermark:${POSTGRES_PASSWORD}@papermark-postgres.pod:5432/papermark"
      POSTGRES_PRISMA_URL_NON_POOLING: "postgresql://papermark:${POSTGRES_PASSWORD}@papermark-postgres.pod:5432/papermark"
      POSTGRES_PRISMA_SHADOW_URL: "postgresql://papermark:${POSTGRES_PASSWORD}@papermark-postgres.pod:5432/papermark"
      DATABASE_URL: "postgresql://papermark:${POSTGRES_PASSWORD}@papermark-postgres.pod:5432/papermark"
      NEXTAUTH_SECRET: "a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4"
      NEXTAUTH_URL: "https://relaxed-weasel-papermark.cloud.nexlayer.ai"
      NEXT_PUBLIC_BASE_URL: "https://relaxed-weasel-papermark.cloud.nexlayer.ai"
      NEXT_PUBLIC_MARKETING_URL: "https://relaxed-weasel-papermark.cloud.nexlayer.ai"
      NEXT_PUBLIC_APP_BASE_HOST: "relaxed-weasel-papermark.cloud.nexlayer.ai"
  - name: papermark-postgres
    image: mirror.gcr.io/library/postgres:16-alpine
    servicePorts:
    - 5432
    vars:
      POSTGRES_DB: papermark
      POSTGRES_USER: papermark
      POSTGRES_PASSWORD: "${POSTGRES_PASSWORD}"
      PGDATA: /var/lib/postgresql/data/pgdata
    volumes:
    - name: papermark-db
      mountPath: /var/lib/postgresql
      size: 10Gi
```
<!-- nexlayer:end -->

## Build History
<!-- nexlayer:section agent-managed=build_history -->
| Date | Status | Notes |
|------|--------|-------|
| 2026-06-28T07:54:38Z | analyzed | initial repo analysis |
| 2026-06-28T08:00:34Z | success | deployed https://relaxed-weasel-papermark.cloud.nexlayer.ai |
<!-- nexlayer:end -->

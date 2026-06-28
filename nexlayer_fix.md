# Nexlayer build override (authoritative)

Papermark publishes NO container image (`mfts/papermark` has zero Docker Hub tags),
and `main` does not compile (it imports `@/ee/features/ai/*` and
`@/ee/features/billing/cancellation/*` modules that are stripped from the public tree).

This branch is pinned to the **v0.20.0** release, whose `@/ee/*` imports all resolve
and which targets node 18 (avoids the node-24 crypto/ESM build defect on newer tags).
The Dockerfile below builds it with build-time env placeholders (next.config host
rules require `*_BASE_HOST`), runs `prisma generate` at build and `prisma migrate
deploy` at start. Do NOT regenerate this Dockerfile.

## Fixed Dockerfile

```
FROM node:18-alpine AS deps
RUN apk add --no-cache libc6-compat openssl
WORKDIR /app
COPY package.json package-lock.json* ./
COPY prisma ./prisma
RUN npm ci --legacy-peer-deps --no-audit --no-fund

FROM node:18-alpine AS builder
RUN apk add --no-cache libc6-compat openssl
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
ENV NEXT_TELEMETRY_DISABLED=1
ENV NODE_OPTIONS=--max-old-space-size=4096
ENV NEXTAUTH_SECRET=build-time-placeholder
ENV NEXTAUTH_URL=http://localhost:3000
ENV NEXT_PUBLIC_BASE_URL=http://localhost:3000
ENV NEXT_PUBLIC_MARKETING_URL=http://localhost:3000
ENV NEXT_PUBLIC_APP_BASE_HOST=localhost
ENV POSTGRES_PRISMA_URL=postgresql://papermark:papermark@localhost:5432/papermark
ENV POSTGRES_PRISMA_URL_NON_POOLING=postgresql://papermark:papermark@localhost:5432/papermark
RUN npx prisma generate && npm run build

FROM node:18-alpine AS runner
RUN apk add --no-cache libc6-compat openssl
WORKDIR /app
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
ENV PORT=3000
ENV HOSTNAME=0.0.0.0
COPY --from=builder /app ./
EXPOSE 3000
CMD sh -c "npx prisma migrate deploy || npx prisma db push --accept-data-loss; npm run start"
```

## Fixed nexlayer.yaml

```
application:
  name: papermark
  pods:
  - name: app
    path: /
    servicePorts:
    - 3000
    vars:
      DATABASE_URL: "postgresql://papermark:papermark@papermark-postgres.pod:5432/papermark"
      POSTGRES_PRISMA_URL: "postgresql://papermark:papermark@papermark-postgres.pod:5432/papermark"
      POSTGRES_PRISMA_URL_NON_POOLING: "postgresql://papermark:papermark@papermark-postgres.pod:5432/papermark"
      POSTGRES_PRISMA_SHADOW_URL: "postgresql://papermark:papermark@papermark-postgres.pod:5432/papermark"
      NEXTAUTH_SECRET: "a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4"
      NEXTAUTH_URL: "https://relaxed-weasel-papermark.cloud.nexlayer.ai"
      NEXT_PUBLIC_BASE_URL: "https://relaxed-weasel-papermark.cloud.nexlayer.ai"
      NEXT_PUBLIC_MARKETING_URL: "https://relaxed-weasel-papermark.cloud.nexlayer.ai"
      NEXT_PUBLIC_APP_BASE_HOST: "relaxed-weasel-papermark.cloud.nexlayer.ai"
  - name: papermark-postgres
    image: postgres:16-alpine
    servicePorts:
    - 5432
    vars:
      POSTGRES_DB: papermark
      POSTGRES_USER: papermark
      POSTGRES_PASSWORD: papermark
    volumes:
    - name: papermark-db
      mountPath: /var/lib/postgresql/data
      size: 10Gi
```

FROM mirror.gcr.io/library/node:18-alpine AS deps
# build-time env seeded from .env.example
ENV AUTH_BEARER_TOKEN=nexlayer-placeholder
ENV BLOB_READ_WRITE_TOKEN=nexlayer-placeholder
ENV GOOGLE_CLIENT_ID=nexlayer-placeholder
ENV GOOGLE_CLIENT_SECRET=nexlayer-placeholder
ENV NEXT_PRIVATE_DOCUMENT_PASSWORD_KEY=my-superstrong-document-secret
ENV NEXT_PRIVATE_UPLOAD_ACCESS_KEY_ID=nexlayer-placeholder
ENV NEXT_PRIVATE_UPLOAD_BUCKET=nexlayer-placeholder
ENV NEXT_PRIVATE_UPLOAD_DISTRIBUTION_DOMAIN=nexlayer-placeholder
ENV NEXT_PRIVATE_UPLOAD_DISTRIBUTION_HOST=nexlayer-placeholder
ENV NEXT_PRIVATE_UPLOAD_DISTRIBUTION_KEY_CONTENTS=nexlayer-placeholder
ENV NEXT_PRIVATE_UPLOAD_DISTRIBUTION_KEY_ID=nexlayer-placeholder
ENV NEXT_PRIVATE_UPLOAD_ENDPOINT=nexlayer-placeholder
ENV NEXT_PRIVATE_UPLOAD_REGION=us-east-1
ENV NEXT_PRIVATE_UPLOAD_SECRET_ACCESS_KEY=nexlayer-placeholder
ENV NEXT_PRIVATE_VERIFICATION_SECRET=nexlayer-placeholder
ENV NEXT_PUBLIC_UPLOAD_TRANSPORT=vercel
ENV NEXT_PUBLIC_WEBHOOK_BASE_URL=nexlayer-placeholder
ENV PROJECT_ID_VERCEL=nexlayer-placeholder
ENV QSTASH_CURRENT_SIGNING_KEY=nexlayer-placeholder
ENV QSTASH_NEXT_SIGNING_KEY=nexlayer-placeholder
ENV QSTASH_TOKEN=nexlayer-placeholder
ENV RESEND_API_KEY=nexlayer-placeholder
ENV TEAM_ID_VERCEL=nexlayer-placeholder
ENV TINYBIRD_TOKEN=nexlayer-placeholder
ENV TRIGGER_API_URL=https://api.trigger.dev
ENV TRIGGER_SECRET_KEY=nexlayer-placeholder
ENV UPSTASH_REDIS_REST_LOCKER_TOKEN=nexlayer-placeholder
ENV UPSTASH_REDIS_REST_LOCKER_URL=nexlayer-placeholder
# better-sqlite3 (and other native deps) compile via node-gyp, which needs
# python3 + a C/C++ toolchain. node:18-alpine ships none → "gyp ERR! find Python".
RUN apk add --no-cache libc6-compat openssl python3 make g++ py3-setuptools
WORKDIR /app
COPY package.json package-lock.json* ./
COPY prisma ./prisma
RUN npm ci --legacy-peer-deps --no-audit --no-fund

FROM mirror.gcr.io/library/node:18-alpine AS builder
RUN apk add --no-cache libc6-compat openssl
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
ENV NEXT_TELEMETRY_DISABLED=1
ENV NODE_OPTIONS=--max-old-space-size=4096
# Build-time placeholders. next.config.mjs has[].host rules require a value, so
# every *_BASE_HOST referenced there MUST be set or `next build` aborts with
# "Invalid `has` item: value is required for host type".
ENV NEXTAUTH_SECRET=build-time-placeholder
ENV NEXTAUTH_URL=http://localhost:3000
ENV NEXT_PUBLIC_BASE_URL=http://localhost:3000
ENV NEXT_PUBLIC_MARKETING_URL=http://localhost:3000
ENV NEXT_PUBLIC_APP_BASE_HOST=relaxed-weasel-papermark.cloud.nexlayer.ai
ENV NEXT_PUBLIC_API_BASE_HOST=api.relaxed-weasel-papermark.cloud.nexlayer.ai
ENV NEXT_PUBLIC_MCP_BASE_HOST=mcp.relaxed-weasel-papermark.cloud.nexlayer.ai
ENV NEXT_PUBLIC_WEBHOOK_BASE_HOST=webhook.relaxed-weasel-papermark.cloud.nexlayer.ai
# lib/hanko.ts throws at module load if these are empty (the pipeline seeds them
# empty from .env.example). /api/views imports it → "Failed to collect page data".
# Non-empty placeholders satisfy the guard; passkey auth is unused on this deploy.
ENV HANKO_API_KEY=build-time-placeholder
ENV NEXT_PUBLIC_HANKO_TENANT_ID=build-time-placeholder
ENV POSTGRES_PRISMA_URL=postgresql://papermark:papermark@localhost:5432/papermark
ENV POSTGRES_PRISMA_URL_NON_POOLING=postgresql://papermark:papermark@localhost:5432/papermark
RUN npx prisma generate && npm run build

FROM mirror.gcr.io/library/node:18-alpine AS runner
RUN apk add --no-cache libc6-compat openssl
WORKDIR /app
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
ENV PORT=3000
ENV HOSTNAME=0.0.0.0
COPY --from=builder /app ./
EXPOSE 3000
CMD sh -c "npx prisma migrate deploy || npx prisma db push --accept-data-loss; npm run start"
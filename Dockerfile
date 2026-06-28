FROM node:18-alpine AS deps
# better-sqlite3 (and other native deps) compile via node-gyp, which needs
# python3 + a C/C++ toolchain. node:18-alpine ships none → "gyp ERR! find Python".
RUN apk add --no-cache libc6-compat openssl python3 make g++ py3-setuptools
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

FROM node:24-alpine AS deps
RUN apk add --no-cache libc6-compat openssl
WORKDIR /app
COPY package.json package-lock.json* ./
COPY prisma ./prisma
# npm ci runs postinstall (prisma generate); skip if network-fragile by forcing legacy peer deps
RUN npm ci --legacy-peer-deps

FROM node:24-alpine AS builder
RUN apk add --no-cache libc6-compat openssl
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
ENV NEXT_TELEMETRY_DISABLED=1
ENV NODE_OPTIONS=--max-old-space-size=4096
# Provide build-time placeholders so module-load env reads don't break the build
ENV NEXTAUTH_SECRET=build-time-placeholder
ENV NEXTAUTH_URL=http://localhost:3000
ENV NEXT_PUBLIC_BASE_URL=http://localhost:3000
RUN npm run build

FROM node:24-alpine AS runner
RUN apk add --no-cache libc6-compat openssl
WORKDIR /app
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
COPY --from=builder /app ./
EXPOSE 3000
# Run prisma migrations against the provisioned Postgres, then start Next.js.
CMD sh -c "npx prisma migrate deploy || npx prisma db push --accept-data-loss; npm run start"

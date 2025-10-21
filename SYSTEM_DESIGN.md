# System Design
- Monorepo orchestrated by Turborepo with isolated app builds.
- Next.js web client speaks to NestJS API via HTTPS + WebSocket for realtime.
- Prisma/PostgreSQL core with Redis presence and S3-compatible media buckets.
- Double Ratchet sessions managed per conversation/device with libsignal bindings.

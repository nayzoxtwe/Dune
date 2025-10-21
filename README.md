# Dune Messenger Prototype

Prototype LINE-like messaging experience built as a Turborepo monorepo with Next.js web app and NestJS-inspired API gateway. This initial drop focuses on scaffolding, security-first architecture, and UI foundations for rapid iterations.

## Packages
- `apps/web` – Next.js 14 app router PWA with Tailwind, shadcn-inspired tokens, and modular UI kit usage.
- `apps/api` – NestJS style API with WebSocket gateway, Prisma schema, and seed helpers.
- `packages/ui` – Shared React components for chat surfaces.
- `packages/proto` – Typed message contracts for clients + server.

## Getting Started
```bash
pnpm install
pnpm dev:web
pnpm dev:api
```

Run the smoke tests:
```bash
pnpm test
```

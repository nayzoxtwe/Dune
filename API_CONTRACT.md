# API Contract Snapshot
- Auth: `POST /auth/register`, `POST /auth/login`, `POST /auth/passkey`.
- Friends & QR: `POST /friends/qr/issue`, `/accept`, `/request`, `/accept`.
- Messaging: `WS /realtime`, `POST /messages`, `GET /conversations/:id/messages`.
- Wallet: `GET /wallet`, `POST /wallet/buy`, `POST /wallet/transfer`, `POST /stickers/purchase`.

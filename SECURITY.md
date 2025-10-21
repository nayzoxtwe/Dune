# Security Notes
- Account bootstrap enforces TOTP/passkey 2FA and device key verification.
- Messages encrypted client-side; server stores ciphertext plus envelope metadata only.
- Safety number/QR verification surfaces fingerprint mismatches prominently.
- Ratelimits layered by IP, account, and sensitive endpoints with Redis counters.

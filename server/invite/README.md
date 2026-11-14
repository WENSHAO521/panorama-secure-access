# Invitation server

A Cloudflare Worker that hands out and checks invitation codes. The app asks for a code only when it was built with
`INVITE_API` and `INVITE_PUBLIC_KEY`; a build without them, such as a fork or a local build, opens as before.

- A code admits up to `max` devices, may expire, and can be revoked or have a device removed.
- Redeeming a code returns a token signed with Ed25519 for this device, valid for `TOKEN_DAYS` (30). The app verifies
  the signature locally (Rust, `plugins/rust_api/rust/src/api/invite.rs`), so it opens offline while the token lasts.
- At each launch the app renews the token. A revoked code, or a device removed from its code, locks the app again;
  being offline does not, until the token expires.

## Deploy (once)

```bash
cd server/invite
npm install
npx wrangler login
npx wrangler kv namespace create INVITES   # paste the printed id into wrangler.toml
npm run keygen                             # prints SIGNING_KEY and INVITE_PUBLIC_KEY
npx wrangler secret put SIGNING_KEY        # paste the private key
npx wrangler secret put ADMIN_TOKEN        # any long random string
npm run deploy                             # prints https://panorama-invite.<account>.workers.dev
```

Then in the GitHub repository, under Settings > Secrets and variables > Actions > Variables, add:

- `INVITE_API`: the Worker URL, for example `https://panorama-invite.<account>.workers.dev`
- `INVITE_PUBLIC_KEY`: the public key `npm run keygen` printed

The next beta or stable build asks for a code. Keep the private key only in the Worker secret: whoever holds it can sign
tokens.

## Manage codes

```bash
API=https://panorama-invite.<account>.workers.dev
AUTH="Authorization: Bearer <ADMIN_TOKEN>"

# 10 codes, each for up to 2 devices, valid for 90 days (days 0 = no expiry)
curl -X POST "$API/admin/codes" -H "$AUTH" -d '{"count":10,"max":2,"days":90,"note":"friends"}'

curl "$API/admin/codes" -H "$AUTH"                                          # list with use counts
curl -X POST "$API/admin/revoke" -H "$AUTH" -d '{"code":"K7QM-W2XP"}'       # revoke
curl -X POST "$API/admin/revoke" -H "$AUTH" -d '{"code":"K7QM-W2XP","revoked":false}'  # restore
curl -X POST "$API/admin/unbind" -H "$AUTH" -d '{"code":"K7QM-W2XP","device":"<id>"}'  # free one device
curl -X POST "$API/admin/unbind" -H "$AUTH" -d '{"code":"K7QM-W2XP"}'       # free all devices
```

The app shows its device ID under the code field; tapping it copies it.

## Test

```bash
npm test
```

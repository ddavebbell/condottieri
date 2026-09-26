# Socii on Cloudflare

One Worker. It serves the game as a static asset and keeps one profile per
Google account in D1. The page stays fully playable as a guest, offline or
opened from disk; signing in only adds a copy of the save on the server.

    src/index.js              the Worker: sign-in, sessions, /api/me, /api/save
    migrations/0001_*.sql     the two tables, users and sessions
    tools/stage.js            builds the game and copies it to public/index.html
    wrangler.jsonc            config. public/ and .wrangler/ are not committed

## Run it locally

    cd worker
    node tools/stage.js
    wrangler d1 migrations apply condottieri --local
    wrangler dev --var DEV_FAKE_LOGIN:1

Open http://localhost:8787. With `DEV_FAKE_LOGIN` the Google button signs in
a made-up player, so the whole loop can be tried without Google.
`/auth/google?as=2` signs in a second one.

## Deploy

Once, on a fresh account:

    wrangler login
    wrangler d1 create condottieri          # paste the database_id into wrangler.jsonc
    wrangler d1 migrations apply condottieri --remote
    wrangler secret put GOOGLE_CLIENT_SECRET
    # and put the client id in wrangler.jsonc under vars

Every release:

    node tools/stage.js
    wrangler deploy

Google Cloud console, the OAuth client's authorised redirect URI must be
exactly `https://<worker url>/auth/callback`. The Worker is named `socii`
(the game's name); the D1 database kept its original name, `condottieri`.

## Sessions and safety

The session cookie is HttpOnly, SameSite=Lax and Secure; only its SHA-256
lives in the database. Writes (`PUT /api/save`, `POST /auth/logout`,
`DELETE /api/me`) require an `Origin` header matching the site, which a
browser only sends from the page itself. A save is capped at 64 KB and must
be a JSON object; the Worker stores it without looking inside, so the page
owns the format (see `design/SHELL-NOTES.md`, once written).

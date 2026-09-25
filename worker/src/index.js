/* Condottieri on Cloudflare.

   Serves the game (prototype/dist.html, staged into public/) and keeps one
   profile per Google account: a display name and the same save JSON the
   page keeps in localStorage. The page only ever sees a session cookie;
   the Google secret stays here.

   Routes
     GET  /auth/google     start Google sign-in
     GET  /auth/callback   Google returns here; makes a session, goes to /
     POST /auth/logout     end the session
     GET  /api/me          { signedIn, name, save, updatedAt } or { signedIn:false }
     PUT  /api/save        store the save JSON (body, at most SAVE_LIMIT bytes)
     DELETE /api/me        delete the account and everything in it
     everything else       the static game

   Local development without Google: `wrangler dev --var DEV_FAKE_LOGIN:1`
   makes /auth/google sign in a made-up player (?as=<n> for several). */

const SESSION_DAYS = 30;
const STATE_MINUTES = 10;
const SAVE_LIMIT = 64 * 1024;
const GOOGLE_AUTH = 'https://accounts.google.com/o/oauth2/v2/auth';
const GOOGLE_TOKEN = 'https://oauth2.googleapis.com/token';

export default {
  async fetch(req, env) {
    const url = new URL(req.url);
    const p = url.pathname;
    try {
      if (p === '/auth/google'   && req.method === 'GET')    return authStart(req, env, url);
      if (p === '/auth/callback' && req.method === 'GET')    return authCallback(req, env, url);
      if (p === '/auth/logout'   && req.method === 'POST')   return logout(req, env, url);
      if (p === '/api/me'        && req.method === 'GET')    return me(req, env);
      if (p === '/api/me'        && req.method === 'DELETE') return deleteMe(req, env, url);
      if (p === '/api/save'      && req.method === 'PUT')    return putSave(req, env, url);
      if (p.startsWith('/api/') || p.startsWith('/auth/')) return json({ error: 'not found' }, 404);
      return env.ASSETS.fetch(req);
    } catch (e) {
      console.error(e && e.stack || e);
      return json({ error: 'server error' }, 500);
    }
  }
};

/* ---------- sign in ---------- */

async function authStart(req, env, url) {
  if (env.DEV_FAKE_LOGIN === '1') {
    const n = (url.searchParams.get('as') || '1').replace(/[^a-z0-9]/gi, '');
    const user = await upsertUser(env, { sub: 'dev-' + n, email: 'dev' + n + '@example.invalid', name: 'Dev Player ' + n });
    return withSession(env, url, user.id, redirect('/#signedin'));
  }
  if (!env.GOOGLE_CLIENT_ID || !env.GOOGLE_CLIENT_SECRET) {
    return json({ error: 'Google sign-in is not configured on this server' }, 503);
  }
  const state = randomHex(16);
  const q = new URLSearchParams({
    client_id: env.GOOGLE_CLIENT_ID,
    redirect_uri: url.origin + '/auth/callback',
    response_type: 'code',
    scope: 'openid profile email',
    state,
    prompt: 'select_account'
  });
  const res = redirect(GOOGLE_AUTH + '?' + q);
  res.headers.append('Set-Cookie', cookie('oauth_state', state, url, STATE_MINUTES * 60));
  return res;
}

async function authCallback(req, env, url) {
  const code = url.searchParams.get('code');
  const state = url.searchParams.get('state');
  const cookies = parseCookies(req);
  if (!code || !state || state !== cookies.oauth_state) {
    return text('Sign-in did not complete. Go back and try again.', 400);
  }
  const tokenRes = await fetch(GOOGLE_TOKEN, {
    method: 'POST',
    headers: { 'content-type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      code,
      client_id: env.GOOGLE_CLIENT_ID,
      client_secret: env.GOOGLE_CLIENT_SECRET,
      redirect_uri: url.origin + '/auth/callback',
      grant_type: 'authorization_code'
    })
  });
  if (!tokenRes.ok) {
    console.error('token exchange failed', tokenRes.status, await tokenRes.text());
    return text('Google did not accept the sign-in. Go back and try again.', 502);
  }
  const tokens = await tokenRes.json();
  /* The id token came straight from Google's token endpoint over TLS,
     authenticated with our client secret, so its claims are trusted
     without a signature check. The audience and issuer are checked. */
  const claims = decodeJwtPayload(tokens.id_token);
  if (!claims || claims.aud !== env.GOOGLE_CLIENT_ID ||
      !/^(https:\/\/)?accounts\.google\.com$/.test(claims.iss || '') || !claims.sub) {
    return text('Google returned an unexpected identity. Go back and try again.', 502);
  }
  const user = await upsertUser(env, { sub: claims.sub, email: claims.email || null, name: claims.name || claims.given_name || null });
  const res = redirect('/#signedin');
  res.headers.append('Set-Cookie', cookie('oauth_state', '', url, 0));
  return withSession(env, url, user.id, res);
}

async function logout(req, env, url) {
  if (!sameOrigin(req, url)) return json({ error: 'forbidden' }, 403);
  const sid = parseCookies(req).sid;
  if (sid) await env.DB.prepare('DELETE FROM sessions WHERE token_hash = ?').bind(await sha256(sid)).run();
  const res = new Response(null, { status: 204 });
  res.headers.append('Set-Cookie', cookie('sid', '', url, 0));
  return res;
}

/* ---------- the profile ---------- */

async function me(req, env) {
  const user = await currentUser(req, env);
  if (!user) return json({ signedIn: false });
  let save = null;
  try { save = JSON.parse(user.save); } catch (e) { save = null; }
  return json({ signedIn: true, name: user.name, save, updatedAt: user.updated_at });
}

async function putSave(req, env, url) {
  if (!sameOrigin(req, url)) return json({ error: 'forbidden' }, 403);
  const user = await currentUser(req, env);
  if (!user) return json({ error: 'not signed in' }, 401);
  const body = await req.text();
  if (body.length > SAVE_LIMIT) return json({ error: 'save too large' }, 413);
  let parsed;
  try { parsed = JSON.parse(body); } catch (e) { parsed = null; }
  if (!parsed || typeof parsed !== 'object' || Array.isArray(parsed)) return json({ error: 'save must be a JSON object' }, 400);
  const now = Date.now();
  await env.DB.prepare('UPDATE users SET save = ?, updated_at = ? WHERE id = ?').bind(body, now, user.id).run();
  return json({ updatedAt: now });
}

async function deleteMe(req, env, url) {
  if (!sameOrigin(req, url)) return json({ error: 'forbidden' }, 403);
  const user = await currentUser(req, env);
  if (!user) return json({ error: 'not signed in' }, 401);
  await env.DB.batch([
    env.DB.prepare('DELETE FROM sessions WHERE user_id = ?').bind(user.id),
    env.DB.prepare('DELETE FROM users WHERE id = ?').bind(user.id)
  ]);
  const res = new Response(null, { status: 204 });
  res.headers.append('Set-Cookie', cookie('sid', '', url, 0));
  return res;
}

/* ---------- users and sessions ---------- */

async function upsertUser(env, g) {
  const now = Date.now();
  /* A returning player keeps the name they chose; only the email is refreshed. */
  await env.DB.prepare(
    `INSERT INTO users (id, google_sub, email, name, save, created_at, updated_at)
     VALUES (?, ?, ?, ?, '{}', ?, ?)
     ON CONFLICT(google_sub) DO UPDATE SET email = excluded.email`
  ).bind(crypto.randomUUID(), g.sub, g.email, g.name, now, now).run();
  return env.DB.prepare('SELECT id, name FROM users WHERE google_sub = ?').bind(g.sub).first();
}

async function withSession(env, url, userId, res) {
  const token = randomHex(32);
  const expires = Date.now() + SESSION_DAYS * 86400000;
  await env.DB.batch([
    env.DB.prepare('DELETE FROM sessions WHERE user_id = ? AND expires_at < ?').bind(userId, Date.now()),
    env.DB.prepare('INSERT INTO sessions (token_hash, user_id, expires_at) VALUES (?, ?, ?)').bind(await sha256(token), userId, expires)
  ]);
  res.headers.append('Set-Cookie', cookie('sid', token, url, SESSION_DAYS * 86400));
  return res;
}

async function currentUser(req, env) {
  const sid = parseCookies(req).sid;
  if (!sid) return null;
  return env.DB.prepare(
    `SELECT u.id, u.name, u.save, u.updated_at
       FROM sessions s JOIN users u ON u.id = s.user_id
      WHERE s.token_hash = ? AND s.expires_at > ?`
  ).bind(await sha256(sid), Date.now()).first();
}

/* ---------- small things ---------- */

const json = (o, status = 200) => new Response(JSON.stringify(o), {
  status, headers: { 'content-type': 'application/json', 'cache-control': 'no-store' }
});
const text = (s, status = 200) => new Response(s, { status, headers: { 'content-type': 'text/plain; charset=utf-8' } });
const redirect = to => new Response(null, { status: 302, headers: { location: to } });

/* Mutating requests must come from the page itself. */
function sameOrigin(req, url) {
  const o = req.headers.get('origin');
  return !!o && o === url.origin;
}

function cookie(name, value, url, maxAge) {
  let c = name + '=' + value + '; Path=/; HttpOnly; SameSite=Lax; Max-Age=' + maxAge;
  if (url.protocol === 'https:') c += '; Secure';
  return c;
}

function parseCookies(req) {
  const out = {};
  for (const part of (req.headers.get('cookie') || '').split(';')) {
    const i = part.indexOf('=');
    if (i > 0) out[part.slice(0, i).trim()] = part.slice(i + 1).trim();
  }
  return out;
}

function randomHex(bytes) {
  const a = new Uint8Array(bytes);
  crypto.getRandomValues(a);
  return [...a].map(b => b.toString(16).padStart(2, '0')).join('');
}

async function sha256(s) {
  const d = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(s));
  return [...new Uint8Array(d)].map(b => b.toString(16).padStart(2, '0')).join('');
}

function decodeJwtPayload(jwt) {
  try {
    const b64 = jwt.split('.')[1].replace(/-/g, '+').replace(/_/g, '/');
    return JSON.parse(new TextDecoder().decode(Uint8Array.from(atob(b64), c => c.charCodeAt(0))));
  } catch (e) { return null; }
}

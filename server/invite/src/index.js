import { importKeys, readToken, signToken } from './token.js';

// No 0/O, 1/I/L: codes are read aloud and typed from screenshots.
const ALPHABET = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
const DEVICE_PATTERN = /^[A-Za-z0-9_-]{16,64}$/;
const DAY = 24 * 60 * 60;

let cachedKeys;

async function keysOf(env) {
  cachedKeys ??= importKeys(env.SIGNING_KEY);
  return cachedKeys;
}

export function normalizeCode(code) {
  return typeof code === 'string' ? code.toUpperCase().replace(/[^A-Z0-9]/g, '') : '';
}

function json(body, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'content-type': 'application/json; charset=utf-8' },
  });
}

const refuse = (error, status = 403) => json({ error }, status);

async function readBody(request) {
  try {
    return await request.json();
  } catch {
    return {};
  }
}

const recordKey = (code) => `code:${code}`;

async function loadRecord(env, code) {
  return code ? env.INVITES.get(recordKey(code), 'json') : null;
}

/** Why [record] cannot serve [device], or null when it can. */
function refusalOf(record, device, now) {
  if (!record) return 'invalid';
  if (record.revoked) return 'revoked';
  if (record.expires && record.expires <= now * 1000) return 'expired';
  if (!record.devices.includes(device) && record.devices.length >= record.max) {
    return 'exhausted';
  }
  return null;
}

async function issue(env, code, device, now) {
  const { sign } = await keysOf(env);
  const days = Number(env.TOKEN_DAYS) || 30;
  const exp = now + days * DAY;
  const token = await signToken(sign, { v: 1, c: code, d: device, iat: now, exp });
  return json({ token, exp });
}

async function redeem(request, env, now) {
  const body = await readBody(request);
  const code = normalizeCode(body.code);
  const device = body.device;
  if (typeof device !== 'string' || !DEVICE_PATTERN.test(device)) {
    return refuse('bad_request', 400);
  }
  const record = await loadRecord(env, code);
  const refusal = refusalOf(record, device, now);
  if (refusal) return refuse(refusal);
  if (!record.devices.includes(device)) {
    record.devices.push(device);
    await env.INVITES.put(recordKey(code), JSON.stringify(record));
  }
  return issue(env, code, device, now);
}

/** A token, even an expired one, buys a new one while its code still holds its device. */
async function refresh(request, env, now) {
  const body = await readBody(request);
  const { verify } = await keysOf(env);
  const claims = await readToken(verify, body.token);
  if (!claims || claims.v !== 1) return refuse('invalid');
  const record = await loadRecord(env, claims.c);
  const refusal = refusalOf(record, claims.d, now);
  if (refusal) return refuse(refusal);
  if (!record.devices.includes(claims.d)) return refuse('unbound');
  return issue(env, claims.c, claims.d, now);
}

function randomCode() {
  const bytes = crypto.getRandomValues(new Uint8Array(8));
  return Array.from(bytes, (byte) => ALPHABET[byte % ALPHABET.length]).join('');
}

const formatCode = (code) => `${code.slice(0, 4)}-${code.slice(4)}`;

async function admin(request, env, url, now) {
  const auth = request.headers.get('authorization') ?? '';
  if (!env.ADMIN_TOKEN || auth !== `Bearer ${env.ADMIN_TOKEN}`) {
    return refuse('unauthorized', 401);
  }
  if (url.pathname === '/admin/codes' && request.method === 'GET') {
    const codes = [];
    let cursor;
    do {
      const page = await env.INVITES.list({ prefix: 'code:', cursor });
      for (const { name } of page.keys) {
        const record = await env.INVITES.get(name, 'json');
        codes.push({ code: formatCode(name.slice(5)), ...record, used: record.devices.length });
      }
      cursor = page.list_complete ? undefined : page.cursor;
    } while (cursor);
    return json({ codes });
  }
  const body = await readBody(request);
  if (url.pathname === '/admin/codes' && request.method === 'POST') {
    const count = Math.min(Math.max(Number(body.count) || 1, 1), 100);
    const max = Math.max(Number(body.max) || 1, 1);
    const days = Number(body.days) || 0;
    const record = {
      max,
      devices: [],
      expires: days > 0 ? (now + days * DAY) * 1000 : null,
      revoked: false,
      note: typeof body.note === 'string' ? body.note.slice(0, 200) : '',
      created: now * 1000,
    };
    const codes = [];
    while (codes.length < count) {
      const code = randomCode();
      if (await env.INVITES.get(recordKey(code))) continue;
      await env.INVITES.put(recordKey(code), JSON.stringify(record));
      codes.push(formatCode(code));
    }
    return json({ codes, max, expires: record.expires });
  }
  const code = normalizeCode(body.code);
  const record = await loadRecord(env, code);
  if (!record) return refuse('invalid', 404);
  if (url.pathname === '/admin/revoke' && request.method === 'POST') {
    record.revoked = body.revoked !== false;
  } else if (url.pathname === '/admin/unbind' && request.method === 'POST') {
    record.devices = body.device ? record.devices.filter((d) => d !== body.device) : [];
  } else {
    return refuse('not_found', 404);
  }
  await env.INVITES.put(recordKey(code), JSON.stringify(record));
  return json({ code: formatCode(code), ...record });
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const now = Math.floor(Date.now() / 1000);
    if (url.pathname.startsWith('/admin/')) return admin(request, env, url, now);
    if (request.method !== 'POST') return refuse('not_found', 404);
    switch (url.pathname) {
      case '/v1/redeem':
        return redeem(request, env, now);
      case '/v1/refresh':
        return refresh(request, env, now);
      default:
        return refuse('not_found', 404);
    }
  },
};

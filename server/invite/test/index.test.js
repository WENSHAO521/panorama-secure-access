import assert from 'node:assert/strict';
import { test } from 'node:test';

import worker from '../src/index.js';
import { fromBase64url } from '../src/token.js';

class MemoryKv {
  map = new Map();
  async get(key, type) {
    const value = this.map.get(key);
    if (value === undefined) return null;
    return type === 'json' ? JSON.parse(value) : value;
  }
  async put(key, value) {
    this.map.set(key, value);
  }
  async list({ prefix }) {
    const keys = [...this.map.keys()].filter((k) => k.startsWith(prefix)).map((name) => ({ name }));
    return { keys, list_complete: true };
  }
}

const pair = await crypto.subtle.generateKey({ name: 'Ed25519' }, true, ['sign', 'verify']);
const env = {
  INVITES: new MemoryKv(),
  SIGNING_KEY: Buffer.from(await crypto.subtle.exportKey('pkcs8', pair.privateKey)).toString('base64'),
  ADMIN_TOKEN: 'admin-secret',
  TOKEN_DAYS: '30',
};
const deviceA = 'deviceAAAAAAAAAAAAAAAA';
const deviceB = 'deviceBBBBBBBBBBBBBBBB';

async function call(path, body, { auth, method = 'POST' } = {}) {
  const headers = { 'content-type': 'application/json' };
  if (auth) headers.authorization = `Bearer ${auth}`;
  const response = await worker.fetch(
    new Request(`https://invite.test${path}`, {
      method,
      headers,
      body: method === 'GET' ? undefined : JSON.stringify(body ?? {}),
    }),
    env,
  );
  return { status: response.status, body: await response.json() };
}

async function newCode(options = {}) {
  const { body } = await call('/admin/codes', { count: 1, max: 1, ...options }, { auth: 'admin-secret' });
  return body.codes[0];
}

test('admin routes need the token', async () => {
  assert.equal((await call('/admin/codes', { count: 1 })).status, 401);
  assert.equal((await call('/admin/codes', { count: 1 }, { auth: 'wrong' })).status, 401);
});

test('a code redeems to a token the public key verifies', async () => {
  const code = await newCode();
  assert.match(code, /^[A-HJ-NP-Z2-9]{4}-[A-HJ-NP-Z2-9]{4}$/);
  const { status, body } = await call('/v1/redeem', { code: code.toLowerCase(), device: deviceA });
  assert.equal(status, 200);
  const [payload, signature] = body.token.split('.');
  const valid = await crypto.subtle.verify(
    'Ed25519',
    pair.publicKey,
    fromBase64url(signature),
    new TextEncoder().encode(payload),
  );
  assert.ok(valid);
  const claims = JSON.parse(new TextDecoder().decode(fromBase64url(payload)));
  assert.equal(claims.d, deviceA);
  assert.equal(claims.exp - claims.iat, 30 * 86400);
});

test('a code holds as many devices as it allows, and the same device again', async () => {
  const code = await newCode({ max: 1 });
  assert.equal((await call('/v1/redeem', { code, device: deviceA })).status, 200);
  assert.equal((await call('/v1/redeem', { code, device: deviceA })).status, 200);
  const second = await call('/v1/redeem', { code, device: deviceB });
  assert.deepEqual(second, { status: 403, body: { error: 'exhausted' } });
});

test('unknown, revoked and expired codes are refused by name', async () => {
  assert.equal((await call('/v1/redeem', { code: 'NOPE-NOPE', device: deviceA })).body.error, 'invalid');
  const revoked = await newCode();
  await call('/admin/revoke', { code: revoked }, { auth: 'admin-secret' });
  assert.equal((await call('/v1/redeem', { code: revoked, device: deviceA })).body.error, 'revoked');
  const expired = await newCode({ days: 1 });
  const key = `code:${expired.replace('-', '')}`;
  const record = JSON.parse(env.INVITES.map.get(key));
  env.INVITES.map.set(key, JSON.stringify({ ...record, expires: Date.now() - 1000 }));
  assert.equal((await call('/v1/redeem', { code: expired, device: deviceA })).body.error, 'expired');
});

test('a bad device id is a bad request', async () => {
  const code = await newCode();
  assert.equal((await call('/v1/redeem', { code, device: 'x' })).status, 400);
});

test('refresh renews a live token and stops once the code is revoked or unbound', async () => {
  const code = await newCode({ max: 2 });
  const { body } = await call('/v1/redeem', { code, device: deviceA });
  const renewed = await call('/v1/refresh', { token: body.token });
  assert.equal(renewed.status, 200);
  assert.notEqual(renewed.body.token, undefined);

  const [payload, signature] = body.token.split('.');
  const flipped = signature[0] === 'A' ? 'B' : 'A';
  const forged = `${payload}.${flipped}${signature.slice(1)}`;
  assert.equal((await call('/v1/refresh', { token: forged })).body.error, 'invalid');

  await call('/admin/unbind', { code, device: deviceA }, { auth: 'admin-secret' });
  assert.equal((await call('/v1/refresh', { token: body.token })).body.error, 'unbound');

  const again = await call('/v1/redeem', { code, device: deviceA });
  await call('/admin/revoke', { code }, { auth: 'admin-secret' });
  assert.equal((await call('/v1/refresh', { token: again.body.token })).body.error, 'revoked');
});

test('the admin list shows each code with its use', async () => {
  const { body } = await call('/admin/codes', null, { auth: 'admin-secret', method: 'GET' });
  assert.ok(body.codes.length > 0);
  assert.ok(body.codes.every((entry) => typeof entry.used === 'number'));
});

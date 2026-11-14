const encoder = new TextEncoder();
const decoder = new TextDecoder();

export function base64url(bytes) {
  let binary = '';
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary).replaceAll('+', '-').replaceAll('/', '_').replace(/=+$/, '');
}

export function fromBase64url(text) {
  const padded = text.replaceAll('-', '+').replaceAll('_', '/');
  const binary = atob(padded + '='.repeat((4 - (padded.length % 4)) % 4));
  return Uint8Array.from(binary, (char) => char.charCodeAt(0));
}

export function fromBase64(text) {
  return Uint8Array.from(atob(text.trim()), (char) => char.charCodeAt(0));
}

/** The signing key and its public half, from the PKCS#8 secret. */
export async function importKeys(pkcs8Base64) {
  const sign = await crypto.subtle.importKey(
    'pkcs8',
    fromBase64(pkcs8Base64),
    { name: 'Ed25519' },
    true,
    ['sign'],
  );
  const { x } = await crypto.subtle.exportKey('jwk', sign);
  const verify = await crypto.subtle.importKey(
    'jwk',
    { kty: 'OKP', crv: 'Ed25519', x },
    { name: 'Ed25519' },
    true,
    ['verify'],
  );
  return { sign, verify };
}

/** `<payload>.<signature>`, both base64url; the app checks the same bytes. */
export async function signToken(key, claims) {
  const payload = base64url(encoder.encode(JSON.stringify(claims)));
  const signature = await crypto.subtle.sign('Ed25519', key, encoder.encode(payload));
  return `${payload}.${base64url(new Uint8Array(signature))}`;
}

/** The claims of a token this server signed, expired or not, or null. */
export async function readToken(key, token) {
  if (typeof token !== 'string') return null;
  const [payload, signature, extra] = token.split('.');
  if (!payload || !signature || extra !== undefined) return null;
  try {
    const valid = await crypto.subtle.verify(
      'Ed25519',
      key,
      fromBase64url(signature),
      encoder.encode(payload),
    );
    return valid ? JSON.parse(decoder.decode(fromBase64url(payload))) : null;
  } catch {
    return null;
  }
}

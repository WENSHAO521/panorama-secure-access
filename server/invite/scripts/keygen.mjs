// Prints a new Ed25519 key pair: the private half for the Worker's SIGNING_KEY
// secret, the public half for the app's INVITE_PUBLIC_KEY build variable.
const pair = await crypto.subtle.generateKey({ name: 'Ed25519' }, true, ['sign', 'verify']);
const pkcs8 = Buffer.from(await crypto.subtle.exportKey('pkcs8', pair.privateKey));
const raw = Buffer.from(await crypto.subtle.exportKey('raw', pair.publicKey));
console.log(`SIGNING_KEY (Worker secret, keep private):\n${pkcs8.toString('base64')}\n`);
console.log(`INVITE_PUBLIC_KEY (app build variable):\n${raw.toString('base64')}`);

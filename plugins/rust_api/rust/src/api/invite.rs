use ed25519_dalek::{Signature, VerifyingKey};
use flutter_rust_bridge::frb;

/// Whether `signature` is the invitation server's Ed25519 signature of
/// `message` under `public_key`. Malformed keys and signatures do not verify.
#[frb(sync)]
pub fn verify_invite_signature(public_key: Vec<u8>, message: Vec<u8>, signature: Vec<u8>) -> bool {
    let Ok(key) = <[u8; 32]>::try_from(public_key.as_slice()) else {
        return false;
    };
    let Ok(key) = VerifyingKey::from_bytes(&key) else {
        return false;
    };
    let Ok(signature) = Signature::from_slice(&signature) else {
        return false;
    };
    key.verify_strict(&message, &signature).is_ok()
}

#[cfg(test)]
mod tests {
    use super::verify_invite_signature;
    use ed25519_dalek::{Signer, SigningKey};

    fn key() -> SigningKey {
        SigningKey::from_bytes(&[7; 32])
    }

    #[test]
    fn accepts_the_signature_of_the_message() {
        let key = key();
        let signature = key.sign(b"payload").to_bytes().to_vec();
        let public = key.verifying_key().to_bytes().to_vec();
        assert!(verify_invite_signature(
            public,
            b"payload".to_vec(),
            signature
        ));
    }

    #[test]
    fn refuses_another_message_key_or_garbage() {
        let key = key();
        let signature = key.sign(b"payload").to_bytes().to_vec();
        let public = key.verifying_key().to_bytes().to_vec();
        let other = SigningKey::from_bytes(&[9; 32])
            .verifying_key()
            .to_bytes()
            .to_vec();
        assert!(!verify_invite_signature(
            public.clone(),
            b"payloae".to_vec(),
            signature.clone()
        ));
        assert!(!verify_invite_signature(
            other,
            b"payload".to_vec(),
            signature.clone()
        ));
        assert!(!verify_invite_signature(
            public.clone(),
            b"payload".to_vec(),
            vec![0; 12]
        ));
        assert!(!verify_invite_signature(
            vec![1, 2, 3],
            b"payload".to_vec(),
            signature
        ));
    }
}

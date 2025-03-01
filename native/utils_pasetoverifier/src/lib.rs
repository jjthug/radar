use rustler::{Error, NifResult};
use chrono::{Duration, Utc};
use pasetors::claims::Claims;
use pasetors::claims::ClaimsValidationRules;
use pasetors::keys::SymmetricKey;
use pasetors::{local, Local, version4::V4};
use pasetors::token::UntrustedToken;
use std::convert::TryFrom;
use serde_json::Value;

const SYMMETRIC_KEY: &str = "01234567890123456789012345678966";

#[rustler::nif(schedule = "DirtyCpu")]
fn encode_token(user_id: i64, expiration_minutes: i64) -> NifResult<String> {
    let sk = match SymmetricKey::<V4>::from(SYMMETRIC_KEY.as_bytes()) {
        Ok(key) => key,
        Err(_) => return Err(rustler::Error::Atom("invalid_key")),
    };

    let expired_at = Utc::now() + Duration::minutes(expiration_minutes);
    let expired_at_str = expired_at.to_rfc3339();

    let mut claims = Claims::new().map_err(|_| rustler::Error::Atom("claims_error"))?;
    claims
        .add_additional("user_id", Value::Number(user_id.into()))
        .map_err(|_| rustler::Error::Atom("claims_error"))?;
    claims
        .add_additional("expiredAt", Value::String(expired_at_str))
        .map_err(|_| rustler::Error::Atom("claims_error"))?;

    let token = local::encrypt(&sk, &claims, None, None)
        .map_err(|_| rustler::Error::Atom("encryption_failed"))?;

    Ok(token)
}

#[rustler::nif(schedule = "DirtyCpu")]
fn validate_token(token: String) -> NifResult<(String, String)> {
    let sk = match SymmetricKey::<V4>::from(SYMMETRIC_KEY.as_bytes()) {
        Ok(key) => key,
        Err(_) => return Err(Error::Atom("invalid_key")),
    };

    let untrusted_token = match UntrustedToken::<Local, V4>::try_from(token.as_str()) {
        Ok(token) => token,
        Err(_) => return Err(Error::Atom("invalid_token_format")),
    };

    let validation_rules = ClaimsValidationRules::new();
    let trusted_token = match local::decrypt(&sk, &untrusted_token, &validation_rules, None, None) {
        Ok(token) => token,
        Err(_) => return Err(Error::Atom("decryption_failed")),
    };

    let claims = trusted_token.payload_claims().ok_or(Error::Atom("missing_claims"))?;

    let user_id = claims
        .get_claim("user_id")
        .and_then(|c| c.as_str())
        .ok_or(Error::Atom("missing_user_id"))?
        .to_string();

    let expired_at = claims
        .get_claim("expiredAt")
        .and_then(|c| c.as_str())
        .ok_or(Error::Atom("missing_expired_at"))?
        .to_string();

    if !validate_expiration(&expired_at) {
        return Err(Error::Atom("token_expired"));
    }

    Ok((user_id, expired_at))
}

fn validate_expiration(expired_at: &str) -> bool {
    match expired_at.parse::<chrono::DateTime<Utc>>() {
        Ok(expiration_time) => expiration_time > Utc::now(),
        Err(_) => false,
    }
}

rustler::init!("Elixir.Utils.PasetoVerifier");

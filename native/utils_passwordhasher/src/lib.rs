use rustler::NifResult;
use bcrypt::{hash, verify, DEFAULT_COST};

#[rustler::nif(schedule = "DirtyCpu")]
fn hash_password(password: String) -> NifResult<String> {
    match hash(password, DEFAULT_COST) {
        Ok(hashed) => Ok(hashed),
        Err(_) => Err(rustler::Error::Atom("hash_error")),
    }
}

#[rustler::nif(schedule = "DirtyCpu")]
fn verify_password(password: String, hashed_password: String) -> NifResult<bool> {
    match verify(password, &hashed_password) {
        Ok(valid) => Ok(valid),
        Err(_) => Err(rustler::Error::Atom("verify_error")),
    }
}

rustler::init!("Elixir.Utils.PasswordHasher");
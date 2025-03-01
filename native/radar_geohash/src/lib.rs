use rustler::NifResult;
use geohash::{encode, decode, neighbor, Direction, Coord};

#[rustler::nif(schedule = "DirtyCpu")]
fn geohash_encode(lat: f64, lon: f64, precision: usize) -> NifResult<String> {
    let coord = Coord { x: lon, y: lat };
    match encode(coord, precision) {
        Ok(hash) => Ok(hash),
        Err(_) => Err(rustler::Error::Atom("encoding_failed")),
    }
}

#[rustler::nif(schedule = "DirtyCpu")]
fn geohash_decode(hash: String) -> NifResult<(f64, f64)> {
    match decode(&hash) {
        Ok((coord, _, _)) => Ok((coord.y, coord.x)), // (lat, lon)
        Err(_) => Err(rustler::Error::Atom("decoding_failed")),
    }
}

#[rustler::nif(schedule = "DirtyCpu")]
fn geohash_neighbors(hash: String) -> NifResult<Vec<String>> {
    let directions = [
        Direction::N, Direction::S, Direction::E, Direction::W,
        Direction::NE, Direction::NW, Direction::SE, Direction::SW,
    ];
    
    let neighbors: Vec<String> = directions.iter()
        .filter_map(|&dir| neighbor(&hash, dir).ok())
        .collect();
    
    Ok(neighbors)
}

rustler::init!("Elixir.Utils.GeoHash");

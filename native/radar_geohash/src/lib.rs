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
fn geohash_encode_str(lat: String, lon: String, precision: usize) -> NifResult<String> {
    let lat: f64 = lat.parse().map_err(|_| rustler::Error::Atom("invalid_latitude"))?;
    let lon: f64 = lon.parse().map_err(|_| rustler::Error::Atom("invalid_longitude"))?;

    let coord = Coord { x: lon, y: lat };
    match encode(coord, precision) {
        Ok(hash) => Ok(hash),
        Err(_) => Err(rustler::Error::Atom("encoding_failed")),
    }
}


#[rustler::nif(schedule = "DirtyCpu")]
fn geohash_neighbors_and_bounds(
    lat: f64,
    lon: f64,
    precision: usize,
) -> NifResult<(Vec<String>, (f64, f64, f64, f64), String)> {
    // Convert lat & lon from String to f64
    let coord = geohash::Coord { x: lon, y: lat };
    let hash = geohash::encode(coord, precision)
        .map_err(|_| rustler::Error::Atom("geohash_encode_failed"))?;

    let directions = [
        Direction::N,
        Direction::S,
        Direction::E,
        Direction::W,
        Direction::NE,
        Direction::NW,
        Direction::SE,
        Direction::SW,
    ];

    let mut neighbors: Vec<String> = directions
        .iter()
        .filter_map(|&dir| neighbor(&hash, dir).ok())
        .collect();

    neighbors.push(hash.clone()); // Include center geohash

    match decode(&hash) {
        Ok((coord, lon_error, lat_error)) => {
            let min_lat = coord.y - lat_error;
            let max_lat = coord.y + lat_error;
            let min_lon = coord.x - lon_error;
            let max_lon = coord.x + lon_error;
            Ok((neighbors, (min_lat, max_lat, min_lon, max_lon), hash))
        }
        Err(_) => Err(rustler::Error::BadArg),
    }
}

rustler::init!("Elixir.Utils.GeoHash");

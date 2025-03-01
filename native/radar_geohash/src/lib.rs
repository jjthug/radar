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
fn geohash_neighbors(lat_str: String, lon_str: String, precision: usize) -> NifResult<Vec<String>> {
    // Convert lat & lon from String to f64
    let lat: f64 = lat_str.parse().map_err(|_| rustler::Error::Atom("invalid_latitude"))?;
    let lon: f64 = lon_str.parse().map_err(|_| rustler::Error::Atom("invalid_longitude"))?;

    let coord = Coord { x: lon, y: lat };
    let hash = encode(coord, precision).map_err(|_| rustler::Error::Atom("geohash_encode_failed"))?;
    
    let directions = [
        Direction::N, Direction::S, Direction::E, Direction::W,
        Direction::NE, Direction::NW, Direction::SE, Direction::SW,
    ];
    
    let mut neighbors: Vec<String> = directions.iter()
        .filter_map(|&dir| neighbor(&hash, dir).ok())
        .collect();
    
    neighbors.push(hash); // Include center geohash

    Ok(neighbors)
}



/// Get geohash boundaries
#[rustler::nif(schedule = "DirtyCpu")]
fn geohash_bounds(geohash: &str) -> NifResult<(f64, f64, f64, f64)> {
    match geohash::decode(geohash) {
        Ok((coord, lon_error, lat_error)) => {
            let min_lat = coord.y - lat_error;
            let max_lat = coord.y + lat_error;
            let min_lon = coord.x - lon_error;
            let max_lon = coord.x + lon_error;
            Ok((min_lat, max_lat, min_lon, max_lon))
        }
        Err(_) => Err(rustler::Error::BadArg),
    }
}


rustler::init!("Elixir.Utils.GeoHash");

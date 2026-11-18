"""Create one standardized HDF5 file for each geography layer."""

# Import filesystem and warning utilities for the conversion operation.
from pathlib import Path
import struct
import warnings

# Import HDF5, NetCDF, numerical, spreadsheet, and raster-image tools for conversion.
import h5py
import netCDF4
import numpy as np
import pandas as pd
from PIL import Image
from scipy.optimize import brentq


def write_dataset(path: Path, latitude: np.ndarray, longitude: np.ndarray, data: np.ndarray, time=None) -> None:
    """Write one layer using the common latitude/longitude HDF5 layout."""
    # Create the destination directory and replace only this generated layer file.
    path.parent.mkdir(parents=True, exist_ok=True)
    with h5py.File(path, "w") as output:
        output.create_dataset("lat", data=np.asarray(latitude).reshape(-1))
        output.create_dataset("lon", data=np.asarray(longitude).reshape(-1))
        output.create_dataset("data", data=data, compression="gzip", compression_opts=4, shuffle=True)
        if time is not None:
            output.create_dataset("time", data=np.asarray(time).reshape(-1))


def convert_geography(source: Path, destination: Path) -> None:
    """Extract the weight raster, which still uses the MATLAB geography product."""
    # MATLAB stores two-dimensional arrays reversed in HDF5, so transpose the weight raster.
    with h5py.File(source, "r") as input_file:
        latitude = input_file["lat"][:].reshape(-1)
        longitude = input_file["lon"][:].reshape(-1)
        write_dataset(destination / "W.h5", latitude, longitude, input_file["W"][:].T)


def convert_sea(source: Path, destination: Path) -> None:
    """Save the native 0.5-degree SAGE sea mask without spatial resampling."""
    # Read the source suitability values and coordinate axes from the NetCDF file.
    with netCDF4.Dataset(source) as input_file:
        source_variable = input_file.variables["data"]
        source_data = np.ma.asarray(source_variable[0, 0, :, :], dtype=np.float32)
        source_latitude = np.asarray(input_file.variables["latitude"][:], dtype=np.float64)
        source_longitude = np.asarray(input_file.variables["longitude"][:], dtype=np.float64)
        # Threshold source values before sorting the descending NetCDF latitude axis.
        sea = np.asarray(source_data.filled(np.nan)) > 100.0
        latitude_order = np.argsort(source_latitude)
        longitude_order = np.argsort(source_longitude)
        sea = np.take(np.take(sea, latitude_order, axis=0), longitude_order, axis=1)
        source_latitude = source_latitude[latitude_order]
        source_longitude = source_longitude[longitude_order]
    # Store the categorical mask at its actual SAGE resolution for loader-side resampling.
    path = destination / "sea.h5"
    write_dataset(path, source_latitude, source_longitude, sea.astype(np.uint8))
    with h5py.File(path, "a") as output:
        # Record the source resolution and classification threshold with the raster.
        output.attrs["source_delta"] = 0.5
        output.attrs["source"] = str(source)
        output.attrs["sea_threshold"] = 100.0


def _bil_metadata(header_path: Path, world_path: Path) -> tuple[int, int, float, float, float]:
    """Read a HydroSHEDS BIL header and world file into raster placement values."""
    # Parse named header fields while allowing the source's whitespace-separated format.
    header = {}
    for line in header_path.read_text(encoding="ascii").splitlines():
        fields = line.split()
        if len(fields) >= 2:
            header[fields[0].upper()] = fields[1]
    # Read the six world-file values in their documented order.
    world = np.loadtxt(world_path, dtype=np.float64).reshape(-1)
    if world.size != 6:
        raise ValueError(f"Invalid BIL world file: {world_path}")
    return (
        int(header["NROWS"]),
        int(header["NCOLS"]),
        float(world[0]),
        float(world[4]),
        float(world[5]),
    )


def convert_acc(source: Path, destination: Path) -> None:
    """Merge HydroSHEDS ACC tiles on a global 30-arc-second grid, preserving raw values."""
    # Use the source's 30-arc-second cell centers as the output grid resolution.
    delta = 1.0 / 120.0
    latitude_count = round(180.0 / delta)
    longitude_count = round(360.0 / delta)
    latitude = -90.0 + delta / 2.0 + np.arange(latitude_count) * delta
    longitude = -180.0 + delta / 2.0 + np.arange(longitude_count) * delta
    tile_names = ("af", "as", "au", "ca", "eu", "na", "sa")
    path = destination / "acc.h5"
    destination.mkdir(parents=True, exist_ok=True)
    with h5py.File(path, "w") as output:
        # Save the native 30-arc-second global grid and merge tiles before any resizing.
        output.create_dataset("lat", data=latitude)
        output.create_dataset("lon", data=longitude)
        merged = output.create_dataset(
            "data",
            shape=(latitude_count, longitude_count),
            dtype="i4",
            chunks=(120, 480),
            compression="gzip",
            compression_opts=4,
            shuffle=True,
            fillvalue=0,
        )
        # Place each native BIL tile from its world-file pixel-center coordinates.
        for tile_name in tile_names:
            stem = f"{tile_name}_acc_30s_bil/{tile_name}_acc_30s"
            tile_path = source / f"{stem}.bil"
            rows, columns, pixel_size, first_lon, first_lat = _bil_metadata(
                source / f"{stem}.hdr", source / f"{stem}.blw"
            )
            if not np.isclose(pixel_size, delta, rtol=0.0, atol=1e-10):
                raise ValueError(f"Unexpected ACC pixel size in {tile_path}: {pixel_size}")
            # HydroSHEDS files contain little-endian signed 32-bit integers.
            tile = np.fromfile(tile_path, dtype="<i4")
            if tile.size != rows * columns:
                raise ValueError(f"Unexpected BIL data size in {tile_path}: found {tile.size} cells")
            tile = tile.reshape(rows, columns)
            # Convert the upper-left pixel-center coordinates to ascending global-grid slices.
            first_column = int(round((first_lon - longitude[0]) / delta))
            last_row = int(round((first_lat - (rows - 1) * delta - latitude[0]) / delta))
            row_slice = slice(last_row, last_row + rows)
            column_slice = slice(first_column, first_column + columns)
            if row_slice.start < 0 or row_slice.stop > latitude_count or column_slice.start < 0 or column_slice.stop > longitude_count:
                raise ValueError(f"ACC tile {tile_path} extends outside the global geographic grid")
            # Flip north-to-south BIL rows and merge native pixels with MATLAB's maximum rule.
            tile = np.flipud(tile)
            previous = merged[row_slice, column_slice]
            merged[row_slice, column_slice] = np.maximum(previous, tile)
        # Record source metadata while leaving masking and normalization to load_layers.py.
        output.attrs["source_delta"] = delta
        output.attrs["source"] = str(source)
        output.attrs["nodata_policy"] = "uncovered cells are zero"
        output.attrs["merge_order"] = "native-resolution tiles merged by maximum"


def _read_uncompressed_float64_geotiff(source: Path) -> tuple[np.ndarray, dict[int, tuple[int, ...] | tuple[float, ...]]]:
    """Read the uncompressed, single-band float64 TIFF representation used by HMISea10."""
    # Read TIFF directory metadata directly because Pillow does not support this float64 file.
    file_bytes = source.read_bytes()
    byte_order = "<" if file_bytes[:2] == b"II" else ">" if file_bytes[:2] == b"MM" else None
    if byte_order is None:
        raise ValueError(f"Unsupported TIFF byte order in {source}")
    # Require classic TIFF and read its first image-file directory.
    if struct.unpack_from(f"{byte_order}H", file_bytes, 2)[0] != 42:
        raise ValueError(f"Only classic TIFF is supported for {source}")
    directory_offset = struct.unpack_from(f"{byte_order}I", file_bytes, 4)[0]
    entry_count = struct.unpack_from(f"{byte_order}H", file_bytes, directory_offset)[0]
    type_sizes = {1: 1, 3: 2, 4: 4, 12: 8}
    tag_values: dict[int, tuple[int, int, int | tuple[int, ...] | tuple[float, ...]]] = {}
    # Decode TIFF tag values, including arrays stored after the directory entries.
    for entry_index in range(entry_count):
        entry_offset = directory_offset + 2 + entry_index * 12
        tag, tag_type, value_count, value_offset = struct.unpack_from(
            f"{byte_order}HHII", file_bytes, entry_offset
        )
        if tag_type not in type_sizes:
            continue
        byte_count = value_count * type_sizes[tag_type]
        value_bytes = (
            file_bytes[entry_offset + 8 : entry_offset + 8 + byte_count]
            if byte_count <= 4
            else file_bytes[value_offset : value_offset + byte_count]
        )
        format_by_type = {1: "B", 3: "H", 4: "I", 12: "d"}
        unpacked = struct.unpack(f"{byte_order}{format_by_type[tag_type] * value_count}", value_bytes)
        tag_values[tag] = (tag_type, value_count, unpacked[0] if value_count == 1 else unpacked)
    # Validate the HMISea10 layout before interpreting its raster strips.
    width = int(tag_values[256][2])
    height = int(tag_values[257][2])
    bits_per_sample = int(tag_values[258][2])
    compression = int(tag_values[259][2])
    samples_per_pixel = int(tag_values[277][2])
    sample_format = int(tag_values[339][2])
    if (bits_per_sample, compression, samples_per_pixel, sample_format) != (64, 1, 1, 3):
        raise ValueError(f"Unsupported HMI TIFF encoding in {source}")
    strip_offsets = np.asarray(tag_values[273][2], dtype=np.int64)
    strip_byte_counts = np.asarray(tag_values[279][2], dtype=np.int64)
    rows_per_strip = int(tag_values[278][2])
    # Decode strips into a float64 array, then return only the GeoTIFF tags needed below.
    raster = np.empty((height, width), dtype=np.float64)
    for strip_index, (strip_offset, strip_size) in enumerate(zip(strip_offsets, strip_byte_counts)):
        strip = np.frombuffer(file_bytes, dtype=f"{byte_order}f8", count=strip_size // 8, offset=int(strip_offset))
        first_row = strip_index * rows_per_strip
        strip_rows = min(rows_per_strip, height - first_row)
        raster[first_row : first_row + strip_rows] = strip.reshape(strip_rows, width)
    decoded_tags = {tag: values[2] for tag, values in tag_values.items()}
    return raster.astype(np.float32), decoded_tags


def _cea_latitude(northing: float, semi_major_axis: float, flattening: float) -> float:
    """Invert the WGS84 cylindrical equal-area northing to geographic latitude."""
    # Compute the ellipsoid eccentricity used by the GeoTIFF's WGS84 projection.
    eccentricity = np.sqrt(2.0 * flattening - flattening**2)

    def northing_for_latitude(latitude_radians: float) -> float:
        # Evaluate the cylindrical equal-area ellipsoid function at one latitude.
        sine_latitude = np.sin(latitude_radians)
        denominator = 1.0 - eccentricity**2 * sine_latitude**2
        q_value = (1.0 - eccentricity**2) * (
            sine_latitude / denominator
            - np.log((1.0 - eccentricity * sine_latitude) / (1.0 + eccentricity * sine_latitude))
            / (2.0 * eccentricity)
        )
        return semi_major_axis * q_value / 2.0

    # Solve monotonically over the geographic latitude range for the raster row.
    return brentq(lambda latitude: northing_for_latitude(latitude) - northing, -np.pi / 2.0, np.pi / 2.0)


def convert_hmi(source: Path, destination: Path) -> None:
    """Save the native HMI pixels with geographic coordinates from its GeoTIFF tags."""
    # Decode pixels and georeferencing without resizing or applying normalization.
    raster, tags = _read_uncompressed_float64_geotiff(source)
    if 33550 not in tags or 33922 not in tags or 34735 not in tags or 34736 not in tags:
        raise ValueError(f"HMI GeoTIFF is missing required georeferencing tags: {source}")
    # Require the source's WGS84 cylindrical equal-area projection before applying its transform.
    geo_keys = np.asarray(tags[34735], dtype=np.int64).reshape(-1, 4)
    pixel_scale = np.asarray(tags[33550], dtype=np.float64)
    tie_points = np.asarray(tags[33922], dtype=np.float64).reshape(-1, 6)
    geo_doubles = np.asarray(tags[34736], dtype=np.float64)
    # Resolve GeoKey values stored directly or by offset into the GeoDoubleParams tag.
    key_values = {}
    for key, location, value_count, value_offset in geo_keys:
        if location == 0:
            key_values[int(key)] = (int(value_offset),)
        elif location == 34736:
            key_values[int(key)] = tuple(geo_doubles[value_offset : value_offset + value_count])
    transform_key = key_values.get(3075)
    geographic_key = key_values.get(2048)
    if transform_key is None or int(transform_key[0]) != 28 or geographic_key is None or int(geographic_key[0]) != 4326:
        raise ValueError(f"HMI GeoTIFF uses an unsupported projection in {source}")
    semi_major_axis = float(geo_doubles[5])
    inverse_flattening = float(geo_doubles[4])
    flattening = 1.0 / inverse_flattening
    raster_i, raster_j, _, model_x, model_y, _ = tie_points[0]
    # Pixel-is-area coordinates are centered by half a source pixel in each direction.
    pixel_columns = np.arange(raster.shape[1], dtype=np.float64) + 0.5 - raster_i
    pixel_rows = np.arange(raster.shape[0], dtype=np.float64) + 0.5 - raster_j
    projected_longitude = model_x + pixel_columns * pixel_scale[0]
    projected_northing = model_y - pixel_rows * pixel_scale[1]
    source_longitude = np.degrees(projected_longitude / semi_major_axis)
    source_latitude = np.array(
        [_cea_latitude(value, semi_major_axis, flattening) for value in projected_northing],
        dtype=np.float64,
    )
    # Reorder image rows and columns with their derived ascending geographic coordinates.
    latitude_order = np.argsort(source_latitude)
    longitude_order = np.argsort(source_longitude)
    raster = np.take(np.take(raster, latitude_order, axis=0), longitude_order, axis=1)
    source_latitude = source_latitude[latitude_order]
    source_longitude = source_longitude[longitude_order]
    # Save unmodified native values and exact source coordinates for load-time resampling.
    path = destination / "hmidata.h5"
    write_dataset(path, source_latitude, source_longitude, raster)
    with h5py.File(path, "a") as output:
        # Keep source projection details alongside the native geographic coordinate vectors.
        output.attrs["source"] = str(source)
        output.attrs["source_pixel_size_m"] = pixel_scale[0]
        output.attrs["source_projection"] = "WGS84 cylindrical equal-area"



def _normalise_longitude(longitude: np.ndarray) -> np.ndarray:
    """Wrap longitude coordinates to the interval [-180, 180)."""
    # Convert all source longitudes into the common global range.
    return ((np.asarray(longitude, dtype=np.float64) + 180.0) % 360.0) - 180.0


def _trace_coordinate_axis(dimensions: tuple[str, ...], coordinate: str) -> int:
    """Locate a coordinate axis within a NetCDF variable's dimension names."""
    # Support the conventional coordinate names used by TraCE NetCDF variables.
    aliases = {"latitude": ("lat", "latitude"), "longitude": ("lon", "longitude"), "time": ("time", "t")}[coordinate]
    # Return the first exact or prefixed dimension-name match.
    for axis, name in enumerate(dimensions):
        lowered = name.lower()
        if lowered in aliases or any(lowered.startswith(alias) for alias in aliases):
            return axis
    raise ValueError(f"Could not find the {coordinate} axis in dimensions {dimensions}.")


def _convert_trace_variable(
    source_path: Path,
    variable_name: str,
    destination: Path,
    sample_step: int,
) -> None:
    """Select every Nth NetCDF timestep without spatial resampling or normalization."""
    # Open each NetCDF source independently because variable metadata can differ.
    with netCDF4.Dataset(source_path) as source:
        source_variable = next(
            variable for variable in source.variables.values()
            if len(variable.dimensions) == 3
            and variable.name.lower() not in {"lat", "latitude", "lon", "longitude", "time"}
        )
        # Read coordinate arrays and sort them for spatial extent selection.
        coordinates = {name.lower(): name for name in source.variables}
        latitude_name = coordinates.get("lat", coordinates.get("latitude"))
        longitude_name = coordinates.get("lon", coordinates.get("longitude"))
        time_name = coordinates.get("time")
        if not all((latitude_name, longitude_name, time_name)):
            raise ValueError(f"Could not identify coordinates for {source_variable.name} in {source_path}.")
        source_latitude = np.asarray(source.variables[latitude_name][:], dtype=np.float64)
        source_longitude = _normalise_longitude(source.variables[longitude_name][:])
        source_time = np.asarray(source.variables[time_name][:], dtype=np.float64)
        latitude_order = np.argsort(source_latitude)
        longitude_order = np.argsort(source_longitude)
        source_latitude = source_latitude[latitude_order]
        source_longitude = source_longitude[longitude_order]
        # Retain every tenth source timestep while leaving the spatial axes unchanged.
        time_axis = _trace_coordinate_axis(tuple(source_variable.dimensions), "time")
        selected_time = np.arange(0, source_time.size, sample_step, dtype=np.int64)
        time_values = source_time[selected_time]
        if variable_name == "temp":
            # Convert the temperature source's thousand-year coordinate to calendar years.
            time_values = 1950.0 + time_values * 1000.0
        # Write selected source timesteps directly on their sorted NetCDF coordinate axes.
        output_path = destination / f"{variable_name}.h5"
        destination.mkdir(parents=True, exist_ok=True)
        with h5py.File(output_path, "w") as output:
            output.create_dataset("lat", data=source_latitude)
            output.create_dataset("lon", data=source_longitude)
            output.create_dataset("time", data=time_values)
            output_data = output.create_dataset(
                "data",
                shape=(time_values.size, source_latitude.size, source_longitude.size),
                dtype="f4",
                chunks=(1, source_latitude.size, source_longitude.size),
                compression="gzip",
                compression_opts=4,
                shuffle=True,
            )
            # Select and reorder each retained slice without changing its coordinate grid.
            for output_index, source_index in enumerate(selected_time):
                source_selection = tuple(
                    source_index if axis == time_axis else slice(None)
                    for axis in range(len(source_variable.dimensions))
                )
                # Preserve NetCDF missing values as NaNs for later finite-value normalization.
                raw_masked = np.ma.asarray(source_variable[source_selection], dtype=np.float32)
                raw = np.asarray(raw_masked.filled(np.nan), dtype=np.float32)
                spatial_dimensions = tuple(
                    name for axis, name in enumerate(source_variable.dimensions) if axis != time_axis
                )
                latitude_axis = _trace_coordinate_axis(spatial_dimensions, "latitude")
                longitude_axis = _trace_coordinate_axis(spatial_dimensions, "longitude")
                raw = np.take(raw, latitude_order, axis=latitude_axis)
                raw = np.take(raw, longitude_order, axis=longitude_axis)
                raw = np.moveaxis(raw, (latitude_axis, longitude_axis), (0, 1))
                output_data[output_index] = raw
            # Record the source and decimation settings without applying normalization.
            output.attrs["source"] = str(source_path)
            output.attrs["sample_step"] = sample_step
            output.attrs["sample_years"] = sample_step * 10


def convert_trace_netcdf(
    temperature_source: Path,
    precipitation_source: Path,
    destination: Path,
    sample_step: int = 10,
) -> None:
    """Write decimated TraCE NetCDF temperature and precipitation files."""
    # Validate temporal decimation before opening the source files.
    if sample_step <= 0:
        raise ValueError("sample_step must be a positive integer.")
    # Save both variables with their source coordinate grids unchanged.
    _convert_trace_variable(temperature_source, "temp", destination, sample_step)
    _convert_trace_variable(precipitation_source, "prec", destination, sample_step)


def convert_csi(source: Path, destination: Path) -> None:
    """Save the source CSI raster on a padded global grid at its native resolution."""
    # Read the original float-valued GeoTIFF without resampling or normalizing it.
    with Image.open(source) as image_file:
        source_data = np.asarray(image_file, dtype=np.float32)
    # Match the source resolution and global axis construction in build_geography.m.
    delta = 1.0 / 12.0
    latitude_count = round(180.0 / delta)
    longitude_count = round(360.0 / delta)
    if source_data.shape[1] != longitude_count or source_data.shape[0] > latitude_count:
        raise ValueError("The CSI GeoTIFF dimensions do not match the expected 1/12-degree global coverage.")
    # Flip the north-to-south TIFF rows and pad the uncovered northern latitude range with zeros.
    global_data = np.zeros((latitude_count, longitude_count), dtype=np.float32)
    global_data[: source_data.shape[0], :] = np.flipud(source_data)
    # Create ascending pixel-center axes at the unresampled GeoTIFF resolution.
    latitude = -90.0 + delta / 2.0 + np.arange(latitude_count) * delta
    longitude = -180.0 + delta / 2.0 + np.arange(longitude_count) * delta
    # Save the padded native-resolution source for load_layer to resample on demand.
    path = destination / "csi.h5"
    write_dataset(path, latitude, longitude, global_data)
    with h5py.File(path, "a") as output:
        output.attrs["source_delta"] = delta
        output.attrs["source"] = str(source)


def _select_columns(frame: pd.DataFrame, *names: str) -> pd.DataFrame:
    """Select named table columns while tolerating MATLAB-style header normalization."""
    # Normalize punctuation and case so Excel headers match their MATLAB field names.
    normalized = {"".join(character.lower() for character in str(column) if character.isalnum()): column for column in frame.columns}
    selected = []
    for name in names:
        # Resolve each requested field against the normalized source header names.
        key = "".join(character.lower() for character in name if character.isalnum())
        if key not in normalized:
            raise ValueError(f"Required column {name!r} was not found in input table.")
        selected.append(normalized[key])
    # Return only the required columns in the requested order.
    return frame.loc[:, selected]


def _load_pinhasi(source: Path) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    """Load Pinhasi SITE rows and convert radiocarbon years like get_dataset.m."""
    # Skip the workbook's citation row so pandas reads the actual column names.
    table = pd.read_excel(source, engine="xlrd", header=1)
    # MATLAB calls the source's unnamed first column Var1, so select it by position.
    site_rows = table.loc[table.iloc[:, 0].astype(str).str.strip() == "SITE"]
    records = _select_columns(site_rows, "Latitude", "Longitude", "CALC14BP")
    # Apply the same BP-to-calendar-year conversion used by get_dataset.m.
    return records.iloc[:, 0].to_numpy(), records.iloc[:, 1].to_numpy(), 1950.0 - records.iloc[:, 2].to_numpy()


def _load_wheat(source: Path) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    """Load and concatenate Pinhasi and De Souza wheat records."""
    # Read the Pinhasi workbook and convert its dates using the MATLAB rule.
    pinhasi = _load_pinhasi(source / "pinhasi" / "Neolithic_timing_Europe_PLOS.xls")
    # Read the De Souza CSV and select its coordinate and BP columns.
    de_souza_table = pd.read_csv(source / "de_souza_wheat_data" / "dates.csv")
    de_souza = _select_columns(de_souza_table, "Latitude", "Longitude", "bp")
    # Append De Souza records after Pinhasi records, matching get_dataset.m order.
    return (
        np.concatenate((pinhasi[0], de_souza.iloc[:, 0].to_numpy())),
        np.concatenate((pinhasi[1], de_souza.iloc[:, 1].to_numpy())),
        np.concatenate((pinhasi[2], 1950.0 - de_souza.iloc[:, 2].to_numpy())),
    )


def _load_rice(source: Path) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    """Load Cobo rice records from the workbook's S1 Table."""
    # Read the S1 Table with its header row, matching the MATLAB Cobo table fields.
    table = pd.read_excel(source / "cobo_etal" / "cobo_etal_data.xlsx", sheet_name="S1 Table", header=4)
    # Select coordinates and the estimated date mean used by get_dataset.m.
    records = _select_columns(table, "Latitude", "Longitude", "Est_DateMean_BC_AD_")
    # Return the table values without date conversion, as the MATLAB source does.
    return records.iloc[:, 0].to_numpy(), records.iloc[:, 1].to_numpy(), records.iloc[:, 2].to_numpy()


def _load_maize(source: Path) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    """Load the calibrated maize dates in get_dataset.m order."""
    # Calendar years from the IntCal20 calibration of the radiocarbon ages
    # (python/calibrate_maize_dates.py): the cleaned Hart rows, then the
    # earliest Zea mays date at each unique p3k14c coordinate.
    table = pd.read_csv(source / "hart_maize" / "maize_calibrated_intcal20.csv")
    records = _select_columns(table, "lat", "lon", "year_cal")
    return records.iloc[:, 0].to_numpy(), records.iloc[:, 1].to_numpy(), records.iloc[:, 2].to_numpy()


def convert_crops(source: Path, destination: Path, delta: float = 0.5, padding: float = 5.0) -> None:
    """Save each source dataset as coordinate vectors and MATLAB-style indices."""
    # Map requested output crop names to the datasets used by get_dataset.m.
    crop_loaders = {"wheat": _load_wheat, "rice": _load_rice, "maize": _load_maize}
    # Reject invalid grid spacing and padding before reading any source files.
    if delta <= 0.0:
        raise ValueError("delta must be positive.")
    if padding < 0.0:
        raise ValueError("padding must be non-negative.")
    for crop_name, loader in crop_loaders.items():
        # Load latitude, longitude, and time arrays from the matching raw sources.
        latitude, longitude, time = (np.asarray(values, dtype=np.float64).reshape(-1) for values in loader(source))
        # Require aligned, finite event records so all three index columns are defined.
        if not (latitude.size == longitude.size == time.size):
            raise ValueError(f"Dataset {crop_name} has misaligned latitude, longitude, and time arrays.")
        valid_records = np.isfinite(latitude) & np.isfinite(longitude) & np.isfinite(time)
        if not np.all(valid_records):
            # Warn about discarded rows and keep all coordinate arrays aligned.
            warnings.warn(
                f"Dataset {crop_name}: removing {np.count_nonzero(~valid_records)} record(s) with non-finite coordinates or times.",
                RuntimeWarning,
                stacklevel=2,
            )
            latitude = latitude[valid_records]
            longitude = longitude[valid_records]
            time = time[valid_records]
        if latitude.size == 0:
            raise ValueError(f"Dataset {crop_name} contains no records.")
        # Define the spatial extent from observed coordinates plus the requested padding.
        latitude_extent = np.clip([latitude.min() - padding, latitude.max() + padding], -90.0, 90.0)
        longitude_extent = np.clip([longitude.min() - padding, longitude.max() + padding], -180.0, 180.0)
        # Construct regional coordinate axes using the requested global grid spacing.
        global_latitude = np.arange(-90.0 + delta / 2.0, 90.0, delta)
        global_longitude = np.arange(-180.0 + delta / 2.0, 180.0, delta)
        selected_latitude = np.flatnonzero((global_latitude >= latitude_extent[0]) & (global_latitude <= latitude_extent[1]))
        selected_longitude = np.flatnonzero((global_longitude >= longitude_extent[0]) & (global_longitude <= longitude_extent[1]))
        if selected_latitude.size == 0 or selected_longitude.size == 0:
            raise ValueError(f"Dataset {crop_name} extent does not contain any grid points at delta={delta}.")
        # Map observations to the nearest global grid coordinate, clipped to the regional axes.
        latitude_grid_indices = np.rint((latitude - global_latitude[0]) / delta).astype(np.int64)
        longitude_grid_indices = np.rint((longitude - global_longitude[0]) / delta).astype(np.int64)
        latitude_grid_indices = np.clip(latitude_grid_indices, selected_latitude[0], selected_latitude[-1])
        longitude_grid_indices = np.clip(longitude_grid_indices, selected_longitude[0], selected_longitude[-1])
        # Convert zero-based grid offsets to one-based MATLAB-compatible regional indices.
        latitude_indices = latitude_grid_indices - selected_latitude[0] + 1
        longitude_indices = longitude_grid_indices - selected_longitude[0] + 1
        # Match data_prep.m's 40-year temporal grid and its 1000-year trailing horizon.
        time_step = 40.0
        start_time = np.floor(time.min() / time_step) * time_step
        end_time = np.ceil(time.max() / time_step) * time_step + 1000.0
        time_indices = np.floor((time - start_time) / time_step + 0.5).astype(np.int64) + 1
        # Assemble one MATLAB-compatible [latitude, longitude, time] index row per record.
        indices = np.column_stack((latitude_indices, longitude_indices, time_indices))
        # Write point coordinates, indices, extent, and grid metadata without saving grid axes.
        path = destination / f"{crop_name}.h5"
        path.parent.mkdir(parents=True, exist_ok=True)
        with h5py.File(path, "w") as output:
            output.create_dataset("lat", data=latitude)
            output.create_dataset("lon", data=longitude)
            output.create_dataset("time", data=time)
            output.create_dataset("index", data=indices)
            output.create_dataset("lat_extent", data=latitude_extent)
            output.create_dataset("lon_extent", data=longitude_extent)
            output.create_dataset("padding", data=padding)
            output.create_dataset("delta", data=delta)
            output.create_dataset("time_step", data=time_step)
            output.create_dataset("start_time", data=start_time)
            output.create_dataset("end_time", data=end_time)


if __name__ == "__main__":
    # Retain the MATLAB geography product only for the latitude-weight layer.
    convert_geography(Path("data/prep/geography_0p5deg.mat"), Path("data/processed"))
    # Preserve the native SAGE, HydroSHEDS, and HMI source data without normalization.
    convert_sea(Path("data/raw/SAGE/land_suit/land_suit_0.50x0.50.nc"), Path("data/processed"))
    convert_acc(Path("data/raw/HydroSHEDS/ACC"), Path("data/processed"))
    convert_hmi(Path("data/raw/HMI/HMISea10.tif"), Path("data/processed"))
    # Convert source NetCDF traces using every tenth timestep without normalization.
    # convert_trace_netcdf(
    #     Path("data/raw/trace/TraCE-21K-II.ann.TS.nc"),
    #     Path("data/raw/trace/TraCE-21K-II.ann.PRECT.nc"),
    #     Path("data/processed"),
    #     sample_step=10,
    # )
    # # Preserve CSI's 1/12-degree source resolution and defer normalization to the loader.
    convert_csi(Path("data/raw/csi/pre1500OptCalories.tif"), Path("data/processed/"))
    # # Generate event point objects from the MATLAB dataset sources with five-degree padding.
    # # convert_crops(Path("data/raw"), Path("data/processed/crop"), delta=0.5, padding=5.0)

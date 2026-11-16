"""Convert TraCE NetCDF variables to a spatially interpolated HDF5 dataset."""

# Import the command-line and path utilities used by the conversion script.
import argparse
from pathlib import Path

# Import numerical and file-format dependencies used for chunked conversion.
import h5py
import netCDF4
import numpy as np
from scipy.interpolate import RegularGridInterpolator


def parse_args() -> argparse.Namespace:
    """Parse conversion options supplied on the command line."""
    # Define the command-line parser and its documented defaults.
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--temperature", type=Path, required=True)
    parser.add_argument("--precipitation", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--delta", type=float, default=0.5)
    parser.add_argument("--sample-years", type=int, default=100)
    parser.add_argument("--input-years", type=int, default=10)
    return parser.parse_args()


def normalise_longitude(longitude: np.ndarray) -> np.ndarray:
    """Convert longitudes to the interval [-180, 180) and sort them."""
    # Wrap longitudes and return the sorted coordinate vector.
    return ((np.asarray(longitude, dtype=np.float64) + 180.0) % 360.0) - 180.0


def target_grid(delta: float) -> tuple[np.ndarray, np.ndarray]:
    """Build the global cell-centre grid used by the existing workflow."""
    # Place grid-cell centres half a cell away from the geographic boundaries.
    latitude = np.arange(-90.0 + delta / 2.0, 90.0, delta)
    longitude = np.arange(-180.0 + delta / 2.0, 180.0, delta)
    return latitude, longitude


def variable_axes(dataset: netCDF4.Dataset, variable: netCDF4.Variable) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    """Read and identify the latitude, longitude, and time coordinate arrays."""
    # Prefer coordinate variables named by their standard NetCDF conventions.
    dimensions = tuple(variable.dimensions)
    coordinate_names = {name.lower(): name for name in dataset.variables}
    latitude_name = coordinate_names.get("lat", coordinate_names.get("latitude"))
    longitude_name = coordinate_names.get("lon", coordinate_names.get("longitude"))
    time_name = coordinate_names.get("time")
    if not all((latitude_name, longitude_name, time_name)):
        raise ValueError(f"Could not identify coordinate variables for dimensions {dimensions}.")
    # Return coordinates as floating-point arrays for interpolation and metadata.
    return (
        np.asarray(dataset.variables[latitude_name][:], dtype=np.float64),
        normalise_longitude(dataset.variables[longitude_name][:]),
        np.asarray(dataset.variables[time_name][:], dtype=np.float64),
    )


def coordinate_axis(dimensions: tuple[str, ...], coordinate: str) -> int:
    """Find a latitude, longitude, or time axis from common NetCDF names."""
    # Accept conventional names as well as names with prefixes or suffixes.
    aliases = {
        "latitude": ("lat", "latitude"),
        "longitude": ("lon", "longitude"),
        "time": ("time", "t"),
    }[coordinate]
    return next(
        index for index, name in enumerate(dimensions)
        if name.lower() in aliases or any(name.lower().startswith(alias) for alias in aliases)
    )


def reorder_data(
    data: np.ndarray,
    variable_dimensions: tuple[str, ...],
    latitude_order: np.ndarray,
    longitude_order: np.ndarray,
) -> np.ndarray:
    """Sort source coordinates and return one timestep as latitude-by-longitude."""
    # Locate spatial axes in the original two-dimensional slice.
    latitude_axis = coordinate_axis(variable_dimensions, "latitude")
    longitude_axis = coordinate_axis(variable_dimensions, "longitude")
    # Apply each coordinate permutation to its own axis before transposing.
    data = np.take(data, latitude_order, axis=latitude_axis)
    data = np.take(data, longitude_order, axis=longitude_axis)
    return np.moveaxis(data, (latitude_axis, longitude_axis), (0, 1))


def convert_variable(
    source_path: Path,
    variable_name: str,
    output: h5py.File,
    latitude: np.ndarray,
    longitude: np.ndarray,
    sample_step: int,
) -> None:
    """Interpolate one NetCDF variable and write it one timestep at a time."""
    # Open the source independently so temperature and precipitation can differ slightly in metadata.
    with netCDF4.Dataset(source_path) as source:
        source_variable = next(
            variable for variable in source.variables.values()
            if len(variable.dimensions) == 3 and variable.name not in {"lat", "latitude", "lon", "longitude", "time"}
        )
        source_latitude, source_longitude, source_time = variable_axes(source, source_variable)
        selected_time = np.arange(0, len(source_time), sample_step, dtype=np.int64)
        time_values = source_time[selected_time]
        if variable_name == "temp":
            # TraCE temperature time coordinates are represented in thousands of years in the source files.
            time_values = 1950.0 + time_values * 1000.0

        # Sort source longitude and latitude so RegularGridInterpolator receives ascending axes.
        longitude_order = np.argsort(source_longitude)
        latitude_order = np.argsort(source_latitude)
        source_longitude = source_longitude[longitude_order]
        source_latitude = source_latitude[latitude_order]
        shape = (len(time_values), len(latitude), len(longitude))
        dataset = output.create_dataset(
            variable_name,
            shape=shape,
            dtype="f4",
            chunks=(1, len(latitude), len(longitude)),
            compression="gzip",
            compression_opts=4,
            shuffle=True,
        )
        # Interpolate each retained timestep without materialising the complete 3-D source array.
        mesh_longitude, mesh_latitude = np.meshgrid(longitude, latitude)
        query_points = np.column_stack((mesh_latitude.ravel(), mesh_longitude.ravel()))
        time_axis = coordinate_axis(source_variable.dimensions, "time")
        for output_index, source_index in enumerate(selected_time):
            # Select one timestep regardless of whether time is the first, second, or third axis.
            source_selection = tuple(
                source_index if index == time_axis else slice(None)
                for index in range(len(source_variable.dimensions))
            )
            raw = np.asarray(source_variable[source_selection], dtype=np.float32)
            spatial_dimensions = tuple(
                name for index, name in enumerate(source_variable.dimensions) if index != time_axis
            )
            raw = reorder_data(raw, spatial_dimensions, latitude_order, longitude_order)
            interpolator = RegularGridInterpolator(
                (source_latitude, source_longitude), raw, method="linear", bounds_error=False, fill_value=np.nan
            )
            interpolated = interpolator(query_points).reshape(len(latitude), len(longitude))
            # Normalize this time slice independently, ignoring interpolation NaNs.
            mean = np.nanmean(interpolated)
            std = np.nanstd(interpolated)
            if std == 0.0:
                raise ValueError(f"Variable {variable_name} has a zero-variance time slice.")
            dataset[output_index] = (interpolated - mean) / std
        dataset.attrs["source"] = str(source_path)
        dataset.attrs["sample_step"] = sample_step
        dataset.attrs["sample_years"] = sample_step * 10


def main() -> None:
    """Convert both TraCE variables into one queryable HDF5 file."""
    # Parse options and validate the requested temporal sampling ratio.
    arguments = parse_args()
    if arguments.sample_years % arguments.input_years != 0:
        raise ValueError("sample-years must be an integer multiple of input-years.")
    sample_step = arguments.sample_years // arguments.input_years
    latitude, longitude = target_grid(arguments.delta)
    arguments.output.parent.mkdir(parents=True, exist_ok=True)
    # Write coordinates and variables with HDF5 compression and chunking.
    with h5py.File(arguments.output, "w") as output:
        output.create_dataset("lat", data=latitude)
        output.create_dataset("lon", data=longitude)
        convert_variable(arguments.temperature, "temp", output, latitude, longitude, sample_step)
        convert_variable(arguments.precipitation, "prec", output, latitude, longitude, sample_step)
        output.attrs["description"] = "TraCE data spatially interpolated and temporally decimated."
        output.attrs["sample_years"] = arguments.sample_years


if __name__ == "__main__":
    # Run the conversion when this file is executed as a script.
    main()

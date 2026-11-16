# Geography and TraCE data processing

This document describes the Python processing pipeline that creates standardized
HDF5 files under `data/processed/`. No MATLAB files are modified.

## Standardized files

Static geography layers are stored in separate files:

- `W.h5`
- `csidata.h5`
- `acc.h5`
- `sea.h5`
- `hmidata.h5`

TraCE variables are stored in:

- `temp.h5`
- `prec.h5`

Each file contains `lat`, `lon`, and `data` datasets. Static data uses
latitude-by-longitude order. Trace data additionally contains `time` and uses
time-by-latitude-by-longitude order. HDF5 compression is used for data arrays.
Crop point datasets are also stored separately as `wheat.h5`, `maize.h5`, and
`rice.h5`; their format is described below.

## TraCE processing

The source files are `data/raw/trace/TraCE-21K-II.ann.TS.nc` and
`data/raw/trace/TraCE-21K-II.ann.PRECT.nc`.

The source timestep is 10 years. Every tenth timestep is retained, producing
100-year spacing. Values are decimated rather than averaged across the ten
source timesteps.

Both variables are interpolated onto the global 0.5-degree grid:

- Latitude centres: `-89.75` through `89.75` degrees.
- Longitude centres: `-179.75` through `179.75` degrees.

Temperature and precipitation are normalized independently after interpolation.
Each retained time slice is normalized separately to mean zero and standard
deviation one. NaN interpolation values remain NaN and are excluded from the
per-slice statistics. The resulting HDF5 files support partial reads.

The implementation is in `trace_to_hdf5.py`. The existing resampled trace file
was split into the standardized `temp.h5` and `prec.h5` files, with the 100-year
time coordinate restored from the original NetCDF coordinate.

## Static geography layers

`convert_layers_to_hdf5.py` extracts most static layers from
`data/prep/geography_0p5deg.mat`. MATLAB v7.3 arrays are transposed during
conversion to produce the common latitude-by-longitude layout.

The CSI layer comes from `data/raw/csi/pre1500OptCalories.tif`. The converter
pads its northern edge to a global grid and stores the unnormalized raster at
its native 1/12-degree resolution in `csidata.h5`. `load_layer` resizes it to
the requested `delta` with Pillow bicubic interpolation, clips negative values,
normalizes using land cells, and sets sea cells to zero. The default `delta` is
0.5 degrees, matching `build_geography.m`. For `acc`, statistics are calculated
from land cells using the explicit sea mask; land values are normalized and
sea cells are set to zero.

Crop point files follow the source selection in `src/get_dataset.m`:

- Wheat combines Pinhasi `SITE` rows and De Souza wheat records.
- Rice reads the Cobo workbook's `S1 Table` sheet.
- Maize combines the cleaned maize workbook with earliest per-location dates
  from `p3k14c_2022.06.csv` rows whose taxa contain `Zea mays`.

Each separate crop HDF5 file contains aligned `lat`, `lon`, and `time` arrays,
plus an `index` matrix with one-based `[latitude_index, longitude_index,
time_index]` rows. The spatial index axes use the function's `delta` (default
0.5 degrees) and the observed coordinate bounds expanded by `padding` (default
5 degrees). The time index uses the 40-year step and 1000-year trailing horizon
from `data_prep.m`. The file stores `lat_extent`, `lon_extent`, `padding`,
`delta`, `time_step`, `start_time`, and `end_time`; the regional grid vectors
are not stored. The converter warns and drops a record if its latitude,
longitude, or time is non-finite; all three point arrays and the index matrix
remain aligned.

## Loading geography layers

Use `load_layer` from `load_layers.py`:

```python
from load_layers import load_layer

layer = load_layer("acc", (15.0, 60.0), (-17.0, 65.0))
data = layer["data"]
lat = layer["lat"]
lon = layer["lon"]
```

For trace data, omitting `year_extent` averages over all years:

```python
precipitation = load_layer("prec", (15.0, 60.0), (-17.0, 65.0))
```

To average over an inclusive year range:

```python
temperature = load_layer(
    "temp", (15.0, 60.0), (-17.0, 65.0), year_extent=(-1000.0, 1000.0)
)
```

`year_extent` applies only to `temp` and `prec`.

For the native-resolution CSI source, request a resolution with `delta`:

```python
csi = load_layer("csidata", (15.0, 60.0), (-17.0, 65.0), delta=0.5)
```

The `delta` argument currently applies to `csidata`; other layers retain the
resolution stored in their HDF5 files. CSI is downsampled with Pillow's bicubic
resampler, then clipped and normalized against the sea mask at the target grid.

## Loading crop data

Use `load_data` from `load_data.py` to load a crop point file:

```python
from load_data import load_data

crop = load_data("wheat")
lat = crop["lat"]
lon = crop["lon"]
time = crop["time"]
indices = crop["index"]
lat_extent = crop["lat_extent"]
lon_extent = crop["lon_extent"]
```

The coordinate arrays and extents use degrees. Each row of `indices` matches
the corresponding coordinate row and contains one-based regional latitude,
longitude, and time indices. The returned object also includes `padding`,
`delta`, `time_step`, `start_time`, and `end_time`. Grid coordinate vectors
are not stored in the HDF5 file; use the stored extents and `delta` to
reconstruct the spatial axes.

## Dependencies and regeneration

The scripts require `numpy`, `h5py`, `netCDF4`, `scipy`, `pandas`, `openpyxl`,
`xlrd` (for reading the legacy Pinhasi `.xls` workbook), and `Pillow`.

Regenerate standardized files with:

```powershell
.venv\Scripts\python.exe python\convert_layers_to_hdf5.py
```

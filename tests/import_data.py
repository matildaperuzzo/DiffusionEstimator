#  import data from /Users/mperuzzo/Documents/repos/bottlenecks/data/raw/SAGE/land_suit/land_suit_0p50x0p50.nc
import xarray as xr
filepath = '/Users/mperuzzo/Documents/repos/bottlenecks/data/raw/SAGE/land_suit/land_suit_0p50x0p50.nc'
data = xr.open_dataset(filepath)
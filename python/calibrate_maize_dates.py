"""Calibrate the maize radiocarbon dates with IntCal20.

The maize sources report conventional radiocarbon ages (14C yr BP), while the
wheat (Pinhasi CALC14BP, de Souza bp) and rice (Cobo Est_DateMean) dates are
already calibrated. This script calibrates every maize date that
src/get_dataset.m loads, so that all three crops enter the fits as calendar
years.

Method: the standard probability calibration used by OxCal, rcarbon and Bchron.
On a one-year cal BP grid, the calibrated density of a date is proportional to
N(c14_age; mu(t), sqrt(err^2 + sigma(t)^2)), where mu and sigma are the IntCal20
curve and its error (Reimer et al. 2020, Radiocarbon 62,
doi:10.1017/RDC.2020.41; Northern Hemisphere, as all sites lie between 15 and
51 degrees N). The point estimate is the median of that density, and the
arrival year is 1950 minus the median.

Rows, in the order get_dataset.m returns them:
  1. MaizeDataset_cleaned.xlsx (Hart), in file order. The date is the
     "14C age" column. Its "Year" column is 2000 minus that age and is not
     used. The lab error comes from the p3k14c record with the same site
     trinomial and age; rows without a match get the median matched error.
  2. p3k14c_2022.06.csv, Zea mays records with an age and coordinates, one
     row per unique (Lat, Long), sorted by Lat and then Long as MATLAB's
     unique(..., 'rows') does. At each coordinate the date with the earliest
     calibrated median is kept.

Run from the repository root:
    python python/calibrate_maize_dates.py
Writes data/raw/hart_maize/maize_calibrated_intcal20.csv (829 rows).
"""
from pathlib import Path

import numpy as np
import pandas as pd

SOURCE = Path("data/raw/hart_maize")
CURVE = SOURCE / "intcal20.14c"
OUTPUT = SOURCE / "maize_calibrated_intcal20.csv"

# IntCal20 on a one-year grid from 0 to 20,000 cal BP.
curve = pd.read_csv(CURVE, comment="#", header=None,
                    names=["calbp", "c14", "sigma", "delta14c", "delta14c_sigma"])
curve = curve.sort_values("calbp")
GRID = np.arange(0, 20001)
MU = np.interp(GRID, curve.calbp, curve.c14)
SIGMA = np.interp(GRID, curve.calbp, curve.sigma)


def calibrate(age, err):
    """Return median, mean and 95% range (cal BP) of the calibrated density."""
    s = np.sqrt(err ** 2 + SIGMA ** 2)
    density = np.exp(-0.5 * ((age - MU) / s) ** 2) / s
    density /= density.sum()
    cdf = np.cumsum(density)
    median = GRID[np.searchsorted(cdf, 0.5)]
    mean = (GRID * density).sum()
    low, high = GRID[np.searchsorted(cdf, 0.025)], GRID[np.searchsorted(cdf, 0.975)]
    return median, mean, low, high


# Hart rows, with lab errors matched from p3k14c by site trinomial and age.
hart = pd.read_excel(SOURCE / "MaizeDataset_cleaned.xlsx")
# round_trip parsing gives the same doubles as MATLAB's readtable, so the
# coordinates written below equal the ones the uncalibrated loader read.
p3k = pd.read_csv(SOURCE / "p3k14c_2022.06.csv", low_memory=False, float_precision="round_trip")
p3k["site_key"] = p3k["SiteID"].astype(str).str.strip().str.upper()
hart["site_key"] = hart["County"].astype(str).str.strip().str.upper()
matched_error = p3k.groupby(["site_key", "Age"])["Error"].min()
hart["err"] = [matched_error.get((k, a), np.nan) for k, a in zip(hart.site_key, hart["14C age"])]
hart["err_src"] = np.where(hart.err.notna(), "p3k14c match", "assumed")
default_error = float(np.nanmedian(hart.err))
hart["err"] = hart.err.fillna(default_error)
rows_hart = pd.DataFrame({
    "source": "Hart", "site": hart.County, "lat": hart.Latitude, "lon": hart.Longitude,
    "c14": hart["14C age"], "err": hart.err, "err_src": hart.err_src, "n_dates": 1,
})

# p3k14c Zea mays rows: the earliest calibrated date at each unique coordinate.
maize = p3k[p3k["Taxa"].fillna("").str.lower().str.contains("zea mays")].copy()
maize = maize.dropna(subset=["Age", "Lat", "Long"])
maize["err"] = [e if e == e and e > 0 else default_error for e in maize.Error]
maize["median"] = [calibrate(a, e)[0] for a, e in zip(maize.Age, maize.err)]
rows_p3k = []
for (lat, lon), group in maize.groupby(["Lat", "Long"], sort=True):
    best = group.loc[group["median"].idxmax()]
    rows_p3k.append({"source": "p3k14c", "site": best.SiteName, "lat": lat, "lon": lon,
                     "c14": best.Age, "err": best.err, "err_src": "p3k14c",
                     "n_dates": len(group)})
rows_p3k = pd.DataFrame(rows_p3k)

out = pd.concat([rows_hart, rows_p3k], ignore_index=True)
cal = [calibrate(a, e) for a, e in zip(out.c14, out.err)]
out["calbp_median"] = [c[0] for c in cal]
out["calbp_mean"] = [round(c[1], 1) for c in cal]
out["calbp_lo95"] = [c[2] for c in cal]
out["calbp_hi95"] = [c[3] for c in cal]
out["year_cal"] = 1950 - out.calbp_median
out.to_csv(OUTPUT, index=False)

print(f"Hart rows: {len(rows_hart)} ({(hart.err_src == 'p3k14c match').sum()} with a matched lab "
      f"error; the rest get +-{default_error:g})")
print(f"p3k14c coordinates: {len(rows_p3k)}")
print(f"wrote {OUTPUT} ({len(out)} rows); earliest year {out.year_cal.min()}, "
      f"latest {out.year_cal.max()}")

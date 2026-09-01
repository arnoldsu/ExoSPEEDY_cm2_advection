#!/usr/bin/env python3
"""Prepare a 12-month ACCESS-CM2 0-40 m advection forcing for T30 SPEEDY."""
from __future__ import annotations
import argparse
from pathlib import Path
import numpy as np
import xarray as xr
from scipy.spatial import cKDTree

DEFAULT_INPUT = ("/g/data/p66/ars599/work_ryan/atm_analysis/ocn_data/"
                 "temp_advection_Omon_bj594_piControl_r1i1p1_0001-0100.nc")

def arguments():
    p = argparse.ArgumentParser()
    p.add_argument("--input", default=DEFAULT_INPUT)
    p.add_argument("--output-dir", default="cm2_advection_forcing/output")
    p.add_argument("--start-year", type=int, default=1985)
    p.add_argument("--end-year", type=int, default=2014)
    p.add_argument("--depth", type=float, default=40.0)
    return p.parse_args()

def remap(field, src_lon, src_lat, dst_lon, dst_lat):
    valid = np.isfinite(field) & np.isfinite(src_lon) & np.isfinite(src_lat)
    lon, lat, val = np.mod(src_lon[valid], 360.0), src_lat[valid], field[valid]
    points = np.column_stack([np.concatenate((lon-360, lon, lon+360)),
                              np.concatenate((lat, lat, lat))])
    values = np.tile(val, 3)
    xx, yy = np.meshgrid(dst_lon, dst_lat)
    # Robust nearest-ocean mapping supplies values near mismatched coastlines.
    # The Fortran reader subsequently sets SPEEDY land points to zero.
    _, index = cKDTree(points).query(np.column_stack((xx.ravel(), yy.ravel())))
    return values[index].reshape(xx.shape).astype(np.float32)

def main():
    a = arguments()
    output = Path(a.output_dir)
    output.mkdir(parents=True, exist_ok=True)
    ds = xr.open_dataset(a.input, chunks={"time": 12, "st_ocean": 4})
    var = ds["temp_advection"]
    levels = ds.st_ocean.where(ds.st_ocean < a.depth, drop=True)
    expected = np.array([5., 15., 25., 35.])
    if not np.allclose(levels.values, expected):
        raise ValueError(f"Expected layer centres {expected}; got {levels.values}")
    selected = var.sel(time=slice(f"{a.start_year}-01-01",
                                  f"{a.end_year}-12-31"),
                       st_ocean=levels)
    if selected.sizes["time"] == 0:
        raise ValueError("Requested year range contains no records")
    upper40 = selected.sum("st_ocean", skipna=True).where(
        selected.notnull().any("st_ocean"))
    # analysis3-26.01 currently has an optional flox/numba version conflict.
    # Native xarray aggregation is deterministic and avoids that dependency.
    with xr.set_options(use_flox=False):
        clim = upper40.groupby("time.month").mean(
            "time", skipna=True).compute()
    roots, _ = np.polynomial.legendre.leggauss(48)
    dst_lat = np.degrees(np.arcsin(roots))[::-1]
    dst_lon = np.arange(96, dtype=float) * 3.75
    fields = np.empty((12, 48, 96), dtype=np.float32)
    for month in range(1, 13):
        fields[month-1] = remap(clim.sel(month=month).values,
                                ds.geolon_t.values, ds.geolat_t.values,
                                dst_lon, dst_lat)
    out_nc = output/"qadv_cm2_0_40m_clim.t30.nc"
    out_grd = output/"qadv_cm2_0_40m_clim.t30.grd"
    result = xr.Dataset(
        {"qadv": (("month", "lat", "lon"), fields)},
        coords={"month": np.arange(1, 13), "lat": dst_lat, "lon": dst_lon},
        attrs={"source": str(Path(a.input).resolve()),
               "source_years": f"{a.start_year}-{a.end_year}",
               "processing": "sum 5,15,25,35m; monthly climatology; nearest-ocean T30 remap"})
    result.qadv.attrs.update(units="W m-2",
        long_name="ACCESS-CM2 0-40m ocean-advection heat convergence")
    result.to_netcdf(out_nc)
    fields.astype(">f4").tofile(out_grd)
    print(f"Wrote {out_nc}")
    print(f"Wrote {out_grd} ({out_grd.stat().st_size} bytes)")
    print(f"Range: {np.nanmin(fields):.3f} to {np.nanmax(fields):.3f} W m-2")

if __name__ == "__main__":
    main()

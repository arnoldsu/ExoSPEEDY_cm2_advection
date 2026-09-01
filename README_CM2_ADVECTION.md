# ExoSPEEDY with ACCESS-CM2 ocean-advection forcing

This independent copy does not modify the original ExoSPEEDY.

## Lightweight GitHub checkout

Generated model output, restart files, build products and logs are excluded
from Git. The local Gadi checkout uses symbolic links for the large SPEEDY
data/hflux directories and for the prepared CM2 forcing. These linked data
files are not stored in GitHub. On another system, provide the SPEEDY input
data separately and run the Python preparation script to regenerate forcing.

## Configuration

The source temp_advection values are already cp*rho*dz*tendency in W m-2.
The preparation script sums the 5, 15, 25 and 35 m layers (0-40 m),
calculates the final-30-year (1985-2014) monthly climatology, and remaps it
to T30 using nearest valid ocean cells. The Fortran reader then applies the
SPEEDY Earth land-sea mask and sets forcing to zero over land.

The model uses:

    dSST/dt = (Q_atmosphere + Q_advection_CM2) / (rho*cp*40m)

The model uses SPEEDY's original Earth land-sea mask, topography, albedo,
land temperature, snow, vegetation and soil-moisture boundary data. CM2
advection is set to zero at land points. Idealised HORDIFSEA diffusion is
disabled to prevent double counting.

The original SPEEDY land/sea weighted surface-flux routines and seasonal
Earth radiation are restored. The ExoSPEEDY aquaplanet-only surface-flux
and fixed-equinox radiation replacements are not used in experiment 107.
SPEEDY's FORIN5 routine interpolates smoothly between monthly means.

## One-command run

    cd /g/data/p66/ars599/MODEL/speedy/ExoSPEEDY_cm2_advection
    ./submit_all.sh

The forcing job runs first. Experiment 107 starts automatically after it
succeeds; there are no interactive model questions.

The model job loads intel-compiler/2021.10.0 and verifies that the restart
file exists, so a compiler failure cannot be reported as a successful run.

Monitor with:

    qstat -u "$USER"
    tail -f logs/prepare.out
    tail -f logs/model.out

Model output is in output/exp_107. Prepared forcing is in
cm2_advection_forcing/output as both NetCDF and SPEEDY .grd files.
The PBS model job automatically converts all GrADS output groups to NetCDF
after a successful run. Existing output can be converted manually with:

    ./convert_output_to_netcdf.sh output/exp_107

Experiment 107 is configured for one year (NMONTS=12), starting at
2000-01-01. It runs from a fresh initial state rather than a restart.

## Manual preparation

    module use /g/data/xp65/public/modules
    module load conda/analysis3-26.01
    python cm2_advection_forcing/prepare_cm2_advection.py

Use --start-year and --end-year to select another climatology period.

## Implementation

- update/ini_inbcon.f reads 12 direct-access forcing records from unit 32.
- update/cpl_sea.f performs daily interpolation.
- update/cpl_sea_model.f adds CM2 advection to the surface heat flux.
- update/com_qadv_cm2.h contains forcing arrays.
- ver41.5.input/inpfiles.s links the generated forcing file (the legacy
  run_exp.s does not copy update/*.s files).

The binary has 12 big-endian float32 records, 96x48 values per record,
longitude fastest, and no record markers. Its expected size is 221184 bytes.
The experiment makefile uses Intel's -assume byterecl so direct-access RECL
values are interpreted in bytes, as required by SPEEDY's input routines.

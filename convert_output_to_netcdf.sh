#!/bin/bash
set -euo pipefail

root=$(cd "$(dirname "$0")" && pwd)
outdir=${1:-"$root/output/exp_107"}
cd "$outdir"

shopt -s nullglob
converted=0
for ctl in at*.ctl day*.ctl; do
  stem=${ctl%.ctl}
  grids=("${stem}"_*.grd)
  if ((${#grids[@]} == 0)); then
    echo "skip $ctl: no matching .grd file" >&2
    continue
  fi
  nc=${grids[0]%.grd}.nc
  echo "converting $ctl -> $nc"
  cdo -O -f nc4c import_binary "$ctl" "$nc"
  converted=$((converted + 1))
done

if ((converted == 0)); then
  echo "No GrADS output was converted" >&2
  exit 1
fi


#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p logs cm2_advection_forcing/output
prep_id=$(qsub -o logs/prepare.out -e logs/prepare.err pbs/prepare_forcing.pbs)
run_id=$(qsub -W depend=afterok:"$prep_id" -o logs/model.out \
  -e logs/model.err pbs/run_model.pbs)
printf 'forcing job: %s\nmodel job:   %s (afterok dependency)\n' \
  "$prep_id" "$run_id"


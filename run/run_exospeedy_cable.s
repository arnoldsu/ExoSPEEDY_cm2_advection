#!/bin/bash
set -e

COUPLED_DRIVER=${EXOSPEEDY_CABLE_DRIVER:-/g/data/p66/ars599/MODEL/CABLE/src/component/daily_test/run_exospeedy_cable.sh}

exec "$COUPLED_DRIVER" "$@"

#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/conf/slurm.env"

cd "${SCRIPT_DIR}"

mkdir -p logs

ARRAY_ID="$(sbatch --parsable \
    --array=1-8 \
    01_persample.sbatch)"

echo "Submitted per-sample array: ${ARRAY_ID}" >&2

COHORT_ID="$(sbatch --parsable \
    --dependency=afterok:${ARRAY_ID} \
    --kill-on-invalid-dep=yes \
    02_cohort.sbatch)"

echo "Submitted cohort job: ${COHORT_ID}" >&2

#!/usr/bin/env bash
#SBATCH --job-name=variant_persample
#SBATCH --partition=courses
#SBATCH --account=binf6610.202710
#SBATCH --array=1-8
#SBATCH --cpus-per-task=4
#SBATCH --mem=8G
#SBATCH --time=02:00:00
#SBATCH --export=NONE
#SBATCH --output=logs/persample_%A_%a.out

set -euo pipefail

mkdir -p logs

source "${SLURM_SUBMIT_DIR}/conf/slurm.env"


SAMPLE="$(awk -F',' -v n="${SLURM_ARRAY_TASK_ID}" 'NR == n + 1 { print $1 }' "${SAMPLESHEET}")"

[[ -n "${SAMPLE}" ]] || {
    echo "task ${SLURM_ARRAY_TASK_ID}: no row ${SLURM_ARRAY_TASK_ID} in ${SAMPLESHEET}" >&2
    exit 64
}

THREADS="${SLURM_CPUS_PER_TASK}"
export THREADS

export TMPDIR="/tmp/${SLURM_JOB_ID}"
mkdir -p "${TMPDIR}"
trap 'rm -rf "${TMPDIR}"' EXIT

RUN_DIR="${RUN_ROOT}/${SAMPLE}"
mkdir -p "${RUN_DIR}"

cd "${PIPELINE_DIR}"

echo "Starting sample: ${SAMPLE}" >&2
echo "Threads: ${THREADS}" >&2
echo "Run directory: ${RUN_DIR}" >&2

apptainer exec --cleanenv --env THREADS="${THREADS}" --env TMPDIR="${TMPDIR}" --env SLURM_JOB_ID="${SLURM_JOB_ID}" --env SLURM_CPUS_PER_TASK="${SLURM_CPUS_PER_TASK}" --bind /courses/BINF6610.202710,/scratch/${USER} "${SIF}" bash run_sample.sh "${SAMPLESHEET}" "${RUN_DIR}" "${SAMPLE}"

echo "Sample completed: ${SAMPLE}" >&2

#!/usr/bin/env bash
#SBATCH --job-name=variant_pull
#SBATCH --partition=courses
#SBATCH --account=binf6610.202710
#SBATCH --cpus-per-task=2
#SBATCH --mem=4G
#SBATCH --time=00:30:00
#SBATCH --export=NONE
#SBATCH --output=logs/pull_%j.out

set -euo pipefail

mkdir -p logs
mkdir -p "/scratch/${USER}/containers"
export APPTAINER_CACHEDIR="/scratch/${USER}/containers/cache"
mkdir -p "${APPTAINER_CACHEDIR}"

apptainer pull --force \
    "/scratch/${USER}/containers/variant-call.sif" \
    "docker://nayakshi/variant-call:week3"

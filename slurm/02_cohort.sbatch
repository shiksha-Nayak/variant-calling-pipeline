#!/usr/bin/env bash
#SBATCH --job-name=variant_cohort
#SBATCH --partition=courses
#SBATCH --account=binf6610.202710
#SBATCH --cpus-per-task=4
#SBATCH --mem=8G
#SBATCH --time=02:00:00
#SBATCH --export=NONE
#SBATCH --output=logs/cohort_%j.out

set -euo pipefail

mkdir -p logs

source "${SLURM_SUBMIT_DIR}/conf/slurm.env"

module load miniconda3/25.9.1
source activate "${CONDA_ENV}"

THREADS="${SLURM_CPUS_PER_TASK}"
export THREADS

export TMPDIR="/tmp/${SLURM_JOB_ID}"
mkdir -p "${TMPDIR}"
trap 'rm -rf "${TMPDIR}"' EXIT

RUN_DIR="${RUN_ROOT}/cohort"
mkdir -p "${RUN_DIR}"

cd "${PIPELINE_DIR}"
source lib/common.sh

echo "Starting cohort stages..." >&2
echo "Threads: ${THREADS}" >&2
echo "Run directory: ${RUN_DIR}" >&2

# Collect per-sample outputs into the cohort directory.
mkdir -p "${RUN_DIR}/gvcf" "${RUN_DIR}/fastqc" "${RUN_DIR}/trimmed"

while IFS=$'\t' read -r SAMPLE CONDITION REPLICATE LIBRARY R1 R2; do
    [[ -z "${SAMPLE}" ]] && continue

    SAMPLE_DIR="${RUN_ROOT}/${SAMPLE}"

    ln -sf "${SAMPLE_DIR}/gvcf/${SAMPLE}.g.vcf.gz" \
        "${RUN_DIR}/gvcf/${SAMPLE}.g.vcf.gz"
    ln -sf "${SAMPLE_DIR}/gvcf/${SAMPLE}.g.vcf.gz.tbi" \
        "${RUN_DIR}/gvcf/${SAMPLE}.g.vcf.gz.tbi"

    if [[ -d "${SAMPLE_DIR}/fastqc" ]]; then
        for FILE in "${SAMPLE_DIR}/fastqc"/*; do
            [[ -e "${FILE}" ]] || continue
            ln -sf "${FILE}" "${RUN_DIR}/fastqc/$(basename "${FILE}")"
        done
    fi

    if [[ -d "${SAMPLE_DIR}/trimmed" ]]; then
        for FILE in "${SAMPLE_DIR}/trimmed"/*; do
            [[ -e "${FILE}" ]] || continue
            ln -sf "${FILE}" "${RUN_DIR}/trimmed/$(basename "${FILE}")"
        done
    fi
done < <(read_samplesheet "${SAMPLESHEET}")

bash stages/06_joint_genotyping.sh \
    "${SAMPLESHEET}" \
    "${RUN_DIR}" \
    "${REF}" \
    "${REGION}"

bash stages/07_filter_variants.sh \
    "${SAMPLESHEET}" \
    "${RUN_DIR}" \
    "${REF}"

bash stages/08_multiqc.sh \
    "${SAMPLESHEET}" \
    "${RUN_DIR}"

python3 stages/10_export_tsv.py \
    "${RUN_DIR}/variants/cohort.filtered.vcf.gz" \
    "${RUN_DIR}"

bash stages/09_publish.sh \
    "${RUN_DIR}" \
    "${REF}" \
    "${REGION}"

echo "Cohort stages completed successfully." >&2#!/usr/bin/env bash
#SBATCH --job-name=variant_cohort
#SBATCH --partition=courses
#SBATCH --account=binf6610.202710
#SBATCH --cpus-per-task=4
#SBATCH --mem=8G
#SBATCH --time=02:00:00
#SBATCH --export=NONE
#SBATCH --output=logs/cohort_%j.out

set -euo pipefail

mkdir -p logs

source "${SLURM_SUBMIT_DIR}/conf/slurm.env"

module load miniconda3/25.9.1
source activate "${CONDA_ENV}"

THREADS="${SLURM_CPUS_PER_TASK}"
export THREADS

export TMPDIR="/tmp/${SLURM_JOB_ID}"
mkdir -p "${TMPDIR}"
trap 'rm -rf "${TMPDIR}"' EXIT

RUN_DIR="${RUN_ROOT}/cohort"
mkdir -p "${RUN_DIR}"

cd "${PIPELINE_DIR}"
source lib/common.sh

echo "Starting cohort stages..." >&2
echo "Threads: ${THREADS}" >&2
echo "Run directory: ${RUN_DIR}" >&2

bash stages/06_joint_genotyping.sh \
    "${SAMPLESHEET}" \
    "${RUN_DIR}" \
    "${REF}" \
    "${REGION}"

bash stages/07_filter_variants.sh \
    "${SAMPLESHEET}" \
    "${RUN_DIR}" \
    "${REF}"

bash stages/08_multiqc.sh \
    "${SAMPLESHEET}" \
    "${RUN_DIR}"

python3 stages/10_export_tsv.py \
    "${RUN_DIR}/variants/cohort.filtered.vcf.gz" \
    "${RUN_DIR}"

bash stages/09_publish.sh \
    "${RUN_DIR}" \
    "${REF}" \
    "${REGION}"

echo "Cohort stages completed successfully." >&2

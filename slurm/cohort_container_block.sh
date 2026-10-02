#!/usr/bin/env bash
set -euo pipefail

cd "${PIPELINE_DIR}"
source lib/common.sh

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

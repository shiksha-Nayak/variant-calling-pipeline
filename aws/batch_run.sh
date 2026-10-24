#!/usr/bin/env bash
set -euo pipefail

# Settings supplied by the AWS Batch job definition
: "${DATA:?Set DATA to the S3 smoke-data folder}"
: "${RESULTS:?Set RESULTS to the S3 results folder}"
: "${REF_NAME:=smoke.fa}"

job="${AWS_BATCH_JOB_ID:-local}"
work=$(mktemp -d /tmp/run.XXXXXX)

# Step 1: Download smoke dataset from S3
echo "[batch_run] 1/3 copying ${DATA}/ to ${work}/data"
aws s3 cp "${DATA%/}/" "${work}/data/" --recursive --no-progress

# Step 2: Run the variant-calling pipeline
echo "[batch_run] 2/3 running the pipeline: REF=${REF_NAME} REGION=${REGION:-?} THREADS=${THREADS:-?}"

export TMPDIR="${work}/tmp"
mkdir -p "$TMPDIR"

cd /pipeline

REF="${work}/data/${REF_NAME}" \
bash /pipeline/run_pipeline.sh "${work}/data/samplesheet.csv" "${work}/out"

# Step 3: Upload pipeline results to S3
echo "[batch_run] 3/3 copying ${work}/out/ to ${RESULTS%/}/${job}/"

aws s3 cp "${work}/out/" "${RESULTS%/}/${job}/" \
  --recursive --no-progress

echo "[batch_run] done"

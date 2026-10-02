#!/usr/bin/env bash
set -euo pipefail

SAMPLESHEET="${1:?Usage: ./run_sample.sh samplesheet.csv output_dir sample_id}"
OUTDIR="${2:?Missing output directory}"
SAMPLE="${3:?Missing sample ID}"
REQUESTED_STAGE="${4:-5}"

if [[ "$REQUESTED_STAGE" =~ ^[6-9]$ ]]; then
    echo "ERROR: run_sample.sh handles stages 0-5 only; stage $REQUESTED_STAGE is a cohort stage." >&2
    exit 64
fi

if [[ ! "$REQUESTED_STAGE" =~ ^[0-5]$ ]]; then
    echo "ERROR: Invalid stage: $REQUESTED_STAGE. Allowed stages are 0-5." >&2
    exit 64
fi

source lib/common.sh

TMP_SHEET="${OUTDIR}/.${SAMPLE}.samplesheet.csv"
mkdir -p "$OUTDIR"

cleanup() {
    rm -f "$TMP_SHEET"
}
trap cleanup EXIT

{
    head -n 1 "$SAMPLESHEET"
    awk -F',' -v sample="$SAMPLE" 'NR > 1 && $1 == sample' "$SAMPLESHEET"
} > "$TMP_SHEET"

if [[ "$(wc -l < "$TMP_SHEET")" -ne 2 ]]; then
    echo "ERROR: Sample not found or sample ID is duplicated: $SAMPLE" >&2
    exit 1
fi

echo "Stage 0: Validate sample $SAMPLE" >&2
bash stages/00_validate.sh "$TMP_SHEET"

echo "Stage 1: Raw quality control for $SAMPLE" >&2
bash stages/01_fastqc.sh "$TMP_SHEET" "$OUTDIR"

echo "Stage 2: Read trimming for $SAMPLE" >&2
bash stages/02_fastp.sh "$TMP_SHEET" "$OUTDIR"

echo "Stage 3: Alignment for $SAMPLE" >&2
bash stages/03_align.sh "$TMP_SHEET" "$OUTDIR" "$REF"

echo "Stage 4: BAM processing for $SAMPLE" >&2
bash stages/04_process_bam.sh "$TMP_SHEET" "$OUTDIR"

echo "Stage 5: HaplotypeCaller for $SAMPLE" >&2
bash stages/05_haplotypecaller.sh "$TMP_SHEET" "$OUTDIR" "$REF" "$REGION"

echo "Per-sample stages 0-5 completed: $SAMPLE" >&2

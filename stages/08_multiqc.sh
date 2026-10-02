#!/usr/bin/env bash
set -euo pipefail

SAMPLESHEET="${1:?Usage: 08_multiqc.sh samplesheet.csv output_dir}"
OUTDIR="${2:?Missing output directory}"

mkdir -p "$OUTDIR/qc"

python3 -m multiqc \
    "$OUTDIR/fastqc" \
    "$OUTDIR/trimmed" \
    -o "$OUTDIR/qc" \
    -n multiqc_report.html \
    --force

echo "MultiQC report created: $OUTDIR/qc/multiqc_report.html" >&2

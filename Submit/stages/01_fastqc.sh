#!/usr/bin/env bash
set -euo pipefail

SAMPLESHEET="${1:?Usage: 01_fastqc.sh samplesheet.csv output_dir}"
OUTDIR="${2:?Usage: 01_fastqc.sh samplesheet.csv output_dir}"

mkdir -p "$OUTDIR/fastqc/raw"

SHEET_DIR="$(cd "$(dirname "$SAMPLESHEET")" && pwd)"

while IFS=, read -r sample_id condition replicate library_type r1_fastq r2_fastq; do
    [[ "$sample_id" == "sample_id" || -z "$sample_id" ]] && continue

    [[ "$r1_fastq" = /* ]] || r1_fastq="$SHEET_DIR/$r1_fastq"

    fastqc -o "$OUTDIR/fastqc/raw" "$r1_fastq"

    if [[ "$library_type" == "paired" ]]; then
        [[ "$r2_fastq" = /* ]] || r2_fastq="$SHEET_DIR/$r2_fastq"
        fastqc -o "$OUTDIR/fastqc/raw" "$r2_fastq"
    fi
done < "$SAMPLESHEET"

echo "Raw FastQC completed."

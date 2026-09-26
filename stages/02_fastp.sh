#!/usr/bin/env bash
set -euo pipefail

SAMPLESHEET="${1:?Usage: 02_fastp.sh samplesheet.csv output_dir}"
OUTDIR="${2:?Usage: 02_fastp.sh samplesheet.csv output_dir}"

SHEET_DIR="$(cd "$(dirname "$SAMPLESHEET")" && pwd)"
mkdir -p "$OUTDIR/trimmed"

while IFS=, read -r sample_id condition replicate library_type r1_fastq r2_fastq; do
    [[ "$sample_id" == "sample_id" || -z "$sample_id" ]] && continue

    [[ "$r1_fastq" = /* ]] || r1_fastq="$SHEET_DIR/$r1_fastq"

    if [[ "$library_type" == "paired" ]]; then
        [[ "$r2_fastq" = /* ]] || r2_fastq="$SHEET_DIR/$r2_fastq"

        fastp \
            -i "$r1_fastq" -I "$r2_fastq" \
            -o "$OUTDIR/trimmed/${sample_id}_R1.trimmed.fastq.gz" \
            -O "$OUTDIR/trimmed/${sample_id}_R2.trimmed.fastq.gz" \
            -h "$OUTDIR/trimmed/${sample_id}_fastp.html" \
            -j "$OUTDIR/trimmed/${sample_id}_fastp.json"
    else
        fastp \
            -i "$r1_fastq" \
            -o "$OUTDIR/trimmed/${sample_id}_R1.trimmed.fastq.gz" \
            -h "$OUTDIR/trimmed/${sample_id}_fastp.html" \
            -j "$OUTDIR/trimmed/${sample_id}_fastp.json"
    fi
done < "$SAMPLESHEET"

echo "Fastp trimming completed."

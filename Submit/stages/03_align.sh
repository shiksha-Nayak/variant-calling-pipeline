#!/usr/bin/env bash
set -euo pipefail

SAMPLESHEET="${1:?Usage: 03_align.sh samplesheet.csv output_dir reference.fa}"
OUTDIR="${2:?Missing output directory}"
REF="${3:?Missing reference FASTA}"

SHEET_DIR="$(cd "$(dirname "$SAMPLESHEET")" && pwd)"
mkdir -p "$OUTDIR/aligned"

while IFS=, read -r sample_id condition replicate library_type r1_fastq r2_fastq; do
    [[ "$sample_id" == "sample_id" || -z "$sample_id" ]] && continue

    R1="$OUTDIR/trimmed/${sample_id}_R1.trimmed.fastq.gz"
    SAM="$OUTDIR/aligned/${sample_id}.sam"
    RG="@RG\tID:${sample_id}\tSM:${sample_id}\tPL:ILLUMINA"

    if [[ "$library_type" == "paired" ]]; then
        R2="$OUTDIR/trimmed/${sample_id}_R2.trimmed.fastq.gz"
        bwa mem -R "$RG" "$REF" "$R1" "$R2" > "$SAM"
    else
        bwa mem -R "$RG" "$REF" "$R1" > "$SAM"
    fi

    echo "Alignment completed: $sample_id"
done < "$SAMPLESHEET"

echo "BWA alignment completed."

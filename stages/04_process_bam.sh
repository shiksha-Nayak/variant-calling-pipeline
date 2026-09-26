#!/usr/bin/env bash
set -euo pipefail

SAMPLESHEET="${1:?Usage: 04_process_bam.sh samplesheet.csv output_dir}"
OUTDIR="${2:?Missing output directory}"

mkdir -p "$OUTDIR/sorted" "$OUTDIR/markdup"

while IFS=, read -r sample_id condition replicate library_type r1_fastq r2_fastq; do
    [[ "$sample_id" == "sample_id" || -z "$sample_id" ]] && continue

    SAM="$OUTDIR/aligned/${sample_id}.sam"
    SORTED="$OUTDIR/sorted/${sample_id}.sorted.bam"
    MARKED="$OUTDIR/markdup/${sample_id}.markdup.bam"
    METRICS="$OUTDIR/markdup/${sample_id}.duplicate_metrics.txt"

    samtools sort -o "$SORTED" "$SAM"
    samtools index "$SORTED"

    python3 "$HOME/Downloads/gatk-4.7.0.0/gatk" MarkDuplicates \
        --INPUT "$SORTED" \
        --OUTPUT "$MARKED" \
        --METRICS_FILE "$METRICS" \
        --CREATE_INDEX true

    echo "BAM processing completed: $sample_id"
done < "$SAMPLESHEET"

echo "Sorting, indexing, and duplicate marking completed."

#!/usr/bin/env bash
set -euo pipefail

SAMPLESHEET="${1:?Usage: 04_process_bam.sh samplesheet.csv output_dir}"
OUTDIR="${2:?Missing output directory}"

source lib/common.sh

THREADS="${SLURM_CPUS_PER_TASK:-1}"

mkdir -p "$OUTDIR/sorted" "$OUTDIR/markdup"

while IFS=$'\t' read -r sample_id condition replicate library_type r1_fastq r2_fastq; do
    [[ -z "$sample_id" ]] && continue

    SAM="$OUTDIR/aligned/${sample_id}.sam"
    SORTED="$OUTDIR/sorted/${sample_id}.sorted.bam"
    MARKED="$OUTDIR/markdup/${sample_id}.markdup.bam"
    METRICS="$OUTDIR/markdup/${sample_id}.duplicate_metrics.txt"

    samtools sort -@ "$THREADS" -T "${TMPDIR}/sort" -o "$SORTED" "$SAM"
    samtools index "$SORTED"

    gatk MarkDuplicates \
        --INPUT "$SORTED" \
        --OUTPUT "$MARKED" \
        --METRICS_FILE "$METRICS" \
        --CREATE_INDEX true

    echo "BAM processing completed: $sample_id" >&2
done < <(read_samplesheet "$SAMPLESHEET")

echo "Sorting, indexing, and duplicate marking completed." >&2

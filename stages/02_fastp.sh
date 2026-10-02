#!/usr/bin/env bash
set -euo pipefail

SAMPLESHEET="${1:?Usage: 02_fastp.sh samplesheet.csv output_dir}"
OUTDIR="${2:?Usage: 02_fastp.sh samplesheet.csv output_dir}"

source lib/common.sh

THREADS="${SLURM_CPUS_PER_TASK:-1}"

mkdir -p "$OUTDIR/trimmed"

while IFS=$'\t' read -r sample_id condition replicate library_type r1_fastq r2_fastq; do
    [[ -z "$sample_id" ]] && continue

    if [[ "$library_type" == "paired" ]]; then
        fastp \
            -i "$r1_fastq" -I "$r2_fastq" \
            -o "$OUTDIR/trimmed/${sample_id}_R1.trimmed.fastq.gz" \
            -O "$OUTDIR/trimmed/${sample_id}_R2.trimmed.fastq.gz" \
            -w "$THREADS" \
            -h "$OUTDIR/trimmed/${sample_id}_fastp.html" \
            -j "$OUTDIR/trimmed/${sample_id}_fastp.json"
    else
        fastp \
            -i "$r1_fastq" \
            -o "$OUTDIR/trimmed/${sample_id}_R1.trimmed.fastq.gz" \
            -w "$THREADS" \
            -h "$OUTDIR/trimmed/${sample_id}_fastp.html" \
            -j "$OUTDIR/trimmed/${sample_id}_fastp.json"
    fi
done < <(read_samplesheet "$SAMPLESHEET")

echo "Fastp trimming completed." >&2

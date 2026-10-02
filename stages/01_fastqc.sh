#!/usr/bin/env bash
set -euo pipefail

SAMPLESHEET="${1:?Usage: 01_fastqc.sh samplesheet.csv output_dir}"
OUTDIR="${2:?Usage: 01_fastqc.sh samplesheet.csv output_dir}"

source lib/common.sh

THREADS="${SLURM_CPUS_PER_TASK:-1}"

mkdir -p "$OUTDIR/fastqc/raw"

while IFS=$'\t' read -r sample_id condition replicate library_type r1_fastq r2_fastq; do
    [[ -z "$sample_id" ]] && continue

    fastqc --threads "$THREADS" -o "$OUTDIR/fastqc/raw" "$r1_fastq"

    if [[ "$library_type" == "paired" ]]; then
        fastqc --threads "$THREADS" -o "$OUTDIR/fastqc/raw" "$r2_fastq"
    fi
done < <(read_samplesheet "$SAMPLESHEET")

echo "Raw FastQC completed." >&2

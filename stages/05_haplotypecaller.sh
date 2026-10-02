#!/usr/bin/env bash
set -euo pipefail

SAMPLESHEET="${1:?Usage: 05_haplotypecaller.sh samplesheet.csv output_dir reference.fa region}"
OUTDIR="${2:?Missing output directory}"
REF="${3:?Missing reference FASTA}"
REGION="${4:?Missing calling region}"

source lib/common.sh

THREADS="${SLURM_CPUS_PER_TASK:-1}"

mkdir -p "$OUTDIR/gvcf"

while IFS=$'\t' read -r sample_id condition replicate library_type r1_fastq r2_fastq; do
    [[ -z "$sample_id" ]] && continue

    gatk HaplotypeCaller \
        -R "$REF" \
        -I "$OUTDIR/markdup/${sample_id}.markdup.bam" \
        -O "$OUTDIR/gvcf/${sample_id}.g.vcf.gz" \
        -ERC GVCF \
        --native-pair-hmm-threads "$THREADS" \
        -L "$REGION"

    echo "HaplotypeCaller completed: $sample_id" >&2
done < <(read_samplesheet "$SAMPLESHEET")

echo "GVCF calling completed." >&2

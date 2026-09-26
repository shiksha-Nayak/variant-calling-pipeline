#!/usr/bin/env bash
set -euo pipefail

SAMPLESHEET="${1:?Usage: 05_haplotypecaller.sh samplesheet.csv output_dir reference.fa region}"
OUTDIR="${2:?Missing output directory}"
REF="${3:?Missing reference FASTA}"
REGION="${4:?Missing calling region}"

mkdir -p "$OUTDIR/gvcf"

while IFS=, read -r sample_id condition replicate library_type r1_fastq r2_fastq; do
    [[ "$sample_id" == "sample_id" || -z "$sample_id" ]] && continue

    python3 "$HOME/Downloads/gatk-4.7.0.0/gatk" HaplotypeCaller \
        -R "$REF" \
        -I "$OUTDIR/markdup/${sample_id}.markdup.bam" \
        -O "$OUTDIR/gvcf/${sample_id}.g.vcf.gz" \
        -ERC GVCF \
        -L "$REGION"

    echo "HaplotypeCaller completed: $sample_id"
done < "$SAMPLESHEET"

echo "GVCF calling completed."

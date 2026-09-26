#!/usr/bin/env bash
set -euo pipefail

SAMPLESHEET="${1:?Usage: 07_filter_variants.sh samplesheet.csv output_dir reference.fa}"
OUTDIR="${2:?Missing output directory}"
REF="${3:?Missing reference FASTA}"

INPUT="$OUTDIR/variants/joint.vcf.gz"
OUTPUT="$OUTDIR/variants/cohort.filtered.vcf.gz"

python3 "$HOME/Downloads/gatk-4.7.0.0/gatk" VariantFiltration \
    -R "$REF" \
    -V "$INPUT" \
    -O "$OUTPUT" \
    --filter-name "LowQual" \
    --filter-expression "QUAL < 30"

echo "Variant filtering completed: $OUTPUT"

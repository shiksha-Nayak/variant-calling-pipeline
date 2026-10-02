#!/usr/bin/env bash
set -euo pipefail

SAMPLESHEET="${1:?Usage: 07_filter_variants.sh samplesheet.csv output_dir reference.fa}"
OUTDIR="${2:?Missing output directory}"
REF="${3:?Missing reference FASTA}"

source lib/common.sh

INPUT="$OUTDIR/variants/joint.vcf.gz"
OUTPUT="$OUTDIR/variants/cohort.filtered.vcf.gz"

gatk VariantFiltration \
    -R "$REF" \
    -V "$INPUT" \
    -O "$OUTPUT" \
    --filter-name "LowQual" \
    --filter-expression "QUAL < 30"

echo "Variant filtering completed: $OUTPUT" >&2

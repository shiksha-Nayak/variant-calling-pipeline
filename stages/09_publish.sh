#!/usr/bin/env bash
set -euo pipefail

OUTDIR="${1:?Usage: 09_publish.sh output_dir reference region}"
REF="${2:?Missing reference}"
REGION="${3:?Missing region}"

VCF="$OUTDIR/variants/cohort.filtered.vcf.gz"
TSV="$OUTDIR/variants.tsv"
SAMPLE_MAP="$OUTDIR/sample_map.txt"

if [[ ! -f "$VCF" ]]; then
    echo "ERROR: Filtered VCF not found: $VCF" >&2
    exit 1
fi

if [[ ! -f "$TSV" ]]; then
    echo "ERROR: TSV not found: $TSV" >&2
    exit 1
fi

cp "$VCF" "$OUTDIR/cohort.filtered.vcf.gz"

if [[ -f "$VCF.tbi" ]]; then
    cp "$VCF.tbi" "$OUTDIR/cohort.filtered.vcf.gz.tbi"
fi

bash lib/write_manifest.sh "$OUTDIR" "$REF" "$REGION" "$SAMPLE_MAP"

echo "Publishing completed." >&2

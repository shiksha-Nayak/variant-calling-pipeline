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

python3 - "$OUTDIR" "$REF" "$REGION" "$SAMPLE_MAP" <<'PY'
import json
import sys
from pathlib import Path

outdir = Path(sys.argv[1])
ref = sys.argv[2]
region = sys.argv[3]
sample_map = Path(sys.argv[4])

samples = []
if sample_map.is_file():
    with open(sample_map) as f:
        for line in f:
            fields = line.strip().split()
            if fields:
                samples.append(fields[0])

manifest = {
    "reference": ref,
    "region": region,
    "samples": samples,
    "filtered_vcf": "cohort.filtered.vcf.gz",
    "variants_tsv": "variants.tsv",
    "qc_report": "qc/multiqc_report.html"
}

with open(outdir / "manifest.json", "w") as f:
    json.dump(manifest, f, indent=2)
    f.write("\n")

print("Manifest created.")
PY

echo "Publishing completed."

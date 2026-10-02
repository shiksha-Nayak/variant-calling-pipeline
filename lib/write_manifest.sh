#!/usr/bin/env bash
set -euo pipefail

OUTDIR="${1:?Usage: write_manifest.sh output_dir reference region sample_map}"
REF="${2:?Missing reference}"
REGION="${3:?Missing region}"
SAMPLE_MAP="${4:?Missing sample map}"

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

python3 - "$OUTDIR" "$REF" "$REGION" "$SAMPLE_MAP" "$REPO_DIR" <<'PY'
import json
import subprocess
import sys
from pathlib import Path

outdir = Path(sys.argv[1])
ref = sys.argv[2]
region = sys.argv[3]
sample_map = Path(sys.argv[4])
repo_dir = Path(sys.argv[5])

try:
    git_sha = subprocess.check_output(
        ["git", "rev-parse", "HEAD"],
        cwd=repo_dir,
        text=True,
        stderr=subprocess.DEVNULL
    ).strip()
except Exception:
    git_sha = "unknown"

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
    "qc_report": "qc/multiqc_report.html",
    "git_sha": git_sha
}

with open(outdir / "manifest.json", "w") as f:
    json.dump(manifest, f, indent=2)
    f.write("\n")

print("Manifest created.")
PY

#!/usr/bin/env bash
set -euo pipefail

OUTDIR="${1:?Usage: write_manifest.sh output_dir reference region sample_map}"
REF="${2:?Missing reference}"
REGION="${3:?Missing region}"
SAMPLE_MAP="${4:?Missing sample map}"
SAMPLESHEET="${5:-/courses/BINF6610.202710/data/samplesheet-variant8.csv}"

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

python3 - "$OUTDIR" "$REF" "$REGION" "$SAMPLE_MAP" "$REPO_DIR" "$SAMPLESHEET" <<'PY'
import csv
import hashlib
import json
import os
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

outdir = Path(sys.argv[1])
ref = sys.argv[2]
region = sys.argv[3]
sample_map = Path(sys.argv[4])
repo_dir = Path(sys.argv[5])

now = datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")
started_at = os.environ.get("RUN_STARTED_AT", now)

try:
    git_sha = subprocess.check_output(
        ["git", "rev-parse", "HEAD"],
        cwd=repo_dir,
        text=True,
        stderr=subprocess.DEVNULL
    ).strip()
except Exception:
    git_sha = "unknown"

samplesheet = Path(sys.argv[6])
samples = []
with open(samplesheet, newline="") as f:
    reader = csv.DictReader(f)
    for row in reader:
        samples.append({
            "sample_id": row["sample_id"],
            "library_type": row["library_type"],
            "condition": row["condition"]
        })

container_digest = (
    "sha256:362030c575c53f64a9bef692c9ebe84ef6cc7d064d6513acabc8a68d30a37747"
)

output_files = [
    ("publish", "cohort_vcf", "cohort.filtered.vcf.gz"),
    ("publish", "cohort_vcf_index", "cohort.filtered.vcf.gz.tbi"),
    ("analyze", "variant_table", "variants.tsv"),
    ("qc_report", "multiqc", "qc/multiqc_report.html"),
]

outputs = []
for stage, output_type, relative_path in output_files:
    path = outdir / relative_path
    if not path.is_file():
        raise SystemExit(f"ERROR: Required output missing: {path}")

    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)

    outputs.append({
        "stage": stage,
        "type": output_type,
        "path": relative_path,
        "checksum": f"sha256:{h.hexdigest()}"
    })

variants_tsv = outdir / "variants.tsv"
with open(variants_tsv) as f:
    n_variants_pass = max(0, sum(1 for line in f) - 1)

manifest = {
    "pipeline": {
        "name": "variant-call",
        "version": "3.0.0",
        "implementation": "singularity",
        "git_sha": git_sha,
        "run_id": os.environ.get("SLURM_JOB_ID", "unknown"),
        "started_at": started_at,
        "finished_at": now,
        "exit_status": "success"
    },
    "platform": {
        "kind": "singularity-hpc",
        "container_digests": {
            "variant-call": container_digest
        }
    },
    "reference": {
        "genome": ref,
        "region": region
    },
    "samples": samples,
    "outputs": outputs,
    "metrics": [
        {
            "metric": "n_variants_pass",
            "value": n_variants_pass,
            "unit": "count",
            "stage": "analyze"
        }
    ]
}

with open(outdir / "manifest.json", "w") as f:
    json.dump(manifest, f, indent=2)
    f.write("\n")

print("Manifest created.")
PY

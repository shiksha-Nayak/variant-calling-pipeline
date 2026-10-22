#!/usr/bin/env bash
set -euo pipefail

OUTDIR="${1:?Usage: write_manifest.sh output_dir reference region sample_map samplesheet}"
REF="${2:?Missing reference}"
REGION="${3:?Missing region}"
SAMPLE_MAP="${4:?Missing sample map}"
SAMPLESHEET="${5:?Missing samplesheet}"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

python3 - "$OUTDIR" "$REF" "$REGION" "$SAMPLE_MAP" "$SAMPLESHEET" "$REPO_DIR" <<'PY'
import csv
import hashlib
import json
import os
import subprocess
import sys
import uuid
from datetime import datetime, timezone
from pathlib import Path

outdir = Path(sys.argv[1]).expanduser().resolve()
reference, region = sys.argv[2:4]
sample_map = Path(sys.argv[4]).expanduser()
samplesheet = Path(sys.argv[5]).expanduser()
repo_dir = Path(sys.argv[6])

def utc_now():
    return datetime.now(timezone.utc).isoformat(timespec="seconds")

def sha256(path):
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return "sha256:" + digest.hexdigest()

if not samplesheet.is_file():
    raise SystemExit(f"Samplesheet not found: {samplesheet}")
if not sample_map.is_file():
    raise SystemExit(f"Sample map not found: {sample_map}")

with sample_map.open() as handle:
    mapped_ids = [line.split()[0] for line in handle if line.strip()]
if not mapped_ids:
    raise SystemExit("Sample map is empty")

with samplesheet.open(newline="") as handle:
    reader = csv.DictReader(handle)
    required = {"sample_id", "condition", "library_type"}
    if not required.issubset(reader.fieldnames or []):
        raise SystemExit("Samplesheet missing required columns")
    by_id = {}
    for row in reader:
        sid = row["sample_id"].strip()
        if sid in by_id:
            raise SystemExit(f"Duplicate sample ID: {sid}")
        library = row["library_type"].strip()
        if library not in ("single", "paired"):
            raise SystemExit(f"Invalid library type for {sid}: {library}")
        by_id[sid] = {
            "sample_id": sid,
            "condition": row["condition"].strip(),
            "library_type": library,
        }

missing = sorted(set(mapped_ids) - set(by_id))
if missing:
    raise SystemExit("Sample IDs missing from samplesheet: " + ", ".join(missing))
samples = [by_id[sid] for sid in mapped_ids]

try:
    git_sha = subprocess.check_output(
        ["git", "rev-parse", "HEAD"], cwd=repo_dir,
        text=True, stderr=subprocess.DEVNULL,
    ).strip()
except (OSError, subprocess.CalledProcessError):
    raise SystemExit("Cannot determine git commit SHA")

outputs = []
for relative, stage, kind in (
    ("cohort.filtered.vcf.gz", "publish", "filtered_vcf"),
    ("cohort.filtered.vcf.gz.tbi", "publish", "vcf_index"),
    ("variants.tsv", "publish", "variant_table"),
    ("qc/multiqc_report.html", "qc_report", "multiqc_report"),
):
    path = outdir / relative
    if path.is_file():
        outputs.append({
            "stage": stage, "type": kind, "path": relative,
            "checksum": sha256(path),
        })
if not (outdir / "cohort.filtered.vcf.gz").is_file():
    raise SystemExit("Missing published cohort.filtered.vcf.gz")

metrics = []
tsv = outdir / "variants.tsv"
if tsv.is_file():
    with tsv.open(newline="") as handle:
        reader = csv.DictReader(handle, delimiter="\t")
        if "FILTER" not in (reader.fieldnames or []):
            raise SystemExit("variants.tsv missing FILTER column")
        pass_count = sum(row["FILTER"] == "PASS" for row in reader)
    metrics.append({
        "metric": "pass_variant_count", "value": pass_count,
        "stage": "publish", "unit": "variants",
    })

platform_kind = "laptop"
if os.environ.get("AWS_BATCH_JOB_ID"):
    platform_kind = "aws-batch"
elif os.environ.get("SLURM_JOB_ID"):
    platform_kind = "singularity-hpc" if os.environ.get("APPTAINER_CONTAINER") else "slurm"
elif os.environ.get("APPTAINER_CONTAINER"):
    platform_kind = "singularity-hpc"

finished = utc_now()
started = os.environ.get("PIPELINE_STARTED_AT", finished)
platform = {
    "kind": platform_kind,
    "container": os.environ.get("APPTAINER_CONTAINER", "unknown"),
    "slurm_job_id": os.environ.get("SLURM_JOB_ID", "unknown"),
    "slurm_cpus_per_task": os.environ.get("SLURM_CPUS_PER_TASK", "unknown"),
}

manifest = {
    "pipeline": {
        "name": "variant-call",
        "version": "1.0.0",
        "implementation": "bash",
        "git_sha": git_sha,
        "run_id": os.environ.get("PIPELINE_RUN_ID", str(uuid.uuid4())),
        "started_at": started,
        "finished_at": finished,
        "exit_status": "success",
    },
    "platform": platform,
    "reference": {"genome": reference, "region": region},
    "samples": samples,
    "outputs": outputs,
    "metrics": metrics,
}

outdir.mkdir(parents=True, exist_ok=True)
with (outdir / "manifest.json").open("w") as handle:
    json.dump(manifest, handle, indent=2)
    handle.write("\n")
print("Manifest created:", outdir / "manifest.json")
PY

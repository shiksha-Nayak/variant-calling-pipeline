#!/usr/bin/env bash
set -euo pipefail

SAMPLESHEET="${1:?Missing samplesheet}"
REF="${2:?Missing reference FASTA}"

python3 - "$SAMPLESHEET" "$REF" <<'PYVALIDATE'
import csv
import gzip
import os
import sys

sheet, ref = sys.argv[1:]
required = ["sample_id", "condition", "replicate",
            "library_type", "r1_fastq", "r2_fastq"]

if not os.path.isfile(sheet):
    sys.exit(f"ERROR: Missing samplesheet: {sheet}")

with open(sheet, newline="") as fh:
    reader = csv.DictReader(fh)
    if not reader.fieldnames or any(c not in reader.fieldnames for c in required):
        sys.exit("ERROR: Missing required CSV columns")
    rows = list(reader)

if not rows:
    sys.exit("ERROR: Empty samplesheet")

seen = set()
for row in rows:
    sid = row["sample_id"]
    if not sid or sid in seen:
        sys.exit(f"ERROR: Missing or duplicate sample ID: {sid}")
    seen.add(sid)

    if not row["condition"] or not row["replicate"]:
        sys.exit(f"ERROR: Missing required field: {sid}")

    library = row["library_type"]
    if library not in ("paired", "single"):
        sys.exit(f"ERROR: Invalid library type: {sid}")

    reads = [row["r1_fastq"]]
    if library == "paired":
        reads.append(row["r2_fastq"])

    for read in reads:
        if not read:
            sys.exit(f"ERROR: Missing FASTQ path: {sid}")
        path = read if os.path.isabs(read) else os.path.join(os.path.dirname(sheet), read)
        if not os.path.isfile(path):
            sys.exit(f"ERROR: FASTQ not found: {path}")
        try:
            with gzip.open(path, "rb") as fh:
                while fh.read(1024 * 1024):
                    pass
        except (OSError, EOFError) as exc:
            sys.exit(f"ERROR: Invalid gzip FASTQ {path}: {exc}")

files = [ref, ref + ".fai"]
files += [ref + ext for ext in (".amb", ".ann", ".bwt", ".pac", ".sa")]
files.append(os.path.splitext(ref)[0] + ".dict")

for path in files:
    if not os.path.isfile(path):
        sys.exit(f"ERROR: Missing reference or index: {path}")

print(f"Samplesheet validation passed: {len(rows)} samples")
PYVALIDATE

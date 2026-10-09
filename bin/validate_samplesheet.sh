#!/usr/bin/env bash
set -euo pipefail

SAMPLESHEET="${1:?Missing samplesheet}"

# Check samplesheet is valid CSV
if ! head -1 "$SAMPLESHEET" | grep -q "sample_id"; then
    echo "ERROR: samplesheet missing 'sample_id' column" >&2
    exit 1
fi

echo "Samplesheet validation passed"

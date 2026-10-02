#!/usr/bin/env bash
set -euo pipefail

SAMPLESHEET="${1:?Usage: 00_validate.sh samplesheet.csv}"

if [[ ! -f "$SAMPLESHEET" ]]; then
    echo "ERROR: Samplesheet not found: $SAMPLESHEET" >&2
    exit 1
fi

source lib/common.sh

errors=0
declare -A seen_ids

while IFS=$'\t' read -r sample_id condition replicate library_type r1_fastq r2_fastq; do
    if [[ -z "$sample_id" ]]; then
        continue
    fi

    if [[ -n "${seen_ids[$sample_id]:-}" ]]; then
        echo "ERROR: Duplicate sample ID: $sample_id" >&2
        errors=$((errors + 1))
        continue
    fi
    seen_ids["$sample_id"]=1

    if [[ -z "$condition" || -z "$replicate" || -z "$library_type" || -z "$r1_fastq" ]]; then
        echo "ERROR: Missing required field for $sample_id" >&2
        errors=$((errors + 1))
        continue
    fi

    if [[ "$library_type" != "paired" && "$library_type" != "single" ]]; then
        echo "ERROR: Invalid library type for $sample_id: $library_type" >&2
        errors=$((errors + 1))
        continue
    fi

    if [[ ! -f "$r1_fastq" ]]; then
        echo "ERROR: R1 file missing for $sample_id: $r1_fastq" >&2
        errors=$((errors + 1))
    elif ! gzip -t "$r1_fastq" 2>/dev/null; then
        echo "ERROR: R1 gzip integrity check failed for $sample_id: $r1_fastq" >&2
        errors=$((errors + 1))
    fi

    if [[ "$library_type" == "paired" ]]; then
        if [[ -z "$r2_fastq" ]]; then
            echo "ERROR: R2 path missing for $sample_id" >&2
            errors=$((errors + 1))
        elif [[ ! -f "$r2_fastq" ]]; then
            echo "ERROR: R2 file missing for $sample_id: $r2_fastq" >&2
            errors=$((errors + 1))
        elif ! gzip -t "$r2_fastq" 2>/dev/null; then
            echo "ERROR: R2 gzip integrity check failed for $sample_id: $r2_fastq" >&2
            errors=$((errors + 1))
        fi
    fi

    echo "Validated sample: $sample_id" >&2

done < <(read_samplesheet "$SAMPLESHEET")

if (( errors > 0 )); then
    echo "ERROR: Validation failed with $errors problem(s)." >&2
    exit 1
fi

echo "Validation completed successfully." >&2

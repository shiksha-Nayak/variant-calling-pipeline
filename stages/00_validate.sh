#!/usr/bin/env bash
set -euo pipefail

SAMPLESHEET="${1:?Usage: 00_validate.sh samplesheet.csv}"

if [[ ! -f "$SAMPLESHEET" ]]; then
    echo "ERROR: Samplesheet not found: $SAMPLESHEET" >&2
    exit 1
fi

SHEET_DIR="$(cd "$(dirname "$SAMPLESHEET")" && pwd)"
expected="sample_id,condition,replicate,library_type,r1_fastq,r2_fastq"
header="$(head -n 1 "$SAMPLESHEET" | tr -d '\r')"

if [[ "$header" != "$expected" ]]; then
    echo "ERROR: Incorrect samplesheet header" >&2
    exit 1
fi

seen_ids="|"
errors=0

while IFS=, read -r sample_id condition replicate library_type r1_fastq r2_fastq; do
    sample_id="${sample_id//$'\r'/}"
    [[ -z "$sample_id" ]] && continue

    case "$seen_ids" in
        *"|$sample_id|"*)
            echo "ERROR: Duplicate sample ID: $sample_id" >&2
            errors=$((errors + 1))
            continue
            ;;
    esac
    seen_ids="${seen_ids}${sample_id}|"

    if [[ -z "$condition" || -z "$replicate" || -z "$library_type" || -z "$r1_fastq" ]]; then
        echo "ERROR: Missing required field for $sample_id" >&2
        errors=$((errors + 1))
        continue
    fi

    if [[ "$library_type" != "paired" && "$library_type" != "single" ]]; then
        echo "ERROR: Invalid library type for $sample_id" >&2
        errors=$((errors + 1))
        continue
    fi

    [[ "$r1_fastq" = /* ]] || r1_fastq="$SHEET_DIR/$r1_fastq"

    if [[ ! -f "$r1_fastq" ]]; then
        echo "ERROR: R1 file missing for $sample_id: $r1_fastq" >&2
        errors=$((errors + 1))
    elif [[ "$r1_fastq" == *.gz ]] && ! gzip -t "$r1_fastq" 2>/dev/null; then
        echo "ERROR: Corrupt or truncated R1 gzip for $sample_id: $r1_fastq" >&2
        errors=$((errors + 1))
    fi

    if [[ "$library_type" == "paired" ]]; then
        if [[ -z "$r2_fastq" ]]; then
            echo "ERROR: R2 path missing for $sample_id" >&2
            errors=$((errors + 1))
        else
            [[ "$r2_fastq" = /* ]] || r2_fastq="$SHEET_DIR/$r2_fastq"

            if [[ ! -f "$r2_fastq" ]]; then
                echo "ERROR: R2 file missing for $sample_id: $r2_fastq" >&2
                errors=$((errors + 1))
            elif [[ "$r2_fastq" == *.gz ]] && ! gzip -t "$r2_fastq" 2>/dev/null; then
                echo "ERROR: Corrupt or truncated R2 gzip for $sample_id: $r2_fastq" >&2
                errors=$((errors + 1))
            fi
        fi
    fi

    echo "Validated sample: $sample_id" >&2
done < <(tail -n +2 "$SAMPLESHEET")

if (( errors > 0 )); then
    echo "Validation failed with $errors error(s)." >&2
    exit 1
fi

echo "Validation completed!" >&2

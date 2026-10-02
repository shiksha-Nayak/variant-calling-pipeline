#!/usr/bin/env bash
set -euo pipefail

REF=${REF:-/courses/BINF6610.202710/data/refs/grch38-1000g/GRCh38_full_analysis_set_plus_decoy_hla.fa}
REGION=${REGION:-chr20:1-10000000}

read_samplesheet() {
    local samplesheet="$1"
    local sheet_dir
    sheet_dir="$(cd "$(dirname "$samplesheet")" && pwd)"

    awk -F',' -v sheet_dir="$sheet_dir" '
    NR == 1 {
        for (i = 1; i <= NF; i++) {
            gsub(/\r/, "", $i)
            header[$i] = i
        }

        required["sample_id"] = 1
        required["condition"] = 1
        required["replicate"] = 1
        required["library_type"] = 1
        required["r1_fastq"] = 1
        required["r2_fastq"] = 1

        for (name in required) {
            if (!(name in header)) {
                print "ERROR: Missing required column: " name > "/dev/stderr"
                exit 1
            }
        }

        next
    }

    {
        sample_id = $(header["sample_id"])
        condition = $(header["condition"])
        replicate = $(header["replicate"])
        library_type = $(header["library_type"])
        r1_fastq = $(header["r1_fastq"])
        r2_fastq = $(header["r2_fastq"])

        gsub(/\r/, "", sample_id)
        gsub(/\r/, "", condition)
        gsub(/\r/, "", replicate)
        gsub(/\r/, "", library_type)
        gsub(/\r/, "", r1_fastq)
        gsub(/\r/, "", r2_fastq)

        if (sample_id == "") next

        if (r1_fastq !~ /^\//)
            r1_fastq = sheet_dir "/" r1_fastq

        if (r2_fastq != "" && r2_fastq !~ /^\//)
            r2_fastq = sheet_dir "/" r2_fastq

        print sample_id "\t" condition "\t" replicate "\t" library_type "\t" r1_fastq "\t" r2_fastq
    }
    ' "$samplesheet"
}

#!/usr/bin/env bash
# print_versions.sh — the version of each pipeline tool, as the tool itself reports it.
v() { printf '%-9s %s\n' "$1" "${2:-NOT FOUND}"; }
v bwa      "$(bwa 2>&1 | awk '/^Version/ { print $2 }')"
v samtools "$(samtools --version 2>/dev/null | awk 'NR == 1 { print $2 }')"
v bcftools "$(bcftools --version 2>/dev/null | awk 'NR == 1 { print $2 }')"
v gatk     "$(gatk --version 2>&1 | awk '/Toolkit/ { sub(/^v/, "", $NF); print $NF }')"
v fastqc   "$(fastqc --version 2>/dev/null | awk '{ sub(/^v/, "", $2); print $2 }')"
v fastp    "$(fastp --version 2>&1 | awk '{ print $2 }')"
v multiqc  "$(multiqc --version 2>/dev/null | awk '{ print $NF }')"

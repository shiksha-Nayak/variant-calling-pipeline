#!/usr/bin/env bash
set -euo pipefail

echo "bwa=$(bwa 2>&1 | head -n 1)"
echo "samtools=$(samtools --version | head -n 1)"
echo "bcftools=$(bcftools --version | head -n 1)"
echo "gatk4=$(gatk --version 2>&1 | head -n 1)"
echo "fastqc=$(fastqc --version 2>&1 | head -n 1)"
echo "fastp=$(fastp --version 2>&1 | head -n 1)"
echo "multiqc=$(multiqc --version | head -n 1)"

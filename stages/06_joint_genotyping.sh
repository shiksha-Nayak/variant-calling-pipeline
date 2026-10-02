#!/usr/bin/env bash
set -euo pipefail

SAMPLESHEET="${1:?Usage: 06_joint_genotyping.sh samplesheet.csv output_dir reference.fa region}"
OUTDIR="${2:?Missing output directory}"
REF="${3:?Missing reference FASTA}"
REGION="${4:?Missing calling region}"

source lib/common.sh

THREADS="${SLURM_CPUS_PER_TASK:-1}"

mkdir -p "$OUTDIR/variants"

SAMPLE_MAP="$OUTDIR/sample_map.txt"
TMP_BASE="${TMPDIR:?TMPDIR must be set}"
WORKSPACE="${TMPDIR}/genomicsdb"

mkdir -p "$TMP_BASE"
rm -rf "$WORKSPACE"

: > "$SAMPLE_MAP"

while IFS=$'\t' read -r sample_id condition replicate library_type r1_fastq r2_fastq; do
    [[ -z "$sample_id" ]] && continue
    printf '%s\t%s\n' "$sample_id" "$OUTDIR/gvcf/${sample_id}.g.vcf.gz" >> "$SAMPLE_MAP"
done < <(read_samplesheet "$SAMPLESHEET")

gatk GenomicsDBImport \
    --sample-name-map "$SAMPLE_MAP" \
    --genomicsdb-workspace-path "$WORKSPACE" \
    --reader-threads "$THREADS" \
    -L "$REGION"

gatk GenotypeGVCFs \
    -R "$REF" \
    -V "gendb://$WORKSPACE" \
    -O "$OUTDIR/variants/joint.vcf.gz" \
    -L "$REGION"

echo "Joint genotyping completed." >&2

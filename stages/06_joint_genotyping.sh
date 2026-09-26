#!/usr/bin/env bash
set -euo pipefail

SAMPLESHEET="${1:?Usage: 06_joint_genotyping.sh samplesheet.csv output_dir reference.fa region}"
OUTDIR="${2:?Missing output directory}"
REF="${3:?Missing reference FASTA}"
REGION="${4:?Missing calling region}"

mkdir -p "$OUTDIR/genomicsdb" "$OUTDIR/variants"

SAMPLE_MAP="$OUTDIR/sample_map.txt"
WORKSPACE="$OUTDIR/genomicsdb/workspace"

: > "$SAMPLE_MAP"

while IFS=, read -r sample_id condition replicate library_type r1_fastq r2_fastq; do
    [[ "$sample_id" == "sample_id" || -z "$sample_id" ]] && continue
    printf '%s\t%s\n' "$sample_id" "$OUTDIR/gvcf/${sample_id}.g.vcf.gz" >> "$SAMPLE_MAP"
done < "$SAMPLESHEET"

python3 "$HOME/Downloads/gatk-4.7.0.0/gatk" GenomicsDBImport \
    --sample-name-map "$SAMPLE_MAP" \
    --genomicsdb-workspace-path "$WORKSPACE" \
    -L "$REGION"

python3 "$HOME/Downloads/gatk-4.7.0.0/gatk" GenotypeGVCFs \
    -R "$REF" \
    -V "gendb://$WORKSPACE" \
    -O "$OUTDIR/variants/joint.vcf.gz" \
    -L "$REGION"

echo "Joint genotyping completed."

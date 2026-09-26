#!/usr/bin/env bash
set -euo pipefail

SAMPLESHEET="${1:?Usage: ./run_pipeline.sh samplesheet.csv output_dir}"
OUTDIR="${2:?Missing output directory}"

source conf/pipeline.env

REF="${REF:?Reference not set in conf/pipeline.env}"
REGION="${REGION:?Region not set in conf/pipeline.env}"

echo "Starting variant-calling pipeline..." >&2

echo "Stage 0: Validate samplesheet" >&2
bash stages/00_validate.sh "$SAMPLESHEET"
TARGET="${3:-all}"

if [[ "$TARGET" == "validate" ]]; then
    echo "Validation completed. Stopping before processing." >&2
    exit 0
fi

echo "Stage 1: Raw quality control" >&2
bash stages/01_fastqc.sh "$SAMPLESHEET" "$OUTDIR"

echo "Stage 2: Read trimming" >&2
bash stages/02_fastp.sh "$SAMPLESHEET" "$OUTDIR"

echo "Stage 3: Alignment" >&2
bash stages/03_align.sh "$SAMPLESHEET" "$OUTDIR" "$REF"

echo "Stage 4: BAM processing" >&2
bash stages/04_process_bam.sh "$SAMPLESHEET" "$OUTDIR"

echo "Stage 5: HaplotypeCaller" >&2
bash stages/05_haplotypecaller.sh "$SAMPLESHEET" "$OUTDIR" "$REF" "$REGION"

echo "Stage 6: Joint genotyping" >&2
bash stages/06_joint_genotyping.sh "$SAMPLESHEET" "$OUTDIR" "$REF" "$REGION"

echo "Stage 7: Variant filtering" >&2
bash stages/07_filter_variants.sh "$SAMPLESHEET" "$OUTDIR" "$REF"

echo "Stage 8: MultiQC" >&2
bash stages/08_multiqc.sh "$SAMPLESHEET" "$OUTDIR"

echo "Stage 10: Export variants to TSV" >&2
python3 stages/10_export_tsv.py \
  "$OUTDIR/variants/cohort.filtered.vcf.gz" \
  "$OUTDIR"

echo "Stage 9: Publish final outputs" >&2
bash stages/09_publish.sh "$OUTDIR" "$REF" "$REGION"

echo "Pipeline completed successfully!" >&2

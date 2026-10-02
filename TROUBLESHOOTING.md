# Troubleshooting Guide

## 1. Samplesheet validation fails
**Possible cause:** Missing columns, invalid library type, or missing FASTQ files.

**Fix:**
- Check that the samplesheet contains the required columns:
  `sample_id, condition, replicate, library_type, r1_fastq, r2_fastq`
- Use `paired` or `single` for library type.
- Confirm that FASTQ paths are correct and files exist.

## 2. FastQC or fastp fails
**Possible cause:** FASTQ files are missing, corrupted, or unreadable.

**Fix:**
- Check that the input FASTQ files exist.
- Confirm that the files are valid gzip-compressed FASTQ files.
- Check the error message for the affected sample.

## 3. BWA alignment fails
**Possible cause:** Missing reference indexes or invalid FASTQ paths.

**Fix:**
- Confirm that the reference FASTA exists.
- Check that BWA index files are available.
- Verify that trimmed FASTQ files were generated successfully.

## 4. BAM processing fails
**Possible cause:** Invalid SAM/BAM files or insufficient disk space.

**Fix:**
- Confirm that alignment completed successfully.
- Check available disk space.
- Verify that BAM files are sorted and readable.

## 5. HaplotypeCaller fails
**Possible cause:** Reference mismatch, missing BAM index, or invalid region.

**Fix:**
- Check that the reference FASTA and BAM files use the same reference.
- Confirm that BAM indexes exist.
- Verify that the requested region exists in the reference.

## 6. Joint genotyping fails
**Possible cause:** Missing or invalid GVCF files or sample map.

**Fix:**
- Confirm that every sample has a valid GVCF.
- Check that the sample map contains sample IDs and GVCF paths.
- Verify that the GenomicsDB workspace is valid.

## 7. Variant filtering fails
**Possible cause:** Missing joint VCF or invalid filter expression.

**Fix:**
- Confirm that joint genotyping completed.
- Check that the input VCF exists and is readable.
- Verify the filter expression and reference path.

## 8. MultiQC report is missing
**Possible cause:** QC reports were not generated or the input directory is incorrect.

**Fix:**
- Confirm that FastQC and fastp completed.
- Check that the MultiQC input directories contain reports.
- Review the MultiQC log for errors.

## 9. TSV export fails
**Possible cause:** Missing filtered VCF or incorrect output path.

**Fix:**
- Confirm that the filtered VCF exists.
- Check that the Python script receives the correct input and output paths.
- Verify that the output directory is writable.

## 10. Acceptance test fails
**Possible cause:** Missing samples, missing truth files, or recovery below the required threshold.

**Fix:**
- Confirm that all expected sample names appear in the VCF.
- Check that each sample has a truth file.
- Review the reported recovery percentage for each sample.

## 11. General debugging
- Read the first error message carefully.
- Check the output of the stage immediately before the failure.
- Confirm that the reference, samplesheet, and output paths are correct.
- Rerun only the failed stage after correcting the issue.

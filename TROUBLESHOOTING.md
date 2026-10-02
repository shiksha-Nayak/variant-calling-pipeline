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

# Week 2 Deliberate Slurm Failures

The following failures were deliberately reproduced on Explorer to document Slurm behavior and recovery.

### Failure 1: Deliberately short time limit

A test job (10760448) was submitted with `--time=00:02:00` while running `sleep 180`. Slurm reported the main job state as `TIMEOUT` after 00:02:06.

The batch step was cancelled with exit code 0:15, while the external step was recorded as completed. This demonstrates that a job exceeding its Slurm time limit is terminated by the scheduler.

```text
10760448 TIMEOUT 00:02:06 0:0
10760448.batch CANCELLED 00:02:06 0:15
10760448.extern COMPLETED 00:02:06 0:0
```

### Failure 2: One array task fails with exit 1 and cohort uses afterok

Array job 10760502 had two tasks. Task 1 completed successfully with exit code 0:0, while task 2 failed with exit code 1:0. The dependent cohort job 10760543 was cancelled because its afterok dependency could not be satisfied.

```text
10760502_1 COMPLETED 00:00:01 0:0
10760502_2 FAILED    00:00:02 1:0
10760543   CANCELLED 00:00:00 0:0
```

Slurm reported the specific reason as `DependencyNeverSatisfied` with `Dependency=afterok:10760502_*(failed)`. Therefore, the cohort did not run after the failed array task, which is the intended behavior of the afterok dependency.

### Failure 3: Array requests task 9 but the samplesheet has only 8 samples

Test array 10760641 was submitted with --array=1-9 against the course samplesheet, which contains 8 sample rows. Tasks 1-8 completed successfully, while task 9 failed with exit code 64 because the out-of-range guard detected that no sample exists for row 9.

```text
10760641_1 COMPLETED 0:0
10760641_2 COMPLETED 0:0
10760641_3 COMPLETED 0:0
10760641_4 COMPLETED 0:0
10760641_5 COMPLETED 0:0
10760641_6 COMPLETED 0:0
10760641_7 COMPLETED 0:0
10760641_8 COMPLETED 0:0
10760641_9 FAILED    64:0
```

The exit code 64 came from the explicit no-row guard in the test script. This prevents an invalid array task from continuing with an empty sample ID.

### Failure 4: Job cancelled mid-write and then resubmitted

The first test job, 10760692, was cancelled while it was writing the output file. Slurm recorded the job as CANCELLED after 22 seconds, with the batch step ending with exit code 0:15.

The job was then resubmitted as 10760728. The resubmitted job completed successfully with exit code 0:0 after 4 minutes 34 seconds. The recovered output contained all 1,000 expected lines.

```text
10760692       CANCELLED  00:00:21  0:0
10760692.ba+   CANCELLED  00:00:22  0:15
10760692.ex+   COMPLETED  00:00:21  0:0

10760728       COMPLETED  00:04:34  0:0
10760728.ba+   COMPLETED  00:04:34  0:0
10760728.ex+   COMPLETED  00:05:00  0:0

1000 /scratch/nayak.shi/w2-tests/failure4/output.txt
```

The cancellation left the first run incomplete, demonstrating what happens when a job is stopped during a write. Resubmitting the job allowed the output to be regenerated completely, providing a successful recovery path.

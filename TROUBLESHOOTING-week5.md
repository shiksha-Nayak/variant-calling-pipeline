# Week 5 — Snakemake Troubleshooting

**Course:** BINF6610  
**Assignment:** Assignment 5 — Your Pipeline in Snakemake  
**Platform:** MacBook Air and Northeastern Explorer HPC

## Failure 1: Interrupting a Snakemake Workflow

**Test:** Interrupt a running Snakemake workflow by pressing Ctrl+C.

**Expected issue:** Snakemake may leave unfinished output files and report an incomplete-file error when the workflow is restarted.

**Recovery command:**

`snakemake --rerun-incomplete --profile profiles/laptop --config samplesheet=/path/to/samplesheet.csv ref=/path/to/reference.fa region=smoke_1mb`

**Explanation:** The `--rerun-incomplete` option tells Snakemake to rerun jobs with incomplete outputs instead of restarting the entire workflow. Successfully completed outputs can be reused.

**Status:** This section describes the expected behavior and recovery procedure. The deliberate interruption still needs to be verified.

## Failure 2: Log File Wildcard Mismatch

**Test:** Temporarily change the BWA alignment rule's log path from `logs/bwa_mem/{sample}.log` to `logs/bwa_mem.log`.

**Expected error:** Snakemake requires log files and output files to use the same wildcards. Removing `{sample}` from the log filename causes a wildcard-related rule error.

**Fix:** Restore the original log path:

`log: "logs/bwa_mem/{sample}.log"`

**Explanation:** Each sample produces its own alignment output and must have a corresponding log file. Including `{sample}` ensures that the logs are correctly associated with each sample.

**Status:** The error is described as expected until the deliberate test is performed.

## Failure 3: Ambiguous Rules Without Wildcard Constraints

**Test:** Temporarily remove `wildcard_constraints` from the `fastp_paired` and `fastp_single` rules.

**Expected error:** `AmbiguousRuleException`

**Explanation:** Both trimming rules can match the same R1 trimmed FASTQ output when wildcard constraints are missing. Snakemake cannot determine which rule should produce the file.

**Fix:** Restore the sample constraints:

- Paired-end trimming: `sample=one_of(PAIRED)`
- Single-end trimming: `sample=one_of(SINGLE)`

These constraints ensure that paired-end samples use the paired trimming rule and single-end samples use the single trimming rule.

**Status:** The ambiguity needs to be verified with a deliberate dry run.

## Failure 4: Running Without Apptainer on Explorer

**Test:** Temporarily disable `software-deployment-method: apptainer` in `profiles/explorer/profile.yaml`.

**Expected issue:** A bioinformatics command that is available inside the container may not be available in the job environment.

**Expected error:** `command not found`, potentially with exit code `127`.

**Fix:** Restore the Explorer profile setting:

`software-deployment-method: apptainer`

**Explanation:** Explorer uses Apptainer to execute the required bioinformatics tools inside their designated container images. Disabling container deployment can prevent the tools from running.

**Status:** The specific failure and exit code need to be confirmed by a deliberate test.

## Successful Explorer Pipeline Execution

The eight-sample Snakemake variant-calling workflow successfully completed on October 16, 2026.

**Initial Explorer SLURM job:** `11141488`

- Completed 38 of 38 workflow steps.
- Generated the cohort VCF, variant table, and other pipeline outputs.

**Final Explorer SLURM job:** `11149513`

- Completed 11 of 11 workflow steps.
- Finished the eight FastQC jobs, MultiQC reporting, and publishing stages.

The final outputs are stored in `cluster-run-smk/`, including:

- `cohort.filtered.vcf.gz`
- `cohort.filtered.vcf.gz.tbi`
- `variants.tsv`
- `multiqc_report.html`
- `samples.tsv`
- `manifest.json`
- `records-sha256.txt`
- SLURM execution logs

## Week 4 and Week 5 Record Comparison

The Nextflow and Snakemake workflows produced different record checksums.

The Week 4 Nextflow workflow uses GenomicsDBImport for joint genotyping and QD/FS-based variant filtering, while the Week 5 Snakemake workflow uses CombineGVCFs and QUAL-based filtering. These differences can affect the resulting variant records and annotations.

The checksums and explanation are saved in `cluster-run-smk/records-sha256.txt`.

## Conclusion

The Snakemake workflow successfully processed all eight samples on Explorer and generated the required output files. The troubleshooting cases demonstrate important concepts related to incomplete jobs, wildcard consistency, rule ambiguity, and container deployment.

The four deliberate failure tests should be performed and their actual error messages recorded before describing them as observed failures.

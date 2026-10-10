# Week 4 Troubleshooting

## 1. Interrupt a smoke run and resume

- **Command:** Interrupted a smoke run with `Ctrl+C`, then reran the same command with `-resume`.
- **What it printed:** `VALIDATE` had 1 cached task. `FASTP` processed 3 samples, with 2 cached tasks. `FASTQC` processed 3 samples with none cached. `BWA_MEM` and later stages ran again. Overall, 17 tasks ran and 3 were cached.
- **Fix:** No pipeline change was needed. Using `-resume` reused completed tasks, while interrupted or uncached tasks ran again.

## 2. Pass the reference as a queue channel

- **Command:** Changed the `BWA_MEM` call to `BWA_MEM(FASTP.out.reads, channel.fromPath(params.ref), ref_index)` and ran the smoke dataset.
- **What it printed:** `BWA_MEM` processed 1 item, and the workflow completed without an error. The run had 14 tasks instead of 20, and the VCF `#CHROM` header contained only `smoke_01`.
- **Fix:** Passed the reference as a reusable value using `file(params.ref)` instead of a queue channel.

## 3. Remove the escape before `$` in command substitution

- **Command:** Changed the `VALIDATE` command to `n_rows=$(tail -n +2 ${samplesheet} | grep -c .)`, removing the backslash before `$`.
- **What it printed:** The generated `.command.sh` contained `n_rows=samplesheet.csvtail -n +2  | grep -c .)`. `.command.err` reported `syntax error near unexpected token ')'`. Running `bash .command.run` in the work directory produced the same error and exited with status 2.
- **Fix:** Restored the escape before `$` so Bash could evaluate the command substitution: `n_rows=\$(tail -n +2 ${samplesheet} | grep -c .)`.

## 4. Set HaplotypeCaller time to two minutes on Explorer

- **Command:** Set `time = '2m'` for `HAPLOTYPECALLER` and submitted the pipeline on Explorer.
- **What it printed:** Nextflow reported `terminated with an error exit status (140)`, and the task's `.exitcode` contained `140`. Slurm job `10949468` (`HAPLOTYPECALLER (NA12892)`) was `FAILED` with exit code `12:0`, elapsed time `00:01:33`, and a time limit of `00:02:00`. The other six HaplotypeCaller jobs were reported as `CANCELLED+`.
- **Fix:** Restored `time = '1h'` in `nextflow.config` and resubmitted with `-resume` to reuse completed tasks.

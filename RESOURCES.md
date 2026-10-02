# Resource Measurements

## Successful Week 2 Explorer Run

The per-sample Slurm array used 4 CPUs per task, 8 GB requested memory, and a 2-hour time limit. All 8 array tasks completed successfully with exit code 0:0.

| Task | CPUs | Elapsed | MaxRSS |
|---|---:|---:|---:|
| 10753126_1 | 4 | 00:09:04 | 6.69 GiB |
| 10753126_2 | 4 | 00:09:04 | 6.68 GiB |
| 10753126_3 | 4 | 00:05:46 | 6.02 GiB |
| 10753126_4 | 4 | 00:08:02 | 6.43 GiB |
| 10753126_5 | 4 | 00:05:50 | 6.04 GiB |
| 10753126_6 | 4 | 00:08:42 | 11.87 GiB |
| 10753126_7 | 4 | 00:13:59 | 7.65 GiB |
| 10753126_8 | 4 | 00:10:06 | 14.00 GiB |

The cohort job used 4 CPUs and completed successfully in 00:08:35 with exit code 0:0. Its MaxRSS was 1,563,788K, approximately 1.49 GiB.

## Measured seff output

The actual `seff` output for the successful cohort job was:

```text
Job ID: 10753128

Cluster: explorer

User/Group: nayak.shi/users

State: COMPLETED (exit code 0)

Nodes: 1

Cores per node: 4

CPU Utilized: 00:08:54

CPU Efficiency: 25.92% of 00:34:20 core-walltime

Job Wall-clock time: 00:08:35

Memory Utilized: 1.49 GB

Memory Efficiency: 18.64% of 8.00 GB
```

## Core-count comparison

A BWA alignment benchmark was run on the same NA07357 trimmed paired-end reads using the same Explorer reference.

| CPUs | BWA wall-clock time |
|---:|---:|
| 2 | 7m 58.043s |
| 4 | 3m 39.207s |

The 4-core benchmark reduced wall-clock time by approximately 54% compared with the 2-core run. Based on this measured comparison, 4 CPUs per task were retained for the Week 2 per-sample jobs.

## Resource decision

The measurements showed substantial variation in per-sample memory usage. Most tasks used approximately 6–8 GiB, but task 6 reached 11.87 GiB and task 8 reached 14.00 GiB. Therefore, the 8 GB request was not sufficient to provide comfortable headroom for the observed per-sample peak usage. The successful Week 2 run is retained as the measured result, while a future production run should request more memory for the per-sample jobs.

The cohort job used only 1.49 GB of memory and had 25.92% CPU efficiency, so its measured resource usage was much lower than the per-sample jobs.

## Accounting commands

The resource measurements were obtained using:

```bash
sacct -j 10753126 --format=JobID,State,Elapsed,AllocCPUS,MaxRSS,ExitCode
sacct -j 10753128 --format=JobID,State,Elapsed,AllocCPUS,MaxRSS,ExitCode
seff 10753128
```

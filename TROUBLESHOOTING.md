# Week 3 Container Troubleshooting

## Failure 1: Unpinned Dependencies
When using an unpinned Dockerfile (base image with FROM ubuntu:latest instead of pinned version), rebuilding with --pull --no-cache on a different day results in different package versions being installed. For example, on Day 1 a build might install dpkg 1.20.9 but on Day 2 it could install dpkg 1.21.1, causing version inconsistencies across runs.

Root cause: Base image tag points to the latest version at build time; rebuilding later pulls newer versions.

## Failure 2: Missing Bind Mount
Job 10769757_1: When --bind /courses/BINF6610.202710,/scratch/${USER} was removed from the apptainer exec command:
mkdir: cannot create directory '/scratch': Read-only file system
The container filesystem became read-only because scratch space wasn't bound, preventing any writes to /scratch directories.

Root cause: Without --bind, the container cannot access host filesystem paths.

## Failure 3: Missing Thread Environment Variable
Job 10770880_1: When --env THREADS and --env SLURM_CPUS_PER_TASK were removed from the apptainer exec command, GATK defaulted to single-threaded execution:
IntelPairHmm - Requested threads: 1
The bwa command also used -t 1 instead of the intended -t 4.

Root cause: Pipeline scripts rely on THREADS environment variable; without it, tools default to single thread.

## Failure 4: Architecture Mismatch
When attempting to pull an arm64 image on an amd64 cluster:
apptainer pull --force --arch arm64 /tmp/arch-test/arm64-test.sif docker://ubuntu:24.04
FATAL: could not open image /tmp/arch-test/arm64-test.sif: the image's architecture (arm64) could not run on the host's (amd64)
The container architecture must match the compute node architecture.

Root cause: Image architecture must be compatible with host; arm64 images cannot run on amd64 systems.

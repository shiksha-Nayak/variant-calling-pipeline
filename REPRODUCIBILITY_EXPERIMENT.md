# Week 3 Reproducibility Experiment: Unpinned Dockerfile

## Objective
Demonstrate how using `FROM ubuntu:latest` without a pinned digest leads to non-reproducible builds when rebuilt on different days.

## Setup
Dockerfile uses `FROM ubuntu` (equivalent to `FROM ubuntu:latest`) with `apt-get install curl`.

## Results

### First Build (Friday, October 2, 2026)
Base image digest: `sha256:cd1dba651b3080c3686ecf4e3c4220f026b521fb76978881737d24f200828b2b`

### Second Build (Saturday, October 3, 2026) with `--pull --no-cache`
Base image digest: `sha256:3595d7fc4286a33fad0fd853a4063e654287a9c3787437d7937c94ca3f7a804e`

### Package Version Differences
| Package | First Build | Second Build |
|---------|------------|--------------|
| dpkg | 1.22.6ubuntu6.5 | 1.23.7ubuntu1 |
| libc6 | 2.39-0ubuntu8.6 | 2.43-2ubuntu2.4 |
| curl | 8.5.0-2ubuntu10.15 | 8.18.0-1ubuntu2.7 |
| libcurl4t64 | 8.5.0-2ubuntu10.15 | 8.18.0-1ubuntu2.7 |
| libcrypt1 | 1:4.4.36-4build1 | 1:4.5.1-1 |

Total package differences: 242 lines

## Conclusion
Rebuilding an unpinned image after 24 hours pulls newer base image versions and installs newer dependency packages, causing non-reproducible builds. Pinning base image digests (as in the production Dockerfile) ensures reproducibility across time.

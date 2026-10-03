# Container Image

## The pushed image

docker.io/nayakshi/variant-call@sha256:362030c575c53f64a9bef692c9ebe84ef6cc7d064d6513acabc8a68d30a37747

## Image Details

- Docker Hub image: `docker.io/nayakshi/variant-call:week3`
- Image digest: `sha256:362030c575c53f64a9bef692c9ebe84ef6cc7d064d6513acabc8a68d30a37747`
- Build platform: `linux/amd64`
- Base image: `mambaorg/micromamba:2.0.5-ubuntu24.04`
- Base image digest: `sha256:1c62a28916ad7a4533555a542a5410e55ea2ed2c1e29f00c8fc3f1c8add111d5`

## Pinned tool versions

- bwa=0.7.19
- samtools=1.24
- bcftools=1.24
- gatk4=4.6.2.0
- fastqc=0.12.1
- fastp=1.3.7
- multiqc=1.35
- git=2.47.1

## Build and verification

The image was built for `linux/amd64` so it can run on the x86_64 Explorer cluster. The seven required bioinformatics tools were checked inside the image and matched the course environment versions.

The image was pushed to Docker Hub as a public image and verified as accessible.

FROM mambaorg/micromamba:2.0.5-ubuntu24.04

RUN micromamba install -y -n base -c conda-forge -c bioconda \
    bwa=0.7.19 \
    samtools=1.24 \
    bcftools=1.24 \
    gatk4=4.6.2.0 \
    fastqc=0.12.1 \
    fastp=1.3.7 \
    multiqc=1.35 \
    git=2.47.1 \
    && micromamba clean --all --yes

ENV PATH=/opt/conda/bin:$PATH

WORKDIR /workspace

# Install AWS CLI v2 from the official AWS CLI image
COPY --from=public.ecr.aws/aws-cli/aws-cli:2.37.12 /usr/local/aws-cli /usr/local/aws-cli

USER root
RUN ln -s /usr/local/aws-cli/v2/current/bin/aws /usr/local/bin/aws

# Copy the pipeline into the container
COPY . /pipeline/

# Make the AWS Batch entry script executable
RUN chmod +x /pipeline/aws/batch_run.sh \
    && ln -s /pipeline/aws/batch_run.sh /usr/local/bin/batch_run.sh

ARG PIPELINE_GIT_SHA
ENV PIPELINE_GIT_SHA=${PIPELINE_GIT_SHA}
WORKDIR /pipeline

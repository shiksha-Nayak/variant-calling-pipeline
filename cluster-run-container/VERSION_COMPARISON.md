# Version Comparison

The course Conda environment and the Week 3 Apptainer image were compared using `tests/print_versions.sh`.

All seven required bioinformatics tools matched the course environment versions:

- bwa 0.7.19
- samtools 1.24
- bcftools 1.24
- gatk4 4.6.2.0
- fastqc 0.12.1
- fastp 1.3.7
- multiqc 1.35

The only `diff` output was for GATK because the JAR is installed at different filesystem paths in Conda and the container. The reported GATK version is 4.6.2.0 in both environments.

Therefore, the version comparison confirms that the container uses the required course tool versions.

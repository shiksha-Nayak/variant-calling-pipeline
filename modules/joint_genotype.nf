process JOINT_GENOTYPE {
    container params.containers.gatk

    input:
    path gvcfs
    path tbis
    path ref
    path ref_index
    path ref_dict
    val region

    output:
    tuple path('cohort.vcf.gz'), path('cohort.vcf.gz.tbi'), emit: vcf

    script:
    def gvcf_args = [gvcfs].flatten().collect { "-V ${it}" }.join(' ')
    """
    gatk GenomicsDBImport \\
        ${gvcf_args} \\
        --genomicsdb-workspace-path genomicsdb \\
        -L ${region}

    gatk GenotypeGVCFs \\
        -R ${ref} \\
        -V gendb://genomicsdb \\
        -O cohort.vcf.gz
    """
}

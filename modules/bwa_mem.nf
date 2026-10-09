process BWA_MEM {
    tag "${meta.id}"
    container params.containers.bwa

    input:
    tuple val(meta), path(reads)
    path ref
    path ref_index

    output:
    tuple val(meta), path("${meta.id}.sorted.bam"), emit: bam

    script:
    """
    bwa mem -t ${task.cpus} -R "@RG\\tID:${meta.id}\\tSM:${meta.id}" ${ref} ${reads} \\
        | samtools sort -o ${meta.id}.sorted.bam -
    """
}

process MULTIQC {
    container params.containers.multiqc

    input:
    path fastqc_zips
    path fastp_jsons

    output:
    path 'multiqc_report.html', emit: report

    script:
    """
    multiqc . -n multiqc_report.html
    """
}

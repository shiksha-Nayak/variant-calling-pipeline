process VALIDATE {
    container params.containers.tools

    input:
    path samplesheet
    path fastqs
    path ref
    path ref_index
    path ref_dict

    output:
    path samplesheet, emit: sheet

    script:
    """
    # Check samplesheet is valid CSV
    if ! head -1 ${samplesheet} | grep -q "sample_id"; then
        echo "ERROR: samplesheet missing 'sample_id' column" >&2
        exit 1
    fi
    echo "Samplesheet validation passed"
    """
}

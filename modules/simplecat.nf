// modules/simplecat.nf
process SIMPLECAT {
    label "process_low"
    input:
    val tool
    path header
    path files

    output:
    path "${tool}_combined.tsv"

    script:
    """
        cat ${header} ${files} > ${tool}_combined.tsv
    """
}


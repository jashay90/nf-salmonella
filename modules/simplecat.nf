// modules/simplecat.nf
process SIMPLECAT {
    label "process_low"
    input:
    path header
    path files

    output:
    path "combined.tsv"

    script:
    """
        cat ${header} ${files} > combined.tsv
    """
}


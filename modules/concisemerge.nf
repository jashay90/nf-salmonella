// modules/concisemerge.nf
process CONCISEMERGE {
    label "process_low"
    input:
    val tool
    path tsv_files

    output:
    path "${tool}_combined.tsv"

    script:
    """
    # Grab the header from just one file (they're all identical)
    head -n1 \$(ls ${tsv_files} | head -n1) > ${tool}_combined.tsv

    # Strip the header from every file, concatenate, append
    tail -n +2 -q ${tsv_files} >> ${tool}_combined.tsv
    """
}


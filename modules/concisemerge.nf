// modules/concisemerge.nf
process CONCISEMERGE {
    label "process_low"
    input:
    path tsv_files

    output:
    path "combined.tsv"

    script:
    """
    # Grab the header from just one file (they're all identical)
    head -n1 \$(ls ${tsv_files} | head -n1) > combined.tsv

    # Strip the header from every file, concatenate, append
    tail -n +2 -q ${tsv_files} >> combined.tsv
    """
}


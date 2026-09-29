// modules/addidcolumn.nf
process ADDIDCOLUMN {
    tag "${meta.id}"
    label "process_low"
    input:
    tuple val(meta), path(tsv)

    output:
    tuple val(meta), path("${meta.id}.labelled.tsv")

    script:
    """
    awk -v id="${meta.id}" 'BEGIN{FS=OFS="\t"} 
        NR==1 {print "id", \$0; next} 
        {print id, \$0}' ${tsv} > ${meta.id}.labelled.tsv
    """
}


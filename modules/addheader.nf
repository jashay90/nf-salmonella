// modules/addheader.nf
process ADDHEADER {
	tag "${meta.id}"
	label "process_low"
	input:
	tuple val(meta), path(tsv)
	
	output:
	tuple val(meta), path("${meta.id}.labelled.tsv")

	script:
	"""
	echo -e "\n\n" > ${meta.id}.labelled.tsv
	echo Results from ${meta.id}: >> ${meta.id}.labelled.tsv
	cat ${tsv} >> ${meta.id}.labelled.tsv
	"""
}

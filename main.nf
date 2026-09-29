#!/usr/bin/env nextflow
nextflow.enable.dsl = 2
include { SISTR } from './modules/nf-core/sistr/main'
include { MLST } from './modules/nf-core/mlst/main'
include { ADDIDCOLUMN as SISTRADDID } from './modules/addidcolumn.nf'
include { CONCISEMERGE as SISTRMERGE } from './modules/concisemerge.nf'
include { ADDIDCOLUMN as MLSTADDID } from './modules/addidcolumn.nf'
include { SIMPLECAT as MLSTMERGE } from './modules/simplecat.nf'
include { ADDHEADER as RESFINDERHEADER } from './modules/addheader.nf'
include { SIMPLECAT as RESFINDERMERGE } from './modules/simplecat.nf'
include { ADDHEADER as POINTFINDERHEADER } from './modules/addheader.nf'
include { SIMPLECAT as POINTFINDERMERGE } from './modules/simplecat.nf'
include { ADDHEADER as SPIFINDERHEADER } from './modules/addheader.nf'
include { SIMPLECAT as SPIFINDERMERGE } from './modules/simplecat.nf'
include { CONCISEMERGE as SEQSEROMERGE } from './modules/concisemerge.nf'
include { ADDHEADER as MOBADDHEADER } from './modules/addheader.nf'
include { SIMPLECAT as MOBMERGE } from './modules/simplecat.nf'
include { sortByID } from './lib/utils.nf'

process RESFINDER {
	tag "running resfinder on ${meta.id}"
	label "process_low"
	input:
	tuple val(meta), path(fasta)

	output:
	tuple val(meta), path("${fasta.simpleName}/ResFinder_results_tab.txt"), emit: resfinder
	tuple val(meta), path("${fasta.simpleName}/PointFinder_results.txt"), emit: pointfinder
	tuple val("{task.process}"), val("resfinder"), eval("python -m resfinder -v"), emit: versions_resfinder, topic: versions

	script:
	"""
	python3 -m resfinder -o ${fasta.simpleName} -ifa ${fasta} -db_res ${params.resfinder_db} --acquired -s "Salmonella enterica" -l 0.6 -t 0.9 --point -db_point ${params.pointfinder_db} -l_p 0.6 -t_p 0.9
	"""
}

process SPIFINDER {
	tag "running spifinder on ${meta.id}"
	label "process_low"
        input:
        tuple val(meta), path(fasta)

        output:
        tuple val(meta), path("${fasta.simpleName}/results_tab.tsv"), emit: spifinder
        tuple val("{task.process}"), val("spifinder"), eval("git -C ${file(params.spifinder_py).getParent()} log -n 1 --pretty=format:%cd"), emit: versions_spifinder, topic: versions

        script:
        """
	mkdir ${fasta.simpleName}
	python3 ${params.spifinder_py} -i ${fasta} -o ${fasta.simpleName} -p ${params.spifinder_db} -l 0.6 -t 0.9 -x
        """

}

process ABRICATE {
	tag "running abricate on ${meta.id}"
	label "process_medium"
	label "abricate"
	input:
	tuple val(meta), path(fasta)

	output:
	tuple val(meta), path("${meta.id}_results.tab"), emit: abricate
	tuple val("{task.process}"), val("abricate"), eval("abricate --version | sed 's/abricate\s//'"), emit: versions_abricate, topic: versions

	script:
	"""
	abricate --db vfdb --threads ${task.cpus} ${fasta} > ${meta.id}_results.tab
	"""
}

process ABRICATEMERGE {
	tag "merging abricate results"
	label "process_low"
	label "abricate"
	input:
	path files

	output:
	path "combined.tsv"

	script:
	"""
	abricate --summary ${files} > combined.tsv
	"""
}

process SEQSERO2 {
	tag "running seqsero2 on ${meta.id}"
	label "process_low"
	input:
	tuple val(meta), path(fasta)

	output:
	tuple val(meta), path("${fasta.simpleName}/${fasta.simpleName}_SeqSero_result.tsv"), emit: seqsero
	tuple val("${task.process}"), val('seqsero2'), eval('SeqSero2_package.py --version 2>&1 | sed \'s/^.*SeqSero2_package.py //\''), emit: versions_seqsero2, topic: versions

	script:
	"""
	SeqSero2_package.py -m k -t 4 -i ${fasta} -d ${fasta.simpleName}
	mv ${fasta.simpleName}/SeqSero_result.tsv ${fasta.simpleName}/${fasta.simpleName}_SeqSero_result.tsv
	"""
}

process MOBSUITE {
	tag "running mob_recon on ${meta.id}"
	label "process_medium"
	input:
	tuple val(meta), path(fasta)

	output:
	path("${fasta.simpleName}/contig_report.txt") // just confirming this exists
	tuple val(meta), path("${fasta.simpleName}/mobtyper_results.txt"), optional: true, emit: mobsuite
	tuple val("${task.process}"), val('mob_recon'), eval("mob_recon -h | grep version | sed 's/.*\s//'"), emit: versions_mobsuite, topic: versions

	script:
	"""
	mob_recon --infile ${fasta} --outdir ${fasta.simpleName} -n ${task.cpus} -f --min_con_cov 90 --min_mob_cov 90 --min_rep_cov 90
	"""
}

params.genomes = null
params.outdir = "results"

workflow {
	genome_ch = Channel.fromPath(params.genomes).map { fasta ->
		def sample_id = fasta.simpleName
		tuple ([ id: sample_id ], fasta)
		}
	
	SISTR(genome_ch)
	SISTRMERGE(sortByID(SISTRADDID(SISTR.out.tsv)))
	
	MLST(genome_ch)
	MLSTMERGE(file(params.mlst_header, checkIfExists: true), sortByID(MLST.out.tsv))
	
	RESFINDER(genome_ch)
	RESFINDERHEADER(RESFINDER.out.resfinder)
	RESFINDERMERGE([], sortByID(RESFINDERHEADER.out))
	POINTFINDERHEADER(RESFINDER.out.pointfinder)
	POINTFINDERMERGE([], sortByID(POINTFINDERHEADER.out))
	
	SPIFINDER(genome_ch)
	SPIFINDERHEADER(SPIFINDER.out.spifinder)
	SPIFINDERMERGE([], sortByID(SPIFINDERHEADER.out))
	
	ABRICATE(genome_ch)
	ABRICATEMERGE(sortByID(ABRICATE.out.abricate))
	
	SEQSERO2(genome_ch)
	SEQSEROMERGE(sortByID(SEQSERO2.out.seqsero))
	
	MOBSUITE(genome_ch)
	MOBADDHEADER(MOBSUITE.out.mobsuite)
	MOBMERGE([], sortByID(MOBADDHEADER.out))
	
}

#!/usr/bin/env nextflow
nextflow.enable.dsl = 2
nextflow.preview.topic=true

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
include { CONCISEMERGE as MGEMERGE } from './modules/concisemerge.nf'
include { WRITE_JSONS } from './modules/write_jsons.nf'
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
	python3 -m resfinder -o ${fasta.simpleName} -ifa ${fasta} -db_res ${params.resfinder_db} --acquired --point -db_point ${params.pointfinder_db} ${params.resfinder_params}
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
	python3 ${params.spifinder_py} -i ${fasta} -o ${fasta.simpleName} -p ${params.spifinder_db} ${params.spifinder_params}
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
	abricate --threads ${task.cpus} ${params.abricate_params} ${fasta} > ${meta.id}_results.tab
	"""
}

process ABRICATEMERGE {
	tag "merging abricate results"
	label "abricate"
	input:
	path files

	output:
	path "abricate_combined.tsv"

	script:
	"""
	abricate --summary ${files} > abricate_combined.tsv
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
	SeqSero2_package.py -i ${fasta} -d ${fasta.simpleName} ${params.seqsero_params}
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
	tuple val(meta), path("${fasta.simpleName}/${fasta.simpleName}.mge.report.txt"), optional:true, emit: mge
	tuple val("${task.process}"), val('mob_recon'), eval("mob_recon -h | grep version | sed 's/.*\s//' | head -1"), emit: versions_mobsuite, topic: versions

	script:
	"""
	mob_recon --infile ${fasta} --outdir ${fasta.simpleName} -n ${task.cpus} ${params.mobsuite_params}
	mv ${fasta.simpleName}/mge.report.txt ${fasta.simpleName}/${fasta.simpleName}.mge.report.txt
	"""
}

process GRABMLST {
	tag "extracting MLST for ${meta.id}"
	label "process_low"
	publishDir "${params.outdir}/mlst", pattern: "*_mlst.txt"
	input:
	tuple val(meta), path(tsv)
	output:
	path("${meta.id}_mlst.txt")

	script:
	"""
	awk -F "\t" '{print \$3}' ${tsv} > ${meta.id}_mlst.txt
	"""
}

process GRABSEROVAR {
	tag "extracting serovar for ${meta.id}"
	label "process_low"
	publishDir "${params.outdir}/serovar", pattern: "*_serovar.txt"
	input:
	tuple val(meta), path(tsv)
	output:
	path("${meta.id}_serovar.txt")

	script:
	"""
	tail -1 ${tsv} | awk -F "\t" '{print \$15}' > ${meta.id}_serovar.txt
	"""
}

process GENERATESUMMARY {
	tag "creating a summary file"
	label "process_low"
	publishDir "${params.outdir}", pattern: "summary_report.xlsx", mode: 'copy'
	input:
	path(sistr)
	path(mlst)
	path(res)
	path(point)
	path(spi)
	path(abricate)
	path(seqsero)
	path(mob)
	path(mge)
	path(versions)
	path(params_file)

	output:
	path("summary_report.xlsx")

	script:
	"""
	generate_summary.py --sistr ${sistr} --mlst ${mlst} --res ${res} --point ${point} --spi ${spi} --abricate ${abricate} --seqsero ${seqsero} --mob ${mob} --mge ${mge} --params ${params_file} --versions ${versions} --output summary_report.xlsx
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
	sistrtsv = SISTR.out.tsv
	GRABSEROVAR(sistrtsv)
	sistr = SISTRMERGE('sistr', sortByID(SISTRADDID(sistrtsv)))
	
	MLST(genome_ch)
	mlsttsv = MLST.out.tsv
	GRABMLST(mlsttsv)
	mlst = MLSTMERGE('mlst', file(params.mlst_header, checkIfExists: true), sortByID(mlsttsv))
	
	RESFINDER(genome_ch)
	RESFINDERHEADER(RESFINDER.out.resfinder)
	res = RESFINDERMERGE('res', [], sortByID(RESFINDERHEADER.out))
	POINTFINDERHEADER(RESFINDER.out.pointfinder)
	point = POINTFINDERMERGE('point', [], sortByID(POINTFINDERHEADER.out))
	
	SPIFINDER(genome_ch)
	SPIFINDERHEADER(SPIFINDER.out.spifinder)
	spi = SPIFINDERMERGE('spi', [], sortByID(SPIFINDERHEADER.out))
	
	ABRICATE(genome_ch)
	abricate = ABRICATEMERGE(sortByID(ABRICATE.out.abricate))
	
	SEQSERO2(genome_ch)
	seqsero = SEQSEROMERGE('seqsero', sortByID(SEQSERO2.out.seqsero))
	
	MOBSUITE(genome_ch)
	MOBADDHEADER(MOBSUITE.out.mobsuite)
	mob = MOBMERGE('mob', [], sortByID(MOBADDHEADER.out))
	mge = MGEMERGE('mge', sortByID(MOBSUITE.out.mge))
	
	// make json metadata files
        ch_versions = Channel.topic('versions').unique()
        WRITE_JSONS(ch_versions.collect(flat: false))

	GENERATESUMMARY(sistr, mlst, res, point, spi, abricate, seqsero, mob, mge, WRITE_JSONS.out.vjson, WRITE_JSONS.out.pjson)
}

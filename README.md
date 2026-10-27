# Nextflow Pipeline for Salmonella Typing and Analysis
A nextflow pipeline to run various analysis tools on a Salmonella genome, and to generate a summary XLSX report.

## Prerequisites
In order to run this pipeline, you must have [conda](https://docs.conda.io/projects/conda/en/stable/index.html) and [nextflow](https://www.nextflow.io/docs/latest/index.html) installed. You also need to download the [SPIFinder tool](https://bitbucket.org/genomicepidemiology/spifinder).

### Databases
You will need to download the databases for [ResFinder](https://bitbucket.org/genomicepidemiology/resfinder_db), [PointFinder](https://bitbucket.org/genomicepidemiology/pointfinder_db), and [SPIFinder](https://bitbucket.org/genomicepidemiology/spifinder_db). Other database downloads will be handled by Nextflow/conda.

## Running the pipeline
Go into the main directory for this repository, and run this command:

	nextflow run main.nf -c main.config

You may also run the pipeline from a different directory, in which case you would include the path to main.nf and main.conf
ig, but note that nextflow will create virtual environments for every directory in which you run this pipeline.

A number of parameters may be set either by changing the main.config file or by adding flags with two dashes to the command
 above.

### Parameters most likely to change for each run
	genomes : assembly fasta files as input
	outdir: output directory

### Parameters to change during setup
	resfinder_db : The location of the downloaded ResFinder database
	pointfinder_db : The location of the downloaded PointFinder database
	spifinder_db : The location of the downloaded SPIFinder database
	spifinder_py : The location of the downloaded SPIFinder tool

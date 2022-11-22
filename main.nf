nextflow.enable.dsl = 2

log.info """\
INVADEseq
Bullman Lab
Fred Hutchinson CRC, Seattle WA
================================
manifest        : ${params.manifest}
fastq_dir       : ${params.fastq_dir}
output_dir      : ${params.output_dir}
cellranger_db   : ${params.cellranger_db}
pathseq_db      : ${params.pathseq_db}

cellranger      : ${params.container__cellranger}
"""

include { invadeseq_wf } from "./modules/invadeseq.nf"

workflow {

    if ( "${params.manifest}" == "false" ){error "Must provide parameter manifest"}
    if ( "${params.fastq_dir}" == "false" ){error "Must provide parameter fastq_dir"}
    if ( "${params.output_dir}" == "false" ){error "Must provide parameter output_dir"}
    if ( "${params.cellranger_db}" == "false" ){error "Must provide parameter cellranger_db"}
    if ( "${params.pathseq_db}" == "false" ){error "Must provide parameter pathseq_db"}

    invadeseq_wf()
}
nextflow.enable.dsl = 2

log.info """\
INVADEseq - Visium
Bullman Lab
Fred Hutchinson CRC, Seattle WA
================================
bam_folder      : ${params.bam_folder}
output_dir      : ${params.output_dir}
pathseq_db     : ${params.pathseq_db}
"""

include { visium_wf } from "./modules/visium.nf"

workflow {

    if ( "${params.bam_folder}" == "false" ){error "Must provide parameter bam_folder"}
    if ( "${params.output_dir}" == "false" ){error "Must provide parameter output_dir"}
    if ( "${params.pathseq_db}" == "false" ){error "Must provide parameter pathseq_db"}

    visium_wf()
}
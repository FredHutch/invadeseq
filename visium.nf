nextflow.enable.dsl = 2

log.info """\
INVADEseq
Bullman Lab
Fred Hutchinson CRC, Seattle WA
================================
bam_folder      : ${params.bam_folder}
output_dir      : ${params.output_dir}
pathseq_dir     : ${params.pathseq_dir}
"""

include { visium_wf } from "./modules.nf"

workflow {

    if ( "${params.bam_folder}" == "false" ){error "Must provide parameter bam_folder"}
    if ( "${params.output_dir}" == "false" ){error "Must provide parameter output_dir"}
    if ( "${params.pathseq_dir}" == "false" ){error "Must provide parameter pathseq_dir"}

    visium_wf()
}
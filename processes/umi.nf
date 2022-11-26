process generate_umi_gex {
    container "${params.container__python}"
    publishDir "${params.output_dir}/${samplename}", mode: 'copy', overwrite: true

    input:
    tuple val(samplename), path("pathseq_outputs/"), path("cellranger_outputs/")

    output:
    path "*"

    script:
    """#!/bin/bash
set -e

echo CONTENTS OF cellranger_outputs/:
ls -lah cellranger_outputs
echo
echo

echo CONTENTS OF pathseq_outputs/:
ls -lah pathseq_outputs
echo
echo

UMI_matrix.py \
    cellranger_outputs/*.bam \
    '${samplename}' \
    cellranger_outputs/*.barcodes.txt.gz \
    pathseq_outputs/${samplename}.pathseq.complete.bam \
    pathseq_outputs/${samplename}.pathseq.complete.csv \
    ${samplename}.visium.raw_matrix.readname \
    ${samplename}.visium.raw_matrix.unmap_cbub.bam \
    ${samplename}.visium.raw_matrix.unmap_cbub.fasta \
    ${samplename}.visium.raw_matrix.list \
    ${samplename}.visium.raw.raw_matrix.readnamepath \
    ${samplename}.visium.raw_matrix.genus.cell \
    ${samplename}.visium.raw_matrix.genus.csv \
    ${samplename}.visium.raw_matrix.validate.csv
    """
}
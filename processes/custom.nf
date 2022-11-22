process umi_annotator {
    container "${params.container__python}"
    publishDir "${params.output_dir}/${samplename}", mode: 'copy', overwrite: true

    input:
    tuple val(samplename), path(bam), path(barcodes), path("pathseq_path/")

    output:
    path "*"

    script:
    """#!/bin/bash
set -e

UMI_annotator.py \
    "${bam}" \
    '' \
    "${barcodes}" \
    pathseq_path/${samplename}.pathseq.complete.bam \
    pathseq_path/${samplename}.pathseq.complete.csv \
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
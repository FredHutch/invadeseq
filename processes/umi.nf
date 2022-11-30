process generate_umi {
    container "${params.container__python}"
    publishDir "${params.output_dir}/${samplename}/umi_${params.data_type}", mode: 'copy', overwrite: true
    tag "${samplename}"

    input:
    tuple val(samplename), path("pathseq_outputs/"), path(bam), path("filtered_feature_bc_matrix")

    output:
    path "*"

    script:
    """#!/bin/bash
set -e

echo CONTENTS OF cellranger outputs:
ls -lah ${bam}
ls -lah filtered_feature_bc_matrix
echo
echo

echo CONTENTS OF pathseq_outputs/:
ls -lah pathseq_outputs
echo
echo

UMI_matrix.py \
    ${bam} \
    '${samplename}' \
    filtered_feature_bc_matrix/barcodes.tsv.gz \
    pathseq_outputs/${samplename}.pathseq.complete.bam \
    pathseq_outputs/${samplename}.pathseq.complete.csv \
    ${samplename}.invadeseq.${params.data_type}.readname \
    ${samplename}.invadeseq.${params.data_type}.unmap_cbub.bam \
    ${samplename}.invadeseq.${params.data_type}.unmap_cbub.fasta \
    ${samplename}.invadeseq.${params.data_type}.list \
    ${samplename}.invadeseq.${params.data_type}.raw.readnamepath \
    ${samplename}.invadeseq.${params.data_type}.genus.cell \
    ${samplename}.invadeseq.${params.data_type}.genus.csv \
    ${samplename}.invadeseq.${params.data_type}.validate.csv

# Remove unneded files
echo Removing unneeded files
rm ${samplename}.invadeseq.${params.data_type}.genus.cell

echo Done
    """
}


process combine_all {
    container "${params.container__python}"
    publishDir "${params.output_dir}", mode: 'copy', overwrite: true

    input:
    path "inputs/"

    output:
    path "csv_novami.csv"

    script:
    """#!/bin/bash
set -e

merge_dedup_metadata.py inputs/
"""
}
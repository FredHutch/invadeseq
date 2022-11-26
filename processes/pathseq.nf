process pathseq {
    memory "${params.pathseq_mem_gb}.GB"
    cpus "${params.pathseq_cpus}"
    container "${params.container__pathseq}"
    publishDir "${params.output_dir}/${samplename}/${params.pathseq_subfolder}", mode: 'copy', overwrite: true
    
    input:
    tuple val(samplename), path(bam)
    path "pathseq_db/"

    output:
    tuple val(sample), path(bam)

    script:
    """#!/bin/bash
set -euo pipefail

echo Contents of pathseq database folder
ls -lahtr pathseq_db

gatk \
    --java-options "-Xmx${params.pathseq_mem_gb}g" \
    PathSeqPipelineSpark \
    --input ${bam} \
    --filter-bwa-image pathseq_db/pathseq_host.fa.img \
    --kmer-file pathseq_db/pathseq_host.bfi \
    --min-clipped-read-length 60 \
    --microbe-fasta pathseq_db/pathseq_microbe.fa \
    --microbe-bwa-image pathseq_db/pathseq_microbe.fa.img \
    --taxonomy-file pathseq_db/pathseq_taxonomy.db \
    --output ${samplename}.pathseq.complete.bam \
    --scores-output ${samplename}.pathseq.complete.csv \
    --is-host-aligned false \
    --filter-duplicates false \
    --min-score-identity .7
    """
}

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
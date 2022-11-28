process pathseq {
    memory "${params.pathseq_mem_gb}.GB"
    cpus "${params.pathseq_cpus}"
    container "${params.container__pathseq}"
    publishDir "${params.output_dir}/${samplename}/${params.pathseq_subfolder}", mode: 'copy', overwrite: true
    tag "${samplename}"
    
    input:
    tuple val(samplename), path(bam)
    path "pathseq_db"

    output:
    tuple val(sample), path("${samplename}.pathseq.*")

    script:
    """#!/bin/bash
set -euo pipefail

echo Contents of pathseq database folder
ls -lahtr pathseq_db

echo Setting up a local tmp dir
mkdir -p tmp

gatk \
    --java-options "-Xmx${params.pathseq_mem_gb}g" \
    PathSeqPipelineSpark \
    --input ${bam} \
    --filter-bwa-image pathseq_db/pathseq_host.fa.img \
    --kmer-file pathseq_db/pathseq_host.bfi \
    --min-clipped-read-length ${params.pathseq_min_clipped_read_length} \
    --microbe-dict pathseq_db/pathseq_microbe.dict \
    --microbe-bwa-image pathseq_db/pathseq_microbe.fa.img \
    --taxonomy-file pathseq_db/pathseq_taxonomy.db \
    --output ${samplename}.pathseq.complete.bam \
    --scores-output ${samplename}.pathseq.complete.csv \
    --is-host-aligned false \
    --filter-duplicates false \
    --min-score-identity ${params.pathseq_min_score_identity} \
    --tmp-dir "\$PWD/tmp"
    """
}

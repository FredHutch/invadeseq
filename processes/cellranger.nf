process cellranger_count {
    container "${params.container__cellranger}"
    publishDir "${params.output_dir}/${sample}/cellranger_${params.data_type}", mode: 'copy', overwrite: true
    label "cpu_large"
    tag "${sample}"

    input:
    tuple val(sample), val(gex_id)
    path "fastqs/"
    path "cellranger_db"

    output:
    tuple val(sample), path("${sample}/outs/*")

    """#!/bin/bash
set -e

cellranger count \
    --id=${sample} \
    --transcriptome=\$PWD/cellranger_db/ \
    --fastqs=fastqs/ \
    --sample=${gex_id}
    """
}
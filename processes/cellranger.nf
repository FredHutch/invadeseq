process cellranger_count {
    container "${params.container__cellranger}"
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
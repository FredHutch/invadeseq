process cellranger_count_gex {
    container "${params.container__cellranger}"
    label "cpu_large"

    input:
    tuple val(sample), val(gex_id)
    path "fastqs/"
    path "cellranger_db"

    output:
    tuple val(sample), path("${sample}/*")

    """#!/bin/bash
set -e

cellranger count \
    --id=${sample} \
    --transcriptome=\$PWD/cellranger_db/ \
    --fastqs=fastqs/ \
    --sample=${gex_id}
    """
}
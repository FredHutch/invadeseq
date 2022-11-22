process cellranger_count_gex {
    container "${params.container__cellranger}"
    label "cpu_large"

    input:
    tuple val(sample), path(gex_id)
    path "fastqs/"
    path "cellranger_db"

    output:
    tuple val(sample), path("*")

    """#!/bin/bash
set -e

cellranger count \
    --id=${gex_id} \
    --transcriptome=\$PWD/cellranger_db/ \
    --fastqs=fastqs/ \
    --sample=${sample}
    """
}
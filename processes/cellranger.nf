process cellranger_count_gex {
    container "${params.container__cellranger}"
    label "cpu_large"

    input:
    tuple val(sample), path("inputs/")
    path "cellranger_db/"

    output:
    tuple val(sample), path("*")

    """#!/bin/bash
set -e

cellranger count \
    --id=${sample} \
    --transcriptome=\$PWD/cellranger_db/ \
    --fastqs=\$PWD/inputs/ \
    --sample=${sample}
    """
}
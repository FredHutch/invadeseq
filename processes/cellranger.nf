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

process cellranger_aggr {
    container "${params.container__cellranger}"
    publishDir "${params.output_dir}/", mode: 'copy', overwrite: true
    label "cpu_large"

    input:
    path "inputs/"

    output:
    path "gex/*"

    """#!/bin/bash
set -e

echo sample_id,molecule_h5 > libraries.csv

for sample in *; do
    if [ -s \$sample/outs/molecule_info.h5 ]; then
        echo \$sample,\$sample/outs/molecule_info.h5 >> libraries.csv
    fi
done

cat libraries.csv

cellranger aggr \
    --id=gex \
    --csv=libraries.csv
    """
}
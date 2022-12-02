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
    --sample=${gex_id} \
    --chemistry=${params.chemistry}
    """
}

process cellranger_rename {
    container "${params.container__cellranger}"
    label "io_limited"

    input:
    tuple val(sample), path("molecule_info.h5")

    output:
    path "${sample}.molecule_info.h5"

    """#!/bin/bash
set -e

cp molecule_info.h5 ${sample}.molecule_info.h5
    """
}

process cellranger_aggr {
    container "${params.container__cellranger}"
    publishDir "${params.output_dir}/", mode: 'copy', overwrite: true
    label "cpu_large"

    input:
    path "*"

    output:
    path "gex/outs/*"

    """#!/bin/bash
set -e

echo sample_id,molecule_h5 > libraries.csv

for fp in *.molecule_info.h5; do
    if [ -s \$fp ]; then
        sample=\$(echo \$fp | sed 's/.molecule_info.h5//')
        echo \$sample,\$fp >> libraries.csv
    fi
done

cat libraries.csv

cellranger aggr \
    --id=gex \
    --csv=libraries.csv
    """
}

process cellranger_rename {
    container "${params.container__cellranger}"
    label "io_limited"

    input:
    tuple val(sample), path("molecule_info.h5")

    output:
    path "${sample}.molecule_info.h5"

    """#!/bin/bash
set -e

cp molecule_info.h5 ${sample}.molecule_info.h5
    """
}

process cellranger_aggr {
    container "${params.container__cellranger}"
    publishDir "${params.output_dir}/", mode: 'copy', overwrite: true
    label "cpu_large"

    input:
    path "*"

    output:
    path "gex/outs/*"

    """#!/bin/bash
set -e

echo sample_id,molecule_h5 > libraries.csv

for fp in *.molecule_info.h5; do
    if [ -s \$fp ]; then
        sample=\$(echo \$fp | sed 's/.molecule_info.h5//')
        echo \$sample,\$fp >> libraries.csv
    fi
done

cat libraries.csv

cellranger aggr \
    --id=gex \
    --csv=libraries.csv
    """
}
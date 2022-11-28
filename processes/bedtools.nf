process bam_to_fastq {
    container "${params.container__bedtools}"
    label "cpu_large"
    tag "${sample}"

    input:
    tuple val(sample), val(bam)

    output:
    tuple val(sample), path("${sample}.r1.fq"), path("${sample}.r2.fq")

    """#!/bin/bash
set -e

bedtools \
    bamtofastq \
        -i ${bam} \
        -fq ${sample}.r1.fq \
        -fq2 ${sample}.r2.fq
    """
}


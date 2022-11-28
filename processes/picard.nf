process fastq_to_bam {
    container "${params.container__picard}"
    label "cpu_large"
    tag "${sample}"

    input:
    tuple val(sample), path(fastq)

    output:
    tuple val(sample), path("${sample}.bam")

    """#!/bin/bash
set -e

EBROOTPICARD=/usr/local/share/picard-2.27.4-0

mkdir tmp

java \
    -Xmx700G \
    -Djava.io.tmpdir=\$PWD/tmp \
    -jar \$EBROOTPICARD/picard.jar \
    FastqToSam \
    FASTQ=${fastq} \
    OUTPUT=${sample}.bam \
    SAMPLE_NAME=${sample}
    """
}
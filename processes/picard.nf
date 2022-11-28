process fastq_to_bam {
    container "${params.container__picard}"
    label "cpu_large"
    tag "${sample}"

    input:
    tuple val(sample), val(fastq)

    output:
    tuple val(sample), path("${sample}.bam")

    """#!/bin/bash
set -e

EBROOTPICARD=/usr/local/share/picard-2.27.4-0

java -Xmx700G -jar $EBROOTPICARD/picard.jar FastqToSam \
    FASTQ=${fastq} \
    OUTPUT=${sample}.bam \
    READ_GROUP_NAME=H0164.2 \
    SAMPLE_NAME=PRJNA627695 \
    LIBRARY_NAME=Solexa-272222 \
    PLATFORM_UNIT=H0164ALXX140820.2 \
    PLATFORM=illumina 
    """
}
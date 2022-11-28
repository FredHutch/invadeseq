process trimmomatic {
    container "${container__trimmomatic}"
    label "cpu_large"
    tag "${sample}"

    input:
        tuple val(sample), path(fastq)

    output:
        tuple val(sample), path("SE_trim.fq")

"""#!/bin/bash
set -euo pipefail

EBROOTTRIMMOMATIC=/usr/local/share/trimmomatic-0.32-4

java -jar \
    \$EBROOTTRIMMOMATIC/trimmomatic.jar SE \
    -threads ${task.cpus} \
    ${fastq} \
    SE_trim.fq \
    ILLUMINACLIP:\$EBROOTTRIMMOMATIC/adapters/TruSeq3-PE-2.fa:2:30:10 \
    LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:36 HEADCROP:15
"""

}



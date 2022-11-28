// Run FastQC
process fastqc {
    container "${container__fastqc}"
    publishDir "${params.output_dir}/${sample}/${params.fastqc_subfolder}", mode: 'copy', overwrite: true
    label "cpu_large"
    tag "${sample}"

    input:
        tuple val(sample), path(fastq)

    output:
        file "*_fastqc.zip"

"""#!/bin/bash
set -euo pipefail

fastqc -t ${task.cpus} -o ./ ${fastq}
"""

}

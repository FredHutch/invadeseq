include { pathseq } from "./../processes/pathseq.nf"
include { umi_annotator } from "./processes/custom.nf"

workflow visium_wf {

    if ( "${params.bam_folder}" == "false" ){error "Must provide parameter bam_folder"}
    if ( "${params.output_dir}" == "false" ){error "Must provide parameter output_dir"}
    if ( "${params.pathseq_db}" == "false" ){error "Must provide parameter pathseq_db"}

    // Point to the pathseq database folder
    pathseq_db = file(
        "${params.pathseq_db}",
        checkIfExists: true,
        type: "dir"
    )

    // The bam_folder contains subfolders which are named for each sample
    // Inside each of the sample folders, the BAM file is named
    // with a predictable relative path.

    Channel
        .fromPath(
            "${params.bam_folder}/*",
            type: "dir",
            checkIfExists: true
        )
        .map {
            it -> [
                it.name,
                file(
                    "${params.bam_folder}/${it.name}/${params.spaceranger_bam_path}",
                    type: "file"
                )
            ]
        }
        .filter { !it[1].isEmpty() }
        .set { bam_ch }

    Channel
        .fromPath(
            "${params.bam_folder}/*",
            type: "dir",
            checkIfExists: true
        )
        .map {
            it -> [
                it.name,
                file(
                    "${params.bam_folder}/${it.name}/${params.spaceranger_barcodes_path}",
                    type: "file"
                )
            ]
        }
        .filter { !it[1].isEmpty() }
        .set { barcodes_ch }

    pathseq(
        bam_ch,
        pathseq_db
    )

    umi_annotator(
        bam_ch
            .join(barcodes_ch)
            .join(pathseq.out)
    )
}
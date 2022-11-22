// include { pathseq } from "./../processes/pathseq.nf"
include { cellranger_count_gex } from "./../processes/cellranger.nf"

workflow visium_wf {

    if ( "${params.manifest}" == "false" ){error "Must provide parameter manifest"}
    if ( "${params.output_dir}" == "false" ){error "Must provide parameter output_dir"}
    if ( "${params.cellranger_db}" == "false" ){error "Must provide parameter cellranger_db"}
    if ( "${params.pathseq_db}" == "false" ){error "Must provide parameter pathseq_db"}

    // Point to the cellranger database folder
    cellranger_db = file(
        "${params.cellranger_db}",
        checkIfExists: true,
        type: "dir"
    )

    // Point to the pathseq database folder
    pathseq_db = file(
        "${params.pathseq_db}",
        checkIfExists: true,
        type: "dir"
    )

    // Parse the manifest file provided by the user
    Channel
        .fromPath(
            "${params.manifest}",
            type: "file",
            checkIfExists: true
        )
        .splitCsv(
            header: true,
            strip: true
        )
        .map {
            it -> [
                it.sample,
                file(it.gex, type: "folder", checkIfExists: true),
                file(it.16S, type: "folder", checkIfExists: true)
            ]
        }
        .set { manifest }

    //////////////////////
    // ANALYZE GEX DATA //
    //////////////////////

    // Run the gene expression analysis for each sample
    cellranger_count_gex(
        manifest.map { it -> [it[0], it[1]] }
    )

    // // Run pathseq on the output from cellranger count for the GEX data
    // pathseq_gex(cellranger_count_gex.out)

    // // Generate the UMI matrix for GEX data
    // generate_umi_gex(pathseq_gex.out)

    // //////////////////////
    // // ANALYZE 16S DATA //
    // //////////////////////

    // // Run cellranger count on the 16S data
    // cellranger_count_16S(
    //     manifest.map { it -> [it[0], it[2]] }
    // )

    // // Convert those BAM files to FASTQ
    // bam_to_fastq(cellranger_count_16S.out)

    // // Run FASTQC on the raw reads
    // fastqc_raw(bam_to_fastq.out)

    // // Run Trimmomatic on the raw reads
    // trimmomatic(bam_to_fastq.out)

    // // Run FASTQC on the trimmed reads
    // fastqc_trimmed(trimmomatic.out)

    // // Make BAM files in preparation for pathseq
    // fastq_to_bam(trimmomatic.out)

    // // Run pathseq on the trimmed 16S data
    // pathseq_16S(fastq_to_bam.out)

    // // Generate the UMI matrix for 16S data
    // generate_umi_16S(pathseq_gex.out)

    // //////////////////////////////
    // // COMBINE GEX AND 16S DATA //
    // //////////////////////////////
    // combine_all(
    //     generate_umi_gex
    //         .out
    //         .join(
    //             generate_umi_16S
    //                 .out
    //         )
    // )

}
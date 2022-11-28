// include { pathseq } from "./../processes/pathseq.nf"
include { cellranger_count as cellranger_count_gex } from "./../processes/cellranger.nf"
include { cellranger_count as cellranger_count_16S } from "./../processes/cellranger.nf"
include { pathseq as pathseq_gex } from "./../processes/pathseq.nf" addParams(pathseq_subfolder: "pathseq_gex")
include { generate_umi_gex } from "./../processes/umi.nf"
include { validate_manifest } from "./../processes/validate.nf"
include { bam_to_fastq } from "./../processes/bedtools.nf"

workflow invadeseq_wf {

    if ( "${params.manifest}" == "false" ){error "Must provide parameter manifest"}
    if ( "${params.fastq_dir}" == "false" ){error "Must provide parameter fastq_dir"}
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

    // Get the complete list of FASTQ files in the input directory
    Channel
        .fromPath(
            "${params.fastq_dir}**.fastq.gz",
            type: "file",
            checkIfExists: true
        ).toSortedList()
        .set { fastq_ch }

    // Log the number of FASTQ files found
    fastq_ch
        .flatten()
        .count()
        .view { n -> "Found ${n} FASTQ files in ${params.fastq_dir}" }

    // Parse the manifest file provided by the user
    Channel
        .fromPath(
            "${params.manifest}",
            type: "file",
            checkIfExists: true
        ) | validate_manifest

    validate_manifest.out
        .splitCsv(
            header: true,
            strip: true
        )
        .map {
            it -> [
                it.sample,
                it.gex,
                it.microbial
            ]
        }
        .set { manifest }

    //////////////////////
    // ANALYZE GEX DATA //
    //////////////////////

    // Run the gene expression analysis for each sample
    cellranger_count_gex(
        manifest.map { it -> [it[0], it[1]] },
        fastq_ch,
        cellranger_db
    )

    cellranger_count_gex
        .out
        .transpose()
        .view()

    // Make a channel with just the BAM produced by the cellranger count command
    cellranger_count_gex
        .out
        .transpose()
        .filter {
            it[1].name.endsWith('.bam')
        }
        .set { cellranger_count_gex_bam }

    // Run pathseq on the output from cellranger count for the GEX data
    pathseq_gex(
        cellranger_count_gex_bam,
        pathseq_db
    )

    // Generate the UMI matrix for GEX data
    generate_umi_gex(
        pathseq_gex
            .out
            .join(
                cellranger_count_gex
                    .out
            )
    )

    //////////////////////
    // ANALYZE 16S DATA //
    //////////////////////

    // Run cellranger count on the 16S data
    cellranger_count_16S(
        manifest.map { it -> [it[0], it[2]] },
        fastq_ch,
        cellranger_db
    )

    // Make a channel with just the BAM produced by the cellranger count command
    cellranger_count_16S
        .out
        .transpose()
        .filter {
            it[1].name.endsWith('.bam')
        }
        .set { cellranger_count_16S_bam }

    // Convert those BAM files to FASTQ
    bam_to_fastq(
        cellranger_count_16S_bam
    )
    // Output: tuple val(sample), path(R1), path(R2)

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
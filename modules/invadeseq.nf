// include { pathseq } from "./../processes/pathseq.nf"
include { cellranger_count as cellranger_count_gex } from "./../processes/cellranger.nf" addParams(data_type: "gex", chemistry: "${params.gex_chemistry}")
include { cellranger_count as cellranger_count_16S } from "./../processes/cellranger.nf" addParams(data_type: "16S", chemistry: "${params.microb_chemistry}")
include { cellranger_rename } from "./../processes/cellranger.nf"
include { cellranger_aggr } from "./../processes/cellranger.nf"
include { pathseq as pathseq_gex } from "./../processes/pathseq.nf" addParams(pathseq_subfolder: "pathseq_gex")
include { pathseq as pathseq_16S } from "./../processes/pathseq.nf" addParams(pathseq_subfolder: "pathseq_16S")
include { generate_umi as generate_umi_gex } from "./../processes/umi.nf" addParams(data_type: "gex")
include { generate_umi as generate_umi_16S } from "./../processes/umi.nf" addParams(data_type: "16S")
include { combine_all } from "./../processes/umi.nf"
include { deduplication } from "./../processes/umi.nf"
include { validate_manifest } from "./../processes/validate.nf"
include { bam_to_fastq } from "./../processes/bedtools.nf"
include { fastqc as fastqc_raw } from "./../processes/fastqc.nf" addParams(fastqc_subfolder: "preqc")
include { fastqc as fastqc_trimmed } from "./../processes/fastqc.nf" addParams(fastqc_subfolder: "postqc")
include { trimmomatic } from "./../processes/trimmomatic.nf"
include { fastq_to_bam } from "./../processes/picard.nf"

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

    // Make a channel with just the BAM produced by the cellranger count command
    cellranger_count_gex
        .out
        .transpose()
        .filter {
            it[1].name.endsWith('.bam')
        }
        .set { cellranger_count_gex_bam }

    // Log the number of BAM files found
    cellranger_count_gex_bam
        .count()
        .view { n -> "Generated BAM files from ${n} GEX samples" }

    // Make a channel with just the barcodes produced by the cellranger count command
    cellranger_count_gex
        .out
        .transpose()
        .filter {
            it[1].name.endsWith('filtered_feature_bc_matrix')
        }
        .set { cellranger_count_gex_barcodes }

    // Log the number of barcodes files found
    cellranger_count_gex_barcodes
        .count()
        .view { n -> "Generated barcodes files from ${n} GEX samples" }

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
                cellranger_count_gex_bam
            )
            .join(
                cellranger_count_gex_barcodes
            )
        )

    // Aggregate all of the GEX count data
    cellranger_count_gex
        .out
        .transpose()
        .filter {
            it[1].name.endsWith('molecule_info.h5')
        }
        .set { cellranger_count_gex_h5 }

        cellranger_count_gex_h5
            .count()
            .view { n -> "Merging ${n} CellRanger counts results" }

        cellranger_count_gex_h5 \
        | cellranger_rename \
        | toSortedList \
        | cellranger_aggr

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

    // Run FASTQC on the raw read 1
    fastqc_raw(
        bam_to_fastq
            .out
            .map { it -> [it[0], it[1]] }
    )

    // Run Trimmomatic on the raw reads, but just the read 1
    trimmomatic(
        bam_to_fastq
            .out
            .map { it -> [it[0], it[1]] }
    )

    // Run FASTQC on the trimmed reads
    fastqc_trimmed(trimmomatic.out)

    // Make BAM files in preparation for pathseq
    fastq_to_bam(trimmomatic.out)

    // Run pathseq on the trimmed 16S data
    pathseq_16S(
        fastq_to_bam.out,
        pathseq_db
    )

    // Generate the UMI matrix for 16S data
    generate_umi_16S(
        pathseq_16S
            .out
            .join(
                cellranger_count_16S_bam
            )
            .join(
                cellranger_count_gex_barcodes
            )
    )

    //////////////////////////////
    // COMBINE GEX AND 16S DATA //
    //////////////////////////////

    genus_csv_list = generate_umi_gex
        .out
        .flatten()
        .mix(
            generate_umi_16S
                .out
                .flatten()
        )
        .filter {
            it.name.endsWith('genus.csv')
        }
        .toSortedList()

    combine_all(genus_csv_list)

   ///////////////////////////
   // PERFORM DEDUPLICATION //
   ///////////////////////////

    validate_csv_list_16S = generate_umi_16S
        .out
        .flatten()
        .filter {
            it.name.endsWith('validate.csv')
        }
        .toSortedList()

    validate_csv_list_gex = generate_umi_gex
        .out
        .flatten()
        .filter {
            it.name.endsWith('validate.csv')
        }
        .toSortedList()

    deduplication(
        combine_all.out,
        validate_csv_list_16S,
        validate_csv_list_gex
    )
}
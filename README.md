# INVADEseq
Analysis of combined 10X human and microbial data

## Input Data

To run INVADEseq, the user must provide single-cell sequencing data produced by the
10X Chromium platform, both for gene expression (GEX) and for 16S-enriched sequences.
In order to specify the location of the input data, the user will construct a
manifest file listing the paired datasets which were produced from each sample.

The inputs to this workflow will be the FASTQ files output from `cellranger mkfastq`.
After running `cellranger mkfastq`, the FASTQ files which are produced will be tagged
with the sample names used when preparing the samples for the 10X Chromium platform.
All of the FASTQ files being used as inputs must be contained at some level within
a shared directory.

The format of the manifest file will be a CSV with the column names `sample`, `gex`, and `microbial`.
The values provided in the `gex` and `microbial` columns will be the dataset IDs
which were used for the same biological source sample.

For example:

```
sample,gex,microbial
sampleA,sampleA_gex,sampleA_microbial
sampleB,sampleB_gex,sampleB_microbial
sampleC,sampleC_gex,sampleC_microbial
```

The manifest file must be provided to the workflow using the parameter `manifest`.

The root folder which contains all of the FASTQ files used in the analysis must be
provided with the parameter `fastq_dir`.
Note that any files with the extension `.fastq.gz` can be used in the analysis,
even if they are nested within additional subfolders.

## Reference Data

The user must provide reference databases for both the CellRanger-compatible transcriptome
as well as the PathSeq database.

Those databases are provided using the parameters:

  - CellRanger: `cellranger_db`
  - PathSeq: `pathseq_db`

## Running the Workflow

### Nextflow

The workflow can be run using the Nextflow workflow management system, which can be
set up following [their user documentation](https://nextflow.io/).

### Containers

The software used in each step of the workflow has been provided via Docker containers
which are specified in the workflow.
Those software containers can be used either via Docker ([installation instructions](https://docs.docker.com/get-docker/))
or Singularity ([installation instructions](https://docs.sylabs.io/guides/latest/user-guide/)).
Singularity is typically used on HPC systems which do not allow users the root
access needed for running Docker.

After either Docker or Singularity, Nextflow must be configured to use either
system as appropriate.
The most convenient way to set up this configuration is to create a file called
`nextflow.config` which follows [the configuration instructions for Nextflow](https://www.nextflow.io/docs/latest/config.html).
It is also possible to set up other types of job execution systems (e.g. AWS,
Google Cloud, Azure, SLURM, PBS) which can be managed directly by Nextflow.
This configuration file can be used across multiple runs of the workflow on
the same computational system.

### Reference Databases

To run the workflow, two reference databases are required.
The PathSeq database can be downloaded [from the Broad FTP server](https://software.broadinstitute.org/pathseq/Downloads.html).
The CellRanger database can be downloaded [from the 10X Genomics website](https://support.10xgenomics.com/single-cell-gene-expression/software/downloads/latest).
The paths to the root directory of both of these databases will be required
to run the workflow.

### Parameters

For each individual run, a file with the parameters for each run should be
created [in JSON format](https://www.w3schools.com/js/js_json_intro.asp),
typically called `params.json`.
The required parameters for the workflow are:

 - `manifest`: Manifest describing the paired datasets used for each sample
 - `fastq_dir`: Base folder which contains all of the FASTQ inputs
 - `cellranger_db`: Folder containing CellRanger database
 - `pathseq_db`: Folder containing the PathSeq database

 ### Launching the Workflow

 Once all of the previous steps have been completed, the workflow can be
 launched with a command like:

 ```bash
 nextflow run FredHutch/invadeseq -params-file params.json -c nextflow.config
 ```

 ## Quickstart (with the BASH Workbench)

 To more easily set up and launch the workflow, users may take advantage of
 a command-line utility called the [BASH Workbench](https://github.com/FredHutch/bash-workbench/wiki).
 This utility can be installed directly with the command `pip3 install bash-workbench`.
 After installation, the BASH Workbench can be launched interactively with the command
 `wb`.
 Users of the Fred Hutch computing cluster can launch the workbench directly
 via `wb` without the need for any installation.

 ### Setup

 To set up this workflow in the BASH Workbench, select:
 
 - Select `Manage Repositories`;
 - Select `Download New Repository`;
 - then enter `FredHutch/invadeseq` and confirm

 After setting up the workflow, the workbench can be exited with Control+C.

 ### Launching the Workflow

 After setting up the workflow, it can be run by:

 - Navigating to the folder intended for the output files;
 - Launching the BASH Workbench (`wb`);
 - Select `Run Tool`;
 - Select `FredHutch_invadeseq`;
 - Select `invadeseq`;
 - Enter [the appropriate parameters](#parameters);
 - Select `Review and Run`;
 - Select `FredHutch_invadeseq`;
 - Select `slurm` (if using an HPC SLURM cluster) or `docker` (for local execution);
 - Enter any needed parameters for the SLURM or Docker configuration. For example, SLURM users will need to enter the `scratch_dir` parameter using a folder on the scratch filesystem which can be used for temporary files;
 - Select `Review and Run`;
 - Select `Run Now`

 Once the workflow has been launched, a record will be saved of the parameters
 used for execution, as well as all of the logs which were produced during
 execution.

 ## Output Files

 The output files produced by the workflow include:

 ```bash
 csv_novami.csv                # Combined genus-level counts per cell
 gex/                          # Combined gene expression counts per cell
 <SAMPLE>/                     # Folder with sample-level results
          pathseq_16S/         # PathSeq results from 16S data
          pathseq_gex/         # PathSeq results from GEX data
          cellranger_16S/      # CellRanger results from 16S data
          cellranger_gex/      # CellRanger results from GEX data
          preqc/               # FASTQC results for 16S (R1) data pre-trimming
          postqc/              # FASTQC results for 16S (R1) data post-trimming
          umi_16S/             # UMI summary metrics for 16S data
          umi_gex/             # UMI summary metrics for GEX data
 ```

## Authors

Analysis code was written by Hanrui Wu (hwu at fredhutch dot org).
Workflow code was written by Samuel Minot (sminot at fredhutch dot org).

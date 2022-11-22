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

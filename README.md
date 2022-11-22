# INVADEseq
Analysis of combined 10X human and microbial data

## Input Data

To run INVADEseq, the user must provide single-cell sequencing data produced by the
10X Chromium platform, both for gene expression (GEX) and for 16S-enriched sequences.
In order to specify the location of the input data, the user will construct a
manifest file listing the location of those folders for each sample.
The contents of each folder will be the output from `cellranger mkfastq`.
To be clear, both the GEX and 16S data for each sample will each be located in a
distinct folder prior to running this workflow.

The format of the manifest file will be a CSV with the column names `sample`, `gex`, and `16S`.
For example:

```
sample,gex,16S
sampleA,/path/to/gex/for/sampleA,/path/to/16S/for/sampleA
sampleB,/path/to/gex/for/sampleB,/path/to/16S/for/sampleB
sampleC,/path/to/gex/for/sampleC,/path/to/16S/for/sampleC
```

The manifest file must be provided to the workflow using the parameter `manifest`.


## Reference Data

The user must provide reference databases for both the CellRanger-compatible transcriptome
as well as the PathSeq database.

Those databases are provided using the parameters:

  - CellRanger: `cellranger_db`
  - PathSeq: `pathseq_db`

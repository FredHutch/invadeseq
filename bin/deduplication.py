#!/usr/bin/env python3
from pathlib import Path
import pandas as pd
from collections import Counter
from sys import argv

"""
# The purpose of this script is deduplication of the merged metadata. Since there are replicated cell names from GEX libraries and 16s libraries, it is necessary to add UMI count from both techniques together into unique cell names.
# usage: 
# python metadata_dedup.py \
    GEX_pathogen_UMI_matrix_output_folder(with validation csvs) \
    16s_pathogen_UMI_matrix_output_folder(with validation csvs) \
    Merged_csv_matrix_from_previous_step \
    Dedup_csv_matrix
# Note: Merged_csv_matrix_from_previous_step is a csv file containg 7 clinical samples from our study
#       otherwise please modify the sample names in the script.
"""

def read_and_mkdic(validate_csv_file, sample_name):
    UMI_bac_list = []
    validate_csv = open(validate_csv_file,'r')
    for each_line in validate_csv:
        each_line = each_line.rstrip('\n')
        each_line = sample_name+'_'+each_line
        UMI_bac_list.append(each_line)
    return UMI_bac_list

#add lists together
# then count
def count_elements(merged_UMI_bac_list):
    count_dict = Counter(merged_UMI_bac_list)
    return count_dict

#add dics together: ndic = list(dict(dic0.items()) + list(dic1.items()))
#generate a dataframe, that will be a minux matrix
#df.values[rows, cols] = np.nan
def minux_matrix(count_dict,nova_mi_merged_csv_file,nova_mi_merged_csv_file_dedup):
    nova_mi_merged = pd.read_csv(
        nova_mi_merged_csv_file,
        header = 0,
        sep = ',',
        index_col='barcode'
    )
    print('before merge = ',len(nova_mi_merged))
    nova_mi_merged = nova_mi_merged.groupby(nova_mi_merged.index).sum()
    print('after merge = ',len(nova_mi_merged))
    n=0
    rowNamesArr = list(nova_mi_merged.index.values)
    columnsNamesArr = list(nova_mi_merged.columns.values)
    for each_cell_UMI in count_dict:
        n+=1
        if n%1000 == 0:
            print('now working on: ',n/len(count_dict)*100,'%')
        cell = each_cell_UMI.split('+')[0]
        pathogen = each_cell_UMI.split(',')[1]
        count = count_dict[each_cell_UMI]-1
        colindex = columnsNamesArr.index(pathogen)
        rowindex = rowNamesArr.index(cell)
        prev = int(nova_mi_merged.loc[cell,pathogen])
        nova_mi_merged.loc[cell,pathogen]=prev-count
        after = int(nova_mi_merged.loc[cell,pathogen])
    nova_mi_merged.to_csv(nova_mi_merged_csv_file_dedup,sep=',',index=True)
    return


def is_validate_csv(file: Path):

    if file.name.endswith(".validate.csv"):
        if '.invadeseq.' in file.name:
            return True
    return False


def parse_sample_name(file: Path):

    return file.name.split('.invadeseq.')[0]


def run():

    # Set up a list which will combine the contents of the
    # validate.csv files from both the GEX and 16S data
    UMI_bac_list=[]

    # Directory containing results from GEX 
    path_gex = argv[1]
    # Directory containing results from 16s
    path_16S = argv[2]

    # input file, merged UMI matrix generated from previous step
    nova_mi_merged_csv_file = argv[3]

    # output file
    nova_mi_merged_csv_file_dedup = argv[4]

    #also modified the cell names in sub merged csvs!

    # Process both of the folders of inputs, both for the
    # GEX data and the 16S data
    for folder in [path_gex, path_16S]:

        # Iterate over each fo the files in the folder
        for file in Path(folder).iterdir():

            # If the file is a validate.csv (which we expect)
            if is_validate_csv(file):

                # Extract the sample name
                sample_name = parse_sample_name(file)

                # Add the sample name to each row and extend UMI_bac_list
                UMI_bac_list.extend(
                    read_and_mkdic(
                        file.absolute(),
                        sample_name
                    )
                )

    count_dict = count_elements(UMI_bac_list)
    minux_matrix(
        count_dict,
        nova_mi_merged_csv_file,
        nova_mi_merged_csv_file_dedup
    )


if __name__ == "__main__":

    run()

#!/usr/bin/env python3
"""
Created on Thu Mar 13 9:31:11 2020
@author: Hanrui Wu
"""
import pysam
import sys
import gzip

# read PathSeq bam file, extract read names with YP tag
def read_cell_names1(pathseq_bam_file, write_bac):
    seqbam = pysam.AlignmentFile(pathseq_bam_file, "rb",threads=36)
    read_name_pathseq = open(write_bac,'w')
    total_pathseq_reads=0
    total_YP_reads=0
    for each_line in seqbam:
        total_pathseq_reads+=1
        if each_line.has_tag('YP'):
            total_YP_reads+=1
            outline = each_line.query_name + '\t' + each_line.get_tag('YP') + '\t' + str(each_line.mapping_quality) + '\n'
            read_name_pathseq.write(outline)
    print('Total reads in pathseq bam = ',total_pathseq_reads)
    print('Total reads in pathseq bam with YP tag  = ',total_YP_reads)
    return

# construct a dictionary for pathogen annotation
def read_readnames(readname_file):
    set_for_readnames = set()
    dict_name = {}
    with open (readname_file,'r') as r:
        for each_line in r:
            each_line = each_line.rstrip('\n')
            each_line_list = each_line.split('\t')
            set_for_readnames.add(each_line_list[0])
            dict_name[each_line_list[0]] = {}
            dict_name[each_line_list[0]]["pathogen"] = each_line_list[1]
            dict_name[each_line_list[0]]["mapping_quality"] = each_line_list[2]
    #print('Number of Pathseq Reads (with YP TAG) = ',len(set_for_readnames))
    return set_for_readnames, dict_name

def read_pathseq_report_and_create_dict(pathseq_report_csv):
    pathseq_report = open(pathseq_report_csv,'r')
    #three dicts: 1. cell-> cell_UMI 2. UMI-> id_sting 3. id -> genus
    #id -> genus:
    dict_for_genus = {}
    set_for_genera = set()
    for each_line in pathseq_report:
        each_line = each_line.rstrip('\n')
        each_line_list = each_line.split('\t')
        level = each_line_list[2]
        tax = each_line_list[3]
        if level == 'genus':
            set_for_genera.add(tax)
        if '|' in each_line_list[1]:
            name_string_list = each_line_list[1].split('|')
            for n in range(len(name_string_list)):
                pointer = -n-1
                if not '_' in name_string_list[pointer]:
                    name = name_string_list[pointer]
                    break
                if 'unclassified' in name_string_list[pointer]:
                    name = name_string_list[pointer]
                    break
            id = each_line_list[0]
            dict_for_genus[id] = name
    print ("len(dict_for_genus) = ",len(dict_for_genus))
    return dict_for_genus

def read_cell_names2(set_of_readnames, dict_name, dict_for_genus,original_bam_file,unmap_cbub_bam_file,unmap_cbub_fasta_file, out_cell_list,out_readname_cell_path):
    seqbam = pysam.AlignmentFile(original_bam_file, "rb",threads=36)
    readname_cell_path = open(out_readname_cell_path,'w')
    # Also output fasta and bam for pathseq/kraken2
    unmap_cbub_fasta = open(unmap_cbub_fasta_file,'w')
    unmap_cbub_bam = pysam.AlignmentFile(unmap_cbub_bam_file, "wb", seqbam)
    set_for_infect_cells=set()
    total_cellranger_bam_reads = 0
    total_cellranger_reads_UB_CB_tags = 0
    total_cellranger_reads_UB_CB_unmap = 0
    total_cellranger_reads_UB_CB_unmap_Aligned_to_Pathseq_YP_reads = 0
    total_potential_UMI_including_ambigious_reads = set()
    #output a bam file with only UBCB unmap reads
    for each_line in seqbam:
        total_cellranger_bam_reads+=1
        if each_line.has_tag('CB') and each_line.has_tag('UB'):
            total_cellranger_reads_UB_CB_tags+=1
            if each_line.has_tag('CB') and each_line.has_tag('UB') and each_line.is_unmapped:#updated 0520: only extract unmapped reads from cellranger
                total_cellranger_reads_UB_CB_unmap+=1
                # output a fasta file for kraken2
                query_name_in_cellranger_bam = each_line.query_name
                seq_in_cellranger_bam = each_line.query_sequence
                unmap_cbub_fasta.write('>')
                unmap_cbub_fasta.write(query_name_in_cellranger_bam)
                unmap_cbub_fasta.write('\n')
                unmap_cbub_fasta.write(seq_in_cellranger_bam)
                unmap_cbub_fasta.write('\n')
                unmap_cbub_bam.write(each_line)
                if each_line.query_name in set_of_readnames:
                    set_for_infect_cells.add(each_line.get_tag('CB'))
                    readname = each_line.query_name
                    cellname = each_line.get_tag('CB')
                    umi = each_line.get_tag('UB')
                    path = dict_name[readname]["pathogen"]
                    # translate id to genus
                    id_string_list = path.split(',')
                    genus_list = []
                    for each_id in id_string_list:
                    # ignore unfound genus
                        if each_id in dict_for_genus:
                            genus = dict_for_genus[each_id]
                            genus_list.append(genus)
                        #else:
                         #   print(each_id,"  not found")
                    genus_list = list(set(genus_list))
                    genus_list.sort()
                    genus_list_string = ','.join(genus_list)
                    #barcode_UMI_dict[barcode_UMI]["genus_string"] = genus_list
                    mapping_quality = dict_name[readname]["mapping_quality"]
                    outline = readname+'\t'+cellname+'\t'+umi+'\t'+path+'\t'+mapping_quality+'\t'+genus_list_string+'\n'
                    readname_cell_path.write(outline)
                    total_potential_UMI_including_ambigious_reads.add(umi)
                    total_cellranger_reads_UB_CB_unmap_Aligned_to_Pathseq_YP_reads+=1
    print('total cellranger bam reads = ',total_cellranger_bam_reads)
    print('total unmapped cellranger bam reads with UB and CB tags = ',total_cellranger_reads_UB_CB_unmap)
    #print('total cellranger reads with UB_CB_unmap Aligned to Pathseq reads with YP tags = ',total_cellranger_reads_UB_CB_unmap_Aligned_to_Pathseq_YP_reads)
    #print('total potential UMI including ambigious reads = ',len(total_potential_UMI_including_ambigious_reads))
    cell_list = open(out_cell_list,'w')
    for each_cell in set_for_infect_cells:
        cell_list.write(each_cell)
        cell_list.write('\n')
    return 

def generate_barcode_UMI_dict(out_readname_cell_path):
    cell_path_file = open(out_readname_cell_path,'r')
    barcode_UMI_dict = {}
    for each_line in cell_path_file:
        each_line = each_line.rstrip('\n')
        each_line_list = each_line.split('\t')   
        read_name =  each_line_list[0]
        cell_barcode = each_line_list[1]
        UMI = each_line_list[2]
        id_string = each_line_list[3]
        id_string_list = id_string.split(',')
        barcode_UMI = cell_barcode+'+'+UMI
        mapping_quality = each_line_list[4]
        genus_string = each_line_list[5]
        #then, pick the read with highest mapping quality (Alignment Score, AS tag) for each UMI, it's a different strategy then previous idea
        if not barcode_UMI in barcode_UMI_dict:
            barcode_UMI_dict[barcode_UMI]={}
            barcode_UMI_dict[barcode_UMI]["id_string"] = id_string_list
            barcode_UMI_dict[barcode_UMI]["mapping_quality"] = int(mapping_quality)
            barcode_UMI_dict[barcode_UMI]["genus_string"] = genus_string
        elif int(mapping_quality) > barcode_UMI_dict[barcode_UMI]["mapping_quality"]:
            barcode_UMI_dict[barcode_UMI]["id_string"] = id_string_list
            barcode_UMI_dict[barcode_UMI]["mapping_quality"] = int(mapping_quality) 
            barcode_UMI_dict[barcode_UMI]["genus_string"] = genus_string
    print('Total UMI in barcode_UMI_dict = ',len(barcode_UMI_dict))
    return barcode_UMI_dict #fast, no need to generate another temp file

def output_cells_genus_list(barcode_UMI_dict,dict_for_genus):
    # Three dicts: 1. cell-> cell_UMI 2. UMI-> id_sting 3. id -> genus
    cells_dict = {}
    for barcode_UMI in barcode_UMI_dict:
        cell = barcode_UMI.split('+')[0]
        if not cell in cells_dict:
            cells_dict[cell]=[]
            cells_dict[cell].append(barcode_UMI)
        else:
            cells_dict[cell].append(barcode_UMI)
    # UMI_id_dict is to store UMI <- ids string
    UMI_id_dict = {}
    for barcode_UMI in barcode_UMI_dict:
        #0523:
        if not ',' in barcode_UMI_dict[barcode_UMI]["genus_string"]:
            UMI_id_dict[barcode_UMI] = barcode_UMI_dict[barcode_UMI]["id_string"]
    # update UMI_id_dict with genus name
    unambigious_UMI = {}
    for barcode_UMI in UMI_id_dict:
        id_list = UMI_id_dict[barcode_UMI]
        genus_list = []
        for each_id in id_list:
            if each_id in dict_for_genus:
                genus = dict_for_genus[each_id]
                genus_list.append(genus)
        genus_list = list(set(genus_list))
        if len(genus_list) == 1:#only keep unambigious UMI
            unambigious_UMI[barcode_UMI] = genus_list[0]
    # construct cell_metadata using unambigious_UMI dict,also count the number of UMI in cells
    print('Total unambigious UMI = ',len(unambigious_UMI))
    cell_metadata_dict = {}
    for barcode_UMI in unambigious_UMI:
        barcode = barcode_UMI.split('+')[0]
        UMI = barcode_UMI.split('+')[1]
        genus = unambigious_UMI[barcode_UMI]
        if not barcode in cell_metadata_dict:
            cell_metadata_dict[barcode] = {} 
            cell_metadata_dict[barcode]['genus'] = []
            cell_metadata_dict[barcode]['genus'].append(genus)
            cell_metadata_dict[barcode]['barcode_UMI']={}
            cell_metadata_dict[barcode]['barcode_UMI'][barcode_UMI] = genus
            cell_metadata_dict[barcode]['pathogen_count']={}
        else:
            cell_metadata_dict[barcode]['genus'].append(genus)
            cell_metadata_dict[barcode]['barcode_UMI'][barcode_UMI] = genus
        if not genus in cell_metadata_dict[barcode]['pathogen_count']:
            cell_metadata_dict[barcode]['pathogen_count'][genus] = 1
        else:
            cell_metadata_dict[barcode]['pathogen_count'][genus] += 1
            # count pathogen UMI for each cell
    # then create output
    # put the output part into an individual function
    return cell_metadata_dict

def output_cell_metadata(cell_metadata_dict,out_genus_file,sample_ident,barcode_whitelist_file):
    print('total pathogen-associated gems = ', len(cell_metadata_dict))
    white_list_set = set()
    white_list_dict = {}
    white_list = gzip.open(barcode_whitelist_file, 'rt')
    for each_line in white_list:
        each_line = each_line.rstrip('\n')
        white_list_set.add(each_line)
    #print("total number of cells = ", len(white_list_set))
    for barcode in cell_metadata_dict:
        if barcode in white_list_set:
            white_list_dict[barcode]= cell_metadata_dict[barcode]
    cell_metadata_dict = white_list_dict
    print("total filtered pathogen-associated cells = ", len(cell_metadata_dict))
    #dict_updated with white list
    genus_file = open(out_genus_file,'w')
    header = 'cell_name,pathogen,UMI_count,pathogen_count\n'
    genus_file.write(header)
    for barcode in cell_metadata_dict:
        if not sample_ident == '':
            cell_name = sample_ident+'_'+barcode
        else:
            cell_name = barcode
        genus_list = []
        for barcode_UMI in cell_metadata_dict[barcode]['barcode_UMI']:
            genus_list.append(cell_metadata_dict[barcode]['barcode_UMI'][barcode_UMI])
        sorted_genus_list = list(set(genus_list))
        sorted_genus_list.sort()
        genus = '+'.join(sorted_genus_list)            
        UMI_count = len(cell_metadata_dict[barcode]['barcode_UMI'])
        #then a new list for pathogen count
        pathogen_count_list = []
        for each_pathogen in cell_metadata_dict[barcode]['pathogen_count']:
            pathogen_count=each_pathogen
            pathogen_count+=':'
            pathogen_count+=str(cell_metadata_dict[barcode]['pathogen_count'][each_pathogen])
            pathogen_count_list.append(pathogen_count)
        pathogen_count_list.sort()
        pathogen_count_str = ';'.join(pathogen_count_list)
        pathogen_count_mini_dict = cell_metadata_dict[barcode]['pathogen_count']
        temp_max_list = []
        UMI_count_sum = 0
        #for each_pathogen in pathogen_count_mini_dict:
        max_count = max(pathogen_count_mini_dict.values())
        for key,value in pathogen_count_mini_dict.items():
            if value == max_count:
                temp_max_list.append(key)
                max_UMI = value
            UMI_count_sum += value
        UMI_count = UMI_count_sum
        if len(set(temp_max_list)) > 1: 
            genus = 'MULTI'
            UMI_count = UMI_count_sum
        else:
            genus = temp_max_list[0]
            UMI_count = max_UMI
        output_line = ','.join([cell_name,genus,str(UMI_count),pathogen_count_str])+'\n'
        if UMI_count >= 1:
            genus_file.write(output_line)
    return

def UMI_table_output(cell_metadata_dict,barcode_whitelist_file,sample_ident,output_UMI_table_csv,output_UMI_validate_table_csv):
    # use cell white list (filtered cell list) from Cellranger Count expression matrix, can be replaced with the raw matrix
    white_list_set = set()
    white_list_dict = {}
    white_list = gzip.open(barcode_whitelist_file, 'rt')
    for each_line in white_list:
        each_line = each_line.rstrip('\n')
        white_list_set.add(each_line)
    print("total number of cells = ", len(white_list_set))
    for barcode in cell_metadata_dict:
        if barcode in white_list_set:
            white_list_dict[barcode]= cell_metadata_dict[barcode]
    cell_metadata_dict = white_list_dict
    # print a UMI table for cross validation (cell+UMI and pathogen)
    output_UMI_validate_table = open(output_UMI_validate_table_csv,'w')
    for each_cell in cell_metadata_dict:
        for each_UMI in cell_metadata_dict[each_cell]['barcode_UMI']:
            UMI = each_UMI
            pathogen = cell_metadata_dict[each_cell]['barcode_UMI'][UMI]
            output_UMI_validate_table.write(UMI+','+pathogen+'\n')
    output_UMI_table = open(output_UMI_table_csv,'w')
    # output everything for metadata
    # get a complete list of all genera in this sample:
    genera_list_set = set()
    for barcode in cell_metadata_dict:
        for pathogen in cell_metadata_dict[barcode]['pathogen_count']:
            #cell_metadata_dict[barcode]['pathogen_count'][pathogen]
            genera_list_set.add(pathogen)
    genera_list = sorted(list(genera_list_set))
    header = ['barcode']+genera_list
    header_out = ','.join(header)
    output_UMI_table.write(header_out)
    output_UMI_table.write('\n')
    # start each_line
    for barcode in cell_metadata_dict:
        if not sample_ident == '':
            cell_name = sample_ident+'_'+barcode
        else:
            cell_name = barcode
        genera_count_list = []
        for each_genus in genera_list:
            if each_genus in cell_metadata_dict[barcode]['pathogen_count']:
                genus_count = cell_metadata_dict[barcode]['pathogen_count'][each_genus]
            else:
                genus_count = 0
            genera_count_list.append(str(genus_count))
        output_line = [cell_name]+genera_count_list
        output_line_out = ','.join(output_line)
        output_UMI_table.write(output_line_out)
        output_UMI_table.write('\n')
    return

if __name__ == "__main__":
    cellranger_bam_file,sample_ident,barcode_whitelist_file,pathseq_bam_file,pathseq_report_csv,read_name_pathseq,unmap_cbub_bam_file,unmap_cbub_fasta_file,out_cell_list,out_readname_cell_path,out_genus_file,output_UMI_table_csv,output_UMI_validate_table_csv=sys.argv[1:]
    dict_for_genus = read_pathseq_report_and_create_dict(pathseq_report_csv)
    step1 = read_cell_names1(pathseq_bam_file, read_name_pathseq)
    step2 = read_readnames(read_name_pathseq)
    step3 = read_cell_names2(step2[0], step2[1], dict_for_genus,cellranger_bam_file,unmap_cbub_bam_file,unmap_cbub_fasta_file, out_cell_list,out_readname_cell_path)
    step4 = generate_barcode_UMI_dict(out_readname_cell_path)
    step5 = output_cells_genus_list(step4,dict_for_genus)
    output_cell_metadata(step5,out_genus_file,sample_ident,barcode_whitelist_file)
    cell_metadata_dict = step5
    UMI_table_output(cell_metadata_dict,barcode_whitelist_file,sample_ident,output_UMI_table_csv,output_UMI_validate_table_csv)


# cellranger_bam_file,
# sample_ident,
# barcode_whitelist_file,
# pathseq_bam_file,
# pathseq_report_csv,
# read_name_pathseq,
# unmap_cbub_bam_file,
# unmap_cbub_fasta_file,
# out_cell_list,
# out_readname_cell_path,
# out_genus_file,
# output_UMI_table_csv,
# output_UMI_validate_table_csv=sys.argv[1:]


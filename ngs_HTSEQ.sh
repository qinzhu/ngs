#!/bin/bash

# Copyright (c) 2012,2013, Stephen Fisher and Junhyong Kim, University of
# Pennsylvania.  All Rights Reserved.
#
# You may not use this file except in compliance with the Kim Lab License
# located at
#
#     http://kim.bio.upenn.edu/software/LICENSE
#
# Unless required by applicable law or agreed to in writing, this
# software is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
# CONDITIONS OF ANY KIND, either express or implied.  See the License
# for the specific language governing permissions and limitations
# under the License.

##########################################################################################
# INPUT: $SAMPLE/star/STAR_Unique.bam
# OUTPUT: $SAMPLE/htseq/$SAMPLE.htseq.cnts.txt, $SAMPLE/htseq/$SAMPLE.htseq.log.txt, $SAMPLE/htseq/$SAMPLE.htseq.err.txt
# REQUIRES: HTSeq, Pysam, NumPY, runHTSeq.py
##########################################################################################

##########################################################################################
# USAGE
##########################################################################################

NGS_USAGE+="Usage: `basename $0` htseq OPTIONS sampleID    --  run HTSeq on unique mapped reads\n"

##########################################################################################
# HELP TEXT
##########################################################################################

ngsHelp_HTSEQ() {
    echo -e "Usage:\n\t`basename $0` htseq [-i inputDir] [-f inputFile] [-stranded] [-introns] -s species sampleID"
    echo -e "Input:\n\tsampleID/inputDir/inputFile"
    echo -e "Output:\n\tsampleID/htseq/sampleID.htseq.cnts.txt\n\tsampleID/htseq/sampleID.htseq.log.txt\n\tsampleID/htseq/sampleID.htseq.err.txt"
    echo -e "Requires:\n\tHTSeq version 0.6 or later ( http://www-huber.embl.de/users/anders/HTSeq/ )\n\tPysam ( https://pypi.python.org/pypi/pysam )\n\tdynamicRange.py ( https://github.com/safisher/ngs )"
    echo -e "Options:"
    echo -e "\t-i inputDir - location of source file (default: star)."
    echo -e "\t-f inputFile - source file (default: sampleID.star.unique.bam)."
    echo -e "\t-stranded - use strand information (default: no).\n"
    echo -e "\t-introns - also compute intron counts (default: no). The intron file is expected to have the same name as the exon file with the addition of \".intron.gtf\".\n"
    echo -e "\t-s species - species from repository: $HTSEQ_REPO.\n"
    echo -e "Run HTSeq using runHTSeq.py script. This requires a BAM file as generated by either RUMALIGN or STAR (STAR by default)."
    echo -e "The following HTSeq parameter values are used when intron counting is disabled (i.e. the default):\n \t--mode=intersection-nonempty --stranded=no --type=exon --idattr=gene_id\n"
    echo -e "INTRON COUNTING (-introns option):"
    echo -e "When intron counting is enabled (-introns) then exons will be counted using intersection-strict and introns will be counted with intersection-nonempty. In this case three counts files will be generated:"
    echo -e "\tSampleID.htseeq.exons.cnts: exon counts"
    echo -e "\tSampleID.htseeq.introns.cnts: intron counts"
    echo -e "\tSampleID.htseeq.cnts.txt: combined counts tab delimited (gene, exons, introns, total)\n"
    echo -e "For a description of the HTSeq parameters see http://www-huber.embl.de/users/anders/HTSeq/doc/count.html#count"
}

##########################################################################################
# LOCAL VARIABLES WITH DEFAULT VALUES. Using the naming convention to
# make sure these variables don't collide with the other modules.
##########################################################################################

ngsLocal_HTSEQ_INP_DIR="star"
# the default for ngsLocal_HTSEQ_INP_FILE is set in ngsCmd_HTSEQ()
# because it depends on the value of $SAMPLE and $SAMPLE doesn't have
# a value until the ngsCmd_HTSEQ() function is run.
ngsLocal_HTSEQ_INP_FILE=""
ngsLocal_HTSEQ_STRANDED="no"
ngsLocal_HTSEQ_INTRONS="no"

##########################################################################################
# PROCESSING COMMAND LINE ARGUMENTS
# HTSEQ args: -s value, -g value, sampleID
##########################################################################################

ngsArgs_HTSEQ() {
    if [ $# -lt 3 ]; then printHelp "HTSEQ"; fi
    
    # getopts doesn't allow for optional arguments so handle them manually
    while true; do
	case $1 in
	    -i) ngsLocal_HTSEQ_INP_DIR=$2
		shift; shift;
		;;
	    -f) ngsLocal_HTSEQ_INP_FILE=$2
		shift; shift;
		;;
	    -stranded) ngsLocal_HTSEQ_STRANDED="yes"
		shift;
		;;
	    -introns) ngsLocal_HTSEQ_INTRONS="yes"
		shift;
		;;
	    -s) SPECIES=$2
		shift; shift;
		;;
	    -*) printf "Illegal option: '%s'\n" "$1"
		printHelp $COMMAND
		exit 0
		;;
 	    *) break ;;
	esac
    done
    
    SAMPLE=$1
}

##########################################################################################
# RUNNING COMMAND ACTION
# Run HTSeq on uniqely mapped alignments, as generated by the POST command.
##########################################################################################

ngsCmd_HTSEQ() {
    prnCmd "# BEGIN: HTSEQ"
    
    # make relevant directory
    if [ ! -d $SAMPLE/htseq ]; then 
	prnCmd "mkdir $SAMPLE/htseq"
	if ! $DEBUG; then mkdir $SAMPLE/htseq; fi
    fi
    
    # print version info in $SAMPLE directory
    prnCmd "# HTSeq version: python -c 'import HTSeq, pkg_resources; print pkg_resources.get_distribution(\"HTSeq\").version'"
    if ! $DEBUG; then 
	# returns: "0.5.4p5"
	ver=$(python -c "import HTSeq, pkg_resources; print pkg_resources.get_distribution(\"HTSeq\").version")
	prnVersion "htseq" "program\tversion\ttranscriptome" "htseq\t$ver\t$HTSEQ_REPO/$SPECIES.gz"
    fi
    
    # if the user didn't provide an input file then set it to the
    # default
    if [[ -z "$ngsLocal_HTSEQ_INP_FILE" ]]; then 
	ngsLocal_HTSEQ_INP_FILE="$SAMPLE.star.unique.bam"
    fi
    
    # We assume that the alignment file exists
    prnCmd "python -m HTSeq.scripts.count --format=bam --order=pos --mode=intersection-nonempty --stranded=$ngsLocal_HTSEQ_STRANDED --type=exon --idattr=gene_id $SAMPLE/$ngsLocal_HTSEQ_INP_DIR/$ngsLocal_HTSEQ_INP_FILE $HTSEQ_REPO/$SPECIES.gz > $SAMPLE/htseq/$SAMPLE.htseq.out 2>&1"
    if ! $DEBUG; then 
        python -m HTSeq.scripts.count --format=bam --order=pos --mode=intersection-nonempty --stranded=$ngsLocal_HTSEQ_STRANDED --type=exon --idattr=gene_id $SAMPLE/$ngsLocal_HTSEQ_INP_DIR/$ngsLocal_HTSEQ_INP_FILE $HTSEQ_REPO/$SPECIES.gz > $SAMPLE/htseq/$SAMPLE.htseq.out 2>&1
    fi
    
    prnCmd "# splitting output file into counts, log, and error files"
    # parse output into three files: gene counts ($SAMPLE.htseq.cnts.txt), 
    # warnings ($SAMPLE.htseq.err.txt), log ($SAMPLE.htseq.log.txt)
    if ! $DEBUG; then 
	# only generate error file if Warnings exist. If we run grep
	# and it doesn't find any matches then it will exit with an
	# error code which would cause the program to crash since we
	# use "set -o errexit"
	local containsWarnings=$(grep -c 'Warning' $SAMPLE/htseq/$SAMPLE.htseq.out)
	if [[ $containsWarnings -gt 0 ]]; then
	    prnCmd "grep 'Warning' $SAMPLE/htseq/$SAMPLE.htseq.out > $SAMPLE/htseq/$SAMPLE.htseq.err.txt"
	    grep 'Warning' $SAMPLE/htseq/$SAMPLE.htseq.out > $SAMPLE/htseq/$SAMPLE.htseq.err.txt
	    
	    prnCmd "grep -v 'Warning' $SAMPLE/htseq/$SAMPLE.htseq.out > $SAMPLE/htseq/tmp.txt"
	    grep -v 'Warning' $SAMPLE/htseq/$SAMPLE.htseq.out > $SAMPLE/htseq/tmp.txt
	else
	    prnCmd "mv $SAMPLE/htseq/$SAMPLE.htseq.out $SAMPLE/htseq/tmp.txt"
	    cp $SAMPLE/htseq/$SAMPLE.htseq.out $SAMPLE/htseq/tmp.txt
	fi
	
	prnCmd "echo -e 'gene\tcount' > $SAMPLE/htseq/$SAMPLE.htseq.cnts.txt"
	echo -e 'gene\tcount' > $SAMPLE/htseq/$SAMPLE.htseq.cnts.txt
	
	prnCmd "$GREPP '\t' $SAMPLE/htseq/tmp.txt | $GREPP -v 'no_feature|ambiguous|too_low_aQual|not_aligned|alignment_not_unique' >> $SAMPLE/htseq/$SAMPLE.htseq.cnts.txt"
	$GREPP '\t' $SAMPLE/htseq/tmp.txt | $GREPP -v 'no_feature|ambiguous|too_low_aQual|not_aligned|alignment_not_unique' >> $SAMPLE/htseq/$SAMPLE.htseq.cnts.txt
	
	prnCmd "$GREPP -v '\t' $SAMPLE/htseq/tmp.txt > $SAMPLE/htseq/$SAMPLE.htseq.log.txt"
	$GREPP -v '\t' $SAMPLE/htseq/tmp.txt > $SAMPLE/htseq/$SAMPLE.htseq.log.txt
	
	prnCmd "$GREPP 'no_feature|ambiguous|too_low_aQual|not_aligned|alignment_not_unique' $SAMPLE/htseq/tmp.txt >> $SAMPLE/htseq/$SAMPLE.htseq.log.txt"
	$GREPP 'no_feature|ambiguous|too_low_aQual|not_aligned|alignment_not_unique' $SAMPLE/htseq/tmp.txt >> $SAMPLE/htseq/$SAMPLE.htseq.log.txt
	
	prnCmd "rm $SAMPLE/htseq/$SAMPLE.htseq.out $SAMPLE/htseq/tmp.txt"
	rm $SAMPLE/htseq/$SAMPLE.htseq.out $SAMPLE/htseq/tmp.txt
    fi
    
    # run error checking
    if ! $DEBUG; then ngsErrorChk_HTSEQ $@; fi
    
    prnCmd "# FINISHED: HTSEQ"
}

##########################################################################################
# ERROR CHECKING. Make sure output file exists, is not effectively
# empty and warn user if HTSeq output any warnings.
##########################################################################################

ngsErrorChk_HTSEQ() {
    prnCmd "# HTSEQ ERROR CHECKING: RUNNING"
    
    inputFile="$SAMPLE/$ngsLocal_HTSEQ_INP_DIR/$ngsLocal_HTSEQ_INP_FILE"
    outputFile="$SAMPLE/htseq/$SAMPLE.htseq.cnts.txt"
    
    # make sure expected output file exists
    if [ ! -f $outputFile ]; then
	errorMsg="Expected HTSeq output file does not exist.\n"
	errorMsg+="\tinput file: $inputFile\n"
	errorMsg+="\toutput file: $outputFile\n"
	prnError "$errorMsg"
    fi
    
    # if cnts file only has 1 line then error and print contents of log file
    counts=`wc -l $outputFile | awk '{print $1}'`
    
    # if counts file only has one line, then HTSeq didn't work
    if [ "$counts" -eq "1" ]; then
	errorMsg="HTSeq failed to run properly. See HTSeq error below:\n"
	errorMsg+="\tinput file: $inputFile\n"
	errorMsg+="\toutput file: $outputFile\n\n"
	errorMsg+=`cat $SAMPLE/htseq/$SAMPLE.htseq.log.txt`
	prnError "$errorMsg"
    fi
    
    # if counts file only has one line, then HTSeq didn't work
    if [ -s $SAMPLE/htseq/$SAMPLE.htseq.err.txt ]; then
	warningMsg="Review the error file listed below to view HTSeq warnings.\n"
	warningMsg+="\tinput file: $inputFile\n"
	warningMsg+="\toutput file: $outputFile\n"
	warningMsg+="\tERROR FILE: $SAMPLE/htseq/$SAMPLE.htseq.err.txt\n"
	prnWarning "$warningMsg"
    fi
    
    prnCmd "# HTSEQ ERROR CHECKING: DONE"
}

##########################################################################################
# PRINT STATS. Prints a tab-delimited list stats of interest.
##########################################################################################

ngsStats_HTSEQ() {
    if [ $# -ne 1 ]; then
	prnError "Incorrect number of parameters for ngsStats_HTSEQ()."
    fi
    
    # total number of reads that mapped unambigously to genes
    readsCounted=$(cat $SAMPLE/htseq/$SAMPLE.htseq.cnts.txt | awk '{sum += $2} END {print sum}')
    header="Reads Counted"
    values="$readsCounted"
    
    # number of genes with at least 1 read mapped
    numGenes=$($GREPP -v "\t0$" $SAMPLE/htseq/$SAMPLE.htseq.cnts.txt | grep -v "gene" | wc -l)
    header="$header\tNum Genes"
    values="$values\t$numGenes"
    
    # average number of reads that mapped unambigously to genes
    avgReadPerGene=$(($readsCounted/$numGenes))
    header="$header\tAvg Read Per Gene"
    values="$values\t$avgReadPerGene"
    
    # maximum number of reads that mapped unambigously to a single gene
    maxReadsPerGene=$(grep -v "gene" $SAMPLE/htseq/$SAMPLE.htseq.cnts.txt | awk '{if(max=="") {max=$2}; if($2>max) {max=$2};} END {print max}')
    header="$header\tMax Reads Per Gene"
    values="$values\t$maxReadsPerGene"
    
    # number of reads that didn't map to a gene region
    noFeature=$(tail -5 $SAMPLE/htseq/$SAMPLE.htseq.log.txt | head -1 | awk '{print $2}')
    header="$header\tNo Feature"
    values="$values\t$noFeature"
    
    # number of reads that completely overlapped two or more gene regions
    ambiguousMapped=$(tail -4 $SAMPLE/htseq/$SAMPLE.htseq.log.txt | head -1 | awk '{print $2}')
    header="$header\tAmbiguous Mapped"
    values="$values\t$ambiguousMapped"
    
    # compute dynamic range
    dynamicRange=$(dynamicRange.py -c $SAMPLE/htseq/$SAMPLE.htseq.cnts.txt)
    header="$header\tDynamic Range"
    values="$values\t$dynamicRange"
    
    case $1 in
	header) 
	    echo "$header"
	    ;;
	
	values) 
	    echo "$values"
	    ;;
	
	*) 
	    # incorrect argument
	    prnError "Invalid parameter for ngsStats_HTSEQ() (got $1, expected: 'header|values')."
	    ;;
    esac
}

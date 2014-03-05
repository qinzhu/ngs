#!/bin/bash

# Copyright (c) 2012-2014, Stephen Fisher, Hoa Giang, and Junhyong Kim, University of
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
# SINGLE-END READS:
# INPUT: $SAMPLE/trim/unaligned_1.fq
# OUTPUT: $SAMPLE/bowtie/$SAMPLE.bowtie.sorted.bam
#
# PAIRED-END READS:
# INPUT: $SAMPLE/trim/unaligned_1.fq and $SAMPLE/orig/unaligned_2.fq
# OUTPUT: $SAMPLE/bowtie/$SAMPLE.bowtie.sorted.bam and $SAMPLE/bowtie/SE_mapping
#
# REQUIRES: bowtie, samtools
##########################################################################################

##########################################################################################
# USAGE
##########################################################################################

ngsUsage_BOWTIE="Usage: `basename $0` bowtie OPTIONS sampleID    --  run bowtie on trimmed reads\n"

##########################################################################################
# HELP TEXT
##########################################################################################

ngsHelp_BOWTIE="Usage:\n\t`basename $0` bowtie [-i inputDir] [-v mismatches] [-m maxMulti] [-minins minInsertSize] [-maxins maxInsertSize] -p numProc -s species [-se] sampleID\n"
ngsHelp_BOWTIE+="Input:\n\tsampleID/inputDir/unaligned_1.fq\n\tsampleID/inputDir/unaligned_2.fq (paired-end reads)\n"
ngsHelp_BOWTIE+="Output:\n\tsampleID/bowtie/sampleID.bowtie.sorted.bam\n\tsampleID/bowtie/sampleID.suppressed.sorted.bam\n\tsampleID/bowtie/sampleID.stats.txt\n"
ngsHelp_BOWTIE+="Requires:\n\tbowtie ( http://bowtie-bio.sourceforge.net/index.shtml )\n\tsamtools ( http://samtools.sourceforge.net/ )\n"
ngsHelp_BOWTIE+="Options:\n"
ngsHelp_BOWTIE+="\t-i inputDir - directory with unaligned reads (default: trim)\n"
ngsHelp_BOWTIE+="\t-v mismatches - maximum mismatches allowed per read length (default: 3)\n"
ngsHelp_BOWTIE+="\t-m maxMulti - suppress all alignments if > m alignments (default: 1)\n"
ngsHelp_BOWTIE+="\t-minins minInsertSize - minimum insert size for PE alignment (default: 250bp)\n"
ngsHelp_BOWTIE+="\t-maxins maxInsertSize - maximum insert size for PE alignment (default: 450bp)\n"
ngsHelp_BOWTIE+="\t-p numProc - number of cpu to use\n"
ngsHelp_BOWTIE+="\t-s species - species from repository: $BOWTIE_REPO\n"
ngsHelp_BOWTIE+="\t-se - single-end reads (default: paired-end)\n\n"
ngsHelp_BOWTIE+="Run bowtie on the unaligned reads (ie sampleID/inputDir). The arguments used assume Bowtie version 1. Output is placed in the directory sampleID/bowtie. Multimapping reads that exceed the maxMulti count are output to the sampleID.suppressed.sorted.bam file (ie the Bowtie -max flag is used to direct the reads to this file). For paired-end samples, after the paired mapping is complete then all unmapped reads are aligned as if they were single-end with the alignments stored in the sampleID/bowtie/SE_mapping directory. The alignment stats for the single-end and paired-end mappings are reported in the stats file."

##########################################################################################
# LOCAL VARIABLES WITH DEFAULT VALUES. Using the naming convention to
# make sure these variables don't collide with the other modules.
##########################################################################################

ngsLocal_BOWTIE_INP_DIR="trim"
ngsLocal_BOWTIE_MISMATCHES=3
ngsLocal_BOWTIE_MAXMULTI=1
ngsLocal_BOWTIE_MININS=250
ngsLocal_BOWTIE_MAXINS=450

##########################################################################################
# PROCESSING COMMAND LINE ARGUMENTS
# BOWTIE args: -p value, -s value, -se (optional), sampleID
##########################################################################################

ngsArgs_BOWTIE() {
	if [ $# -lt 4 ]; then
		printHelp $COMMAND
		exit 0
	fi
	
   	# getopts doesn't allow for optional arguments so handle them manually
	while true; do
		case $1 in
			-i) ngsLocal_BOWTIE_INP_DIR=$2
				shift; shift;
				;;
			-v) ngsLocal_BOWTIE_MISMATCHES=$2
				shift; shift;
				;;
			-m) ngsLocal_BOWTIE_MAXMULTI=$2
				shift; shift;
				;;			
			-minins) ngsLocal_BOWTIE_MININS=$2
				shift; shift;
				;;
			-maxins) ngsLocal_BOWTIE_MAXINS=$2
				shift; shift;
				;;
			-p) NUMCPU=$2
				shift; shift;
				;;
			-s) SPECIES=$2
				shift; shift;
				;;
			-se) SE=true
				shift;
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
# Run BOWTIE. Run BOWTIE on untrimmed data.
##########################################################################################

ngsCmd_BOWTIE() {
	if $SE; then prnCmd "# BEGIN: BOWTIE SINGLE-END ALIGNMENT"
	else prnCmd "# BEGIN: BOWTIE PAIRED-END ALIGNMENT"; fi
	
    # print version info in journal file
	prnCmd "# bowtie version"
	if ! $DEBUG; then prnCmd "# `bowtie --version | head -1`"; fi
	
    # make relevant directory
	if [ ! -d $SAMPLE/bowtie ]; then 
		prnCmd "mkdir $SAMPLE/bowtie"
		if ! $DEBUG; then mkdir $SAMPLE/bowtie; fi

		if ! $SE; then
			prnCmd "mkdir $SAMPLE/bowtie/SE_mapping"
			if ! $DEBUG; then mkdir $SAMPLE/bowtie/SE_mapping; fi
		fi
	fi
	
	if $SE; then 
        # single-end
		prnCmd "bowtie -t -v $ngsLocal_BOWTIE_MISMATCHES -a -m $ngsLocal_BOWTIE_MAXMULTI --best --sam -p $NUMCPU $BOWTIE_REPO/$SPECIES $SAMPLE/$ngsLocal_BOWTIE_INP_DIR/unaligned_1.fq $SAMPLE/bowtie/output_p.sam --max $SAMPLE/bowtie/suppressed.fq --un $SAMPLE/bowtie/notMapped_1.fq > $SAMPLE/bowtie/$SAMPLE.stats.txt 2>&1"
		if ! $DEBUG; then 
			bowtie -t -v $ngsLocal_BOWTIE_MISMATCHES -a -m $ngsLocal_BOWTIE_MAXMULTI --best --sam -p $NUMCPU $BOWTIE_REPO/$SPECIES $SAMPLE/$ngsLocal_BOWTIE_INP_DIR/unaligned_1.fq $SAMPLE/bowtie/output_p.sam --max $SAMPLE/bowtie/suppressed.fq --un $SAMPLE/bowtie/notMapped_1.fq > $SAMPLE/bowtie/$SAMPLE.stats.txt 2>&1
		fi
	else 
        # paired-end
		prnCmd "bowtie -t -v $ngsLocal_BOWTIE_MISMATCHES --minins $ngsLocal_BOWTIE_MININS --maxins $ngsLocal_BOWTIE_MAXINS -a -m $ngsLocal_BOWTIE_MAXMULTI --best --sam -p $NUMCPU $BOWTIE_REPO/$SPECIES -1 $SAMPLE/$ngsLocal_BOWTIE_INP_DIR/unaligned_1.fq -2 $SAMPLE/$ngsLocal_BOWTIE_INP_DIR/unaligned_2.fq $SAMPLE/bowtie/output_p.sam --max $SAMPLE/bowtie/suppressed.sam --un $SAMPLE/bowtie/unmapped.fq > $SAMPLE/bowtie/$SAMPLE.stats.txt 2>&1"
		if ! $DEBUG; then 
			bowtie -t -v $ngsLocal_BOWTIE_MISMATCHES --minins $ngsLocal_BOWTIE_MININS --maxins $ngsLocal_BOWTIE_MAXINS -a -m $ngsLocal_BOWTIE_MAXMULTI --best --sam -p $NUMCPU $BOWTIE_REPO/$SPECIES -1 $SAMPLE/$ngsLocal_BOWTIE_INP_DIR/unaligned_1.fq -2 $SAMPLE/$ngsLocal_BOWTIE_INP_DIR/unaligned_2.fq $SAMPLE/bowtie/output_p.sam --max $SAMPLE/bowtie/suppressed.sam --un $SAMPLE/bowtie/notMapped.fq > $SAMPLE/bowtie/$SAMPLE.stats.txt 2>&1
		fi
	
		# mate 1 as single-end reads
		prnCmd "bowtie -t -v $ngsLocal_BOWTIE_MISMATCHES -a -m $ngsLocal_BOWTIE_MAXMULTI --best --sam -p $NUMCPU $BOWTIE_REPO/$SPECIES $SAMPLE/bowtie/notMapped_1.fq $SAMPLE/bowtie/SE_mapping/output_se1.sam --un $SAMPLE/bowtie/SE_mapping/notMapped_1.fq >> $SAMPLE/bowtie/$SAMPLE.stats.txt 2>&1"
		if ! $DEBUG; then 
			bowtie -t -v $ngsLocal_BOWTIE_MISMATCHES -a -m $ngsLocal_BOWTIE_MAXMULTI --best --sam -p $NUMCPU $BOWTIE_REPO/$SPECIES $SAMPLE/bowtie/notMapped_1.fq $SAMPLE/bowtie/SE_mapping/output_se1.sam --un $SAMPLE/bowtie/SE_mapping/notMapped_1.fq >> $SAMPLE/bowtie/$SAMPLE.stats.txt 2>&1
		fi
	
		# mate 2 as single-end reads
		prnCmd "bowtie -t -v $ngsLocal_BOWTIE_MISMATCHES -a -m $ngsLocal_BOWTIE_MAXMULTI --best --sam -p $NUMCPU $BOWTIE_REPO/$SPECIES $SAMPLE/bowtie/notMapped_2.fq $SAMPLE/bowtie/SE_mapping/output_se2.sam --un $SAMPLE/bowtie/SE_mapping/notMapped_2.fq >> $SAMPLE/bowtie/$SAMPLE.stats.txt 2>&1"
		if ! $DEBUG; then 
			bowtie -t -v $ngsLocal_BOWTIE_MISMATCHES -a -m $ngsLocal_BOWTIE_MAXMULTI --best --sam -p $NUMCPU $BOWTIE_REPO/$SPECIES $SAMPLE/bowtie/notMapped_2.fq $SAMPLE/bowtie/SE_mapping/output_se2.sam --un $SAMPLE/bowtie/SE_mapping/notMapped_2.fq >> $SAMPLE/bowtie/$SAMPLE.stats.txt 2>&1
		fi
	fi
	
    # need to save current directory so we can return here. We also
    # need to adjust $JOURNAL so prnCmd() still works when we change
    # directories
	prnCmd "CUR_DIR=`pwd`"
	CUR_DIR=`pwd`
	
	prnCmd "JOURNAL_SAV=$JOURNAL"
	JOURNAL_SAV=$JOURNAL
	
	prnCmd "cd $SAMPLE/bowtie"
	if ! $DEBUG; then 
		cd $SAMPLE/bowtie
		
		JOURNAL=../../$JOURNAL
		prnCmd "JOURNAL=../../$JOURNAL"
	fi
	
	prnCmd "samtools view -h -b -S -o output_p.bam output_p.sam"
	if ! $DEBUG; then samtools view -h -b -S -o output_p.bam output_p.sam; fi
	prnCmd "samtools sort output_p.bam $SAMPLE.bowtie.sorted"
	if ! $DEBUG; then samtools sort output_p.bam $SAMPLE.bowtie.sorted; fi
	prnCmd "samtools index $SAMPLE.bowtie.sorted.bam"
	if ! $DEBUG; then samtools index $SAMPLE.bowtie.sorted.bam; fi
	prnCmd "rm output_p.sam output_p.bam"
	if ! $DEBUG; then rm output_p.sam output_p.bam; fi
	
	prnCmd "samtools view -h -b -S -o suppressed.bam suppressed.sam"
	if ! $DEBUG; then samtools view -h -b -S -o suppressed.bam suppressed.sam; fi
	prnCmd "samtools sort suppressed.bam $SAMPLE.suppressed.sorted"
	if ! $DEBUG; then samtools sort suppressed.bam $SAMPLE.suppressed.sorted; fi
	prnCmd "samtools index $SAMPLE.suppressed.sorted.bam"
	if ! $DEBUG; then samtools index $SAMPLE.suppressed.sorted.bam; fi
	prnCmd "rm suppressed.sam suppressed.bam"
	if ! $DEBUG; then rm suppressed.sam suppressed.bam; fi
		
	prnCmd "samtools view -h -b -S -o SE_mapping/$SAMPLE.mate1.bam SE_mapping/output_se1.sam"
	if ! $DEBUG; then samtools view -h -b -S -o SE_mapping/$SAMPLE.mate1.bam SE_mapping/output_se1.sam; fi
	prnCmd "samtools view -h -b -S -o SE_mapping/$SAMPLE.mate2.bam SE_mapping/output_se2.sam"
	if ! $DEBUG; then samtools view -h -b -S -o SE_mapping/$SAMPLE.mate2.bam SE_mapping/output_se2.sam; fi
	prnCmd "rm SE_mapping/output_se1.sam SE_mapping/output_se2.sam"
	if ! $DEBUG; then rm SE_mapping/output_se1.sam SE_mapping/output_se2.sam; fi
	
    # return to proper directory and restore $JOURNAL
	prnCmd "cd $CUR_DIR"
	if ! $DEBUG; then 
		cd $CUR_DIR
		
		JOURNAL=$JOURNAL_SAV
		prnCmd "JOURNAL=$JOURNAL_SAV"
	fi
	
	# run error checking
	if ! $DEBUG; then ngsErrorChk_BOWTIE $@; fi

	if $SE; then prnCmd "# FINISHED: BOWTIE SINGLE-END ALIGNMENT"
	else prnCmd "# FINISHED: BOWTIE PAIRED-END ALIGNMENT"; fi
}

##########################################################################################
# ERROR CHECKING. Make sure output file exists and is not empty.
##########################################################################################

ngsErrorChk_BOWTIE() {
	prnCmd "# BOWTIE ERROR CHECKING: RUNNING"

	inputFile_1="$SAMPLE/$ngsLocal_BOWTIE_INP_DIR/unaligned_1.fq"
	inputFile_2="$SAMPLE/$ngsLocal_BOWTIE_INP_DIR/unaligned_2.fq"
	outputFile="$SAMPLE/bowtie/$SAMPLE.bowtie.sorted.bam"

	# make sure expected output file exists
	if [[ ! -s $outputFile ]]; then
		errorMsg="Output file doesn't exist or is empty.\n"
		errorMsg+="\tinput file: $inputFile_1\n"
		if ! $SE; then errorMsg+="\tinput file: $inputFile_2\n"; fi
		errorMsg+="\toutput file: $outputFile\n"
		prnError "$errorMsg"
	fi

	prnCmd "# BOWTIE ERROR CHECKING: DONE"
}

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
# INPUT: list input files here
# OUTPUT: list output files here
# REQUIRES: list any external programs required to complete COMMAND function
##########################################################################################

# "TEMPLATE" is a place holder and should be replaced by the name of the command

##########################################################################################
# USAGE
# ngsUsage_TEMPLATE should be a single line that ends in a "\n"
##########################################################################################

NGS_USAGE+="put usage and brief description here\n"

##########################################################################################
# HELP TEXT
# ngsHelp_TEMPLATE should contain expanded help
##########################################################################################

ngsHelp_TEMPLATE() {
	echo -e "put usage here\t"
	echo -e "descriptive text here"
}

##########################################################################################
# LOCAL VARIABLES WITH DEFAULT VALUES. Using the naming convention to
# make sure these variables don't collide with the other modules.
##########################################################################################

# put local variables here using module naming convention: ngsLocal_TEMPLATE_VARIABLENAME

##########################################################################################
# PROCESSING COMMAND LINE ARGUMENTS
# TEMPLATE args
##########################################################################################

ngsArgs_TEMPLATE() {
	# process arguments here
}

##########################################################################################
# RUNNING COMMAND ACTION
# TEMPLATE command
##########################################################################################

ngsCmd_TEMPLATE() {
	# 1. create subdirectory, if necessary
	# 2. output version information using prnVersion() (see ngs.sh)
	# 3. do stuff here
	# 4. call ngsErrorChk_TEMPLATE
}

##########################################################################################
# ERROR CHECKING
##########################################################################################

ngsErrorChk_TEMPLATE() {
	# check to make sure output files are valid (eg they exist and are not empty)
}

##########################################################################################
# PRINT STATS
##########################################################################################

ngsStats_TEMPLATE() {
	# expect one argument that is either "header" or "values" and output tab-delimited list stats of interest.
}

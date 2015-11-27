#!/bin/sh
#
# Copyright (c) 2015, Flinders University, South Australia. All rights reserved.
# Contributors: Library, Information Services, Flinders University.
# See the accompanying LICENSE file (or http://opensource.org/licenses/BSD-3-Clause).
#
# - Iterate from YEAR_BEGIN to YEAR_END inclusive.
# - Add a MARC 008 normalization rule for each year (for a digital thesis
#   record).
# - All of the generated normalization rules can be stored in a single
#   normalization rule file.
#
##############################################################################
YEAR_BEGIN=1960			# Begin year (inclusive); format YYYY
YEAR_END=2040			# End year (inclusive); format YYYY

yyyy=$YEAR_BEGIN
while [ $yyyy -le $YEAR_END ]; do
	yy=`echo $yyyy |cut -c 3-4`
	#echo "### YYYY=$yyyy -- YY=$yy"

	cat <<-EO_NORM_RULE
		rule "Equella thesis - Add 008 for year $yyyy"
		  when
		    (exists "024.a.flex-*") AND (not existsControl "008") AND (exists "260.c.$yyyy")
		  then
		    addcontrolField "008.${yy}0101s$yyyy    xra||||fsm||||000#||eng|d"
		end

	EO_NORM_RULE
	yyyy=`expr $yyyy + 1`
done


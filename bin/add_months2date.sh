#!/bin/sh
#
# Copyright (c) 2015, Flinders University, South Australia. All rights reserved.
# Contributors: Library, Information Services, Flinders University.
# See the accompanying LICENSE file (or http://opensource.org/licenses/BSD-3-Clause).
#
# Add NUM_MONTHS to the specified DATE (format DD/MM/YYYY). Send the
# result to stdout (format yyyy-mm-dd). On error, send $STDOUT_ERROR_MSG
# to stdout.
#
##############################################################################
APP=`basename "$0"`
STDOUT_ERROR_MSG="Unknown"

##############################################################################
usage_exit() {
  stderr_msg="$1"
  stdout_msg="$2"
  [ -n "$stdout_msg" ] && echo -e "$stdout_msg"
  [ -n "$stderr_msg" ] && echo -e "$stderr_msg" >&2

  cat <<-USAGE_MSG >&2
		Usage:  $APP  DATE  NUM_MONTHS
		where
		- DATE has format DD/MM/YYYY
		  * DD   = 1 or 2 digit day of month (1..31)
		  * MM   = 1 or 2 digit month number (1..12)
		  * YYYY = 2 or 4 digit year. Two digit years are translated into
		           the range: 1969 to 2068
		- NUM_MONTHS is a non-negative integer number of months to be added
		  to the DATE (e.g. 0, 3 or 12)

		The ouput is an ISO date with format yyyy-mm-dd where:
		- yyyy = 4 digit year
		- mm   = 2 digit month number
		- dd   = 2 digit day of month

		Eg. $APP  22/10/2012  4
	USAGE_MSG
  exit 1
}

##############################################################################
ddmmyyyy="$1"
num_months="$2"

# Rough check of command line args
[ $# != 2 ] && usage_exit "" "$STDOUT_ERROR_MSG"
if ! echo "$num_months" |egrep -q "^[0-9]+$"; then usage_exit "Error: '$num_months' is not an integer" "$STDOUT_ERROR_MSG"; fi
if ! echo "$ddmmyyyy" |egrep -q "^[0-9]{1,2}/[0-9]{1,2}/[0-9]{2,4}$"; then usage_exit "Error: '$ddmmyyyy' has invalid date format" "$STDOUT_ERROR_MSG"; fi

# Convert DD/MM/YYYY to yyyy-mm-dd. yyyy may be 2 or 4 digits.
yyyymmdd=`echo "$ddmmyyyy" |
  awk -F/ '
    {printf "%s-%02d-%02d", $3, $2, $1}
'`

# Two digit years are translated into the range 1969 to 2068
calc_date_begin=`date -d "$yyyymmdd 8:00" +%Y-%m-%d`
[ $? != 0 ] && usage_exit "" "$STDOUT_ERROR_MSG"

calc_date_end=`date -d "$calc_date_begin 8:00 $num_months months" +%Y-%m-%d`
[ $? != 0 ] && usage_exit "" "$STDOUT_ERROR_MSG"

echo "$calc_date_end"
exit 0


#!/bin/sh
#
# Copyright (c) 2015, Flinders University, South Australia. All rights reserved.
# Contributors: eResearch@Flinders, Library, Information Services, Flinders University.
# See the accompanying LICENSE file (or http://opensource.org/licenses/BSD-3-Clause).
#
# Create CSV data with embargo end-dates calculated from ADT start date
# and number of months embargoed (specified in the html a-element). Send
# the result to stdout.
##############################################################################


echo "embargo_dir,date_begin,period,date_end,comment"
cat /opt/adt/html/uploads/delayed/index.html |

  egrep "^<a " |

  sed '
    s:^<a href="/::
    s: *</a>.*$::
    s:/catalog-adt-.*\.html::
    s/"> */|/
    s/, */|/g
    s/restricted *//
  ' |

  awk -F\| '
    {printf "%s|%s|%s\n",$1,gensub(/\//, "|", "g", $4),$5}
  ' |

  tr \| " " |

  while read dir dd mm yyyy period; do
    # Period is typically "N months" where N=2,3,12,18,24,36
    date_begin="$yyyy-$mm-$dd"
    calc_date_begin=`date -d "$date_begin 8:00" +%Y-%m-%d`

    diff=""	# Warn if date_begin & calc_date_begin are different
    [ "$date_begin" != "$calc_date_begin" ] && diff="StartDateFormatIsNot_YYYY-MM-DD"

    calc_date_end=`date -d "$calc_date_begin 8:00 $period" +%Y-%m-%d`
    echo "$dir,$date_begin,$period,$calc_date_end,$diff"
  done  # |sort -t\| -k4,4


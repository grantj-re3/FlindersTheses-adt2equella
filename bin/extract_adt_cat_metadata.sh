#!/bin/sh
#
# Copyright (c) 2015, Flinders University, South Australia. All rights reserved.
# Contributors: Library, Information Services, Flinders University.
# See the accompanying LICENSE file (or http://opensource.org/licenses/BSD-3-Clause).
#
# ALGORITHM
# - Extract metadata from approved Australasian Digital Theses (ADT) catalog HTML page.
#   An example of a approved page within the filesystem is:
#   /opt/adt/html/uploads/approved/adt-SFU20050603.095257/catalog-adt-ADT20050603.095257.html
# - Convert result to XML (so we don't rely on HTML-element order and can
#   cope with newlines within metadata).
# - Send result to stdout.
#
##############################################################################
app=`basename $0`
app_dir_temp=`dirname "$0"`		# Might be relative (eg "." or "..") or absolute
root_dir=`cd "$app_dir_temp/.." ; pwd`	# Absolute dir (one level above app dir)
add_months_exe="$root_dir/bin/add_months2date.sh"	# Add N-months to the specified date


##############################################################################
usage_exit() {
  echo "Usage 1:  $app  --approved|-a   ADT_CATALOG_FILE_PATH.html" >&2
  echo "Usage 2:  $app  --embargoed|-e  ADT_CATALOG_FILE_PATH.html" >&2
  echo "     Eg:  $app  -a /opt/adt/html/uploads/approved/adt-SFUyyyymmdd.hhmmdd/catalog-adt-SFUyyyymmdd.hhmmdd.html" >&2
  echo "     Eg:  $app  -a /opt/adt/html/uploads/approved/adt-SFUyyyymmdd.hhmmdd/catalog-adt-ADTyyyymmdd.hhmmdd.html" >&2
  exit 1
}

##############################################################################
# FIXME: Options --approved|-a & --embargoed|-e are not used
if [ "$1" = --approved -o "$1" = -a ]; then
  EMBARGOED_STR=false
elif [ "$1" = --embargoed -o "$1" = -e ]; then
  EMBARGOED_STR=true
else
  usage_exit
fi

shift
[ -z "$1" ] && usage_exit
fname="$1"

[ ! -r "$1" ] && {
  echo "File '$fname' must exist and be readable" >&2
  exit 2
}

cat $fname |

  sed '
    # Remove Carriage Return chars
    s/\r$//

    # Ensure only 1 input-element per line on the incoming stream
    s/<input /\n<input /g
  ' |

  awk -F\" -v add_months_exe="$add_months_exe" '
    BEGIN {
      printf "<CATALOG_BODY>\n"
      pref = "Y."		# Namespace prefix for extra fields in approved page
      n_months = ""		# Number of months to embargo after the approval date
      appr_date = ""		# Approval date: format [D]D/[M]M/[YY]YY
    }

    # Copy selected XPath /HTML/BODY/input elements to output.
    /<input.*type=\"hidden\"/ && $4=="num_months" {n_months=$6;  printf "  <META NAME=\"%s%s\" CONTENT=\"%s\" />\n",pref,$4,$6}
    /<input.*type=\"hidden\"/ && $4=="adate"      {appr_date=$6; printf "  <META NAME=\"%s%s\" CONTENT=\"%s\" />\n",pref,$4,$6}

    END {
      line_release_date_iso = "Unknown"
      line_adate_iso = "Unknown"
      if(appr_date != "") {
        if(n_months != "") {
          cmd = sprintf("%s %s %s", add_months_exe, appr_date, n_months)
          cmd | getline line_release_date_iso
          close(cmd)	# Close pipe in case cmd below is identical (ie. n_months=0)
        }
        cmd = sprintf("%s %s %s", add_months_exe, appr_date, "0")
        cmd | getline line_adate_iso
        close(cmd)
      }

      # Release date: format YYYY-MM-DD (or "Unknown")
      printf "  <META NAME=\"%s%s\" CONTENT=\"%s\" />\n", pref, "adate_iso", line_adate_iso
      printf "  <META NAME=\"%s%s\" CONTENT=\"%s\" />\n", pref, "release_date_iso", line_release_date_iso
      printf "</CATALOG_BODY>\n"
    }
  '

exit 0


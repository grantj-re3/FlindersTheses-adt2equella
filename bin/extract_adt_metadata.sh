#!/bin/sh
#
# Copyright (c) 2015, Flinders University, South Australia. All rights reserved.
# Contributors: Library, Information Services, Flinders University.
# See the accompanying LICENSE file (or http://opensource.org/licenses/BSD-3-Clause).
#
# ALGORITHM
# - Extract metadata from approved Australasian Digital Theses (ADT) HTML page.
#   An example of a approved page within the filesystem is:
#   /opt/adt/html/uploads/approved/adt-SFU20050603.095257/adt-ADT20050603.095257.html
# - Convert result to XML (so we don't rely on HTML-element order and can
#   cope with newlines within metadata).
# - Convert char encoding from WINDOWS-1250 to UTF-8.
# - Send result to stdout.
#
# We are using the approved (admin) HTML page rather than the public/xxxx/index.html
# page because it contains additional metadata (eg. dept, school).
#
# GOTCHAS
# - ADT pages contain some illegal HTML which make them difficult to parse. Eg.
#   /opt/adt/html/uploads/approved/adt-SFU20060130.095828/adt-SFU20060130.095828.html
#   says:
#     <META NAME="DC.Description.abstract" CONTENT="...  and "improve" health systems">
#   We changed to:
#     <META NAME=|DC.Description.abstract| CONTENT=|...  and "improve" health systems|>
#   then replaced the remaining quotes with &quot;.
#
# HTML entity references:
# - http://www.w3schools.com/charsets/ref_html_entities_4.asp
# - http://en.wikipedia.org/wiki/List_of_XML_and_HTML_character_entity_references
# - http://www.htmlcodetutorial.com/characterentities_famsupp_69.html
# - http://www.ascii.cl/htmlcodes.htm
#
##############################################################################
app=`basename $0`


[ x$1 = x ] && {
  echo "Usage:  $app  ADT_FILE_PATH.html" >&2
  echo "   Eg:  $app  /opt/adt/html/uploads/approved/adt-SFUyyyymmdd.hhmmdd/adt-SFUyyyymmdd.hhmmdd.html" >&2
  echo "   Eg:  $app  /opt/adt/html/uploads/approved/adt-SFUyyyymmdd.hhmmdd/adt-ADTyyyymmdd.hhmmdd.html" >&2
  exit 1
}

fname="$1"
#fname="/opt/adt/html/uploads/approved/adt-SFU20050603.095257/adt-ADT20050603.095257.html"
#fname="/opt/adt/html/uploads/approved/adt-SFU20060130.095828/adt-SFU20060130.095828.html"

[ ! -r "$1" ] && {
  echo "File '$fname' must exist and be readable" >&2
  exit 2
}

# Extract "yyyy-mm-dd" from filename "adt-SFUyyyymmdd.HHMMSS.html"
upload_date=`basename "$fname" |
  sed '
    s/^adt-\(SFU\|ADT\)//
    s/\.[0-9]\{6\}\.html$//
    s/^\([0-9]\{4\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)$/\1-\2-\3/
  '`

cat $fname |

  sed '
    # Remove Carriage Return chars
    s/\r$//

    # Convert HTML meta-tags to XML. ie.  <META ...> to <META ... />
    s:" *> *$:" />:
  ' |

  awk -F\" -v upload_date="$upload_date" '
    BEGIN {
      # The ADT char encoding is ISO-8859-1/WINDOWS-1250, but
      # this script will convert to UTF-8 (using iconv)
      char_enc = "UTF-8"	# XML character encoding
      pref = "X."		# Namespace prefix for extra fields in approved page

      # Subset of @names in /HTML/BODY/input fields
      md[0] = "chair"
      #md[1] = "chair_email"
      md[2] = "dtype"
      md[3] = "degree"
      md[4] = "institution"
      md[5] = "dept"
      md[6] = "school"
      md[7] = "dir_name"
    }

    # Close the XML doc
    END {
      # Make upload date available (perhaps assume approx the publish date)
      printf "  <META NAME=\"%s%s\" CONTENT=\"%s\" />\n", pref, "upload_date", upload_date
      printf "</BODY>\n"
    }

    # Copy *all* of XPath /HTML/HEAD to output.
    # This is done because DC.Description.abstract CONTENT attribute may be multi-line.
    /^<HTML>/ {
      get=1
      #printf "<?xml version=\"1.0\" encoding=\"%s\"?>\n",char_enc
      printf "<ADT_METADATA>\n<HEAD>\n"
    }
    /^<BODY / {get=0; print "<BODY>"}
    get==1 && !/^<HTML>/ {print $0}

    # Copy selected XPath /HTML/BODY/input elements to output.
    # All input-elements are on a single line.
    /<input.*type=\"hidden\"/ && $4==md[0] {e=md[0]; print e > "/dev/stderr"; printf "  <META NAME=\"%s%s\" CONTENT=\"%s\" />\n",pref,e,$6}
    #/<input.*type=\"hidden\"/ && $4==md[1] {e=md[1]; print e > "/dev/stderr"; printf "  <META NAME=\"%s%s\" CONTENT=\"%s\" />\n",pref,e,$6}
    /<input.*type=\"hidden\"/ && $4==md[2] {e=md[2]; print e > "/dev/stderr"; printf "  <META NAME=\"%s%s\" CONTENT=\"%s\" />\n",pref,e,$6}
    /<input.*type=\"hidden\"/ && $4==md[3] {e=md[3]; print e > "/dev/stderr"; printf "  <META NAME=\"%s%s\" CONTENT=\"%s\" />\n",pref,e,$6}
    /<input.*type=\"hidden\"/ && $4==md[4] {e=md[4]; print e > "/dev/stderr"; printf "  <META NAME=\"%s%s\" CONTENT=\"%s\" />\n",pref,e,$6}
    /<input.*type=\"hidden\"/ && $4==md[5] {e=md[5]; print e > "/dev/stderr"; printf "  <META NAME=\"%s%s\" CONTENT=\"%s\" />\n",pref,e,$6}
    /<input.*type=\"hidden\"/ && $4==md[6] {e=md[6]; print e > "/dev/stderr"; printf "  <META NAME=\"%s%s\" CONTENT=\"%s\" />\n",pref,e,$6}
    /<input.*type=\"hidden\"/ && $4==md[7] {e=md[7]; print e > "/dev/stderr"; printf "  <META NAME=\"%s%s\" CONTENT=\"%s\" />\n",pref,e,$6}
  ' |

  sed '
    # Temporarily convert double-quotes for NAME,SCHEME,CONTENT attributes into pipes
    s/\(NAME=\)"\([0-9A-Za-z_\.]*\)"/\1|\2|/g
    s/\(SCHEME=\)"\([0-9A-Za-z_\.]*\)"/\1|\2|/g
    s/\(CONTENT=\)"/\1|/g
    s:" />:| />:g

    # Escape any remaining (illegal-HTML) double quotes
    # NOTE: awk(\&quot;\&quot;) -> xml(&quot;&quot;) -> CSV-text("")
    s/"/\&quot;\&quot;/g

    # Fix DC.Rights: Remove ")" from Flinders disclaimer
    s~/disclaimer/)~/disclaimer/~g
    # Fix DC.Rights: Replace unsw disclaimer with Flinders one for a few old records
    s~http://www.unsw.edu.au/help/disclaimer.html)~http://www.flinders.edu.au/disclaimer/~g

    # Fix bad HTML entity refs (eg. which are missing trailing semicolon)
    # NOTE: awk(\&quot;\&quot;) -> xml(&quot;&quot;) -> CSV-text("")
    s/&quote;/\&quot;\&quot;/g	# Mis-spelt; must come before &quot with missing semicolon
    s/&gt\([^;]\)/\&gt;\1/g	# Missing trailing semicolon
    s/&lt\([^;]\)/\&lt;\1/g	# Missing trailing semicolon
    s/&deg\([^;]\)/\&deg;\1/g	# Missing trailing semicolon
    # NOTE: awk(\&quot;\&quot;) -> xml(&quot;&quot;) -> CSV-text("")
    s/&quot\([^;]\)/\&quot;\&quot;\1/g	# Missing trailing semicolon


    # Escape other XML special chars (eg. &)
    s/&\([^a-z]\)/\&amp;\1/g
    s/&$/\&amp;/g

    # Escape other XML special chars (as most HTML entity refs are not legal XML)
    s/&deg;/\&#176;/g
    s/&plusmn;/\&#177;/g
    s/&sup2;/\&#178;/g
    s/&micro;/\&#181;/g
    s/&delta;/\&#948;/g
    s/&ndash;/\&#8211;/g
    s/&permil;/\&#8240;/g

    # Indent meta-tags if required
    s/^<META /  <META /

    # Reinstate pipes into double-quotes for NAME,SCHEME,CONTENT attributes
    s/\(NAME=\)|\([0-9A-Za-z_\.]*\)|/\1"\2"/g
    s/\(SCHEME=\)|\([0-9A-Za-z_\.]*\)|/\1"\2"/g
    s/\(CONTENT=\)|/\1"/g
    s:| />:" />:g
  ' |

  iconv -f WINDOWS-1250 -t UTF8 -	# Convert char encoding to UTF-8

exit 0


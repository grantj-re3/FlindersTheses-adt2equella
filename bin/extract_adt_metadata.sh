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
app_dir_temp=`dirname "$0"`		# Might be relative (eg "." or "..") or absolute
root_dir=`cd "$app_dir_temp/.." ; pwd`	# Absolute dir (one level above app dir)


##############################################################################
usage_exit() {
  echo "Usage 1:  $app  --approved|-a   ADT_FILE_PATH.html" >&2
  echo "Usage 2:  $app  --embargoed|-e  ADT_FILE_PATH.html" >&2
  echo "     Eg:  $app  -a /opt/adt/html/uploads/approved/adt-SFUyyyymmdd.hhmmdd/adt-SFUyyyymmdd.hhmmdd.html" >&2
  echo "     Eg:  $app  -a /opt/adt/html/uploads/approved/adt-SFUyyyymmdd.hhmmdd/adt-ADTyyyymmdd.hhmmdd.html" >&2
  exit 1
}

##############################################################################
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
#fname="/opt/adt/html/uploads/approved/adt-SFU20050603.095257/adt-ADT20050603.095257.html"
#fname="/opt/adt/html/uploads/approved/adt-SFU20060130.095828/adt-SFU20060130.095828.html"

[ ! -r "$1" ] && {
  echo "File '$fname' must exist and be readable" >&2
  exit 2
}

# Extract "yyyymmdd.HHMMSS" from filename "adt-SFUyyyymmdd.HHMMSS.html"
ref_no=`basename "$fname" |
  sed '
    s/^adt-\(SFU\|ADT\)//
    s/\.html$//
  '`
# Extract "yyyy-mm-dd" from ref_no "yyyymmdd.HHMMSS"
upload_date=`basename "$ref_no" |
  sed '
    s/^\([0-9]\{4\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)\.[0-9]\{6\}$/\1-\2-\3/
  '`

cat $fname |

  sed '
    # Remove Carriage Return chars
    s/\r$//

    # Convert HTML meta-tags to XML. ie.  <META ...> to <META ... />
    s:" *> *$:" />:

    # Ensure only 1 input-element per line on the incoming stream
    s/<input /\n<input /g
  ' |

  awk -F\" -v upload_date="$upload_date" -v ref_no="$ref_no" '
    BEGIN {
      # The ADT char encoding is ISO-8859-1/WINDOWS-1250, but
      # this script will convert to UTF-8 (using iconv)
      char_enc = "UTF-8"	# XML character encoding
      pref = "X."		# Namespace prefix for extra fields in approved page

      # Subset of @names in /HTML/BODY/input fields
      md[0] = "chair"
      md[1] = "chair_email"
      md[2] = "dtype"
      md[3] = "degree"
      md[4] = "institution"
      md[5] = "dept"
      md[6] = "school"
      md[7] = "dir_name"
    }

    # Close the XML doc
    END {
      # Make upload date available (perhaps it is approx the publish date)
      printf "  <META NAME=\"%s%s\" CONTENT=\"%s\" />\n", pref, "upload_date", upload_date
      # Make ref_no (ADT Thesis key) available
      printf "  <META NAME=\"%s%s\" CONTENT=\"%s\" />\n", pref, "ref_no", ref_no
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
    /<input.*type=\"hidden\"/ && $4==md[0] {print $4 > "/dev/stderr"; printf "  <META NAME=\"%s%s\" CONTENT=\"%s\" />\n",pref,$4,$6}
    /<input.*type=\"hidden\"/ && $4==md[1] {print $4 > "/dev/stderr"; printf "  <META NAME=\"%s%s\" CONTENT=\"%s\" />\n",pref,$4,$6}
    /<input.*type=\"hidden\"/ && $4==md[2] {print $4 > "/dev/stderr"; printf "  <META NAME=\"%s%s\" CONTENT=\"%s\" />\n",pref,$4,$6}
    /<input.*type=\"hidden\"/ && $4==md[3] {print $4 > "/dev/stderr"; printf "  <META NAME=\"%s%s\" CONTENT=\"%s\" />\n",pref,$4,$6}
    /<input.*type=\"hidden\"/ && $4==md[4] {print $4 > "/dev/stderr"; printf "  <META NAME=\"%s%s\" CONTENT=\"%s\" />\n",pref,$4,$6}
    /<input.*type=\"hidden\"/ && $4==md[5] {print $4 > "/dev/stderr"; printf "  <META NAME=\"%s%s\" CONTENT=\"%s\" />\n",pref,$4,$6}
    /<input.*type=\"hidden\"/ && $4==md[6] {print $4 > "/dev/stderr"; printf "  <META NAME=\"%s%s\" CONTENT=\"%s\" />\n",pref,$4,$6}
    /<input.*type=\"hidden\"/ && $4==md[7] {print $4 > "/dev/stderr"; printf "  <META NAME=\"%s%s\" CONTENT=\"%s\" />\n",pref,$4,$6}
  ' |

  sed '
    # Escape &quot; for CSV compatibility
    # NOTE: awk(\&quot;\&quot;) -> xml(&quot;&quot;) -> CSV-text("")
    s/&quot;/\&quot;\&quot;/g

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

  awk -F\" '
    # Clean DC.Subject.
    #   Multi-valued dc.subject (Equella item/curriculum/thesis/keywords/keyword)
    #   should be delimited with comma (not semi-colon). The method below is a
    #   fudge - we should really create a new DC.Subject XML element for each
    #   multi-valued field and let the XSLT script take care of concatenating them.
    BEGIN {OFS="\""}

    $2=="DC.Subject" {
      if($4=="aged care; alternative therapies; complementary therapies; dementia; early onset dementia; one to one interaction; quality of life; Reiki; therapeutic touch; unconventional therapies")
        $4 = "aged care,alternative therapies,complementary therapies,dementia,early onset dementia,one to one interaction,quality of life,Reiki,therapeutic touch,unconventional therapies"

      else if($4=="germination strategies;  seed size and number; salinity tolerance; arid zone plants; Australian flora; soil properties; revegetation potential")
        $4 = "germination strategies,seed size and number,salinity tolerance,arid zone plants,Australian flora,soil properties,revegetation potential"

      else if($4=="community pharmacy;")
        $4 = "community pharmacy"

      else if($4=="skin cancer; mangosteen; xanthones; cytotoxicity; apoptosis; survival pathway; metastasis")
        $4 = "skin cancer,mangosteen,xanthones,cytotoxicity,apoptosis,survival pathway,metastasis"

      else if($4=="verse novel; children'\''s and adolescent / young adult (YA) literature; voice-zone")
        $4 = "verse novel,children'\''s and adolescent / young adult (YA) literature,voice-zone"

      else if($4=="Psychology of War; Adelaide")
        $4 = "Psychology of War,Adelaide"

      else if($4=="Gender;")
        $4 = "Gender"
    }

    {print $0}
  ' |

  awk -F\" -v EMBARGOED_STR="$EMBARGOED_STR" '
    # Convert DC.Language to give name ("English") rather than RFC1766
    # (ISO639-1) language code ("en"). We retain the xml attribute SCHEME=
    # "RFC1766" here (although it is no longer true after the conversion).
    BEGIN {OFS="\""}
    !($2=="DC.Language" && $4=="RFC1766") {print $0}
    $2=="DC.Language" && $4=="RFC1766" {
      $6 = gensub("en", "English", "", $6)
      print $0
    }

    # Insert DC.Identifier.fixed immediately after DC.Identifier.
    # This repairs the DC.Identifier URI.
    $2=="DC.Identifier" && $4=="URI" {
      $2 = "DC.Identifier.fixed"
      if(EMBARGOED_STR == "false") {
        # Public
        $6 = gensub("//(theses.flinders.edu.au\.?|catalogue.flinders.edu.au./local/adt)/uploads/", "//theses.flinders.edu.au/public/", "", $6)
        $6 = gensub("/public/adt-ADT", "/public/adt-SFU", "", $6)
      }
      else {
        # Embargoed
        $6 = gensub("//theses.flinders.edu.au\.?/uploads/(.*)$", "//theses.flinders.edu.au/uploads/delayed/\\1/catalog-\\1.html", "", $6)
      }
      print $0
    }

    # Insert DC.Date.fixed immediately after DC.Date.valid.
    # This repairs & converts DC.Date.valid values
    $2=="DC.Date.valid" {
      $2 = "DC.Date.fixed"
      $6 = gensub("^.*[\/ \.\-]([0-9]+)$", "\\1", "", $6)	# Strip leading day or month
      $6 = gensub("^([0-9][0-9])$", "20\\1", "", $6)		# Convert YY to YYYY
      #$6 = gensub("^(.*)$", "\\1-01-01", "", $6)		# Convert YYYY to YYYY-MM-DD
      print $0
    }
  ' |

  awk -F\" -v root_dir="$root_dir" '
    # Map thesis to current school.
    # Insert the following before the closing </BODY> tag:
    # - X.school.interim_now15
    # - X.school.clean1
    # - X.faculty.clean1
    # - X.publisher_school
    BEGIN {
      OFS="\""
      fname_sch_conf = root_dir "/etc/schools_now_xmlfields.csv"
      fname_debug    = root_dir "/debug_schools.log"

      # Read school records with format "FacultyName","SchoolKey","SchoolName","SchoolOrgUnit". Eg.
      # "Faculty of Science and Engineering","BS","School of Biological Sciences","330"
      # SchoolCodes = BUS,IS,PSY,SAPS,NILS. LAW,EDU,HACA,BAO. BS,CAPS,CSEM,ENV. HS,MED,NM
      i = 0			# Line number
      while (getline < fname_sch_conf) {
        split($0, col, "\"")
        key = col[4]
        ref_fac[key] = col[2]
        ref_sch[key] = col[6]
        ref_org[key] = col[8]

        i++
        keys_sorted[i] = key
      }
      for(i=1; i<=length(keys_sorted); i++) {
        key = keys_sorted[i]
        printf(" %2d %-6s %-3s %-60s %-60s\n", i, key, ref_org[key], ref_sch[key], ref_fac[key]) > fname_debug
      }
    }

    $2=="X.school"      {sch = $4}
    $2=="X.dept"        {fac = $4}
    $2=="X.dir_name"    {dir = $4}
    $2=="X.institution" {inst = $4}
    !/<\/BODY>/ {print $0}

    /<\/BODY>/ {
      key = ""
      sch_lc = tolower(sch)

      # Use regex to map to current school
      #
      # Fixed:
      # Approved:
      # c adt-SFU20060227.150043 = haca (theology)
      # c adt-SFU20060612.211358 = env
      # c adt-SFU20061010.104925 = haca (archaeology)
      # c adt-SFU20070130.192707 = csem
      # c adt-SFU20080115.222927 = csem
      # c adt-SFU20080430.132508 = caps (physics)
      # c adt-SFU20090810.180637 = med (Biotechnology, Faculty of Health Sciences)
      # c adt-SFU20100602.095058 = haca (archaeology)
      # c adt-SFU20101214.163513 = caps (School of Chemistry, Physics and Earth Sciences)
      # c adt-SFU20110825.112517 = edu
      # c adt-SFU20130410.021018 = bs (biological science)
      # c adt-SFU20141013.091753 = haca (archaeology)
      # c adt-SFU20141027.102258 = csem
      #
      # Embargoed:
      # c HACA: ECWAS (English, Creative Writing and Australian Studies)
      # c adt-SFU20150330.161707 = saps (2 schools; Women’s Studies listed first)

      # Before faculties, perform overrides here (which would otherwise be
      # caught by an inadequate rule below)
      if(dir ~ "adt-SFU20110825.112517")
        key = "EDU"
      else if(dir ~ "adt-SFU20061010.104925")
        key = "HACA"
      else if(dir ~ "adt-SFU20150330.161707")
        key = "SAPS"

      # Faculty of Social and Behavioural Sciences
      else if(sch_lc ~ /business/) 
        key = "BUS"
      else if(sch_lc ~ /(international|development|american).* stud|history/) 
        key = "IS"
      else if(sch_lc ~ /psychology/) 
        key = "PSY"
      else if(sch_lc ~ /sociology|public.* policy.* management|women[^ ]*s.* stud|politics.* public.* policy|social.* policy.* stud|social.* work.* social.* policy/) 
        key = "SAPS"
      else if(sch_lc ~ /nationa.* institute.* labour.* stud/) 
        key = "NILS"

      # Faculty of Education, Humanities and Law
      else if(sch_lc ~ /(^|[^a-z])(law)($|[^a-z])/) 
        key = "LAW"
      else if(sch_lc ~ /education/) 
        key = "EDU"
      else if(sch_lc ~ /humanit[i]?es|screen.* (stud|media)|creative.* writing|english|drama|theology|australian.* stud|yunggorendi *first *nations *centre|tourism|archaeology|french|ecwas/ || dir ~ "adt-SFU20060227.150043|adt-SFU20100602.095058|adt-SFU20141013.091753")
        key = "HACA"

      # Faculty of Science and Engineering
      else if(sch_lc ~ /biolog/ || dir ~ "adt-SFU20130410.021018") 
        key = "BS"
      else if(sch_lc ~ /chem.* physic|chemistry|^caps$/ || dir ~ "adt-SFU20080430.132508|adt-SFU20101214.163513") 
        key = "CAPS"
      else if(sch_lc ~ /informatics.* engin[e]+ring|computer.*(science)?.* engineering.* math/ || dir ~ "adt-SFU20070130.192707|adt-SFU20080115.222927|adt-SFU20141027.102258") 
        key = "CSEM"
      else if(sch_lc ~ /environment|geography|earth.* science|environemt/ || dir ~ "adt-SFU20060612.211358") 
        key = "ENV"

      # Faculty of Medicine, Nursing and Health Sciences
      else if(sch_lc ~ /public.* health|health *science/) 
        key = "HS"
      else if(sch_lc ~ /medicine|medical *school|biotechnology|physiology/ || dir == "adt-SFU20090810.180637") 
        key = "MED"
      else if(sch_lc ~ /nursing/) 
        key = "NM"

      if(key == "") {
        val_sch = sch
        val_fac = fac
        val_org = "Unknown"
        val = sch
      } else {
        val_sch = ref_sch[key]
        val_fac = ref_fac[key]
        val_org = ref_org[key]
        val = sprintf("[[%s]] %s %s (%s)", key, val_org, val_sch, val_fac)
      }

      printf "  <META NAME=\"X.school.interim_now15\" CONTENT=\"%s\" />\n", val
      printf "  <META NAME=\"X.school.clean1\" CONTENT=\"%s\" />\n", val_sch
      printf "  <META NAME=\"X.school_org_unit.clean1\" CONTENT=\"%s\" />\n", val_org
      printf "  <META NAME=\"X.faculty.clean1\" CONTENT=\"%s\" />\n", val_fac
      printf "  <META NAME=\"X.publisher_school\" CONTENT=\"%s, %s\" />\n", inst, val_sch
      print $0
    }
  ' |

  awk -F\" '
    # Insert X.thesis_type before the closing </BODY> tag.
    # X.thesis_type is derived from X.dtype (or X.degree if X.dtype is inconclusive)
    BEGIN {
      dtype=""
      degree=""
    }

    $2=="X.dtype" {dtype=$4}
    $2=="X.degree" {degree=$4}
    !/<\/BODY>/ {print $0}

    /<\/BODY>/ {
      # Default type - hopefully no instances of this!
      type = "FIXME::" dtype "::" degree "::"

      if(tolower(dtype) ~ /^phd /)
        type = "Doctor of Philosophy"

      else if(tolower(dtype) ~ /^masters /)
        type = "Masters by Research"

      else if(tolower(dtype) ~ /professional *doctorate/)
        type = "Professional Doctorate"

      else if(dtype=="") {
        if(tolower(degree) ~ /[^a-z]phd[^a-z]/)
          type = "Doctor of Philosophy"

        else if(tolower(degree) ~ /[^a-z]masters[^a-z]/)
          type = "Masters by Research"
      }

      printf "  <META NAME=\"X.thesis_type\" CONTENT=\"%s\" />\n", type
      print $0
    }
  ' |

  iconv -f WINDOWS-1250 -t UTF8 -	# Convert char encoding to UTF-8

exit 0


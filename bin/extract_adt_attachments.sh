#!/bin/sh
#
# Copyright (c) 2015, Flinders University, South Australia. All rights reserved.
# Contributors: Library, Information Services, Flinders University.
# See the accompanying LICENSE file (or http://opensource.org/licenses/BSD-3-Clause).
#
# ALGORITHM
# - Extract (attachment) filenames from the public Australasian Digital
#   Theses (ADT) index.html page specified on the command line. Eg.
#   /opt/adt/html/public/adt-SFU20050603.095257/index.html
# - Copy the files to a subdirectory where they will be referenced
#   in the Equella EBI-CSV file.
# - Insert into the XML INDEX-element a reference to each file which
#   has been copied to the subdirectory.
# - Close the XML file
# - Send the XML result to stdout.
# - Perform sanity checks on filenames
#
# GOTCHAS
# - The index.html file path specified on the command line might not exist.
#   However (after issuing a warning) we still need to write an empty XML
#   INDEX-element and close the XML file.
#
##############################################################################
app=`basename $0`

APP_DIR_TEMP=`dirname "$0"`		# Might be relative (eg "." or "..") or absolute
OUT_DIR_PARENT=`cd "$APP_DIR_TEMP/.." ; pwd`	# Absolute dir containing out dir parent

ADT_PARENT_DIR_COMMON=/opt/adt/html
###ADT_PARENT_DIR_COMMON="$OUT_DIR_PARENT/test/adt/html"	# FIXME: Use real ADT dir

##############################################################################
usage_exit() {
  echo "Usage 1:  $app  --approved|-a  ADT_FILE_PATH.html  [DEST_DIR]" >&2
  echo "Usage 2:  $app  --embargoed|-e  ADT_DIR_PATH  [DEST_DIR]" >&2
  echo "   ADT_FILE_PATH.html is the file path to the ADT source index.html file" >&2
  echo "     (or /dev/null to avoid extracting attachments)" >&2
  echo "   ADT_DIR_PATH is the path to the ADT source attachment directory" >&2
  echo "     (or /dev/null to avoid extracting attachments)" >&2
  echo "   DEST_DIR is the destination directory for attachments" >&2
  echo "   Eg1:  $app -a /opt/adt/html/public/adt-SFUyyyymmdd.hhmmdd/index.html" >&2
  echo "   Eg2:  $app -e /opt/adt/html/uploads/delayed/adt-SFUyyyymmdd.hhmmdd/restricted" >&2
  exit 1
}

##############################################################################
get_xml_field4() {
  field_name="$1"
  xml_field=`awk -F\" -v fn="$field_name" '$2==fn {print $4}' "$xml_fname"`
}

##############################################################################
get_xml_field6() {
  field_name="$1"
  xml_field=`awk -F\" -v fn="$field_name" '$2==fn {print $6}' "$xml_fname"`
}

##############################################################################
get_xml_surname() {
  field_name="DC.Creator.personalName"
  xml_field=`awk -F\" -v fn="$field_name" '$2==fn {print $4}' "$xml_fname" |
    sed 's/,.*$//'
  `
}

##############################################################################
get_xml_complete_year() {
  field_name="DC.Date.fixed"
  xml_field=`awk -F\" -v fn="$field_name" '$2==fn {print $6}' "$xml_fname" |
    sed 's/\-.*$//'
  `
}

##############################################################################
# Return a list of file attachments and the number of file attachments
##############################################################################
get_attachments_approved() {
  src_fname="$1"

  if [ -f "$src_fname" ]; then
    attachments=`cat $src_fname |
      egrep "<a href=" |
      egrep -v "<IMG SRC=" |
      sed "
        s/^.*<a href=\"//
        s~http://[^/]*~$ADT_PARENT_DIR_COMMON~
        s/\">.*$//
      "
    `
    # Remove duplicates (assumes no spaces in filenames)
    attachments=`echo "$attachments" |xargs echo |tr ' ' '\n' |sort -u`
  else
    # Would not expect to get here but... yet more cleanup needed
    echo "WARNING: '$src_fname' not found; trying attachment folder" >&2

    # Eg. /opt/adt/html/uploads/approved/adt-SFUdddddddd.tttttt/{public,restricted}
    src_dname_parent=`echo "$src_fname" |
      sed 's~/opt/adt/html/public/~/opt/adt/html/uploads/approved/~;  s~/index.html$~~'
    `
    src_dname1="$src_dname_parent/public"
    src_dname2="$src_dname_parent/restricted"

    if [ -d "$src_dname1" ]; then
      src_dname="$src_dname1"
      attachments=`ls -1d $src_dname/*`
    elif [ -d "$src_dname2" ]; then
      src_dname="$src_dname2"
      attachments=`ls -1d $src_dname/*`
    else
      echo "WARNING: Neither '$src_dname1' nor '$src_dname2' folder found (INDEX element will be empty)" >&2
      attachments=""
    fi
  fi
  # This count might not equal the number of real files (eg. if broken hrefs above)
  num_attachments=`echo "$attachments" |wc -w`
}

##############################################################################
# Return a list of file attachments and the number of file attachments
##############################################################################
get_attachments_embargoed() {
  src_dname="$1"
  if [ -d "$src_dname" ]; then
    attachments=`ls -1d $src_dname/*`
  else
    echo "WARNING: '$src_dname' not found (INDEX element will be empty)" >&2
    attachments=""
  fi
  num_attachments=`echo "$attachments" |wc -w`
}

##############################################################################
# Main()
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
dname="$2"

# Extract XML metadata
xml_fname=`echo "$dname" |sed 's/\.d$/.xml/'`
get_xml_complete_year
complete_year="$xml_field"
get_xml_surname
surname="$xml_field"

##############################################################################
if [ $EMBARGOED_STR = 'false' ]; then
  get_attachments_approved  "$1"	# Returns $attachments & $num_attachments
else
  get_attachments_embargoed "$1"	# Returns $attachments & $num_attachments
fi

##############################################################################
# Write the second half of the XML to stdout (ie. INDEX part and closing root tag)
##############################################################################
echo "<INDEX>"

for href_attachment in $attachments; do
  attachment="$href_attachment"
  if [ ! -f "$attachment" ]; then
    attachment2="$href_attachment.pdf"		# Try FILE.pdf.pdf
    if echo "$attachments" |egrep -q "$attachment2"; then
      # FILE.pdf.pdf is already listed for processing; don't process here
      echo "WARNING: Attachment not found: '$attachment'" >&2
      continue
    fi

    if [ -f "$attachment2" ]; then
      attachment="$attachment2"			# Found FILE.pdf.pdf; process it
    else
      echo "WARNING: Attachment not found: '$attachment' (or '$attachment2')" >&2
      continue
    fi
  fi

  # Attachment file exists
  if [ ! -z "$dname" ]; then
    # Replace destination "FILENAME.pdf.pdf" with "FILENAME.pdf"
    attachment_base=`basename "$attachment"`
    if echo "$attachment_base" |egrep -q "\.pdf\.pdf$"; then
      attachment_base=`echo "$attachment_base" |sed 's/\.pdf\.pdf$/.pdf/'`
    fi

    dest_ext=""				# Assume no file-extension
    if echo "$attachment_base" |egrep -q "\."; then
      dest_ext=`echo "$attachment_base" |sed 's/^.*\.//' |tr A-Z a-z`
    fi

    # [Opt 1,2] Make other destination filenames more meaningful
    if echo "$attachment_base" |egrep -q "^01\.?[Ff]ront\.pdf$"; then
      meta_name="I.attachment_abstract"
      attachment_dest="thesis-01abstract.pdf"
      attachment_dest2="Abstract.pdf"

    else
      meta_name="I.attachment"
      attachment_dest="thesis-$attachment_base"
      if echo "$attachment_base" |egrep -q "^02"; then
        attachment_dest2="Thesis-$surname-$complete_year.$dest_ext"
      else
        attachment_dest2="Thesis-$surname-$complete_year-$attachment_base"
      fi
    fi

    # [Opt 3] Make other destination filenames more meaningful
    # Detect variations of 01front.pdf
    if echo "$attachment_base" |tr A-Z a-z |egrep -q "^01\.?front\.pdf$"; then
      meta_name="I.attachment_abstract"
      attachment_dest3="Thesis-$surname-$complete_year-Abstract.pdf"
      [ $num_attachments -gt 2 ] && attachment_dest3="Thesis-$surname-$complete_year-01Abstract.pdf"

    else
      meta_name="I.attachment"
      attachment_dest3="Thesis-$surname-$complete_year.$dest_ext"
      [ $num_attachments -gt 2 ] && attachment_dest3="Thesis-$surname-$complete_year-$attachment_base"
    fi

    # Path to dest file relative to XML/CSV files
    attachment_dest_rel="`basename $dname`/$attachment_dest"
    attachment_dest2_rel="`basename $dname`/$attachment_dest2"
    attachment_dest3_rel="`basename $dname`/$attachment_dest3"
    echo "  <META NAME=\"${meta_name}_clean0\" CONTENT=\"$attachment_base\" />"
    echo "  <META NAME=\"${meta_name}_clean1\" CONTENT=\"$attachment_dest_rel\" />"
    echo "  <META NAME=\"${meta_name}_clean2\" CONTENT=\"$attachment_dest2_rel\" />"
    echo "  <META NAME=\"${meta_name}_clean3\" CONTENT=\"$attachment_dest3_rel\" />"

    echo "Copying $attachment to $attachment_dest3_rel" >&2
    [ ! -d "$dname" ] && mkdir -p "$dname"
    cmd="cp -fp \"$attachment\" \"$dname/$attachment_dest3\""
    #echo "CMD: $cmd" >&2
    eval $cmd
  fi
done

echo "</INDEX>"
echo "</ADT_METADATA>"
[ -z "$attachments" ] && exit 0

##############################################################################
# Check that attachments all have the same parent dir
##############################################################################
attachment1=":"
dir1=":"
for attachment in $attachments; do
  if [ "$dir1" = ":" ]; then
    attachment1="$attachment"
    dir1=`dirname "$attachment"`
  else
    [ "$dir1" != `dirname "$attachment"` ] &&
      echo "WARNING: $attachment & $attachment1 have different parent dirs!" >&2
  fi
done

##############################################################################
# Check if extra files exist than those referenced in the index-file
##############################################################################
for fname_upload in $dir1/*; do
  if ! echo "$attachments" |egrep -q "^$fname_upload$"; then
    echo "WARNING: $fname_upload is not referenced" >&2
  fi
done

exit 0


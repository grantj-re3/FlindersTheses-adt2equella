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
ADT_PARENT_DIR_COMMON=/opt/adt/html

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

##############################################################################
if [ $EMBARGOED_STR = 'false' ]; then
  # Approved thesis
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
  else
    echo "WARNING: '$src_fname' not found (INDEX element will be empty)" >&2
    attachments=""
  fi

else
  # Embargoed thesis
  src_dname="$1"
  if [ -d "$src_dname" ]; then
    attachments=`ls -1d $src_dname/*`
  else
    echo "WARNING: '$src_dname' not found (INDEX element will be empty)" >&2
    attachments=""
  fi

fi

##############################################################################
# Write the second half of the XML to stdout (ie. INDEX part and closing root tag)
##############################################################################
echo "<INDEX>"

for attachment in $attachments; do
  if [ -f "$attachment" ]; then
    # Attachment file exists

    if [ ! -z "$dname" ]; then
      # Replace destination "FILENAME.pdf.pdf" with "FILENAME.pdf"
      attachment_dest=`basename "$attachment"`
      if echo "$attachment_dest" |egrep -q "\.pdf\.pdf$"; then
        attachment_dest=`echo "$attachment_dest" |sed 's/\.pdf\.pdf$/.pdf/'`
      fi

      # Make other destination filenames more meaningful
      if echo "$attachment_dest" |egrep -q "^01front\.pdf$"; then
        attachment_dest="thesis-01abstract.pdf"
        meta_name="I.attachment_abstract"
      else
        attachment_dest="thesis-$attachment_dest"
        meta_name="I.attachment"
      fi

      # Path to dest file relative to XML/CSV files
      attachment_dest_rel="`basename $dname`/$attachment_dest"
      echo "  <META NAME=\"$meta_name\" CONTENT=\"$attachment_dest_rel\" />"

      echo "Copying $attachment to dir $attachment_dest_rel" >&2
      [ ! -d "$dname" ] && mkdir -p "$dname"
      cmd="cp -fp \"$attachment\" \"$dname/$attachment_dest\""
      #echo "CMD: $cmd" >&2
      eval $cmd
    fi

  else
    echo "WARNING: Attachment not found: '$attachment'" >&2

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


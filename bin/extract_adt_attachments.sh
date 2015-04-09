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
[ x$1 = x ] && {
  echo "Usage:  $app  ADT_FILE_PATH.html [DEST_DIR]" >&2
  echo "   DEST_DIR is the destination directory for attachments" >&2
  echo "   Eg:  $app  /opt/adt/html/public/adt-SFUyyyymmdd.hhmmdd/index.html" >&2
  exit 1
}

fname="$1"
#fname="/opt/adt/html/public/adt-SFU20050603.095257/index.html"

dname="$2"

##############################################################################
if [ -f "$1" ]; then
  attachments=`cat $fname |
    egrep "<a href=" |
    egrep -v "<IMG SRC=" |
    sed "
      s/^.*<a href=\"//
      s~http://[^/]*~$ADT_PARENT_DIR_COMMON~
      s/\">.*$//
    "
  `
else
  echo "WARNING: '$fname' not found (INDEX element will be empty)" >&2
  attachments=""
fi

##############################################################################
# Write the second half of the XML to stdout (ie. INDEX part and closing root tag)
##############################################################################
echo "<INDEX>"

for attachment in $attachments; do
  if [ -f "$attachment" ]; then
    # Attachment file exists

    if [ ! -z "$dname" ]; then
      # Relative path to dest file
      dest_attachment="`basename $dname`/`basename $attachment`"
      echo "  <META NAME=\"I.attachment\" CONTENT=\"$dest_attachment\" />"

      #echo "Copying $attachment to dir $dname" >&2
      ###[ ! -d "$dname" ] && mkdir -p "$dname"
      ###cp -fp "$attachment" "$dname"
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


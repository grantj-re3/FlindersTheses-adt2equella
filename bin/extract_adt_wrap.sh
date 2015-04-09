#!/bin/sh
#
# Copyright (c) 2015, Flinders University, South Australia. All rights reserved.
# Contributors: eResearch@Flinders, Library, Information Services, Flinders University.
# See the accompanying LICENSE file (or http://opensource.org/licenses/BSD-3-Clause).
#
# Extract metadata and attachments from an Australian Digital Thesis (ADT) 
# system. The files to be processed will either be approved or delayed
# (ie. embargoed ) HTML files.
#
# ALGORITHM
# - Iterate through all ADT approved (or embargoed) html files:
#   * Extract metadata from approved Australian Digital Thesis (ADT) HTML page.
#     An example of a approved page within the filesystem is:
#     /opt/adt/html/uploads/approved/adt-SFU20050603.095257/adt-ADT20050603.095257.html
#   * For each thesis, invoke the script to extract metadata into an XML file
#   * For each thesis, invoke the script copy attachments to a subdirectory
#     and extract metadata into the same XML file
#   * For each thesis, validate the XML file (using xmllint)
# - Iterate through all XML files generated above:
#   * Convert into a single CSV file with XSLT (using xsltproc)
#
# BUGS:
# - Script features are under development. Eg. Script will give errors
#   when invoked with --embargoed|-e
#
##############################################################################
APP=`basename $0`
APP_DIR_TEMP=`dirname "$0"`		# Might be relative (eg "." or "..") or absolute
APP_DIR=`cd "$APP_DIR_TEMP" ; pwd`	# Absolute dir containing app

EXTRACT_METADATA_SCRIPT="$APP_DIR/extract_adt_metadata.sh"
EXTRACT_ATTACHMENTS_SCRIPT="$APP_DIR/extract_adt_attachments.sh"
XSLT_PATH="$APP_DIR/xml2csv.xsl"

OUT_DIR_APPROVED="$APP_DIR/xmlout"
OUT_DIR_EMBARGO="$APP_DIR/xmlout_embargo"
OUT_CSV_BASENAME=theses_ebi.csv

ADT_PARENT_DIR_COMMON=/opt/adt/html
ADT_MD_PARENT_DIR_APPROVED="$ADT_PARENT_DIR_COMMON/uploads/approved"
ADT_MD_PARENT_DIR_EMBARGO="$ADT_PARENT_DIR_COMMON/uploads/delayed"
ADT_INDEX_PARENT_DIR_APPROVED="$ADT_PARENT_DIR_COMMON/public"

# Limit the number of records to be processed by this script
RECORDS_MAX=99999	# At 27/03/2015 there are 477 dirs (4x html metadata files missing)

##############################################################################
# def find_adt_filename(dir_name, dir_count)
# Arg dir_name:   ADT directory
# Arg dir_count:  ADT directory count
# Returns fname:  Empty fname means "file not found".
##############################################################################
find_adt_filename() {
  dir_name="$1"
  dir_count="$2"
  # Filename format 1: adt-SFU20050603.095257/adt-ADT20050603.095257.html
  # Filename format 2: adt-SFU20050603.095257/adt-SFU20050603.095257.html
  fname1="$dir_name/`echo "$dir_name" |sed 's/^adt-SFU/adt-ADT/; s/$/.html/'`"
  fname2="$dir_name/`echo "$dir_name" |sed 's/$/.html/'`"

  fname="$fname1"
  if [ ! -f "$fname" ]; then
    fname="$fname2"
    if [ ! -f "$fname" ]; then
      echo "[$dir_count] Neither '$fname1' nor '$fname2' exist!!!" >&2
      fname=""
    fi
  fi
}

##############################################################################
# def find_adt_index_filename(dir_name, dir_count) {
##############################################################################
find_adt_index_filename() {
  dir_name="$1"
  dir_count="$2"

  fname_index="$ADT_INDEX_PARENT_DIR_APPROVED/$dir_name/index.html"
}

##############################################################################
# Process command line parameters
##############################################################################
if [ "$1" = --approved -o "$1" = -a ]; then
  ADT_MD_PARENT_DIR="$ADT_MD_PARENT_DIR_APPROVED"
  OUT_DIR="$OUT_DIR_APPROVED"
  EMBARGOED_STR=false

elif [ "$1" = --embargoed -o "$1" = -e ]; then
  ADT_MD_PARENT_DIR="$ADT_MD_PARENT_DIR_EMBARGO"
  OUT_DIR="$OUT_DIR_EMBARGO"
  EMBARGOED_STR=true

else
  echo "Usage:  $APP  --approved|-a  |  --embargoed|-e" >&2
  exit 1
fi

##############################################################################
# Iterate through all ADT HTML files; convert to XML; validate XML
##############################################################################
mkdir -p "$OUT_DIR"
cd $ADT_MD_PARENT_DIR
dir_count=0		# ADT dir count
fnames_out=""		# List of output filenames

echo
echo "Converting each ADT HTML file into an XML file..."
for dir_name in adt-SFU????????.??????; do
  dir_count=`expr $dir_count + 1`
  [ $dir_count -gt $RECORDS_MAX ] && break

  #[ $dir_count -le  300 ] && continue	# DEBUG - SKIP

  [ $dir_count -eq  83 ] && continue	# MANUALLY FIX: 2x junk char ("?" in black diamond)
  [ $dir_count -eq 129 ] && continue	# MANUALLY FIX: spelling errors in sentences 3 & 4 are due to illegal chars
  [ $dir_count -eq 136 ] && continue	# MANUALLY FIX: 2x Illegal char; KS??? gene
  [ $dir_count -eq 225 ] && continue	# MANUALLY FIX: 5x di???usion, 1x ???xed

  find_adt_filename "$dir_name" "$dir_count"		# Returns fname
  [ -z "$fname" ] && continue				# Skip if no HTML metadata file in dir

  # fname_out filename format: yyyymmdd.HHMMSS.xml
  # dname_out dir name format: yyyymmdd.HHMMSS.d
  basename_out=`echo "$dir_name" |sed 's/^adt-SFU//'`
  fname_out="$OUT_DIR/$basename_out.xml"
  dname_out="$OUT_DIR/$basename_out.d"
  echo "[$dir_count] Processing $fname; writing to $fname_out"

  $EXTRACT_METADATA_SCRIPT "$fname" > "$fname_out" 2>/dev/null

  ### Only for non-embargo???
  find_adt_index_filename "$dir_name" "$dir_count"	# Returns fname_index
  $EXTRACT_ATTACHMENTS_SCRIPT "$fname_index" "$dname_out" >> "$fname_out"

  fnames_out="$fnames_out $fname_out"
  xmllint --noout "$fname_out"
done

##############################################################################
# Iterate through all XML files; convert to a single CSV file (with XSLT)
##############################################################################
OUT_CSV_PATH="$OUT_DIR/$OUT_CSV_BASENAME"
rm -f "$OUT_CSV_PATH"

# Note that xsltproc allows parameters to be passed to the XSLT file
xsltproc_clopts_first="--stringparam embargoed_str $EMBARGOED_STR --param add_csv_header \"true()\""
xsltproc_clopts_other="--stringparam embargoed_str $EMBARGOED_STR --param add_csv_header \"false()\""
rec_count=0

echo
echo "Converting XML files into a single EBI CSV file $OUT_CSV_PATH ..."
for fname_out in $fnames_out; do
  rec_count=`expr $rec_count + 1`
  cmd="xsltproc $xsltproc_clopts_other $XSLT_PATH $fname_out >> $OUT_CSV_PATH"
  [ $rec_count = 1 ] && cmd="xsltproc $xsltproc_clopts_first $XSLT_PATH $fname_out > $OUT_CSV_PATH"
  #echo "CMD: $cmd"
  eval $cmd
done
exit 0


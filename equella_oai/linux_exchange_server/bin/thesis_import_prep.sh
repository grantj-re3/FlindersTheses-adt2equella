#!/bin/sh
#
# Copyright (c) 2018-2019, Flinders University, South Australia. All rights reserved.
# Contributors: Library, Corporate Services, Flinders University.
# See the accompanying LICENSE file (or http://opensource.org/licenses/BSD-3-Clause).
#
# Usage:  thesis_import_prep.sh
#
# - It is expected that this program will be run:
#   * after the Alma thesis publication profile (step 2) job
#   * before the Alma thesis import profile (step 3) job
# - It is expected that:
#   * the Alma thesis publication profile (step 2) job,
#   * this program, and
#   * the Alma thesis import profile (step 3) job
#   will work ok for either an incremental or full export/publication.
# - We assume thesis bib MARC-XML files have just been exported
#   (published) from Alma to dir SRC_DIR.
# - We need to prepare the bib files for Repository-import into
#   Alma. The Repository-import creates a corresponding portfolio
#   and attaches it to the existing Alma bib record.
#
##############################################################################
PATH=/bin:/usr/bin:/usr/local/bin;  export PATH

# ARCH_DIR is typically a sibbling dir of this script's (bin) dir.
# Eg. For $HOME/apps/ethesis/bin/thesis_import_prep.sh, ARCH_DIR
# would typically be $HOME/apps/ethesis/archive.
ARCH_DIR=$HOME/apps/ethesis/archive

THESIS_FTP_DIR=$HOME/alma_ftp_dir/ethesis
SRC_DIR=$THESIS_FTP_DIR/from_alma
DEST_DIR=$THESIS_FTP_DIR/to_alma

SRC_BIB_BASENAME="Thesis_bibs_"
SRC_BIB_EXT=".xml.tar.gz"

DEST_BIB_BASENAME="$SRC_BIB_BASENAME"
DEST_BIB_EXT=".xml"

TIMESTAMP=`date +%Y%m%d.%H%M%S`

##############################################################################
# Optionally override any of the above variables.
ENV_PATH="`echo \"$0\" |sed 's/\.sh$/_env.sh/'`"      # Path to THIS_env.sh
[ -f $ENV_PATH ] && . $ENV_PATH

##############################################################################
delete_files_from_dest() {
  echo "== Delete files from destination directory"
  shopt -s nullglob	# Do not execute for-loop body if no files match
  for dest_fname in "$DEST_DIR/$DEST_BIB_BASENAME"*"$DEST_BIB_EXT"; do
    cmd="rm -f \"$dest_fname\""
    echo "CMD: $cmd"
    eval $cmd    
  done
}

##############################################################################
unzip_src_files_to_dest() {
  echo "== Unzip source files into destination directory"
  shopt -s nullglob	# Do not execute for-loop body if no files match
  for src_fname in "$SRC_DIR/$SRC_BIB_BASENAME"*"$SRC_BIB_EXT"; do
    cmd="tar zxvpf \"$src_fname\" -C \"$DEST_DIR\""
    echo "CMD: $cmd"
    eval $cmd    
  done

  for dest_fname in "$DEST_DIR/$DEST_BIB_BASENAME"*"$DEST_BIB_EXT"; do
    cmd="chmod 644 \"$dest_fname\""
    echo "CMD: $cmd"
    eval $cmd    
  done
}

##############################################################################
move_src_files_to_archive() {
  echo "== Move source files to archive directory"

  shopt -s nullglob	# Do not execute for-loop body if no files match
  for src_fname in "$SRC_DIR/$SRC_BIB_BASENAME"*"$SRC_BIB_EXT"; do
    bname=`basename "$src_fname"`
    cmd="mv -fv \"$src_fname\" \"$ARCH_DIR/$bname.$TIMESTAMP\""
    echo "CMD: $cmd"
    eval $cmd    
  done
}

##############################################################################
show_file_info() {
  echo "== Show record counts for each file"
  shopt -s nullglob	# Do not execute for-loop body if no files match
  sum=0
  nfiles=0
  ndelfiles=0
  match="delete"
  for dest_fname in "$DEST_DIR/$DEST_BIB_BASENAME"*"$DEST_BIB_EXT"; do
    nfiles=`expr $nfiles + 1`
    errormsg=`xmllint --format "$dest_fname" 2>&1`
    if [ $? = 0 ]; then
      nrecs=`xmllint --format "$dest_fname" |egrep -c "<record>"`
    else
      echo "  ERROR: $errormsg"
      nrecs=0
    fi
    echo "$dest_fname:$nrecs"
    sum=`expr $sum + $nrecs`

    if `basename "$dest_fname" |egrep -iq "$match"`; then
      ndelfiles=`expr $ndelfiles + 1`
    fi
  done
  echo "Total records being processed:$sum"

  [ $ndelfiles != 0 ] && echo "**WARNING**: $ndelfiles files have '$match' in their filename. Please investigate!"
  echo "== Show file details"
  [ $nfiles != 0 ] && ls -go --time-style="+%F %T" "$DEST_DIR/$DEST_BIB_BASENAME"*"$DEST_BIB_EXT"
}

##############################################################################
# Main
##############################################################################
{
  echo "== Start"
  delete_files_from_dest
  unzip_src_files_to_dest
  move_src_files_to_archive
  show_file_info
  echo "== Finish"
} 2>&1 |sed "s:^:$TIMESTAMP :"


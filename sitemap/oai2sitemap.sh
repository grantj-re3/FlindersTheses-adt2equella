#!/bin/sh
# oai2sitemap.sh
#
# Copyright (c) 2015, Flinders University, South Australia. All rights reserved.
# Contributors: Library, Information Services, Flinders University.
# See the accompanying LICENSE file (or http://opensource.org/licenses/BSD-3-Clause).
#
# BEWARE:
# Function delete_oai_files() deletes multiple files without prompting!
# It is recommended that you:
# - comment out the 'rm' command
# - configure temp_dir and fname_oai_pattern (and other variables) for
#   your environment
# - run this script as an unprivileged user (ie. not root)
# - run the script to confirm that the 'Deleting' output only shows
#   temporary files to be deleted
# - only after all is ok, uncomment the 'rm' command
#
# Creates a sitemap file (as per http://www.sitemaps.org/protocol.html) based
# on target URLs in an OAI-PMH harvest. Suitable for running as a cron job.
#
# Sitemap file limits:
# - 50,000 URLs max
# - 10MB max (uncompressed)
#
# Requires:
# - get_oai_pages (from https://github.com/grantj-re3/FlindersRedbox-rif2website.git)
# - ruby 1.8.7 (which get_oai_pages depends upon)
##############################################################################
# Customise the variables in this section and the function
# extract_target_urls_from_oai_files().

PATH=/bin:/usr/bin:/usr/local/bin;	export PATH

GET_OAI_PAGES_EXE="$HOME/opt/get_oai_pages/bin/get_oai_pages.rb"

# Initial URL of the OAI-PMH provider
#url_oai="http://oai_repo_host/mypath/oai?verb=ListRecords&metadataPrefix=oai_qdc_rhd&set=xxxx"
url_oai="http://oai_repo_host/mypath/oai?verb=ListIdentifiers&metadataPrefix=oai_qdc_rhd&set=xxxx"

# Sitemap destination filename
fname_dest_sitemap="/my/sitemap/path/sitemap.xml.gz"

# Assumes harvested URLs all have same web host & path
target_url_prefix="https://target_host/view/"

# Strongly recommend using absolute paths as matching files will be deleted.
# Pattern must NOT contain white space.
temp_dir="/my/sitemap/temp/dir"
fname_oai_pattern="$temp_dir/oai_page_[0-9][0-9][0-9][0-9].xml"

##############################################################################
# Change directory. Exit if unable to change directory.
cd_exit_on_error() {
  dir="$1"
  cd "$dir"
  if [ $? != 0 ]; then
    echo "ERROR: Cannot change directory to '$dir'" >&2
    exit 1
  fi
}

##############################################################################
# Delete temporary OAI-PMH files
delete_oai_files() {
  ls -1 $fname_oai_pattern >/dev/null 2>&1
  if [ $? = 0 ]; then
    echo "Deleting: `ls -1 $fname_oai_pattern |xargs echo`"
    # BEWARE: This command deletes multiple files without prompting!
    # BEWARE: Pattern must NOT contain white space.
    rm -f $fname_oai_pattern
  fi
}

##############################################################################
# Write URLs to STDOUT; one URL per line.
# Customise this function (eg. egrep and sed) to extract the required URLs.
extract_target_urls_from_oai_ListRecords_files() {
  # Iterate through each OAI-PMH page file.
  for fname in $fname_oai_pattern; do
    # Add newline after every closing tag to make metadata extraction easier
    sed 's~\(</[A-Za-z:_]*>\)~\1\n~g' $fname |
      egrep "<dc:identifier type=\"dcterms:URI\">" |
      sed "
        s~</dc:identifier>.*$~~
        s~^.*/\(theses\|view\)/~$target_url_prefix~
      " # |ruby -r cgi -ne 'puts CGI.escape($_)'	# URL-encode
  done
}

##############################################################################
# Write URLs to STDOUT; one URL per line.
# Customise this function (eg. egrep and sed) to extract the required URLs.
extract_target_urls_from_oai_ListIdentifiers_files() {
  # Iterate through each OAI-PMH page file.
  for fname in $fname_oai_pattern; do
    # Add newline after every closing tag to make metadata extraction easier
    sed 's~\(</[A-Za-z:_]*>\)~\1\n~g' $fname |
      egrep "</identifier>" |
      sed "
        s~</identifier>.*$~~
        s~^.*\(/theses/\|/view/\|\.edu\.au:\)~$target_url_prefix~
      " # |ruby -r cgi -ne 'puts CGI.escape($_)'	# URL-encode
  done
}

##############################################################################
extract_target_urls_from_oai_files() {
  #extract_target_urls_from_oai_ListRecords_files
  extract_target_urls_from_oai_ListIdentifiers_files
}

##############################################################################
# Write sitemap XML to STDOUT
create_sitemap() {
  echo '<?xml version="1.0" encoding="UTF-8"?>'
  echo '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">'
  extract_target_urls_from_oai_files |
    sed '
      s~^~  <url><loc>~
      s~$~</loc></url>~
    '
  echo '</urlset>'
}

##############################################################################
# main()
##############################################################################
delete_oai_files	# Ensure no unwanted files influence results
cd_exit_on_error "$temp_dir"

# Write each OAI-PMH page to a file. Set of files = $fname_oai_pattern
$GET_OAI_PAGES_EXE "$url_oai" 2>&1

echo "Creating sitemap: $fname_dest_sitemap"
create_sitemap |gzip -c - > "$fname_dest_sitemap"
delete_oai_files	# Clean up temporary files
exit 0


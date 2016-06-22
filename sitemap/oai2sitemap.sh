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
# Based on metadata from an OAI-PMH harvest, this program:
# - creates a sitemap file (as per http://www.sitemaps.org/protocol.html) 
# - creates an HTML summary page for Google Scholar (consisting of item
#   date, title and URL)
#
# Suitable for running as a cron job. Eg.
#   15 19 * * * $HOME/bin/oai2sitemap.sh >/dev/null
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
app=`basename $0 .sh`

GET_OAI_PAGES_EXE="$HOME/opt/get_oai_pages/bin/get_oai_pages.rb"

# Initial URL of the OAI-PMH provider
url_oai="http://oai_repo_host/mypath/oai?verb=ListRecords&metadataPrefix=oai_qdc_rhd&set=xxxx"
#url_oai="http://oai_repo_host/mypath/oai?verb=ListIdentifiers&metadataPrefix=oai_qdc_rhd&set=xxxx"

# Assumes harvested URLs all have same web host & path
target_url_prefix="https://target_host/view/"

# Strongly recommend using absolute paths as matching files will be deleted.
# Pattern must NOT contain white space.
temp_dir="/my/sitemap/temp/dir"
fname_oai_pattern="$temp_dir/oai_page_[0-9][0-9][0-9][0-9].xml"

# Destination filenames
fname_dest_sitemap="/my/sitemap/path/sitemap.xml.gz"
fname_dest_html_summary="/my/sitemap/path/thesis_summary.html"
log="$HOME/opt/get_oai_pages/log/$app.log"

# Space separated email list (for mailx)
dest_email_list="me@example.com you@example.com"

oai_recs_per_page=10		# Expected OAI-PMH records per page (except for last page)
datestamp=`date '+%F %T %z'`

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
# Create HTML summary for Google Scholar. Write HTML to STDOUT
create_google_scholar_html_summary() {
  cat <<-END_HTML1
	<html>
	  <head>
	    <meta content="text/html; charset=UTF-8" http-equiv="Content-Type" />
	    <title>Flinders University - Thesis list</title>
	  </head>
	  <body>
	    <h1>Flinders University - Thesis list</h1>
	    <ul>
`
create_google_scholar_html_summary_records |ruby -e '
  # Sort by date-string (usually YYYY) then (case insensitive) title-string
  #   MatchData[0] = Whole line. Eg. <li>Date: 2016; Title: <a href="https://...">My thesis title</a></li>
  #   MatchData[1] = Date string
  #   MatchData[2] = Title string
  regex = /^.*>Date: *(.*); *Title: *<a[^>]*>(.*)<\/a>.*$/
  readlines.				# Array of lines
  map{|line| line.match(regex)}.	# Array of MatchData (1 per line)
  sort{|a,b| a[1]==b[1] ? a[2].casecmp(b[2]) : a[1]<=>b[1]}.	# Sorted array of MatchData
  each{|matchdata| puts matchdata[0]}'
`
	    </ul>
	    <hr/>
	    <p>Page last updated: $datestamp</p>
	  </body>
	</html>
	END_HTML1
}

##############################################################################
# Create HTML summary records for Google Scholar. Write HTML to STDOUT
create_google_scholar_html_summary_records() {
  for fname in $fname_oai_pattern; do
    awk -v fname=$fname -v recs_pp=$oai_recs_per_page '
      # Assumes multi-line dc:title tags contain no other tags or white
      # space on the same line (as if passed through "xmllint --format"). Eg.
      # <dc:title> ...
      #   ...
      #   ... </dc.title>
      ismore == "t" || /<dc:title>/ {
        # No need to translate from ["<",">"] to ["&lt","&gt"] as OAI-PMH source text is already XML
        title = title gensub(/<\/?dc:title>/, "", "g") " "  # Append space to every line of dc:title input

        if(/<\/dc.title>/) {
          ismore = ""		# Last line of the dc.title tag
        } else {
          ismore = "t"		# There are more lines for this dc.title tag
        }
      }

      /<dc:date>.*<\/dc.date>/ {
        date = gensub(/<\/?dc:date>/, "", "g")
      } 

      /<dc:identifier type=\"dcterms:URI\">.*<\/dc:identifier>/ {
        url = gensub(/<\/?dc:identifier( type=\"dcterms:URI\")?>/, "", "g")
      }

      # We have reached the end of this OAI-PMH record
      /<\/record>/ {
        if(url != "" && title != "" && date != "") {
          # If you change the HTML format of the line below, you
          # may need to make corresponding changes to the sort in
          # function create_google_scholar_html_summary()
          printf "<li>Date: %s; Title: <a href=\"%s\">%s</a></li>\n", date, url, title
          line_out_count += 1
        } else {
          printf "WARNING, omitting record with empty field. [Date:%s|URL:%s|Title:%s]\n", date, url, title > "/dev/stderr"
        }
        url = ""
        title = ""
        date = ""
      }

      # We have reached the end of this OAI-PMH page of records
      END {
        if(line_out_count != recs_pp)	# Should only occur for last OAI-PMH page
          printf "INFO: URL count: %d; Filename: \"%s\"\n", line_out_count, fname > "/dev/stderr"
      }
    ' $fname
  done
}

##############################################################################
show_stats() {
  echo "INFO: Expected number of OAI-PMH records per page: $oai_recs_per_page" >&2
  oai_pages=`ls -1 $fname_oai_pattern 2>/dev/null |wc -l`
  echo "INFO: Number of OAI-PMH pages: $oai_pages" >&2
  num_recs=`egrep -c "<li>.*Title:" $fname_dest_html_summary`
  echo "INFO: Actual total HTML-summary records: $num_recs" >&2
}

##############################################################################
# main()
##############################################################################
delete_oai_files	# Ensure no unwanted files influence results
cd_exit_on_error "$temp_dir"

# Write each OAI-PMH page to a file. Set of files = $fname_oai_pattern
# - To omit email, comment out mailx command. Eg. ...|tee $log # |mailx ...
# - To omit logging and email, comment out tee command.
#   Eg. ... 2>&1 # |tee $log ...
$GET_OAI_PAGES_EXE "$url_oai" 2>&1
{
  echo "INFO: Start datestamp: $datestamp" >&2
  echo "Creating sitemap: $fname_dest_sitemap"
  create_sitemap |gzip -c - > "$fname_dest_sitemap"

  echo "Creating HTML summary for Google Scholar: $fname_dest_html_summary"
  create_google_scholar_html_summary > $fname_dest_html_summary
  show_stats
} 2>&1 |tee $log |mailx -s "$app.log" $dest_email_list

delete_oai_files	# Clean up temporary files
exit 0


#!/usr/bin/ruby
#--
# Copyright (c) 2015, Flinders University, South Australia. All rights reserved.
# Contributors: Library, Information Services, Flinders University.
# See the accompanying LICENSE file (or http://opensource.org/licenses/BSD-3-Clause).
#++ 
#
# Read a CSV; force all fields to be quoted; write to STDOUT.
# Assumes fields do not contain the QUOTE character.
##############################################################################
# Add dirs to the library path
$: << File.expand_path("../lib", File.dirname(__FILE__))
$: << File.expand_path("../lib/libext", File.dirname(__FILE__))

require 'faster_csv'

# We assume quote & delim chars of the input CSV file are same as the output file
QUOTE = '"'
DELIM=','

##############################################################################
def process_csv(fname, faster_csv_options={})
  opts = {
    :col_sep => DELIM,
    :headers => false,
    :header_converters => :symbol,
    :quote_char => QUOTE,
  }.merge!(faster_csv_options)

  FasterCSV.foreach(fname, opts) {|line|
    delim = ''
    line.each_with_index{|field, i|
      delim = DELIM if i>0	# Only insert the delim after the first field
      printf "%s%s%s%s", delim, QUOTE, field, QUOTE
    }
    puts
  }
end

##############################################################################
def verify_cmd_line
  if ARGV.length == 0 || ['-h', '--help'].include?(ARGV[0])
    STDERR.puts <<-MSG_USAGE.gsub(/^\t*/, '')
	Usage:  #{File.basename($0)}  CSV_FILE
	Read CSV_FILE, force all fields to be quoted then write to STDOUT.
    MSG_USAGE
    exit 1
  end

  fname = ARGV[0]
  unless File.exists?(fname)
    STDERR.puts "File not found: '#{fname}'"
    exit 2
  end
end

##############################################################################
# Main
##############################################################################
verify_cmd_line
process_csv(ARGV[0])
exit 0


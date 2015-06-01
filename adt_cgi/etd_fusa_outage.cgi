#!/usr/bin/perl
# etd_fusa_outage.cgi (etd.cgi)
# See: perldoc CGI
##############################################################################
use CGI;
use CGI::Carp qw/fatalsToBrowser/;

my $title = "Downtime notice";

##############################################################################
$q = CGI->new;
print $q->header,
      $q->start_html($title);

print <<NOTICE;
<center>
  <table width=600>
    <tr>
      <td width=60><a href="http://example.com"><IMG SRC="http://library.example.com/images/crest/crest55x86.gif" alt="ADT logo" align=middle border=0></a></td>
      <td width=480><font size=+2 face="helvetica,arial"><b>Digital Theses Deposit Form</b></font></td>
    </tr>
  </table>

  <table width=800>
    <tr><td> <h1>$title</h1> </td></tr>
    <tr><td> Thesis submission at Flinders University is temporarily unavailable due to planned maintenance. </td></tr>
    <tr><td> Thesis submission will resume Monday 25th May 2015 9:00 am ACST (GMT+9:30). </td></tr>
  </table>
</center>
NOTICE

print $q->end_html;


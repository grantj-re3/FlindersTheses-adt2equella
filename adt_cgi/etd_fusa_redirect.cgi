#!/usr/bin/perl
# etd_fusa_redirect.cgi (etd.cgi)
# See: perldoc CGI
##############################################################################
use CGI;
use CGI::Carp qw/fatalsToBrowser/;

my $target_url = "http://example.com/new/url";

##############################################################################
$q = CGI->new;
print $q->redirect(
        -uri    => $target_url,
        -status => 302
      ),
      $q->end_html;


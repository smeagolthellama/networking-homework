#!/usr/bin/perl
use strict;
use warnings;
use IO::Socket;

my $sock=new IO::Socket::INET(
	LocalHost=>'localhost',
	LocalPort=>'10001',
	Proto=>'tcp',
	Listen=>1,
	Reuse=>1,
) or die "couldn't create socket: $!\n";

my $string="";
my $client_addr;
until($string=~"exit"){
	my $new_sock=$sock->accept();
	until($string=~"exit"){
		$string=<$new_sock>;
		print "$string";
		print $new_sock uc "$string";
	}
}
close($sock)

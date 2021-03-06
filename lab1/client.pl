#!/usr/bin/perl
use strict;
use warnings;
use Socket;

socket(my $socket, PF_INET, SOCK_STREAM,getprotobyname("tcp"))
	or die("socket:$!");

setsockopt($socket, SOL_SOCKET, SO_REUSEADDR, 1)
	or die("setsockopt:$!");

my $sockaddr=pack_sockaddr_in(10001,inet_aton("127.0.0.1"));

connect($socket, $sockaddr)
	or die("connect:$!");

$socket->autoflush(1);

my $line=<>;
print $socket $line;
$line=<$socket>;
	
if(defined $line){
	print $line;
}

close $socket;

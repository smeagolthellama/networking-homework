#!/usr/bin/perl
use strict;
use warnings;
use Socket;
use utf8;
use Encode qw(encode decode);
use sigtrap qw(handler handler normal-signals stack-trace error-signals);

socket(my $socket, PF_INET, SOCK_STREAM,getprotobyname("tcp"))
	or die("socket:$!");

setsockopt($socket, SOL_SOCKET, SO_REUSEADDR, 1)
	or die("setsockopt:$!");

my $sockaddr=pack_sockaddr_in(10001,inet_aton("127.0.0.1"));

bind($socket,$sockaddr) or die("bind:$!");

listen($socket,5) 
	or die("listen:$!");

my $string="";
until(0){
	accept(my $newsock,$socket)
		or die("accept:$!");
	if(!fork){
		$newsock->autoflush(1);
		while($string=decode("utf8",<$newsock>)){
			$string=~s/\s*$//;
			if($string eq "exit"){
				last;
			}
			print encode "utf8", "$string\n";
			print $newsock encode("utf8", uc "$string\n");
		}
		close $newsock;
		exit;
	}
}
sub handler(){
	close $socket;
	exit;
}

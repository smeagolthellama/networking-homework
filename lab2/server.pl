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
		if($string=decode("utf8",<$newsock>)){
			my @fields=split ' ',$string;

			my $method=$fields[0];
			my $request_URI='.'.$fields[1];
			my $HTTP_version=$fields[2];
			my $status_code=500;
			my $reason_phrase="internal error";
			my $message_body="";

			print "method: $method\n request_URI: $request_URI\n HTTP_version: $HTTP_version\n";

			if($method=~/GET/i){
				if(open(my $f,"<",$request_URI)){
					$status_code="200";
					$reason_phrase="ok";
					binmode $f;
					$message_body=do{local $/; <$f>};#slurp entire file, not line by line.
				}else{
					$status_code="404";
					$reason_phrase="not found.";
					$message_body="<html><title>404 not found</title><body><h1>404 Not Found error</h1></body></html>"
				}
			}elsif($method=~/HEAD/i){

			}

			$string=$HTTP_version.' '.$status_code.' '.$reason_phrase."\r\n".$message_body;

			print encode "utf8", "$string\n";
			print $newsock encode("utf8", "$string\n");

		}
		close $newsock;
		exit;
	}
}

sub get(){}

sub handler(){
	close $socket;
	exit;
}

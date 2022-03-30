#!/usr/bin/perl
use strict;
use warnings;
use Socket;
use utf8;
use Encode qw(encode decode);
use sigtrap qw(handler handler normal-signals stack-trace error-signals);

socket( my $socket, PF_INET, SOCK_STREAM, getprotobyname("tcp") )
  or die("socket:$!");

setsockopt( $socket, SOL_SOCKET, SO_REUSEADDR, 1 )
  or die("setsockopt:$!");

my $sockaddr = pack_sockaddr_in( 10001, inet_aton("127.0.0.1") );

bind( $socket, $sockaddr ) or die("bind:$!");

listen( $socket, 5 )
  or die("listen:$!");

my %mimetypes = qw(
  .htm	text/html
  .html	text/html
  .txt	text/plain
  .json	text/plain
  .gmi	text/gemini
  .css	text/css
  .js	text/javascript
  .jpg	image/jpeg
  .jpeg	image/jpeg
  .png	image/png
  .ogv	video/ogg
);

my $string = "";

$SIG{CHLD}="IGNORE";
until (0) {
    accept( my $newsock, $socket )
      or die("accept:$!");
    if ( !fork ) {
        $newsock->autoflush(1);
        my $keepalive = 0;
        do {
            eval { 
		alarm 1;
		$string = <$newsock> ;
		alarm 0;
            };
	    if ($@) {
		print "in timeout catch.";
		die($@) unless $@ eq "alarm\n";
		$string=0;
            }
                if ($string) {
                    my @fields = split ' ', $string;

                    my $method           = $fields[0];
                    my $request_URI      = "." . $fields[1];
                    my $HTTP_version     = $fields[2];
                    my $status_code      = 500;
                    my $reason_phrase    = "internal error";
                    my $message_body     = "";
                    my $response_headers = "";
                    my %headers          = ();

		    my $timeout=0;
                    do {
			eval { 
				alarm 1;
				$string = <$newsock> ;
				alarm 0;
			};
			if ($@) {
				print "in timeout catch.";
				die($@) unless $@ eq "alarm\n";

				$string=0;
				$timeout=1;
			}
                        unless ( $string ) {
                            last;
                        }
                        $string =~ s/\s*$//;

                        my ( $key, $value ) = split( /: /, $string, 2 );
                        $headers{$key} = $value if defined($key);
                    } until ( $string eq "" or $timeout );


                    if ( defined( $headers{"Connection"} )
                        and $headers{"Connection"} =~ /keep-alive/i )
                    {
                        $keepalive = 1-$timeout;
			$response_headers.="\r\nKeep-Alive: timeout=1, max=100"
                    }

                    if ( $method =~ /GET/i or $method =~ /HEAD/i ) {
                        if ( $request_URI =~ /\/$/ ) {
                            $request_URI .= "index.html";
                            print("autocompleting to index.html:");
                        }
                        print( $$.":". $request_URI. "\n" );
                        $request_URI =~ /\.([^.]+)\Z/;
                        my $extension = $&;

                        if ( exists $mimetypes{$extension} ) {
                            $response_headers .=
                              "\r\nContent-Type: " . $mimetypes{$extension};
                        }
                        else {
                            $response_headers .=
                              "\r\nContent-Type: application/octet-stream";
                        }

                        if ( open( my $f, "<", $request_URI ) ) {
                            $status_code   = "200";
                            $reason_phrase = "ok";
                            binmode $f;
                            $message_body =
                              do { local $/; <$f> }; #slurp entire file, not line by line.
                            $response_headers .=
                              "\r\nContent-Length: " . length($message_body);
                        }
                        else {
                            $status_code   = "404";
                            $reason_phrase = "not found.";
                            $message_body =
"<html><title>404 not found</title><body><h1>404 Not Found error</h1></body></html>";
                            $response_headers .=
                              "\r\nContent-Length: " . length($message_body);
                        }
                    }
                    else {
                        $status_code   = "405";
                        $reason_phrase = "method not allowed.";
                        $message_body =
"<html><body><h1>Method not allowed</h1></body></html>";
                    }

                    if ( $method =~ /HEAD/i ) {
                        $message_body = "";
                    }

                    if ( $response_headers ne "" ) {
                        $response_headers .= "\r\n";
                    }

                    $string =
                        $HTTP_version . ' '
                      . $status_code . ' '
                      . $reason_phrase
                      . $response_headers . "\r\n"
                      . $message_body;

                    print $newsock $string;

                }
                else { $keepalive = 0; }
        } while ($keepalive);
        print "\nconnection closed\n";
        close $newsock;
        exit;
    }
}

sub handler() {
	print "\nconnection closed\n";
    close $socket;
    exit;
}

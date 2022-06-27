# Networking homework

This is the git repository that contains my network programming homework for 
the one semester we did at university.

The folders begining with w all contain things done in relation with and using 
wireshark. Those aren't all that interesting.

`lab1` contains a simple client-server echo thing written in perl, using the 
builtin functions with no wrapper library.

`lab2` contains a basic HTTP 1.1 server, again written in perl, using the basic
builtin functions for everything. The only library used is to ensure the propper
handling of UTF8 characters.

`lab3` I seem to have mislaid somewhere, but it was a very basic SMTP client.

`lab4` contains a client-server internet chat system written in Ada. I think it's
compatible with Ada 95, and in fact might even be compatible with 83, but I only 
ever tested it under Ada 12. It is my first actual proper multithreaded code, and I
didn't know about how tasks interact with the scope they are declared in, so some
of the threads are utterly useless. However, as this is also effectively my first
propper project written in Ada, I am quite proud of it, and have decided I really
like the language.

`lab5` contains a distributed computational solution to the rendering of the 
mandelbrot set, written in Ada. The server gets told how many clients it will
have conecting to it, and it divides the job accordingly. I wrote this in a 
hurry, so it could definitely have some improvements, but it works, and does
the job properly.


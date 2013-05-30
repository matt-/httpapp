#!perl
use warnings;
use strict;

use lib 'lib';
use httpApp;

$|++;

my $httpApp = httpApp->new(		
		appName => 'myApp',
		port => 8080,
		address => '127.0.0.1',
		
		# this is the layout all the views use 
		# views/layout/default.tt
		layout => 'default',
		
		# server can be non blocking
		# timeout tell the server how long to check for a connection per loop
		# if you trun off blocking you can set a callback that gets called once
		# per event loop 
		blocking => 1, # change to 0 to run callback  
		timeout => .1,
		callback => sub{
			my $self = shift;
			print "I am in a loop!\n";
		}, 
		
		debug => {
			all => 1, # warn => 1, error => 1, log => 1,		 
		}, 
);

my $daemon = $httpApp->{daemon};

$SIG{HUP} = sub { $httpApp->load_controllers(); };

$httpApp->run();

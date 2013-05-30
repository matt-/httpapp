package httpApp;

use HTTP::Daemon;
use HTTP::Status;
use Template;
use strict;
use Data::Dumper;

use File::Find;

use vars '$VERSION';
$VERSION = '1.00';

sub new {
    my $class = shift;
    # Create our object!
    my $self = {
        # Defaults
		port => 8080,
		address => '127.0.0.1',
		appName => 'myApp',
		sessionName => 'httpApp',
		blocking => 1,
		timeout => .1,
		debug => {
			all => 0, # warn => 1, error => 1, log => 1,		 
		},
		start_time => time(),
		sessions => {},
        @_
    };
	my %conf;
	$conf{Timeout} = $self->{timeout} unless $self->{blocking};	
	$self->{daemon} = HTTP::Daemon->new( 
		LocalPort => $self->{port} , 
		LocalAddr => $self->{address}, 
		Blocking => $self->{blocking},
		Reuse => 1,
		%conf,
	) || die "Cannot create socket: $!\n";

	# fix: add the content type for css 
	LWP::MediaTypes::add_type("text/css" => qw(css));
   
	bless($self, $class);

	$self->load_controllers();
	$self->load_core();
	
  return $self;
};

# run the server
sub run{
  my $self = shift;

  $self->log("Starting Server pid: $$");
  $self->log("url: ".$self->{daemon}->url);

  # loop and wait for new connections   
  while (1) {
    $self->do_one_loop();

    # if server is non blocking a callback can be called 
    if($self->{callback}){
      $self->{callback}($self) unless $self->{blocking};
    }
  }
}

sub do_one_loop{
	my $self = shift;
	
	my $client = $self->{daemon}->accept;
	return unless $client;
	
	my $request = $client->get_request;
	return unless defined($request);

	my $path = $request->url->path;
	my ($controller, $page, $id) = $path =~ m[^/(\w+)(?:/(\w+))?(?:/(\w+))?];
	$page ||= 'index'; $controller ||= 'index';
	
	# check that the controller exists
	my $controller_file = "controllers/".$controller.".pm";
	if($self->{fileStats}->{$controller_file}){
		my $controller_namespace = $self->{appName}."::".$controller;
		my $ctrl = $controller_namespace->new($self, $client, $request);
		$ctrl->render($page);
  }
	# load a local file if we have one
	elsif(-f "views/pages".$path.".tt"){
		require "controllers/pages.pm";
		my $controller_namespace = $self->{appName}."::pages";
		my $controller = $controller_namespace->new($self, $client, $request);
		$controller->render($page);
	}		
	# load a local file if we have one
	elsif(-f "public/".$path){
		$client->send_file_response("public/".$path);
	}
	# 404 i dont know what you want
	else{
		#$client->send_error(404);
		$self->show_404($client, $request);
	}	
}

# debugging functions
sub log{
	my $self = shift;
	return unless $self->{debug}->{all} || $self->{debug}->{log}; 
	my $message = shift;
	printf "%s => %s\n", (scalar(localtime(time)), $message);
}

sub warn{
	my $self = shift;
	my $message = shift;
	printf "WARN: %s => %s\n", (scalar(localtime(time)), $message);
}

sub error{
	my $self = shift;
	my $message = shift;
	printf "ERROR: %s => %s\n", (scalar(localtime(time)), $message);
}

sub show_404{
	my $self = shift;
	my $client = shift;
	my $request = shift;

	require "controllers/errors.pm";
	my $controller_namespace = $self->{appName}."::errors";
	my $controller = $controller_namespace->new($self, $client, $request);

	$controller->{'page'} = '404';
	$controller->render($controller->{'page'});	
}

# this will reload all controllers 
sub load_controllers{
	my $self = shift;
	
	find({ wanted => sub {
	  return unless -f;
    $self->load_module($_);
	}, no_chdir => 1 }, "controllers");

}

sub load_core{
	my $self = shift;
#
  find({ wanted => sub {
	  return unless -f;
    $self->load_module($_);
	}, no_chdir => 1 }, "lib");
}

# load or reload module into app memory 
sub load_module{
	my $self = shift;
	my $file_name = shift;
	
	my $file_time = (stat $file_name)[9];

	# Check the file times to see if they have changed
	if(
		($self->{fileStats}->{$file_name}) && 
		($file_time == $self->{fileStats}->{$file_name}->{'time'})
	){
		return 1;
	}
	else{
		delete $INC{$file_name} if $INC{$file_name};
	    eval { 
  			local $SIG{__WARN__} = \&warn;
  			require $file_name;
  			$self->log("Loaded Module: $file_name");
  			$self->{fileStats}->{$file_name} = {
  				time => $file_time
  			};		 
	    };
	    if ($@) {
			$self->error("$file_name could not load:\n-------------\n$@\n-------------");
			return 0;
	    }
		return 1;
	}
}

1;

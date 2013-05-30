package httpApp::Controller;

use vars '$VERSION';
use Template;
use strict; 

use JSON;

$VERSION = '1.00';
our $AUTOLOAD;  # it's a package global

use CGI;
use HTTP::Cookies;
use Data::Dumper;
use Digest::MD5 qw(md5_hex);

sub new {
  my $class = shift;
  my $app = shift;
	my $client = shift;
	my $request = shift;
	# Create our object!
	my $path = $request->url->path;
	my ($controller, $page, $id) = $path =~ m[^/(\w+)(?:/(\w+))?(?:/(\w+))?]; 
	$page ||= 'index'; $controller ||= 'index';
	my $self = {
    # Defaults
		layout => 'default',
		controller => $controller,
		page => $page,
		app => $app,
		client => $client,
		request => $request,
		httpStatus => '200',
		cookies => {},
		type => 'html',	
		# controller args are going to come from the main app 
		@_
  };

	$self->{vars} = {
		title => $self->{controller}.' :: '.$self->{page},
		controller => $self->{controller},
		errors => [],
		notice => {},
	};
	
	my $content = ($request->method eq 'GET')?$request->url->query:$request->content;
	$self->{cgi} = CGI->new( $content );
  bless($self, $class);
	$self->parse_cookies();
	$self->start_session();
  return $self;
};

sub AUTOLOAD
{
    my $self = shift;
		my $name = $AUTOLOAD;
		$name =~ s/.*://;   # strip fully-qualified portion
		
		#$self->show_error("Sorry, could not find the sub $name in your controller.");
		return {
			error => "Sorry, could not find the sub $name in your controller.",
		}
}
# placeholder for a deconstructer 
sub DESTROY{
	
}

# render the page 
sub render{
	
	# render should be able to spin off another view than the one we think 
	# we can override $self->{page} 
	
	my $self = shift;
	
	# should page be part of $self or passed in.. 
	# we already pass it into new, we should just use it 
	# from there.
		
	my $page = shift;
	
	# var for tt return
	my $data;
	
	# assume if a method begins with _ that we intend it to be private. 
	# do not run the function and return 404 page; 
	if($page =~ m/^_/){
	  $self->{app}->log("Can not render private method.");
	  return $self->{app}->show_404($self->{client}, $self->{request});
	}

  $self->{app}->log("Render page: ".$self->{controller}."/".$page);
	# call the function form the controller 
	# it should return vars for tt
	my $vars = $self->$page();
	$vars->{'session'} = $self->{app}->{sessions}->{$self->{session_id}};
  # merge the template vars in with the return form the function.
  foreach my $key (keys %{$self->{vars}}){
          $vars->{$key} = $self->{vars}->{$key};
  }

  if($self->{'type'} eq "json"){
        $data = to_json($vars);
  }
  else{
    if(-f 'views/'.$self->{controller}.'/'.$self->{page}.'.tt'){
            my $tt = Template->new({
                    INCLUDE_PATH => 'views',
                    WRAPPER => 'layout/'.$self->{layout}.'.tt'
            });               
            # do something with template errors 
            eval{
                    # use $self controller and page so we can redirect the output to another page 
                    $tt->process($self->{controller}.'/'.$self->{page}.'.tt', $vars, \$data) or die $@;
            };
            #print $self."\n".$self->{page}."\n";
            return $self->show_error($@) if $@;
    }
    else{
        $self->{app}->show_404($self->{client}, $self->{request});
        return;
    }
  }
	# send the page to the user
	my $response =  HTTP::Response->new($self->{httpStatus}, OK => [ 'Content-Type' => 'text/html' ], $data);
	
	# add all cookies to the respones 
	# we need to change this to only add new cookies
	foreach my $cookie_name (keys %{$self->{cookies}}){
		$response->push_header("Set-Cookie" => $cookie_name."=".$self->{cookies}->{$cookie_name}."; path=/;");
	}		
	
	$self->{client}->send_response( $response );	
	$self->{client}->close;
}

sub do_redirect{
	my $self = shift;
	my $location = shift;
	
	# send a 302 redirect to the user
	my $response =  HTTP::Response->new(302, OK => [ 'Content-Type' => 'text/html', 'Location' => $location ], "redirecting...");
	$self->{client}->send_response( $response );
	$self->{client}->close;
}

sub add_error{
	my $self = shift;
	my $error = shift;
	push(@{$self->{vars}->{errors}}, $error);
}

sub set_notice{
	my $self = shift;
	my $header = shift;
	my $message = shift;
	$self->{vars}->{notice} = {
		header => $header,
		message => $message
	};
}

sub show_error{
	my $self = shift;
	my $error = shift;
	
	# make this render template error page if possible
	
	my $response =  HTTP::Response->new(200, OK => [ 'Content-Type' => 'text/html' ], $error);
	$self->{client}->send_response( $response );
	$self->{client}->close;
}

# get or create a new session_id and return the current session
sub start_session{
	my $self = shift;
	$self->{session_id} = $self->get_cookie($self->{app}->{sessionName});
	
	#if we dont have a session id make up a new random one
	unless($self->{session_id}){
	  # session id is PID, time, and random number and client IP
		$self->{session_id} = md5_hex($$ + time() + rand(9999) + $self->{client}->peerhost());
		$self->set_cookie($self->{app}->{sessionName}, $self->{session_id});
		$self->{app}->{sessions}->{$self->{session_id}} = {};
	}
	# so that sessions have state they live in memory in the main app
	return $self->{app}->{sessions}->{$self->{session_id}};
}

# get a value from the currrent session 
sub get_session{
	my $self = shift;
	my $name = shift;
	
	return $self->{app}->{sessions}->{$self->{session_id}}->{$name};
}

# set a value in the current session
sub set_session{
	my $self = shift;
	
	my $name = shift;
	my $value = shift;
	
	$self->{app}->{sessions}->{$self->{session_id}}->{$name} = $value;
}

# reomves the session from main app and also clears the session cookie
sub clear_session{
	my $self = shift;
	delete $self->{app}->{sessions}->{$self->{session_id}};
	$self->set_cookie($self->{app}->{sessionName}, '');
}

# get cookie by name
sub get_cookie{
	my $self = shift;
	my $name = shift;

	return $self->{cookies}->{$name};
}

#set cookie by name
sub set_cookie{
	my $self = shift;
	
	my $name = shift;
	my $value = shift;
	
	$self->{cookies}->{$name} = $value;
}

sub parse_cookies{
	my $self = shift;
	# read the cookie header
	my $cookie_string = $self->{request}->header('cookie');
	
	# split up each cookie into a hash
	foreach my $cookie (split(/;\s+/,$cookie_string)){
		my ($name, $value) = split('=',$cookie);
		$self->{cookies}->{$name} = $value;
	}
}

1;

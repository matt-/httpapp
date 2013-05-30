package myApp::errors;
use base 'httpApp::Controller';
our $AUTOLOAD; 

use strict;

sub AUTOLOAD
{
        my $self = shift;
		my $name = $AUTOLOAD;
		$name =~ s/.*://;   # strip fully-qualified portion
		
		#$self->{page} = $self->{controller};
		$self->{controller} = "errors";
		
		#show clean error
		if($self->{page} eq '404'){
			$self->add_error('Sorry, could not find your page!');
			$self->{httpStatus} = '404';
			#$self->show_error("Sorry, could not find your page!");
		}
		elsif($self->{page} eq '500'){
			$self->add_error("Oops something went wrong...");
			$self->{httpStatus} = '500';
		}
		return {
			title => "Error: ",
		}
}

1;

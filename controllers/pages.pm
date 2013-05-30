package myApp::pages;
use base 'httpApp::Controller';

# this should get called for all files in the pages folder

sub AUTOLOAD
{
        my $self = shift;
		my $name = $AUTOLOAD;
		$name =~ s/.*://;   # strip fully-qualified portion
		
		$self->{page} = $self->{controller};
		$self->{controller} = "pages";
		$self->{vars}->{title} = "Page Not Found";
		
		#show clean error
		#$self->show_error("Sorry, could not find the sub $name in your controller.");
		return {
			title => $self->{controller}."::".$self->{page},
		}
}

1;
package myApp::test;
use base 'httpApp::Controller';

use strict;

sub index{
    my $self = shift;
	#this gets sent to TT
    return {    
		title => 'Tests Page',
    };
}

sub json_test{
	my $self = shift;
	$self->{'type'} = "json";
        return{
	    name => 'matt',
            arr => [1,2,3,4]
	}
}

sub redirect_test{
	my $self = shift;
	$self->do_redirect('/');
	return{
		
	}
}
# test
sub notice_test{
	my $self = shift;
	$self->set_notice('Congratulations', 'The notices work...');
	return{
		
	}
}

sub error_test{
	my $self = shift;
	$self->add_error('One error...');
	
	if ($self->{cgi}->param('more')){
		$self->add_error('Two error...');
	}
	return{
		
	}
}

1;

package myApp::index;
use base 'httpApp::Controller';
use HTML::Entities ();


use strict;

sub index{
	my $self = shift;

	# we can change  the layout if we need to
	#$self->{layout} = 'default';
	
	#this is is your perl logic
	my $name = 	$self->get_session('name');
	$name ||= "bob";
	if($self->{cgi}->param('name')){
		$name = $self->{cgi}->param('name');
		$name = HTML::Entities::encode($name);
		$self->set_session('name', $name);
		$self->set_notice('Congratulations', 'Your name has been set...');
	}
	
	#this gets sent to TT
    return {    
        welcome => "Hi $name!",
		title => 'title form index controller',
		name => $self->get_session('name'),
    };
}

sub logout{
	my $self = shift;
	$self->clear_session();
	# show the index page
	$self->{page} = 'index';
	$self->set_notice('Congratulations', 'Session is now clear...');
	return {
		
	};
}

1;

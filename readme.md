httpapp
========================

A simple MVC style webserver for small web apps (like ruby webrick)

## Requirements ##
* Perl +

## How to use ##
Controllers are simple modules, and views use Template Toolkit.

### Using CLI ###

```
$ perl server.pl
```

Simple Controller

```perl
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

```

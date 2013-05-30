package myApp::debug;
use base 'httpApp::Controller';
use File::Find;
use Data::Dumper;

#use Proc::ProcessTable;

use strict;


sub index{
	my $self = shift;
	#this gets sent to TT
  return {    
  	title => 'Debug Page',
  	sessions => $self->{app}->{sessions},
  };
}

sub files{
  my $self = shift;

  if ($self->{cgi}->param('reload_controllers')){
    $self->{app}->load_controllers();
  }
  elsif($self->{cgi}->param('reload_core')){
    $self->{app}->load_core();
  }
  
  my $controllers = {};
  my $core = {};
    
  return {    
    title => 'Debug Page',
    uptime => time() - $self->{'app'}->{'start_time'}, 
    controllers => $self->_get_files("controllers"),
    core => $self->_get_files("lib"),
  };
}

sub _get_files{
  my $self = shift;
  my $dir = shift;
  my $files = {};
    
  find(sub {
    my $file_time = (stat $_)[9];
    my $file_name = $File::Find::name;
    return unless -f;
    my $status = 0;
    if(!$self->{app}->{fileStats}->{$file_name}){
      $status = 1;
    }
    elsif($self->{app}->{fileStats}->{$file_name}->{time} != $file_time){
      $status = 2;
    }
    $files->{$file_name} = {
      time => $file_time,
      status => $status,
    };    
  }, $dir);
    
  return $files;  
}

1;

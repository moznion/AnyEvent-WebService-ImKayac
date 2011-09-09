package AnyEvent::WebService::ImKayac;

use strict;
use warnings;

our $VERSION = '0.01';

use AnyEvent::HTTP;
use HTTP::Request::Common;
use Digest::SHA qw/sha1_hex/;
use JSON;
use Carp;

=head1 NAME

AnyEvent::WebService::ImKayac - connection wrapper for im.kayac.com

=head1 SYNOPSIS

  use AnyEvent::WebService::ImKayac;

  my $im = AnyEvent::WebService::ImKayac->new(
    type => 'password',
    user => '...',
    password => '...'
  );

  $im->send('Hello! test send!!', sub {
      my $res = shift;
      
      unless ( $res->{result} eq "posted" ) {
          warn $res->{error};
      }
  });

=head2 METHODS

=head3 new

parameters:

if type eq 'secret'
---
type       : secret
secret_key : 'INSERT SECRET KEY'
user       : 'YOUR NAME'


elsif type eq 'password'
---
type     : password
password : 'INSERT PASSWORD'
user     : 'YOUR NAME'


elsif type eq 'none'
---
type : none
user : 'YOUR NAME'

=cut


sub new {
    my $pkg = shift;
    my %args = ($_[1]) ? @_ : %{$_[1]};

    croak "require user" unless $args{user};
    $args{type} = 'none' if $args{type} !~ /^(none|password|secret)$/;

    if ($args{type} eq 'password' && !$args{password}) {
        croak "require password";
    }

    if ($args{type} eq 'secret' && !$args{secret_key}) {
        croak "require secret_key";
    }

    bless \%args, $pkg;
}


=head3 send

It accepts a hash with parameters. You should pass message and cb as parameter.

=cut

sub send {
    my ($self, %args) = @_;
    
    croak "missing required parameter 'message'" unless defined $args{message};
    croak "missing required parameter 'cb'" unless defined $args{cb};
    
    croak "parameter 'cb' should be coderef" unless ref $args{cb} eq 'CODE';

    my $user = $self->{user};
    my $f = sprintf('_param_%s', $self->{type});
    # from http://github.com/typester/irssi-plugins/blob/master/hilight2im.pl
    my $req = POST "http://im.kayac.com/api/post/${user}", [ $self->$f(%args) ];
    my %headers = map { $_ => $req->header($_), } $req->headers->header_field_names;

    http_post $req->uri, $req->content, headers => \%headers, sub {
        my ($body, $hdr) = @_;
        
        my $json = decode_json($body);
        
        $args{cb}->($json);
    };
}


=head2 INTERNAL METHODS

=head3 _param_none

calls if type is 'none'

=cut

sub _param_none {
    my ($self, %args) = @_;
    %args;
}

=head3 _param_password

calls if type is 'password'

=cut

sub _param_password {
    my ($self, %args) = @_;
    $args{password} = $self->{password};
    %args;
}

=head3 _param_secret

calls if type is 'secret'

=cut

sub _param_secret {
    my ($self, %args) = @_;
    my $skey = $self->{secret_key};
    $args{sig} = sha1_hex("$args{message}${skey}");
    %args;
}

1;
__END__

=head1 AUTHOR

taiyoh E<lt>sun.basix@gmail.comE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

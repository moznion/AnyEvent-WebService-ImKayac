package AnyEvent::WebService::ImKayac;

use strict;
use warnings;

our $VERSION = '0.01';
our $URL = "http://im.kayac.com";

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

  $im->send( message => 'Hello! test send!!', cb => sub {
      my ($hdr, $json, $err) = @_;
      
      if ( $err ) {
          warn $err;
      }
      elsif ( ! $json ) {
          warn $hdr->{Reason};
      }
      elsif ( $json->{result} ne "posted" ) {
          warn $json->{error};
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

    croak "missing require parameter 'user'" unless defined $args{user};
    croak "missing require parameter 'type'" unless defined $args{type};
    
    $args{type} = 'none' if $args{type} !~ /^(none|password|secret)$/;

    if ($args{type} eq 'password' && ! defined $args{password}) {
        croak "require password";
    }

    if ($args{type} eq 'secret' && ! defined $args{secret_key}) {
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
    my $cb = delete $args{cb} || croak "missing required parameter 'cb'";
    
    croak "parameter 'cb' should be coderef" unless ref $cb eq 'CODE';

    my $user = $self->{user};
    my $f = sprintf('_param_%s', $self->{type});

    # from http://github.com/typester/irssi-plugins/blob/master/hilight2im.pl
    my $req = POST "$URL/api/post/${user}", [ $self->$f(%args) ];

    my %headers = map { $_ => $req->header($_), } $req->headers->header_field_names;

    http_post $req->uri, $req->content, headers => \%headers, sub {
        my ($body, $hdr) = @_;

        local $@;

        if ( $hdr->{Status} =~ /^2/ ) {
            my $json = eval { decode_json($body) };
            $cb->( $hdr, $json, $@ );
        }
        else {
            $cb->( $hdr, undef, $@ );
        }
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
soh335 E<lt>sugarbabe335@gmail.comE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

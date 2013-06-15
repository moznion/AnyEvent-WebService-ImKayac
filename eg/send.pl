#!/usr/bin/env perl

use strict;
use warnings;

use AnyEvent;
use AnyEvent::WebService::ImKayac;
use Config::Pit;

my %conf = (%{ pit_get('im.kayac.com') }, type => 'secret');

my $cv = AE::cv;

my $im = AnyEvent::WebService::ImKayac->new(%conf);

$im->send( message => 'Hello! test send', cb => sub {
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

        $cv->send;
    });

$cv->recv;

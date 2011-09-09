#!/usr/bin/env perl

use strict;
use warnings;

use AnyEvent;
use AnyEvent::WebService::ImKayac;
use Config::Pit;

my %conf = (%{ pit_get('im.kayac') }, type => 'secret');

my $cv = AE::cv;

my $im = AnyEvent::WebService::ImKayac->new(%conf);

$im->send( message => 'Hello! test send', cb => sub {
    my $res = shift;
    
    unless ( $res->{result} eq "posted" ) {
        warn $res->{error};
    }
    
    $cv->send;
});

$cv->recv;

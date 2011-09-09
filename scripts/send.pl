#!/usr/bin/env perl

use strict;
use warnings;

use FindBin::libs;
use AnyEvent;
use AnyEvent::WebService::ImKayac;
use Config::Pit;

my %conf = (%{ pit_get('im.kayac') }, type => 'secret');

my $cv = AnyEvent::cv;

my $im = AnyEvent::WebService::ImKayac->new(%conf);

$im->send('Hello! test send!!', sub {
    my $res = shift;
    
    unless ( $res->{result} eq "posted" ) {
        warn $res->{error};
    }
    
    $cv->send;
});

$cv->recv;

use strict;
use warnings;
use AnyEvent::WebService::ImKayac;
use Test::More;
use Test::TCP;
use JSON;
use Digest::SHA1;
use Test::Requires qw/Plack::Loader Plack::Request/;

my $tests = {
    none => {
        server => {
            invalid_json => [sub {
                return [200, [ "Content-Type" => "application/json" ], [ "" ] ];
            }],
            type_test => [sub {
                return [200, [ "Content-Type" => "application/json" ], [ encode_json { result => "posted" } ] ];
            }],
            server_error => [sub {
                return [500, [ "Reason" => "server error" ], [] ];
            }],
        },
        client => {
            invalid_json => [sub {
                    my $cv = shift;
                    AnyEvent::WebService::ImKayac->new( user => "hoge", type => "none" )->send( message => "m", cb => sub {
                            my ($hdr, $json, $err) = @_;
                            ok($err, "if json is invalid, defined \$err");
                            ok(! defined $json, "if json is invalid, \$json is undef");
                            $cv->send;
                        });
            }],
            type_test => [sub {
                    my $cv = shift;
                    AnyEvent::WebService::ImKayac->new( user => "hoge", type => "none" )->send( message => "m", cb => sub {
                            my ($hdr, $json, $err) = @_;
                            ok(! $err, "if post is success, \$err is undef");
                            is($json->{result}, "posted", "if post is success, \$json->{result} is posted");
                            $cv->send;
                        });
            }],
            server_error => [sub {
                    my $cv = shift;
                    AnyEvent::WebService::ImKayac->new( user => "hoge", type => "none" )->send( message => "m", cb => sub {
                            my ($hdr, $json, $err) = @_;
                            ok(! $json, "if server is error, \$json is undef");
                            $cv->send;
                        });
            }],
        },
    },
    secret => {
        server => {
            invalid_json => [],
            type_test => [
                sub {
                    my $req = shift;
                    is (Digest::SHA1::sha1_hex($req->body_parameters->{message}."fuga"), $req->body_parameters->{sig}, "message + secret_key is valid");
                    return [200, [ "Content-Type" => "application/json" ], [ encode_json { result => "posted" } ] ];
                },
            ],
            server_error => [],
        },
        client => {
            invalid_json => [],
            type_test => [
                sub {
                    my $cv = shift;
                    AnyEvent::WebService::ImKayac->new( user => "hoge", type => "secret", secret_key => "fuga" )->send( message => "m", cb => sub {
                            my ($hdr, $json, $err) = @_;
                            ok(! $err, "if post is success, \$err is undef");
                            is($json->{result}, "posted", "if post is success, \$json->{result} is posted");
                            $cv->send;
                        });
                },
            ],
            server_error => [],
        },
    },
    password => {
        server => {
            invalid_json => [],
            type_test => [
                sub {
                    my $req = shift;
                    is ($req->body_parameters->{password}, "fuga", "valid password");
                    return [200, [ "Content-Type" => "application/json" ], [ encode_json { result => "posted" } ] ];
                },
            ],
            server_error => [],
        },
        client => {
            invalid_json => [],
            type_test => [
                sub {
                    my $cv = shift;
                    AnyEvent::WebService::ImKayac->new( user => "hoge", type => "password", password => "fuga" )->send( message => "m", cb => sub {
                            my ($hdr, $json, $err) = @_;
                            ok(! $err, "if post is success, \$err is undef");
                            is($json->{result}, "posted", "if post is success, \$json->{result} is posted");
                            $cv->send;
                        });
                },
            ],
            server_error => [],
        },
    },
};

for my $testname (qw/none secret password/) {
    for my $server_test (qw/invalid_json type_test server_error/) {
        test_tcp(
            client => sub {
                my $port = shift;
                local $AnyEvent::WebService::ImKayac::URL = "http://127.0.0.1:$port";

                {
                    my $test = shift @{$tests->{$testname}{client}{$server_test}};
                    if ( $test ) {
                        my $cv = AE::cv;
                        $test and $test->($cv);
                        $cv->recv;
                    }
                }
            },
            server => sub {
                my $port = shift;

                my $app = sub {
                    my $test = shift @{$tests->{$testname}{server}{$server_test}};
                    $test and $test->(Plack::Request->new(shift));
                };

                Plack::Loader->auto(
                    host => "127.0.0.1",
                    port => $port,
                )->run($app);
            },
        );
    }
}

done_testing;

use inc::Module::Install;
name 'AnyEvent-WebService-ImKayac';
all_from 'lib/AnyEvent/WebService/ImKayac.pm';

requires 'AnyEvent::HTTP';
requires 'JSON';
requires 'HTTP::Request::Common';
requires 'Digest::SHA';
test_requires 'Test::TCP';
test_requires 'Test::Requires';

tests 't/*.t';
author_tests 'xt';

build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;

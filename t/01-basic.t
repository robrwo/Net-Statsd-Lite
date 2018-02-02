#!perl

package Net::Statsd::Tiny::Test::Class;

use Test::Roo;

use lib 't/lib';
with qw/ Net::Statsd::Tiny::Test Test::Roo::DataDriven /;

1;

package main;

use Test::Most;

Net::Statsd::Tiny::Test::Class->run_data_tests(
    files => 't/data',
);

done_testing;

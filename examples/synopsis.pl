#!/usr/local/bin/perl -w
#
# synopsis.pl - the SYNOPSIS lifted from `perldoc Resource::Loader`
#
# Joshua Keroes - 25 Apr 2003
#
# Try running this multiple times to see how 'sometimes' and 'always'
# behave with different 'cont' values.

use strict;
use Resource::Loader;
use Data::Dumper;

my $loader = Resource::Loader->new(
         testing => 0,
         verbose => 0,
         cont    => 0,
         resources =>
           [
             { name => 'never',
               when => sub { 0 },
               code => sub { die "this will never be loaded" },
             },
             { name => 'sometimes',
               when => sub { int rand 2 > 0 }, # true 50% of the time
               code => sub { "'sometimes' was loaded. args: [@_]" },
               args => [ qw/foo bar baz/ ],
             },
             { name => 'always',
               when => sub { 1 },
               code => sub { "always' was loaded" },
             },
           ],
);

my $loaded = $loader->load;
my $status = $loader->status;

print "Resource::Loader::loaded():\n  " . Data::Dumper->Dump([$loaded], ['loaded']);
print "Resource::Loader::status():\n  " . Data::Dumper->Dump([$status], ['status']);

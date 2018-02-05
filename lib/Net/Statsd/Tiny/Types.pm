package Net::Statsd::Tiny::Types;

# ABSTRACT: A type library for Net::Statsd::Tiny

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;

BEGIN { extends "Types::Standard" }

our $VERSION = 'v0.2.1';

=head1 DESCRIPTION

This module provides types for L<Net::Statsd::Tiny>.

The types declared here are intended for internal use, and subject to
change.

=cut

declare "PosInt", as Int,
  where { $_ >= 0 },
  inline_as { my $n = $_[1]; "$n >= 0" };

declare "PosNum", as StrictNum,
  where { $_ >= 0 },
  inline_as { my $n = $_[1]; "$n >= 0" };

declare "Port", as "PosInt",
  where { $_ >= 0 && $_ <= 65535 },
  inline_as { my $port = $_[1]; "$port >= 0 && $port <= 65535" };

declare "Rate", as StrictNum,
  where { $_ >= 0 && $_ <= 1 },
  inline_as { my $n = $_[1]; "$n >= 0 && $n <= 1" };

declare "Gauge", as Str,
  where { $_ =~ /\A[\-\+]?\d+\z/ },
  inline_as { my $n = $_[1]; "$n =~ /\\A[\\-\\+]?\\d+\\z/" };

=head1 append:AUTHOR

The initial development of this module was sponsored by Science Photo
Library L<https://www.sciencephoto.com>.

=cut

1;

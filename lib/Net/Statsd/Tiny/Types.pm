package Net::Statsd::Tiny::Types;

use Type::Library -base;
use Type::Utils -all;

BEGIN { extends "Types::Standard" }

declare "PosInt", as Int,
  where { $_ >= 0 },
  inline_as { my $n = $_[1]; "$n >= 0" };

declare "PosNum", as StrictNum,
  where { $_ >= 0 },
  inline_as { my $n = $_[1]; "$n >= 0" };

declare "Port", as PosInt,
  where { $_ >= 0 && $_ <= 65535 },
  inline_as { my $port = $_[1]; "$port >= 0 && $port <= 65535" };

declare "Rate", as StrictNum,
  where { $_ >= 0 && $_ <= 1 },
  inline_as { my $n = $_[1]; "$n >= 0 && $n <= 1" };

declare "Gauge", as Str,
  where { $_ =~ /\A[\-\+]?\d+\z/ },
  inline_as { my $n = $_[1]; "$n =~ /\\A[\\-\\+]?\\d+\\z/" };

1;

# NAME

Net::Statsd::Lite - A lightweight StatsD client that supports multimetric packets

# VERSION

version v0.4.9

# SYNOPSIS

```perl
use Net::Statsd::Lite;

my $stats = Net::Statsd::Lite->new(
  prefix          => 'myapp.',
  autoflush       => 0,
  max_buffer_size => 8192,
);

...

$stats->increment('this.counter');

$stats->set_add( $username ) if $username;

$stats->timing( $run_time * 1000 );

$stats->flush;
```

# DESCRIPTION

This is a small StatsD client that supports the
[StatsD Metrics Export Specification v0.1](https://github.com/b/statsd_spec).

It supports the following features:

- Multiple metrics can be sent in a single UDP packet.
- It supports the meter and histogram metric types.

Note that the specification requires the measured values to be
integers no larger than 64-bits, but ideally 53-bits.

The current implementation expects values to be integers, except where
specified. But it otherwise does not enforce maximum/minimum values.

# ATTRIBUTES

## `host`

The host of the statsd daemon. It defaults to `127.0.0.1`.

## `port`

The port that the statsd daemon is listening on. It defaults to
`8125`.

## `proto`

The network protocol that the statsd daemon is using. It defaults to
`udp`.

## `prefix`

The prefix to prepend to metric names. It defaults to a blank string.

## `autoflush`

A flag indicating whether metrics will be send immediately. It
defaults to true.

When it is false, metrics will be saved in a buffer and only sent when
the buffer is full, or when the ["flush"](#flush) method is called.

Note that when this is disabled, you will want to flush the buffer
regularly at the end of each task (e.g. a website request or job).

Not all StatsD daemons support receiving multiple metrics in a single
packet.

## `max_buffer_size`

The specifies the maximum buffer size. It defaults to `512`.

# METHODS

## `counter`

```
$stats->counter( $metric, $value, $rate );
```

This adds the `$value` to the counter specified by the `$metric`
name.

If a `$rate` is specified and less than 1, then a sampling rate will
be added. `$rate` must be between 0 and 1.

## `update`

This is an alias for ["counter"](#counter), for compatability with
[Etsy::StatsD](https://metacpan.org/pod/Etsy::StatsD) or [Net::Statsd::Client](https://metacpan.org/pod/Net::Statsd::Client).

## `increment`

```
$stats->increment( $metric, $rate );
```

This is an alias for

```
$stats->counter( $metric, 1, $rate );
```

## `decrement`

```
$stats->decrement( $metric, $rate );
```

This is an alias for

```
$stats->counter( $metric, -1, $rate );
```

## `metric`

```
$stats->metric( $metric, $value );
```

This is a counter that only accepts positive (increasing) values. It
is appropriate for counters that will never decrease (e.g. the number
of requests processed.)  However, this metric type is not supported by
many StatsD daemons.

## `gauge`

```
$stats->gauge( $metric, $value );
```

A gauge can be thought of as a counter that is maintained by the
client instead of the daemon, where `$value` is a positive integer.

However, this also supports gauge increment extensions. If the number
is prefixed by a "+", then the gauge is incremented by that amount,
and if the number is prefixed by a "-", then the gauge is decremented
by that amount.

## `timing`

```
$stats->timing( $metric, $value, $rate );
```

This logs a "timing" in milliseconds, so that statistics about the
metric can be gathered. The `$value` must be positive number,
although the specification recommends that integers be used.

In actually, any values can be logged, and this is often used as a
generic histogram for non-timing values (especially since many StatsD
daemons do not support the ["histogram"](#histogram) metric type).

If a `$rate` is specified and less than 1, then a sampling rate will
be added. `$rate` must be between 0 and 1.  Note that sampling
rates for timings may not be supported by all statsd servers.

## `timing_ms`

This is an alias for ["timing"](#timing), for compatability with
[Net::Statsd::Client](https://metacpan.org/pod/Net::Statsd::Client).

## `histogram`

```
$stats->histogram( $metric, $value );
```

This logs a value so that statistics about the metric can be
gathered. The `$value` must be a positive number, although the
specification recommends that integers be used.

This metric type is not supported by many StatsD daemons. You can use
["timing"](#timing) for the same effect.

## `set_add`

```
$stats->set_add( $metric, $string );
```

This adds the the `$string` to a set, for logging the number of
unique things, e.g. IP addresses or usernames.

## `flush`

This sends the buffer to the ["host"](#host) and empties the buffer, if there
is any data in the buffer.

# STRICT MODE

If this module is first loaded in `STRICT` mode, then the values and
rate arguments will be checked that they are the correct type.

See [Devel::StrictMode](https://metacpan.org/pod/Devel::StrictMode) for more information.

# SEE ALSO

This module was forked from [Net::Statsd::Tiny](https://metacpan.org/pod/Net::Statsd::Tiny).

[https://github.com/b/statsd\_spec](https://github.com/b/statsd_spec)

# SOURCE

The development version is on github at [https://github.com/robrwo/Net-Statsd-Lite](https://github.com/robrwo/Net-Statsd-Lite)
and may be cloned from [git://github.com/robrwo/Net-Statsd-Lite.git](git://github.com/robrwo/Net-Statsd-Lite.git)

# BUGS

Please report any bugs or feature requests on the bugtracker website
[https://github.com/robrwo/Net-Statsd-Lite/issues](https://github.com/robrwo/Net-Statsd-Lite/issues)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

# AUTHOR

Robert Rothenberg <rrwo@cpan.org>

The initial development of this module was sponsored by Science Photo
Library [https://www.sciencephoto.com](https://www.sciencephoto.com).

# CONTRIBUTOR

Toby Inkster <tobyink@cpan.org>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2019 by Robert Rothenberg.

This is free software, licensed under:

```
The Artistic License 2.0 (GPL Compatible)
```

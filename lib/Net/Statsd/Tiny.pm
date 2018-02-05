package Net::Statsd::Tiny;

use v5.10;

use Moo 1.000000;

use IO::Socket 1.18 ();
use IO::String;
use MooX::TypeTiny;
use Sub::Quote qw/ quote_sub /;
use Sub::Util 1.40 qw/ set_subname /;
use Net::Statsd::Tiny::Types -types;

use namespace::autoclean;

has host => (
    is      => 'ro',
    isa     => Str,
    default => '127.0.0.1',
);

has port => (
    is      => 'ro',
    isa     => Port,
    default => 8125,
);

has proto => (
    is      => 'ro',
    isa     => Enum [qw/ tcp udp /],
    default => 'udp',
);

has prefix => (
    is      => 'ro',
    isa     => Str,
    default => '',
);

has autoflush => (
    is      => 'ro',
    isa     => Bool,
    default => 1,
);

has _buffer => (
    is      => 'lazy',
    isa     => InstanceOf ['IO::String'],
    builder => sub {
        IO::String->new;
    },
);

has max_buffer_size => (
    is      => 'ro',
    isa     => PosInt,
    default => 512,
);

has _socket => (
    is      => 'lazy',
    isa     => InstanceOf ['IO::Socket::INET'],
    builder => sub {
        my ($self) = shift;
        my $sock = IO::Socket::INET->new(
            PeerAddr => $self->host,
            PeerPort => $self->port,
            Proto    => $self->proto,
        ) or die "Failed to initialize socket: $!";
        return $sock;
    },
    handles => { _send => 'send' },
);

BEGIN {
    my $class = __PACKAGE__;

    my %PROTOCOL = (
        add_set   => [ 's',  Str, ],
        counter   => [ 'c',  Int, 1 ],
        gauge     => [ 'g',  Gauge | PosInt ],
        histogram => [ 'h',  PosInt ],
        meter     => [ 'm',  PosInt ],
        timing    => [ 'ms', PosInt ],
    );

    foreach my $name ( keys %PROTOCOL ) {

        no strict 'refs';

        my $type = $PROTOCOL{$name}[1];
        my $rate = $PROTOCOL{$name}[2];

        my $code =
          defined $rate
          ? q{ my ($self, $metric, $value, $rate) = @_; }
          : q{ my ($self, $metric, $value) = @_; };

        $code .= $type->inline_assert('$value');

        $code .= q/ if (defined $rate) { / . Rate->inline_assert('$rate') . ' }'
          if defined $rate;

        my $tmpl = '%s:%s|' . $PROTOCOL{$name}[0];

        if ( defined $rate ) {

            $code .= q/ if ((defined $rate) && ($rate<1)) {
                     $self->record( $tmpl . '|@%f', $metric, $value, $rate );
                   } else {
                     $self->record( $tmpl, $metric, $value ); } /;
        }
        else {

            $code .= q{$self->record( $tmpl, $metric, $value );};

        }

        quote_sub "${class}::${name}", $code,
          { '$tmpl' => \$tmpl },
          { no_defer => 1 };


    }

    # Alises for other Net::Statsd::Client or Etsy::StatsD

    {
        no strict 'refs';

        *{"${class}::update"}    = set_subname "update"    => \&counter;
        *{"${class}::timing_ms"} = set_subname "timing_ms" => \&timing;

    }

}

sub increment {
    my ( $self, $metric, $rate ) = @_;
    $self->counter( $metric, 1, $rate );
}

sub decrement {
    my ( $self, $metric, $rate ) = @_;
    $self->counter( $metric, -1, $rate );
}

sub record {
    my ( $self, $template, @args ) = @_;

    my $data = $self->prefix . sprintf( $template, @args );

    my $fh  = $self->_buffer;
    my $len = length($data);

    if ( $len >= $self->max_buffer_size ) {
        warn "Data is too large";
        return $self;
    }

    $len += length( ${ $fh->string_ref } );
    if ( $len >= $self->max_buffer_size ) {
        $self->flush;
    }

    say {$fh} $data;

    $self->flush if $self->autoflush;
}

sub flush {
    my ($self) = @_;

    my $fh = $self->_buffer;

    my $data = ${ $fh->string_ref };

    if ( length($data) ) {
        $self->_send( $data, 0 );
        $fh->truncate;
    }
}

sub DEMOLISH {
    my ( $self, $is_global ) = @_;

    return if $is_global;

    $self->flush;
}

=head1 SEE ALSO

L<https://github.com/b/statsd_spec>

=cut

1;

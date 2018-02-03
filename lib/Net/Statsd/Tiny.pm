package Net::Statsd::Tiny;

use v5.10;

use Moo 1.000000;

use Carp;
use IO::Socket 1.18 ();
use IO::String;
use MooX::TypeTiny;
use Sub::Util 1.40 qw/ set_subname /;
use Types::Standard -types;

use namespace::autoclean;

has host => (
    is      => 'ro',
    isa     => Str,
    default => '127.0.0.1',
);

has port => (
    is      => 'ro',
    isa     => Int,
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

has buffer => (
    is      => 'lazy',
    isa     => InstanceOf ['IO::String'],
    builder => sub {
        IO::String->new;
    },
);

has max_buffer_size => (
    is      => 'ro',
    isa     => Int,
    default => 8192,
);

has socket => (
    is      => 'lazy',
    isa     => InstanceOf ['IO::Socket::INET'],
    builder => sub {
        my ($self) = shift;
        my $sock = IO::Socket::INET->new(
            PeerAddr => $self->host,
            PeerPort => $self->port,
            Proto    => $self->proto,
        ) or croak "Failed to initialize socket: $!";
        return $sock;
    },
    handles => [qw/ send /],
);

BEGIN {
    my $class = __PACKAGE__;

    my %CODES = (
        add_set   => [ '%s:%s|s',   qr/\A(.+)\z/ ],
        counter   => [ '%s:%d|c',   qr/\A(\-?[0-9]{1,19})\z/ ],
        gauge     => [ '%s:%s%u|g', qr/\A([\-\+]|)?([0-9]{1,20})\z/ ],
        histogram => [ '%s:%u|h',   qr/\A([0-9]{1,20})\z/ ],
        meter     => [ '%s:%u|m',   qr/\A([0-9]{1,20})\z/ ],
        timing    => [ '%s:%u|ms',  qr/\A([0-9]{1,20})\z/ ],
    );

    foreach my $name ( keys %CODES ) {

        no strict 'refs';

        my $plain = $CODES{$name}[0];
        my $rated = $plain . '|@%f';
        my $parse = $CODES{$name}[1];

        *{"${class}::${name}"} = set_subname $name => sub {
            my ( $self, $metric, $value, $rate ) = @_;
            my @values = $value =~ $parse
              or croak "Invalid value for ${name}: ${value}";
            $self->record(
                defined $rate
                ? ( $rated, $metric, @values, $rate )
                : ( $plain, $metric, @values )
            );
        };

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

    my $fh  = $self->buffer;
    my $len = length($data);

    if ( $len >= $self->max_buffer_size ) {
        carp "Data is too large";
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

    my $fh = $self->buffer;

    my $data = ${ $fh->string_ref };

    if ( length($data) ) {
        $self->send( $data, 0 );
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

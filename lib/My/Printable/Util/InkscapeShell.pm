package My::Printable::Util::InkscapeShell;
use warnings;
use strict;
use v5.10.0;

use lib "$ENV{HOME}/git/dse.d/perl-class-thingy/lib";
use Class::Thingy;

use Expect qw();

public 'expect', lazy => 1, builder => sub {
    my @cmd = ('inkscape', '--shell');
    my $expect = Expect->new();
    $expect->raw_pty(0);
    $expect->spawn(@cmd) or die("Cannot spawn @cmd: $!\n");
    $expect->expect(60, ">");
    return $expect;
};

sub cmd {
    my ($self, $cmd) = @_;
    $cmd =~ s{\R\z}{};          # safer chomp
    $self->expect->send("$cmd\n");
    $self->expect->expect(60, ">");
}

1;

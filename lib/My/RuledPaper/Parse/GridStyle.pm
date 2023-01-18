package My::RuledPaper::Parse::GridStyle;
use warnings;
use strict;

# example:
#     2mm,3,12
#     feint lines every 2mm
#     minor lines every 3 feint lines
#     major lines every 12 feint lines
# example 2:
#     2mm,4
#     feint lines every 2mm
#     **major** lines every 4 feint lines

use base 'Exporter';

our @EXPORT = qw();
our @EXPORT_OK = qw(parseGridStyle);
our %EXPORT_TAGS = (
    'all' => [@EXPORT_OK]
);

use lib "../../..";
use My::RuledPaper::Parse::Dimension qw(parseDimension);

use POSIX qw(round);
use Scalar::Util qw(looks_like_number);

sub parseGridStyle {
    my ($style) = @_;
    $style =~ s{\s+}{}g;
    my @style = split(/,+/, $style);
    my ($spacing, $minor, $major) = @style;
    $spacing = parseDimension($spacing);
    die("invalid grid style: $style ($minor is not a valid minor)\n") if defined $minor && !looks_like_number($minor);
    die("invalid grid style: $style ($major is not a valid major)\n") if defined $major && !looks_like_number($major);
    $minor = round($minor) if defined $minor;
    $major = round($major) if defined $major;
    die("invalid grid style: $style (minor $minor is too small)") if defined $minor && $minor < 1;
    die("invalid grid style: $style (minor $minor is too large)") if defined $minor && $minor > 32;
    die("invalid grid style: $style (major $major is too small)") if defined $major && $major < 1;
    die("invalid grid style: $style (major $major is too large)") if defined $major && $major > 32;
    die("invalid grid style: $style (major $major is not greater than minor $minor)") if defined $major && defined $minor && $major <= $minor;
    die("invalid grid style: $style (major $major is not a multiple of minor $minor)") if defined $major && defined $minor && $major % $minor != 0;
    if (!defined $major) {
        $major = $minor;
        $minor = undef;
    } elsif ($minor == $major) { # in case of something like "2mm,4,4"
        $minor = undef;
    }
    return ($spacing, $minor, $major);
}

1;

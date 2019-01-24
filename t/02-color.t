#!/usr/bin/env perl
use warnings;
use strict;
use v5.10.0;
use Test::More;

plan tests => 24;

use Cwd qw(realpath);
use File::Basename qw(dirname);

our $lib;
BEGIN {
    $lib = dirname(realpath($0)) . '/../lib';
}
use lib $lib;

use My::Printable::Paper::Color;

my $c1 = My::Printable::Paper::Color->new;
ok($c1->asHex eq '#ffffff');
ok($c1->asRGB eq 'rgb(255, 255, 255)');
$c1->r(0.8);
ok($c1->asHex eq '#ccffff');
$c1->g(0.6);
ok($c1->asHex eq '#cc99ff');
$c1->b(0.4);
ok($c1->asHex eq '#cc9966');
$c1->a(0.2);
ok($c1->asHex eq '#cc996633');

my $c2 = My::Printable::Paper::Color->new('#369');
ok($c2->asHex eq '#336699');
ok($c2->asRGB eq 'rgb(51, 102, 153)');

my $c3 = My::Printable::Paper::Color->new('#369c');
ok($c3->asHex eq '#336699cc');
ok($c3->asRGB eq 'rgba(51, 102, 153, 0.8)');

my $c4 = My::Printable::Paper::Color->new('#123456');
ok($c4->asHex eq '#123456');
ok($c4->asRGB eq 'rgb(18, 52, 86)');

my $c5 = My::Printable::Paper::Color->new('#12345678');
ok($c5->asHex eq '#12345678');
ok($c5->asRGB eq 'rgba(18, 52, 86, 0.470588)');

my $c6 = My::Printable::Paper::Color->new('#123456789abc');
ok($c6->asHex eq '#12569a');
ok($c6->asRGB eq 'rgb(18, 86, 154)');

my $c7 = My::Printable::Paper::Color->new('rgb(51, 102, 153)');
ok($c7->asHex eq '#336699');
ok($c7->asRGB eq 'rgb(51, 102, 153)');

my $c8 = My::Printable::Paper::Color->new('rgb(20%, 40%, 60%)');
ok($c8->asHex eq '#336699');
ok($c8->asRGB eq 'rgb(51, 102, 153)');

my $c9 = My::Printable::Paper::Color->new('rgb(51, 102, 153, 0.8)');
ok($c9->asHex eq '#336699cc');
ok($c9->asRGB eq 'rgba(51, 102, 153, 0.8)');

my $c10 = My::Printable::Paper::Color->new('rgb(20%, 40%, 60%, 0.8)');
ok($c10->asHex eq '#336699cc');
ok($c10->asRGB eq 'rgba(51, 102, 153, 0.8)');

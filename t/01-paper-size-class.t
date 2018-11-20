#!/usr/bin/env perl
use warnings;
use strict;
use v5.10.0;
use Test::More;

plan tests => 16;

use Cwd qw(realpath);
use File::Basename qw(dirname);

our $lib;
BEGIN {
    $lib = dirname(realpath($0)) . '/../lib';
}
use lib $lib;

use My::Printable::Document;
use Data::Dumper;

my $d1 = My::Printable::Document->new;
$d1->setPaperSize('a3');

my $d2 = My::Printable::Document->new;
$d2->setPaperSize('a4');

my $d3 = My::Printable::Document->new;
$d3->setPaperSize('a5');

my $d4 = My::Printable::Document->new;
$d4->setPaperSize('a6');

my $d5 = My::Printable::Document->new;
$d5->setPaperSize('11in * 17in');

my $d6 = My::Printable::Document->new;
$d6->setPaperSize('letter');

my $d7 = My::Printable::Document->new;
$d7->setPaperSize('halfletter');

my $d8 = My::Printable::Document->new;
$d8->setPaperSize('4.25in * 5.5in');

ok(!$d1->isA4SizeClass);
ok(!$d1->isA5SizeClass);
ok( $d2->isA4SizeClass);
ok(!$d2->isA5SizeClass);
ok(!$d3->isA4SizeClass);
ok( $d3->isA5SizeClass);
ok(!$d4->isA4SizeClass);
ok(!$d4->isA5SizeClass);
ok(!$d5->isA4SizeClass);
ok(!$d5->isA5SizeClass);
ok( $d6->isA4SizeClass);
ok(!$d6->isA5SizeClass);
ok(!$d7->isA4SizeClass);
ok( $d7->isA5SizeClass);
ok(!$d7->isA4SizeClass);
ok(!$d8->isA5SizeClass);

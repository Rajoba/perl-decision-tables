#!/usr/bin/env perl
# Nested decision tables: the fold table calls the grain table.
# Printers want the grain parallel to the fold, packaging the other way round.
# lfr = "--" means a square cut: no long side, so SB/BB doesn't apply.
# It must only come from x == y; the gap NNNNYY returns it for a non-square sheet.
use strict;
use warnings;
use FindBin;

do "$FindBin::Bin/../et_check.pl" or die $@ || $!;

# inner table: grain direction (lfr = SB, BB, or "--" for a square cut)
our $grain = example_table()->Code([qw(x y px1 py1 px2 py2 DBx DBy)], [qw(lfr DBx DBy)]);

# outer table: what to do with the sheet
my $fold = RegTable->new({
    Bedingungen => [
        '$::grain->(x, y, px1, py1, px2, py2, DBx, DBy)->{lfr} eq "--"',
        'packaging',
        'parallel',     # grain runs parallel to the fold
    ],
    Aktionen => [
        'what = "fold"',
        'what = "rotate sheet 90°"',
        'what = "ask a human"',
    ],
    sets => [
        [[qw(1 - -)], [qw(- - 1)]],   # square cut: grain direction doesn't apply
        [[qw(0 0 1)], [qw(1 - -)]],   # printing: parallel -> fold
        [[qw(0 0 0)], [qw(- 1 -)]],   # printing: across   -> rotate
        [[qw(0 1 1)], [qw(- 1 -)]],   # packaging: parallel -> rotate
        [[qw(0 1 0)], [qw(1 - -)]],   # packaging: across   -> fold
    ],
    else => [qw(- - -)],
});

print "----- report of the fold table\n";
$fold->report;

my $cd = $fold->Code([qw(x y px1 py1 px2 py2 DBx DBy packaging parallel)], [qw(what)]);

print "\n----- runs\n";
my @sheet = (100, 70, 0, 0, 10, 500, 100, 70);   # grain table says BB
my @square = (80, 80, 0, 0, 500, 10, 80, 80);   # x == y: square cut
my @gap   = (1, 2, 0, 0, 1, 1, 1, 2);            # not square, but no rule (NNNNYY)
printf "%-32s %s\n", $_->[0], $cd->(@{$_}[1..$#$_])->{what} for
    ['printing,  parallel',          @sheet, 0, 1],
    ['printing,  across',            @sheet, 0, 0],
    ['packaging, parallel',          @sheet, 1, 1],
    ['packaging, across',            @sheet, 1, 0],
    ['square cut',                   @square, 1, 0],
    ['gap NNNNYY (not square!)',     @gap,   1, 0];

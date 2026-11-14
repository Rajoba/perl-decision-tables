#!/usr/bin/env perl
# Nested decision tables: the fold table calls the grain table.
# Printers want the grain parallel to the fold, packaging the other way round.
use strict;
use warnings;
use FindBin;

do "$FindBin::Bin/../et_check.pl" or die $@ || $!;

# inner table: grain direction (lfr = SB, BB, or "--")
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
        [[qw(1 - -)], [qw(- - 1)]],
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
my @gap   = (1, 2, 0, 0, 1, 1, 1, 2);            # grain table has no rule (NNNNYY)
printf "%-32s %s\n", $_->[0], $cd->(@{$_}[1..$#$_])->{what} for
    ['printing,  parallel',          @sheet, 0, 1],
    ['printing,  across',            @sheet, 0, 0],
    ['packaging, parallel',          @sheet, 1, 1],
    ['packaging, across',            @sheet, 1, 0],
    ['grain table gap (NNNNYY)',     @gap,   1, 0];

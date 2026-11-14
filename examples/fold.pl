#!/usr/bin/env perl
# Nested decision tables: the fold table calls the grain table.
# Printers want the grain parallel to the fold, packaging the other way round.
# lfr = "--" means a square cut: no long side, so SB/BB doesn't apply.
# It must only come from x == y; the gap NNNNYY returns it for a non-square sheet.
use strict;
use warnings;
use FindBin;

do "$FindBin::Bin/../et_check.pl" or die $@ || $!;

my @grainParams = qw(x y px1 py1 px2 py2 DBx DBy);

# The grain table from et_check.pl, optionally with extra rules and another else.
# (Rule sets are copied, because RegTable turns '-' into undef in place.)
sub grain_table
{
	my %opt  = @_;
	my $base = example_table();
	my @sets = map{ [ [ map{ $_ // '-' } @{$_->[0]} ], [ @{$_->[1]} ] ] } @{$base->sets};
	return RegTable->new({
		Bedingungen => $base->Bedingungen,
		Aktionen    => $base->Aktionen,
		sets        => [ @sets, @{ $opt{extra} || [] } ],
		else        => $opt{else} || $base->else,
	});
}

my %variants = (
	'1 as in the repo'   => grain_table(),
	'2 complete'         => grain_table(extra => [
		[[qw(0 0 0 - - -)], [qw(- 1 - - - -)]],     # the commented-out rule: SB
		[[qw(1 - - - - -)], [qw(1 - - - - -)]],     # square cut: "--"
	]),
	'3 never returns --' => grain_table(extra => [
		[[qw(0 0 0 - - -)], [qw(- 1 - - - -)]],
		[[qw(1 - - - - -)], [qw(- 1 - - - -)]],     # thought experiment: square -> SB
	], else => [qw(- - - - - -)]),
);

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

print "----- report of the fold table alone\n";
$fold->report;

foreach my $v (sort keys %variants){
	print "\n##### grain table: $v\n";
	$fold->cross_report({
		0 => {
			name    => 'grain',
			table   => $variants{$v},
			var     => 'lfr',
			when    => sub { $_[0] eq '--' },
			only_if => { '--' => 'x == y' },
		},
	});
}

# Runtime: both tables named, gaps reported with the path.
our $grain = $variants{'1 as in the repo'}->Code(\@grainParams, [qw(lfr DBx DBy)],
	{ name => 'grain', on_gap => 'warn' });
my $cd = $fold->Code([@grainParams, qw(packaging parallel)], [qw(what)], { name => 'fold' });

print "\n----- runs (grain table as in the repo)\n";
local $SIG{__WARN__} = sub { print "    warn: @_" };
my @sheet  = (100, 70, 0, 0, 10, 500, 100, 70);  # grain table says BB
my @square = (80, 80, 0, 0, 500, 10, 80, 80);    # x == y: square cut
my @gap    = (1, 2, 0, 0, 1, 1, 1, 2);           # not square, but no rule (NNNNYY)
foreach my $c (
	['printing,  parallel',          @sheet,  0, 1],
	['printing,  across',            @sheet,  0, 0],
	['packaging, parallel',          @sheet,  1, 1],
	['packaging, across',            @sheet,  1, 0],
	['square cut',                   @square, 1, 0],
	['gap NNNNYY (not square!)',     @gap,    1, 0],
){
	my ($label, @args) = @$c;
	my $what = $cd->(@args)->{what};
	printf "%-32s %s\n", $label, $what;
}

#!/usr/bin/env perl
# Washboarding: printed board laminated onto corrugated board.
# If the grain of the laminated board runs along the flutes, its soft
# direction has to bridge the gaps between the flute tips and it sinks in.
# On a dark or glossy print you see every flute.
#
# One combination is left open on purpose: laminated, grain along the
# flutes, light print. It depends (board weight, flute, glue, customer),
# so it is a gap that goes to a human instead of a rule that pretends to know.
use strict;
use warnings;
use FindBin;

do "$FindBin::Bin/../et_check.pl" or die $@ || $!;

my $t = RegTable->new({
	Bedingungen => [
		'laminated',                    # printed board laminated onto corrugated
		'liner_grain_parallel_flute',   # its grain runs along the flutes
		'dark_or_glossy',               # dark or glossy print
	],
	Aktionen => [
		'what = "ok"',
		'what = "washboard risk: turn the grain"',
	],
	sets => [
		[[qw(0 - -)], [qw(1 -)]],       # no lamination: ok
		[[qw(1 0 -)], [qw(1 -)]],       # grain across the flutes bridges them: ok
		[[qw(1 1 1)], [qw(- 1)]],       # grain along the flutes, dark print: flutes show
	],
	else => [qw(- -)],
});

print "----- report\n";
$t->report;

my @params = qw(laminated liner_grain_parallel_flute dark_or_glossy);
my $cd = $t->Code(\@params, [qw(what)], { name => 'washboard', on_gap => 'warn' });

print "\n----- runs\n";
local $SIG{__WARN__} = sub { print "    warn: @_" };
foreach my $c (
	['plain corrugated',                      0, 0, 1],
	['laminated, grain across, dark',         1, 0, 1],
	['laminated, grain along, dark',          1, 1, 1],
	['laminated, grain along, light',         1, 1, 0],
){
	my ($label, @args) = @$c;
	printf "%-40s %s\n", $label, $cd->(@args)->{what} // '(open: ask a human)';
}

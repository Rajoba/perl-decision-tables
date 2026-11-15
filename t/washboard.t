use strict;
use warnings;
use Test::More;
use FindBin;

my $out = `$^X $FindBin::Bin/../examples/washboard.pl 2>&1`;
is $?, 0, 'examples/washboard.pl runs';
like   $out, qr/Fehlende Regeln:\n-+\nRegel Nr\.: \d+ YYN\n/, 'the open case YYN is reported as missing';
like $out, qr/^plain corrugated\s+ok$/m,                                     'no lamination: ok';
like $out, qr/^laminated, grain across, dark\s+ok$/m,                        'grain across the flutes: ok';
like $out, qr/^laminated, grain along, dark\s+washboard risk: turn the grain$/m, 'grain along, dark print: washboard risk';
like $out, qr/warn: washboard: keine Regel für YYN \(laminated=1, liner_grain_parallel_flute=1, dark_or_glossy=0\)\n^laminated, grain along, light\s+\(open: ask a human\)$/m,
     'grain along, light print: gap reported at runtime and left to a human';
unlike $out, qr/uninitialized| at \S+ line \d+/, 'no Perl warnings';

# exactly one missing row: the report lists the 3 rules plus YYN
my @missing = ($out =~ /^Regel Nr\.: \d+ ([YN]{3})$/mg);
my %rules   = map { $_ => 1 } qw(N-- YN- YYY);
is_deeply [grep { !$rules{$_} } @missing], ['YYN'], 'exactly one missing row';

done_testing;

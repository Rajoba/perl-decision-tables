use strict;
use warnings;
use Test::More;
use FindBin;

my $out = `$^X $FindBin::Bin/../et_check.pl 2>&1`;
is $?, 0, 'et_check.pl runs';

like $out, qr/Fehlende Regeln:/, 'reports missing rules';
like $out, qr/Regel Nr\.: 7 NNNYYY/, 'missing rule 7 found (x<y, |dx|<|dy|, DBx>DBy)';
like $out, qr/Regel Nr\.: 8 NNNNYY/, 'missing rule 8 found (x<y, |dx|<|dy|, DBx<DBy)';
unlike $out, qr/Regel Nr\.: \d+ Y[YN]/, 'contradictory combinations (x == y together with x > y or x < y) are filtered out';

like $out, qr/^lfr == BB$/m,  'compiled sub decides BB for the sample input';
like $out, qr/^DBx == 100$/m, 'DBx taken from x';
like $out, qr/^DBy == 70$/m,  'DBy taken from y';

done_testing;

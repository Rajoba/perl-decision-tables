use strict;
use warnings;
use Test::More;
use FindBin;

my $out = `$^X $FindBin::Bin/../et_check.pl 2>&1`;
is $?, 0, 'et_check.pl runs';

like $out, qr/Fehlende Regeln:/, 'reports missing rules';
# Missing rules: the gap x<y, |dx|<=|dy| and two x == y cases (only else covers them)
like $out, qr/Regel Nr\.: \d+ NNNNYY\nx != y\nx <= y\nabs\(px2 - px1\) <= abs\(py2 - py1\)\nDBx <= DBy\n/,
    'gap x<y, |dx|<=|dy| found, negated conditions shown as <=';
like $out, qr/Regel Nr\.: \d+ YNYNYY/, 'missing x == y case found (|dx|>|dy|)';
like $out, qr/Regel Nr\.: \d+ YNNNYY/, 'missing x == y case found (|dx|<=|dy|)';

# Impossible rows are not reported
unlike $out, qr/Regel Nr\.: \d+ YY/, 'x == y together with x > y is filtered out';
unlike $out, qr/Regel Nr\.: \d+ NNNYYY/,
    'DBx == x, DBy == y, x < y with DBx > DBy is filtered out (unreachable)';

like $out, qr/^lfr == BB$/m,  'compiled sub decides BB for the sample input';
like $out, qr/^DBx == 100$/m, 'DBx taken from x';
like $out, qr/^DBy == 70$/m,  'DBy taken from y';

done_testing;

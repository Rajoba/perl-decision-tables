use strict;
use warnings;
use Test::More;
use FindBin;

# Regression tests for issues reported on the colony.ai post.
do "$FindBin::Bin/../et_check.pl" or die $@ || $!;

# N on a comparison is its exact complement, shown with <= / >=
is ::bedText('a > b', 0),  'a <= b', 'not > is <=';
is ::bedText('a < b', 0),  'a >= b', 'not < is >= (was: stayed <)';
is ::bedText('a >= b', 0), 'a < b',  'not >= is <';
is ::bedText('a <= b', 0), 'a > b',  'not <= is >';
is ::bedText('a == b', 0), 'a != b', 'not == is !=';
is ::bedText('a != b', 0), 'a == b', 'not != is ==';
is ::bedText('abs(px2 - px1) > abs(py2 - py1)', 0), 'abs(px2 - px1) <= abs(py2 - py1)', 'expressions keep their operands';
is ::bedText('a < b && f(x)', 0), '!(a < b && f(x))', 'compound condition negated as a whole';
is ::bedText('wenn # PK', 0), 'wenn nicht PK', 'text condition';
is ::bedText('a > b', 1),  'a > b',  'Y keeps the condition';

# Contradictions across variables
ok  ::contradicts('DBx == x', 'DBy == y', 'x <= y', 'x != y', 'DBx > DBy'), 'old rule 7 (NNNYYY) is impossible';
ok !::contradicts('DBx == x', 'DBy == y', 'x <= y', 'x != y', 'DBx <= DBy'), 'NNNNYY is possible';
ok  ::contradicts('x == y', 'x > y'), 'x == y with x > y';
ok !::contradicts('x == y', 'x <= y'), 'x == y with x <= y is fine';
ok  ::contradicts('a <= b', 'b <= a', 'a != b'), 'a <= b, b <= a, a != b';
ok  ::contradicts('a < b', 'b < c', 'c < a'), 'strict cycle';
ok !::contradicts('a <= b', 'b <= c', 'c <= a'), 'non-strict cycle means all equal, no contradiction';
ok !::contradicts('f(x)', 'a > b'), 'non-comparisons are ignored';

# The example table at the boundary |dx| == |dy|
my $rt = example_table();
my $cd = $rt->Code([qw(x y px1 py1 px2 py2 DBx DBy)], [qw(lfr DBx DBy)]);
is_deeply $cd->(100, 70, 0, 0, 10, 10, 100, 70), { lfr => 'BB', DBx => 100, DBy => 70 },
    'x > y, equal deltas: rule 5 (N on |dx| > |dy|) applies, not else';
is_deeply $cd->(1, 2, 0, 0, 1, 1, 1, 2), { lfr => '--', DBx => 2, DBy => 1 },
    'x=1 y=2 DBx=1 DBy=2, equal deltas: reachable gap NNNNYY, handled by else';

# A table with a < condition: N must evaluate as >=
my $t2 = RegTable->new({
    Bedingungen => ['a < b'],
    Aktionen    => ['r = "lt"', 'r = "ge"'],
    sets        => [ [[qw(1)], [qw(1 -)]], [[qw(0)], [qw(- 1)]] ],
    else        => [qw(- -)],
});
my $cd2 = $t2->Code([qw(a b)], [qw(r)]);
is $cd2->(1, 2)->{r}, 'lt', 'a < b';
is $cd2->(2, 2)->{r}, 'ge', 'a == b is "not a < b"';
is $cd2->(3, 2)->{r}, 'ge', 'a > b is "not a < b"';

done_testing;

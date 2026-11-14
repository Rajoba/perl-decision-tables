use strict;
use warnings;
use Test::More;
use FindBin;

# Several tables at the same time must not affect each other.
# (Before: RegTable kept the current table in package globals, so creating
# a second table silently broke the first one: BB turned into --.)
do "$FindBin::Bin/../et_check.pl" or die $@ || $!;

my @w; local $SIG{__WARN__} = sub { push @w, @_ };

my @params = qw(x y px1 py1 px2 py2 DBx DBy);
my @loc    = qw(lfr DBx DBy);
my @bb     = (100, 70, 0, 0, 10, 500, 100, 70);

my $outer = example_table();
my $cdO   = $outer->Code(\@params, \@loc);
is $cdO->(@bb)->{lfr}, 'BB', 'first table alone';

my $small = RegTable->new({
    Bedingungen => ['a > b'],
    Aktionen    => ['r = "big"', 'r = "small"'],
    sets        => [ [[qw(1)], [qw(1 -)]], [[qw(0)], [qw(- 1)]] ],
    else        => [qw(- -)],
});
my $cdS = $small->Code([qw(a b)], [qw(r)]);

is $cdO->(@bb)->{lfr}, 'BB', 'first table still right after creating a second one';
is $cdS->(5, 1)->{r}, 'big',   'second table';
is $cdS->(1, 5)->{r}, 'small', 'second table, other branch';

# A table calling another table from inside an action (nesting)
our $inner = $cdS;
my $nest = RegTable->new({
    Bedingungen => ['n > 0'],
    Aktionen    => ['out = $::inner->(n, 3)->{r}'],
    sets        => [ [[qw(1)], [qw(1)]] ],
    else        => [qw(-)],
});
my $cdN = $nest->Code([qw(n)], [qw(out)]);
is $cdN->(7)->{out}, 'big',   'outer table calls inner table: 7 > 3';
is $cdN->(2)->{out}, 'small', 'outer table calls inner table: 2 < 3';
is $cdO->(@bb)->{lfr}, 'BB',  'first table still right after nesting';

# Reports stay per table, with their own rule numbers
my $rep = sub { my $t = shift; my $o = ''; open my $fh, '>', \$o; my $old = select $fh; $t->report; select $old; $o };
my $r1 = $rep->($outer);
my $r2 = $rep->(example_table());
is $r1, $r2, 'report of a table is the same no matter how many tables exist';
like $r1, qr/Regel Nr\.: 9 NNNNYY/, 'rule numbers start fresh per table';
like $rep->($small), qr/Regel Nr\.: 2 Y\n/, 'small table numbers its own rules';
unlike $rep->($small), qr/abs\(px2/, 'small table report does not mention the other table';

is_deeply \@w, [], 'no warnings';

done_testing;

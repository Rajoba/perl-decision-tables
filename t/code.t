use strict;
use warnings;
use Test::More;
use FindBin;

# Load the script without running its example.
do "$FindBin::Bin/../et_check.pl" or die $@ || $!;

my $rt = example_table();
my $cd = $rt->Code([qw(x y px1 py1 px2 py2 DBx DBy)], [qw(lfr DBx DBy)]);

my @cases = (
    #  name                               x    y  px1 py1 px2  py2  DBx  DBy   expected
    ['x>y, |dx|>|dy|: SB, swap',        100,  70, 0, 0, 500,  10, 100,  70, { lfr => 'SB', DBx =>  70, DBy => 100 }],
    ['x>y, |dx|<|dy|: BB',              100,  70, 0, 0,  10, 500, 100,  70, { lfr => 'BB', DBx => 100, DBy =>  70 }],
    ['x<y, |dx|>|dy|: BB, swap',         70, 100, 0, 0, 500,  10,  70, 100, { lfr => 'BB', DBx => 100, DBy =>  70 }],
    ['x<y, |dx|<|dy|: gap, else',        70, 100, 0, 0,  10, 500,  70, 100, { lfr => '--', DBx => 100, DBy =>  70 }],
    ['x==y: else',                       80,  80, 0, 0, 500,  10,  80,  80, { lfr => '--', DBx =>  80, DBy =>  80 }],
    ['DBx/DBy taken from x/y first',    100,  70, 0, 0, 500,  10,   1,   2, { lfr => 'SB', DBx =>  70, DBy => 100 }],
    # rules 2/3 match here, but they don't set lfr, so else still runs
    ['gap with DBx!=x: else',            70, 100, 0, 0,  10, 500,   1,   2, { lfr => '--', DBx => 100, DBy =>  70 }],
    ['x==y with DBx!=x: else',           80,  80, 0, 0, 500,  10,   1,   2, { lfr => '--', DBx =>  80, DBy =>  80 }],
);

for my $c (@cases) {
    my ($name, @args) = @$c;
    my $want = pop @args;
    my $out  = '';
    my $got;
    {
        open my $fh, '>', \$out or die;
        my $old = select $fh;
        $got = $cd->(@args);
        select $old;
    }
    is_deeply $got, $want, $name;
    is $out, '', "$name: no output without verbose";
}

# A second table: else assigns nothing, so it runs only when no rule matched.
# (Built after the example tests: RegTable keeps the current table in globals.)
my $t2 = RegTable->new({
    Bedingungen => ['a > b'],
    Aktionen    => ['r = "big"', '&::else_hit(\\r)'],
    sets        => [ [[qw(1)], [qw(1 -)]] ],
    else        => [qw(- 1)],
});
our @notes;
sub else_hit { push @notes, 'else' }
my $cd2 = $t2->Code([qw(a b)], [qw(r)]);
@notes = (); is_deeply $cd2->(5, 1), { r => 'big' }, 'rule matched';   is scalar(@notes), 0, 'else not run';
@notes = (); is_deeply $cd2->(1, 5), { r => undef }, 'no rule matched'; is scalar(@notes), 1, 'else run once';

done_testing;

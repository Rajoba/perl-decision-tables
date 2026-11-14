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

done_testing;

use strict;
use warnings;
use Test::More;
use FindBin;

do "$FindBin::Bin/../et_check.pl" or die $@ || $!;

my $rt     = example_table();
my @params = qw(x y px1 py1 px2 py2 DBx DBy);
my @loc    = qw(lfr DBx DBy);
my @gap    = (1, 2, 0, 0, 1, 1, 1, 2);          # x<y, |dx| == |dy|: missing rule NNNNYY
my @ok     = (100, 70, 0, 0, 10, 500, 100, 70);  # rule 5: BB

# default: silent
{
    my @w; local $SIG{__WARN__} = sub { push @w, @_ };
    my $r = $rt->Code(\@params, \@loc)->(@gap);
    is $r->{lfr}, '--', 'default: else runs';
    is scalar(@w), 0, 'default: no warning';
}

# warn: warns, else still runs
{
    my @w; local $SIG{__WARN__} = sub { push @w, @_ };
    my $cd = $rt->Code(\@params, \@loc, { on_gap => 'warn' });
    my $r = $cd->(@gap);
    is $r->{lfr}, '--', 'warn: else still runs';
    is scalar(@w), 1, 'warn: one warning';
    like $w[0], qr/^keine Regel für NNNNYY \(x=1, y=2, px1=0, py1=0, px2=1, py2=1, DBx=1, DBy=2\)/, 'warn: message with pattern and values';

    @w = ();
    is $cd->(@ok)->{lfr}, 'BB', 'warn: normal case';
    is scalar(@w), 0, 'warn: no warning when a rule decides';
}

# die
{
    my $cd = $rt->Code(\@params, \@loc, { on_gap => 'die' });
    ok !eval { $cd->(80, 80, 0, 0, 500, 10, 80, 80); 1 }, 'die: dies on x == y';
    like $@, qr/^keine Regel für YNYNYY /, 'die: pattern of the missing x == y rule';
    is $cd->(@ok)->{lfr}, 'BB', 'die: normal case';
}

# code ref
{
    my @seen;
    my $cd = $rt->Code(\@params, \@loc, { on_gap => sub { push @seen, [@_] } });
    is $cd->(@gap)->{lfr}, '--', 'code ref: else still runs';
    is_deeply \@seen, [[ 'NNNNYY', { x => 1, y => 2, px1 => 0, py1 => 0, px2 => 1, py2 => 1, DBx => 1, DBy => 2 } ]],
        'code ref: gets pattern and values';
}

# bad option
ok !eval { $rt->Code(\@params, \@loc, { on_gap => 'loud' }); 1 }, 'unknown on_gap value is rejected';

done_testing;

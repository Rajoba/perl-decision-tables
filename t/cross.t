use strict;
use warnings;
use Test::More;
use FindBin;

do "$FindBin::Bin/../et_check.pl" or die $@ || $!;

# mergeRows
is_deeply [::mergeRows([qw(NNNNYY NNNYYY)], {})], ['NNN-YY'], 'two rows merged';
is_deeply [::mergeRows([qw(YY NN)], {})], [qw(NN YY)], 'rows that differ twice stay apart';
is_deeply [::mergeRows([qw(YY YN NY)], { NN => 1 })], ['--'], 'impossible row absorbed into -';
is_deeply [::mergeRows([qw(YY YN)], { NN => 1 })], ['Y-'], 'impossible row not used when not needed';

# outcomes of the grain table: which rows end with which lfr
my $g   = example_table();
my $out = $g->outcomes('lfr');
is_deeply [sort keys %$out], ['--', 'BB', 'SB'], 'grain table returns --, BB, SB';
is scalar(@{$out->{SB}}),  7, 'SB from 7 rows (rule 4)';
is scalar(@{$out->{BB}}), 14, 'BB from 14 rows (rules 5 and 6)';
is scalar(@{$out->{'--'}}), 21, '-- from 21 rows, not just the one gap in the report';
ok !(grep { $_ eq 'NNNYYY' } map { @$_ } values %$out), 'impossible row NNNYYY has no outcome';
ok  (grep { $_ eq 'NNNNNN' } @{$out->{'--'}}), 'NNNNNN (only helper rules match) ends with --';
is_deeply [::mergeRows($out->{'--'}, $g->impossibleRows)], [qw(-NN--- Y-----)], '-- rows merged';

# outcomes agree with the compiled sub for sample inputs
my $cd = $g->Code([qw(x y px1 py1 px2 py2 DBx DBy)], [qw(lfr DBx DBy)]);
is $cd->(70, 100, 0, 0, 10, 500, 1, 2)->{lfr}, '--', 'NNNNNN at runtime: --';
is $cd->(100, 70, 0, 0, 500, 10, 100, 70)->{lfr}, 'SB', 'NYY... at runtime: SB';

# cross_report return value
my $quiet = sub { my $code = shift; my $o = ''; open my $fh, '>', \$o; my $old = select $fh; my $r = $code->(); select $old; ($r, $o) };
my $outer = RegTable->new({
    Bedingungen => ['$::g->(a)->{lfr} eq "--"', 'p'],
    Aktionen    => ['w = "A"', 'w = "B"'],
    sets        => [ [[qw(1 -)], [qw(1 -)]], [[qw(0 -)], [qw(- 1)]] ],
    else        => [qw(- -)],
});
my ($r) = $quiet->(sub { $outer->cross_report({ 0 => { table => $g, var => 'lfr', when => sub { $_[0] eq '--' },
                                                       only_if => { '--' => 'x == y' } } }) });
is_deeply $r, { unreachable => [], violations => 1 }, 'repo grain table: one violation, nothing unreachable';

my $never = RegTable->new({
    Bedingungen => ['a > b'],
    Aktionen    => ['lfr = "SB"', 'lfr = "BB"'],
    sets        => [ [[qw(1)], [qw(1 -)]], [[qw(0)], [qw(- 1)]] ],
    else        => [qw(- -)],
});
($r) = $quiet->(sub { $outer->cross_report({ 0 => { table => $never, var => 'lfr', when => sub { $_[0] eq '--' } } }) });
is_deeply $r, { unreachable => [2], violations => 0 }, 'inner table never returns --: rule 2 unreachable';

done_testing;

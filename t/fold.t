use strict;
use warnings;
use Test::More;
use FindBin;

my $out = `$^X $FindBin::Bin/../examples/fold.pl 2>&1`;
is $?, 0, 'examples/fold.pl runs';
unlike $out, qr/Fehlende Regeln/, 'fold table itself has no missing rules';
like $out, qr/^printing,  parallel\s+fold$/m,                 'printing: parallel -> fold';
like $out, qr/^printing,  across\s+rotate sheet 90°$/m,       'printing: across -> rotate';
like $out, qr/^packaging, parallel\s+rotate sheet 90°$/m,     'packaging: parallel -> rotate';
like $out, qr/^packaging, across\s+fold$/m,                   'packaging: across -> fold';
like $out, qr/^square cut\s+ask a human$/m,                   'square cut -> ask a human';
like $out, qr/^gap NNNNYY \(not square!\)\s+ask a human$/m,   'gap in the inner table also ends at ask a human (wrongly)';
unlike $out, qr/uninitialized| at \S+ line \d+/, 'no Perl warnings';

# cross-table check, one block per grain table variant
my ($v1) = $out =~ /##### grain table: 1 as in the repo\n(.*?)\n#####/s;
my ($v2) = $out =~ /##### grain table: 2 complete\n(.*?)\n#####/s;
my ($v3) = $out =~ /##### grain table: 3 never returns --\n(.*?)\n-----/s;
ok defined $v1 && defined $v2 && defined $v3, 'three variants reported';
like   $v1, qr/lfr = "--" soll nur vorkommen, wenn 'x == y' gilt,\n\s+kommt aber auch hier vor: NNN---/, 'repo: -- from non-square sheets flagged';
like   $v1, qr/Alle Regeln sind erreichbar/, 'repo: all fold rules reachable';
unlike $v2, qr/soll nur vorkommen/, 'complete: -- only from square cuts';
like   $v2, qr/lfr = "--"\s+-> Bedingung Y  aus: Y-----\n/, 'complete: -- exactly from x == y';
like   $v2, qr/Alle Regeln sind erreichbar/, 'complete: square-cut rule still reachable';
like   $v3, qr/Bedingung 1 = Y ist NIE möglich/, 'never --: condition 1 = Y impossible';
like   $v3, qr/Regel 2 \(Y--\) ist nicht erreichbar/, 'never --: square-cut rule unreachable';

# runtime: gaps with the path through both tables
like $out, qr/warn: fold → grain: keine Regel für NNNNYY \(x=1, y=2,/, 'runtime gap reported with path fold → grain';

done_testing;

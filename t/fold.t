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
unlike $out, qr/warning|uninitialized/i, 'no warnings';

done_testing;

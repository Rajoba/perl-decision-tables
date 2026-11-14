use strict;
use warnings;
use Test::More;
use FindBin;
use File::Temp qw(tempfile);

# Add a rule that contradicts rule 5 (BB) with SB for DBx > DBy.
open my $in, '<', "$FindBin::Bin/../et_check.pl" or die $!;
my $src = do { local $/; <$in> };
my $n = ($src =~ s/(\[\[qw\(0 1 0 - - - \)\],\[qw\(- - 1 - - - \)\]\],)/$1\n\t\t\t\t[[qw(0 - - 1 - - )],[qw(- 1 - - - - )]],/);
is $n, 1, 'conflicting rule inserted';

my ($fh, $file) = tempfile(SUFFIX => '.pl', UNLINK => 1);
print $fh $src; close $fh;

my $out = `$^X $file 2>&1`;
is $?, 0, 'modified table runs';
like $out, qr/Regel 5 \(NYN---\) und 6 \(N--Y--\) überkreuzen sich in 4 Fällen:/, 'conflict between rule 5 and 6 reported';
like $out, qr/^\s+NYNYNN$/m, 'overlapping case listed';

done_testing;

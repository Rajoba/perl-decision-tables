use strict;
use warnings;
use Test::More;
use FindBin;
use File::Temp qw(tempfile);

# Add a duplicate of rule 5 and a broader rule with the same action.
open my $in, '<', "$FindBin::Bin/../et_check.pl" or die $!;
my $src = do { local $/; <$in> };
my $n = ($src =~ s/(\[\[qw\(0 1 0 - - - \)\],\[qw\(- - 1 - - - \)\]\],)/$1\n\t\t\t\t[[qw(0 1 0 - - - )],[qw(- - 1 - - - )]],\n\t\t\t\t[[qw(0 1 - - - - )],[qw(- - 1 - - - )]],/);
is $n, 1, 'redundant rules inserted';

my ($fh, $file) = tempfile(SUFFIX => '.pl', UNLINK => 1);
print $fh $src; close $fh;

my $out = `$^X $file 2>&1`;
is $?, 0, 'modified table runs';
like $out, qr/^Regel Nr\.5 \(NYN---\) == Regel Nr\. 6 \(NYN---\)$/m, 'duplicate rule reported';
like $out, qr/^Regel Nr\.5 \(NYN---\) <  Regel Nr\. 7 \(NY----\)$/m, 'rule 5 is covered by rule 7';

done_testing;

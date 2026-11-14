#!/usr/bin/env perl
#===================================================================================
#
#         FILE:  et_check.pl
#
#        USAGE:  perl et_check.pl
#
#  DESCRIPTION:  Decision tables (Entscheidungstabellen): find missing rules,
#                overlapping rules, and compile a table into a callable sub.
#
#        FILES:  ---
#        NOTES:  ---
#       AUTHOR:  Ralf-Jochen Bartel
#      VERSION:  1.0
#      CREATED:  10.08.2004 - 09:11:14
#     REVISION:  ---
#===================================================================================

use strict;
use warnings;
use Data::Dumper;


sub test
{
	my $var = shift;
	my $val = shift;

	$var = $val;
	print "($var)\n";
}	# ----------  end of subroutine test  ----------
sub swap
{
	my ($x, $y)	= @_;

	($$x, $$y) = ($$y, $$x);
}	# ----------  end of subroutine swap  ----------
sub complTbl
{
	my $p	= shift;
	my $seq = 2**($p-1);
	my @cp = ();

	for( my $x=1;$x<=$p;$x++ ){
		my $s = 2**($x-1);
		push(@cp, [map{ (map{ 1 } (1..$s)),(map{ 0 } (1..$s)) } (1..($seq/$s))]);
	}	
	return \@cp;
}	# ----------  end of subroutine complTbl  ----------
sub turnTable
{
	my	$table	= shift;
	my  @nt = ();

	foreach my $x (0..scalar(@{$table->[0]})-1){
		push(@nt, []);
		foreach my $y (0..$#$table){
			push(@{$nt[-1]}, $table->[$y][$x]);
		}
	}

	return \@nt;
}	# ----------  end of subroutine turnTable  ----------

{
	package RegSet;

	use strict;
	use Data::Dumper;
	use base(qw(Class::Accessor));
	use overload 
	'""' => \&show,
	'x'  => \&kreuzen,
	'>'  => \&greater,
	'<'  => \&smaller,
	'==' => \&equal
	;

	RegSet->mk_accessors( qw(set akt Nr) );
	RegSet->mk_ro_accessors( qw(undef complements rsBed irrelevant) );

	our ($Bed, $Akt, $RegAnz) = (undef, undef, 1);

	sub new 
	{
		my($class)  = shift;
		my($params) = @_;
		my($self)   = $class->SUPER::new($params);

		$self->{Nr} = ++$RegAnz if ! defined($self->Nr);
		map{ $self->{set}->[$_] = undef if $self->set->[$_] eq '-' } (0..$#{$self->set});
			$self->{undef} = scalar(@{$self->set}) - scalar(grep{ defined } @{$self->set} );

			my $ct = \@{::complTbl($self->{undef})};
			my $nr = 0;
			foreach my $c (0..$#{$ct->[0]})
				{
					my $r = 0;
					my @tmp = ();

					push(@{$self->{complements}}, []);
					map{  
						push(@tmp, defined $_ ? $_ : $ct->[$r++][$c]);  
					} @{$self->{set}};
					if(defined $self->{complements}->[-1]){
						push(@{$self->{complements}->[-1]}, @tmp) if ! RegSet->new({set => [\@tmp] , akt => $self->akt, Nr => 0})->irrelevant;
					}
				}		

				my %li = ();
				for(my $i=0; $i <= $#$Bed; $i++ ){
					if(defined($self->{set}->[$i])){
						$self->{rsBed}->[$i] = $Bed->[$i];

						$self->{set}->[$i] ? $self->{rsBed}->[$i] =~ s/\# // : $self->{rsBed}->[$i] =~ s/\# /nicht /;
						if(!$self->{set}->[$i]){
							$self->{rsBed}->[$i] =~ s/ \< / \> /g;
							$self->{rsBed}->[$i] =~ s/ \> / \< /g;
							$self->{rsBed}->[$i] =~ s/ \=\= / \!\= /g;
						}
						if($self->{rsBed}->[$i] =~ /\<|\>|\=\=|\!\=/ ){
							my $tmp = $self->{rsBed}->[$i];

							$tmp =~ s/ \< | \> | \=\= | \!\= / /g;
							push(@{$li{$tmp}}, $i);
						}
					} else {
						$self->{rsBed}->[$i] = undef;
					}
					if(scalar( grep{ scalar(@$_) >1 } values %li ) > 0){
						my %bdc = ();

						map{
							map{
								# print "$self->{rsBed}->[$_]\n";
								my $bd = $self->{rsBed}->[$_];
								$bd =~ s/\w+|\d+|\s+//g;
								++$bdc{f_1} if $bd eq '==' || $bd eq '>' || $bd eq '<';
								++$bdc{f_2} if $bd eq '==' || $bd eq '!=';
							} @$_;
							# print Dumper(\%li)."\n";
							# print Dumper(\%bdc)."\n"  if  $bdc{f_1} > 1 || $bdc{f_2} > 1;
							# print '-' x 65  . "\n";
						} grep{ scalar(@$_) > 1 } values %li;
						$self->{irrelevant} = $bdc{f_1} > 1 || $bdc{f_2} > 1 ? 1 : 0;
					}
				}

				return(bless($self, $class));
			}
			sub RegAnz
			{
				my	$self	= shift;

				return $RegAnz;
			}	# ----------  end of subroutine RegAnz  ----------
			sub show
			{
				my	$self	= shift;
				my  @s = ();

				map{
					push(@s,  defined $_ ? $_ ? 'Y' : 'N' : '-');
				} @{$self->set};

				return join('', @s);

			}	# ----------  end of subroutine show  ----------
			sub setBed
			{
				my	$self	= shift;
				my	$Bed	= shift;
			}	# ----------  end of subroutine setBed  ----------
			sub setAkt
			{
				my	$self	= shift;
				my	$Akt	= shift;
			}	# ----------  end of subroutine setAkt  ----------
			sub analy
			{
				my	$self	= shift;
				my  $other = shift;
				my %count  = ();
				my $cmp1   = defined($self->complements) ? $self->complements : [$self->set];
				my $cmp2   = defined($other->complements) ? $other->complements : [$other->set];
				my  $c1    = scalar(@$cmp1);
				my  $c2    = scalar(@$cmp2);
				my $es     = 0;

				foreach my $e (@$cmp1, @$cmp2) { $count{join('', @$e)}++ }
				$es = scalar(grep{ $count{$_} > 1 } keys %count);
				# print "es $es / sc $c1 / oc $c2\n";

				return ($es, $c1, $c2);
			}	# ----------  end of subroutine analy  ----------
			sub kreuzen
			{
				my	$self  = shift;
				my  $other = shift;
				my  ($es, $sc, $oc) = $self->analy($other);

				return $es && $es < $oc && $es < $sc && !$self->irrelevant && !$other->irrelevant;
			}	# ----------  end of subroutine kreuzen  ----------
			sub greater
			{
				my	$self	= shift;
				my  $other = shift;
				my  ($es, $sc, $oc) = $self->analy($other);

				return $es == $oc && $sc > $es && join('', @{$self->akt}) eq join('', @{$other->akt}) && !$self->irrelevant && !$other->irrelevant;
			}	# ----------  end of subroutine greater----------
			sub smaller
			{
				my	$self  = shift;
				my  $other = shift;
				my  ($es, $sc, $oc) = $self->analy($other);

				return $es && $es == $sc && $sc < $oc && join('', @{$self->akt}) eq join('', @{$other->akt}) && !$self->irrelevant && !$other->irrelevant;
			}	# ----------  end of subroutine smaller----------
			sub equal
			{
				my	$self	= shift;
				my  $other = shift;
				my  ($es, $sc, $oc) = $self->analy($other);

				return $es && $es == $oc && $es == $sc && !$self->irrelevant && !$other->irrelevant;
			}	# ----------  end of subroutine equal  ----------
			sub kreuzValues
			{
				my	$self  = shift;
				my  $other = shift;
				my %count  = ();
				my $cmp1   = defined($self->complements) ? $self->complements : [$self->set];
				my $cmp2   = defined($other->complements) ? $other->complements : [$other->set];
				my @res    = ();

				foreach my $e (@$cmp1, @$cmp2) { $count{join('', @$e)}++ }
				map{
					push(@res, [split(//, $_)]); 
				} grep{ $count{$_} > 1 } keys %count;

				return grep{ ! RegSet->new({set => [@$_] , akt => $self->akt}, Nr => 0)->irrelevant } @res;
			}	# ----------  end of subroutine kreuzValues  ----------
			sub report
			{
				my	$self	= shift;
				my $bd = '';

				print "IRRELEVANT\n" if $self->irrelevant;
				if(!$self->irrelevant){
					print "Regel Nr.: $self->{Nr} ".$self->show."\n";
					for(my $i=0; $i <= $#$Bed; $i++ ){
						if(defined($self->{set}->[$i])){
							print "$self->{rsBed}->[$i]\n";
						}
					}
					print "-------------\n";
					for(my $i=0; $i <= @{$self->{akt}}-1; $i++ ){
						if($self->{akt}->[$i] =~ /\d+/){
							print "$Akt->[$i]\n";
						}   
					}
					print "\n";
				}
			}	# ----------  end of subroutine report  ----------	
			sub code
			{
				my	$self	= shift;
				my @bdary = ();
				my @akary = ();
				my %ba    = ();
				my $bd = '';

				for(my $i=0; $i <= $#$Bed; $i++ ){
					if(defined($self->{set}->[$i])){
						$bd = $Bed->[$i];

						$self->{set}->[$i] ? $bd =~ s/\# // : $bd =~ s/\# /nicht /;
						if(!$self->{set}->[$i]){
							$bd =~ s/ \< / \> /g;
							$bd =~ s/ \> / \< /g;
							$bd =~ s/ \=\= / \!\= /g;
						}
						push(@{$ba{'Bed'}}, $bd);
					}
				}
				for(my $i=0; $i <= @{$self->{akt}}-1; $i++ ){
					if($self->{akt}->[$i] =~ /\d+/){
						push(@{$ba{'Akt'}}, $Akt->[$i]);
					}   
				}

				return \%ba;
			}	# ----------  end of subroutine code  ----------
		}	# ----------  end of package RegSet  ----------

		{
			package RegTable;

			use strict;
			use base(qw(Class::Accessor));
			use Data::Dumper;

			RegTable->mk_accessors( qw(Bedingungen Aktionen sets else) );
			RegTable->mk_ro_accessors( qw(Fehlende_Regeln Rsets expReg) );

			sub new {
				my($class)  = shift;
				my($params) = @_;
				my($self)   = $class->SUPER::new($params);
				my %seen    = ();

				$RegSet::Bed = \@{$self->Bedingungen};
				$RegSet::Akt = \@{$self->Aktionen};

				map{ push(@{$self->{Rsets}}, RegSet->new({set => $_->[0] , akt => $_->[1]})) } @{$self->sets};
				# print Dumper($self->{Rsets})."\n";
				# die "Ok...\n";

				# map{ push(@{$self->{expReg}}, @{$_->complements} ) } grep{ defined($_->complements) } @{$self->Rsets};	
				foreach my $rs ( @{$self->Rsets} ){
					if(defined($rs->complements)){ 
						foreach my $cp (@{$rs->complements}){
							push(@{$self->{expReg}}, RegSet->new({set => $cp, akt => $rs->akt, Nr => $rs->Nr}));
						}
					} else {
						push(@{$self->{expReg}}, $rs);
					}
				} 
				# map{ push(@{$self->{expReg}}, $_->set ) } grep{ ! defined($_->complements) } @{$self->Rsets};
				map{ $seen{join('', @{$_->set})} = 1 } @{$self->{expReg}};
				map{ 
					push(@{$self->{Fehlende_Regeln}}, [@$_] ) if ! RegSet->new({set => $_, akt => $self->Rsets->[0]->akt, Nr => 0})->irrelevant ;
				} grep{ !$seen{join('', @$_)} } @{ ::turnTable(::complTbl(scalar(@{$self->Rsets->[0]->set}))) };

				# print Dumper($self->Rsets)."\n";
				# die "Ok...\n";

				return(bless($self, $class));
			}
			sub report
			{
				my	$self	= shift;

				map{ $_->report } @{$self->Rsets};
				# print '#' x 65  . "\n";
				# map{ $_->report } @{$self->expReg};
				print 'X' x 65  . "\n";
				foreach my $e (0..$#{$self->else}){
					next if $self->else->[$e] ne '1';

					print "sonst: $self->{Aktionen}->[$e]\n";
				}
				print 'X' x 65  . "\n";

				if( defined($self->Fehlende_Regeln) ){
#					my $ir = $#{$self->Fehlende_Regeln};
#					map{ --$ir if RegSet->new({set => [@$_] , akt => $self->else})->irrelevant } @{$self->Fehlende_Regeln};
#					if($ir > 0){
					print "\nFehlende Regeln:\n";
					print '-' x 50  . "\n";
					map{ RegSet->new({set => [@$_] , akt => $self->else})->report } @{$self->Fehlende_Regeln};
#					}				
				}


				for( my $x=0;$x < scalar(@{$self->Rsets})-1;$x++ ){
					my $r1 = $self->Rsets->[$x];

					for( my $y=$x+1;$y < scalar(@{$self->Rsets});$y++ ){
						my $r2 = $self->Rsets->[$y];

						if($r1 x $r2){
							my @krv = $r1->kreuzValues($r2);
							if(scalar(@krv) > 0){
								print '-' x 65  . "\n";
								print "Regel ".$r1->Nr." ($r1) und ".$r2->Nr." ($r2) überkreuzen sich in ".scalar(@krv)." Fällen:\n";
								print "    $_\n" foreach sort map{ join('', map{ $_ ? 'Y' : 'N' } @$_) } @krv;
								print "\n";
							}
						}
						print "Regel Nr.".$r1->Nr." ($r1) >  Regel Nr. ".$r2->Nr." ($r2)\n" if $r1 > $r2;
						print "Regel Nr.".$r1->Nr." ($r1) <  Regel Nr. ".$r2->Nr." ($r2)\n" if $r1 < $r2;
						print "Regel Nr.".$r1->Nr." ($r1) == Regel Nr. ".$r2->Nr." ($r2)\n" if $r1 == $r2;
					}
				}

			}	# ----------  end of subroutine report  ----------
			sub Code
			{
				no strict 'refs';

				my	$self	= shift;
				my  $param = shift;
				my  $loc   = shift;

				return sub { 
					my %pidx = ();
					my %lidx = ();
					my $BA;

					print 'code >>> my %pidx = ();'."\n";
					print 'code >>> my %lidx = ();'."\n";
					print 'code >>> my $BA;'."\n";
					
					map{ $pidx{$param->[$_]} = $_ } (0..$#$param);
					map{ $lidx{$loc->[$_]} = undef } (0..$#$loc);

					foreach my $rs (@{$self->Rsets}){ 
						$BA = $rs->code;
						my $res = 1;
						foreach my $b (@{$BA->{'Bed'}}){  
							map{ 
								$b =~ s/\b$_\b/\$\_\[$pidx{$_}\]/g;
							} @$param;
							$res &&= eval($b);
						}
						map{ $lidx{$_} = $_[$pidx{$_}] if !defined($lidx{$_}) && exists($lidx{$_}) } keys %pidx;

						if($res){
							print join("\n", @{$rs->code->{'Bed'}})."\n";
							foreach my $a (@{$BA->{'Akt'}}){  
								map{ 
									$a =~ s/\b$_\b/\$\_\[$pidx{$_}\]/g;
								} grep{ !exists($lidx{$_}) } @$param;
								map{ 
									$a =~ s/\b$_\b/\$lidx\{\'$_\'\}/g;
								} @$loc;
								eval($a);
								print "code >>>> $a\n";
								print '~' x 65  . "\n";
							}					  
							# last;
						}
					};

					my $notdef = scalar( grep{ ! defined($lidx{$_}) } keys %lidx );
					foreach my $e (0..$#{$self->else}){
						next if $self->else->[$e] ne '1';
						if( $notdef > 0 ){
							my $a = $self->{Aktionen}->[$e];
							map{ 
								$a =~ s/\b$_\b/\$lidx\{\'$_\'\}/g;
							} keys %lidx;
							eval($a);
							print "ELSE >>>> $a\n";
							print 'x' x 65  . "\n";
						}  
					}
					map{ print "$_ == $lidx{$_}\n" if defined($lidx{$_}); } sort keys %lidx;
				}
			}	# ----------  end of subroutine Code  ----------
		}	# ----------  end of package RegTable  ----------

# RegSet::setBed(['wenn PK', 'wenn zu schn.', 'wenn betr.']);
# 	my $rt = RegTable->new({Bedingungen => [
# 			'wenn # PK', 'wenn # zu schn.', 'wenn # betr.'],
# 			Aktionen => [
# 			'nichts', 'Verwarnung', 'Führsch. entz.'],
# 			sets     => [ 
# 			[[qw(1 1 -)] , [qw(- - 1)]] , 
# 			[[qw(1 - 1)] , [qw(- 1 -)]]
# 			# RegSet->new({set => [1 , '' , 1] , akt => [qw(- - 1)]}) , 
# 			# RegSet->new({set => [1 , 1   , 0] , akt => [qw(- 1 -)]})
# 			], 
# 			else => [qw(1 - -)]
# 		});
# 	my $rt = RegTable->new({
# 			Bedingungen => [
# 			'wenn Betriebsstätte # im Ausland ist',
# 			'wenn zum ausländischen Staat Doppelbest.abk. # besteht',
# 			'wenn Einkünfte # aus Gewerbebetrieb sind',
# 			'wenn Verlust sich nach inländischem Recht # ergibt',
# 			'wenn Verlust ohne Befreiung # geltend gemacht würde',
# 			'wenn Verlust positive Einkünfte in diesem Land # übersteigt',
# 			'wenn Verlustvorträge aus früheren Jahren # vorliegen',
# 			'wenn ausländische Vorschriften # dagegen sprechen'
# 			],
# 			Aktionen => [
# 			'dann Verlustbetrag vom Gesamtbetrag der Einkünfte abziehen',
# 			'dann Verrechnung mit anderen Einkünften durchführen',
# 			'dann Verlustvortrag vom Gesamtbetrag der Einkünfte abziehen',
# 			'dann keine Anwendung Par. 2a, Abs.3'			  
# 			],
# 			sets =>[[[qw(1 1 1 1 1 1 - 0)], [qw(1 - - -)]],
# 			        [[qw(1 1 1 1 1 0 - 0)], [qw(- 1 - -)]],
# 			        [[qw(1 1 1 - - - 1 0)], [qw(- - 1 -)]]],
# 			else => [qw(- - - 1)]
# 		});
		my $rt = RegTable->new({
				Bedingungen => [
				'x == y',
				'x > y',
				'abs(px2 - px1) > abs(py2 - py1)',
				'DBx > DBy',
				'DBx == x',
				'DBy == y',
				],
				Aktionen    => [
				'lfr = "--"', 
				'lfr = "SB"', 
				'lfr = "BB"', 
				'&::swap(\DBx, \DBy)',
				'DBx = x', 
				'DBy = y',
				],
				sets => [
				[[qw(- - - - 0 - )],[qw(- - - - 1 - )]],
				[[qw(- - - - - 0 )],[qw(- - - - - 1 )]],
				# [[qw(0 0 0 - - - )],[qw(- 1 - - - - )]],
				[[qw(0 1 1 - - - )],[qw(- 1 - 1 - - )]],
				[[qw(0 1 0 - - - )],[qw(- - 1 - - - )]],
				[[qw(0 0 1 - - - )],[qw(- - 1 1 - - )]],
				],
				else => [qw(1 - - 1 -)]
			});
		print "-----\n";
		$rt->report;
		print "\n";

		my $cd = $rt->Code([qw(x y px1 py1 px2 py2 DBx DBy)], [qw(lfr DBx DBy)]);

		&$cd(qw(100 70 20 20 300 3000 70 100));

# print Dumper($cd)."\n";


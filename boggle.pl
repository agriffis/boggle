#!/usr/bin/perl -w
# vim:sw=2

use strict;

#
# Global vars
# 

# These are the REAL cubes...
my (@CUBES) = ( [ qw( S E N I U E ) ],
		[ qw( P C A O S H ) ],
		[ qw( R H E W V T ) ],
		[ qw( G A N E A E ) ],
		[ qw( I Y D T T S ) ],
		[ qw( I E S O T S ) ],
		[ qw( L D I R X E ) ],
		[ qw( M U C I T O ) ],
		[ qw( R L D Y E V ) ],
		[ qw( B J B O O A ) ],
		[ qw( F F A P K S ) ],
		[ qw( Qu I U H N M ) ],
		[ qw( O A O T T W ) ],
		[ qw( G E N E H W ) ],
		[ qw( Y R E T T L ) ],
		[ qw( N H Z L R N ) ] );
my ($W, $H) = (shift @ARGV || 4, shift @ARGV || 4);
my ($SIDES) = $#{$CUBES[0]}+1;
my (@BOARD);

my ($DICTFILE) = "/usr/share/dict/words";
my ($MINLEN) = 4;
my (%WORDS);
my (%FOUND_WORDS);
my (@DIRECTIONS);

#
# Boggle routines
#

sub clear_screen { print "[2J" }

sub move_to($$) { print "[$_[0];$_[1]H" }

sub show_board {
  my ($xloc, $yloc) = (40-$W*2-1, 12-$H-1);
  clear_screen;
  move_to($yloc++, $xloc);
  print "+---" x $W, "+";
  for (my $i = 0; $i < $H; $i++) {
    move_to($yloc++, $xloc);
    print "|";
    for (my $j = 0; $j < $W; $j++) {
      printf(" %-2s|", $BOARD[$i*$W+$j]);
    }
    move_to($yloc++, $xloc);
    print "+---" x $W, "+"
  }
  print "\n";  # flush stdout
}

sub shuffle_board {
  my (@cubes) = ();
  for (my $i = 0; $i < ($W*$H) / ($#CUBES+1); $i++) {
    push @cubes, @CUBES;  # add multiple sets for a large board
  }
  @BOARD = ();
  for (my $i = 0; $i < $W*$H; $i++) {
    my ($c) = rand($#cubes + 1);
    my ($s) = rand($SIDES);
    push(@BOARD, (splice(@cubes,$c,1))->[$s]);
  }
}

#
# Search routines
#

sub load_dictionary {
  my ($firstchar) = '';
  local ($|) = 1;
  print "Loading $DICTFILE...\n";
  open(F, $DICTFILE) || die("$0: Can't open $DICTFILE: $!\n");
  for (grep /^[a-z]{$MINLEN}/o, <F>) { 
    chop; 
    # Do this first so we can short-circuit below
    if (substr($_,0,1) ne $firstchar) {
      $firstchar = substr($_, 0, 1);
      print "$firstchar";
    }
    # Add to hash
    $WORDS{$_} = 2;
    # Short circuit if first prefix is in hash
    s/.$//;
    next if (exists $WORDS{$_});
    $WORDS{$_} = 1;
    # Add remaining prefixes to hash
    while (s/.$// && length($_) >= $MINLEN) {
      $WORDS{$_} = 1 unless $WORDS{$_};
    }
  }
  print "\n";
  close(F);
}

sub search_board_r {
  my ($pos,$search_word,$boardref) = @_;
  $search_word .= $$boardref[$pos];
  if (length($search_word) >= $MINLEN) {
    return unless (exists $WORDS{$search_word});
    if ($WORDS{$search_word} == 2) {
      $FOUND_WORDS{$search_word} = 1;
    }
  }
  # make our own copy
  my (@board) = @$boardref;
  $board[$pos] = '';
  for my $dir (@{$DIRECTIONS[$pos]}) {
    my ($newpos) = $pos + $dir;
    search_board_r($newpos, $search_word, \@board) if ($board[$newpos]);
  }
}

sub load_directions {
  for (my $i = 0; $i < $H; $i++) {
    for (my $j = 0; $j < $W; $j++) {
      $DIRECTIONS[$i*$W+$j] = [];
      push @{$DIRECTIONS[$i*$W+$j]}, -1    if $j > 0;			# W
      push @{$DIRECTIONS[$i*$W+$j]}, -$W-1 if $j > 0 && $i > 0;		# NW
      push @{$DIRECTIONS[$i*$W+$j]}, -$W   if $i > 0;			# N
      push @{$DIRECTIONS[$i*$W+$j]}, -$W+1 if $j < $W-1 && $i > 0;	# NE
      push @{$DIRECTIONS[$i*$W+$j]}, +1    if $j < $W-1;		# E
      push @{$DIRECTIONS[$i*$W+$j]}, +$W+1 if $j < $W-1 && $i < $H-1;	# SE
      push @{$DIRECTIONS[$i*$W+$j]}, +$W   if $i < $H-1;		# S
      push @{$DIRECTIONS[$i*$W+$j]}, +$W-1 if $j > 0 && $i < $H-1;	# SW
    }
  }
}

sub search_board {
  my (@board) = @BOARD;
  # empty out FOUND_WORDS since it's global
  %FOUND_WORDS = ();
  # lowercase board since the dictionary is lowercase
  for (@board) { $_ = lc($_); }
  # start the recursive routine originating on each cube in turn
  for my $i (0..$#board) {
    search_board_r($i, '', \@board);
    #{ local ($|) = 1; print "$board[$i]"; }
  }
}

sub show_found {
  my ($minshowlen) = 4;  # $minshowlen < $IDXLEN is useless...
  my ($pat) = '^' . '[a-z]' x $minshowlen;
  open(M,"|fmt|more");
  print M join("\t", sort grep /$pat/o, keys %FOUND_WORDS), "\n";
  close(M);
}

#
# MAIN
#

load_dictionary;
load_directions;

#$| = 1;
#
#my ($starttime) = (times)[0];
#
#for (my $i = 0; $i < 100; $i++) {
#    shuffle_board;
#    search_board;
#    print ".";
#}
#print "\n";
#
#my ($stoptime) = (times)[0];
#
#print $stoptime - $starttime, "\n";
#
#__END__

do {
  shuffle_board;
  show_board;
  print "\n";
  search_board;
  print "\nPress Enter for solutions...\n";
  <STDIN>;
  show_found;
  print "\nPress Enter... (or EOF to quit)\n";
} while (<STDIN>);

#!/usr/bin/perl -w

use strict ;

{
  our $n = shift @ARGV ;

  for (my $i = 0 ; $i < $n ; $i++) {
    my $a = int(rand 256) ;
    my $b = int(rand 256) ;
    my $c = int(rand 256) ;
    my $d = int(rand 256) ;
    printf "%d.%d.%d.%d\n", $a, $b, $c, $d;
  }
}

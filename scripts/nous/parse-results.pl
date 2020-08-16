#!/usr/bin/env perl

use PerlLib::SwissArmyKnife;

my $contents = read_file('results.txt');
my $start = 0;
$contents =~ s/.*Loading clause searcher from edu\/stanford\/nlp\/models\/naturalli\/clauseSearcherModel\.ser\.gz\.\.\.done \[0\.18 seconds\]//sg;
my @triples;
my @ners;
foreach my $line (split /\n/, $contents) {
  if ($line =~ /\t/) {
    my $triple = [split /\t/, $line];
    push @triples, $triple;
    if ($triple->[2] =~ /^(PERSON|ORGANIZATION|LOCATION)$/) {
      push @ners, $triple;
    }
  }
}
print Dumper(\@triples);
# print Dumper(\@ners);

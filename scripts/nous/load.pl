#!/usr/bin/env perl

# TRY REPLACING THIS WITH MOJOLICIOUS UA

# use IAEC - persist things that can't be computed quickly or easily.

# time invocations.

use PerlLib::Cacher;
use PerlLib::SwissArmyKnife;
use PerlLib::ToText;
use Rival::Lingua::EN::Sentence qw(rival_get_sentences);

my $queue = [
	     'https://www.rug.nl/ocasys/rug/vak/show?code=LIX021M05',
	     'http://arademaker.github.io/blog/2017/02/22/projects.html',
	     'http://arademaker.github.io/about.html',
	    ];

my $totext = PerlLib::ToText->new();
my $cacher = PerlLib::Cacher->new();

while (scalar @$queue) {
  my $url = shift @$queue;
  $cacher->get($url);
  my $html = $cacher->content();
  my $res1 = $totext->ToText
    (
     String => $html,
     Type => 'HTML document text',
    );

  if ($res1->{Success}) {
    my @sentences;
    my $res2 = rival_get_sentences($res1->{Text});
    foreach my $sentence (@$res2) {
      $sentence =~ s/\s+/ /sg;
      push @sentences, $sentence if $sentence =~ /./;
    }
    WriteFile
      (
       File => '/var/lib/myfrdcsa/sandbox/nous-20190618/nous-20190618/TripleExtractor/examples/triple-extractor/triple-extractor-test.input',
       Contents => join("\n",@sentences),
      );
    system 'cd /var/lib/myfrdcsa/sandbox/nous-20190618/nous-20190618 && ./frdcsa.sh > /var/lib/myfrdcsa/codebases/minor/web-agent/scripts/nous/results.txt';
    system 'cd /var/lib/myfrdcsa/codebases/minor/web-agent/scripts/nous && ./parse-results.pl > final-results.dat';
  }
}

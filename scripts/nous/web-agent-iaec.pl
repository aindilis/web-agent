#!/usr/bin/env perl

use FRDCSA::IAEC;
use FRDCSA::IAEC::EdgeFunction;
use FRDCSA::IAEC::NodeDatumAndMetadatum;
use FRDCSA::IAEC::Datum;
use FRDCSA::IAEC::Metadatum;

use KBS2::Util;

use PerlLib::Cacher;

use Data::Compare;
use Data::Dumper;

$UNIVERSAL::debug = 0;
$UNIVERSAL::resources = {};

my $nodedatumandmetadatum = FRDCSA::IAEC::NodeDatumAndMetadatum->new
  (
   Datum => FRDCSA::IAEC::Datum->new(Datum => [
					       'https://www.rug.nl/ocasys/rug/vak/show?code=LIX021M05',
					      ]),
   Metadatum => FRDCSA::IAEC::Metadatum->new(Metadatum => [['isa',Var('?Input'),'string']]),
  );

sub IsStringP {
  my (@input) = @_;
  return scalar $input[0];
}

sub ProcessEffectForPredicate {
  my (%args) = @_;
  if (Compare($args{Result},[1])) {
    # update the metadata of the original
    my $metadatum_serialized = $args{NodeDatumAndMetadatum}->Metadatum->Serialize;
    my $res1 = $args{NodeDatumAndMetadatum}->Metadatum->ProcessMetadatumEffect
      (
       ReturnValue => 1,
       Method => $args{Method},
       Candidate => $args{Candidate},
      );
    if ($res1->{Success}) {
      delete $args{NodeDataAndMetadata}->{$args{NodeDatumAndMetadatum}->Datum->Serialize}{$metadatum_serialized};
      $args{NodeDatumAndMetadatum}->Metadatum($res1->{Metadatum});
      $args{NodeDataAndMetadata}->{$args{NodeDatumAndMetadatum}->Datum->Serialize}{$args{NodeDatumAndMetadatum}->Metadatum->Serialize} =
	$args{NodeDatumAndMetadatum};
    }
  } else {			# if (Compare($args{Result},[0])) {
    # update the metadata of the original
    my $metadatum_serialized = $args{NodeDatumAndMetadatum}->Metadatum->Serialize;
    my $res1 = $args{NodeDatumAndMetadatum}->Metadatum->ProcessMetadatumEffect
      (
       ReturnValue => 0,
       Method => $args{Method},
       Candidate => $args{Candidate},
      );
    if ($res1->{Success}) {
      delete $args{NodeDataAndMetadata}->{$args{NodeDatumAndMetadatum}->Datum->Serialize}{$metadatum_serialized};
      $args{NodeDatumAndMetadatum}->Metadatum($res1->{Metadatum});
      $args{NodeDataAndMetadata}->{$args{NodeDatumAndMetadatum}->Datum->Serialize}{$args{NodeDatumAndMetadatum}->Metadatum->Serialize} =
	$args{NodeDatumAndMetadatum};
    }
  }
}


sub ProcessMetadatumEffectForPredicate {
  my (%args) = @_;
  print Dumper({MyArgs => \%args}) if $UNIVERSAL::debug > 3;
  my $assertions = [];
  if (exists $args{ValueForTrue}) {
    # check if we succeeded, and if so, assert this
    if ($args{ReturnValue} == 1) {
      $assertions = [['assert',$args{ValueForTrue}]];
    } elsif ($args{ReturnValue} == 0) {
      $assertions = [['assert',['neg',$args{ValueForTrue}]]];
    } else {
      die "ouch\n";
    }
  }
  return
    {
     Success => 1,
     Assertions => $assertions,
    };
}

my $iaec = FRDCSA::IAEC->new
  (
   EdgeFunctions =>
   {
    isValidURLP => FRDCSA::IAEC::EdgeFunction->new
    (
     Name => 'isFilenameP',
     Precondition => sub { IsStringP(@_); },
     MetadatumPrecondition => [['isa',Var('?Input'),'string'],['unknown',['isa',Var('?Input'),'validURL']]],
     EdgeFunction => sub {
       require Regexp::Common;
       $_[0] =~ /$RE{URI}{HTTP}/;
     },
     Effect => sub {ProcessEffectForPredicate(@_)},
     MetadatumEffect => sub {
       ProcessMetadatumEffectForPredicate
	 (
	  ValueForTrue => ['isa',Var('?Input'),'validURL'],
	  @_,
	 ),
       },
    ),
    hasHTMLContent => FRDCSA::IAEC::EdgeFunction->new
    (
     Name => 'hasHTMLContent',
     Precondition => sub { IsStringP(@_); },
     MetadatumPrecondition => [['isa',Var('?Input'),'validURL'],['unknown',['hasHTMLContent',Var('?Input')]]],
     EdgeFunction => sub {
       if (! exists $UNIVERSAL::resources->{'PerlLib::Cacher'}) {
    	 require PerlLib::Cacher;
    	 $UNIVERSAL::resources->{'PerlLib::Cacher'} = PerlLib::Cacher->new();
       }
       $UNIVERSAL::resources->{'PerlLib::Cacher'}->get($_[0]);
       $UNIVERSAL::resources->{'PerlLib::Cacher'}->content();
     },
     Effect => sub {
       my (%args) = @_;
       my $nodedatumandmetadatum = FRDCSA::IAEC::NodeDatumAndMetadatum->new
    	 (
    	  Datum => FRDCSA::IAEC::Datum->new(Datum => $args{Result}),
    	  Metadatum => FRDCSA::IAEC::Metadatum->new(Metadatum => [['htmlContentHasURL',Var('?A'),$args{NodeDatumAndMetadatum}->Datum->Datum->[0]]]),
    	 );
       AddNodeDatumAndMetadatum
    	 (
    	  NodeDataAndMetadata => $args{NodeDataAndMetadata},
    	  NodeDatumAndMetadatum => $nodedatumandmetadatum,
    	 );
       ProcessEffectForPredicate(@_)
     },
     MetadatumEffect => sub {
       ProcessMetadatumEffectForPredicate
       	 (
	  @_,
       	  ValueForTrue => ['hasHTMLContent',Var('?Input')],
       	  ReturnValue => 1,
       	 ),
       },
    ),
    # htmlHasText => FRDCSA::IAEC::EdgeFunction->new
    # (
    #  Name => 'htmlHasText',
    #  Precondition => sub { IsStringP(@_); },
    #  MetadatumPrecondition => [['htmlContentHasURL',Var('?Input'),Var('?URL')],['unknown',['htmlHasText',Var('?Input')]]],
    #  EdgeFunction => sub {

    #    # if (! exists $UNIVERSAL::resources->{'PerlLib::Cacher'}) {
    #    # 	 require PerlLib::Cacher;
    #    # 	 $UNIVERSAL::resources->{'PerlLib::Cacher'} = PerlLib::Cacher->new();
    #    # }
    #    # $UNIVERSAL::resources->{'PerlLib::Cacher'}->get($_[0]);
    #    # $UNIVERSAL::resources->{'PerlLib::Cacher'}->content();
    #  },
    #  Effect => sub {
    #    my (%args) = @_;
    #    my $nodedatumandmetadatum = FRDCSA::IAEC::NodeDatumAndMetadatum->new
    # 	 (
    # 	  Datum => FRDCSA::IAEC::Datum->new(Datum => $args{Result}),
    # 	  Metadatum => FRDCSA::IAEC::Metadatum->new(Metadatum => [['htmlHasText',Var('?A')]]),
    # 	 );
    #    AddNodeDatumAndMetadatum
    # 	 (
    # 	  NodeDataAndMetadata => $args{NodeDataAndMetadata},
    # 	  NodeDatumAndMetadatum => $nodedatumandmetadatum,
    # 	 );
    #    ProcessEffectForPredicate(@_)
    #  },
    #  MetadatumEffect => sub {
    #    ProcessMetadatumEffectForPredicate
    #    	 (
    # 	  @_,
    #    	  ValueForTrue => ['hasHTMLContent',Var('?Input')],
    #    	  ReturnValue => 1,
    #    	 ),
    #    },
    # ),
   },
   NodeDataAndMetadataList =>
   [
    $nodedatumandmetadatum,
   ],
  );

my $candidates = $iaec->CollectCandidates
  (
   Method => 'AIProlog',
   NodeDatumAndMetadatum => $nodedatumandmetadatum,
  );
my $numcandidates = scalar keys %$candidates;
while ($numcandidates > 0) {
  print "#Candidates: <<<$numcandidates>>>\n" if $UNIVERSAL::debug > 3;
  $iaec->Fire
    (
     Method => 'AIProlog',
     Candidates => $candidates,
     NodeDatumAndMetadatum => $nodedatumandmetadatum,
    );
  $candidates = $iaec->CollectCandidates
    (
     Method => 'AIProlog',
     NodeDatumAndMetadatum => $nodedatumandmetadatum,
    );
  $numcandidates = scalar keys %$candidates;
  $iaec->ShowFactbases
    (
     Method => 'AIProlog',
    );
}

print Dumper($iaec) if $UNIVERSAL::debug > 3;
$iaec->ShowObjectsAndFactbases
  (
   Method => 'AIProlog',
  );

# my $candidates = $iaec->CollectCandidates
#   (
#    Method => 'AIProlog',
#    NodeDatumAndMetadatum => $nodedatumandmetadatum,
#   );
# my $numcandidates = scalar keys %$candidates;
# while ($numcandidates > 0) {
#   print "#Candidates: <<<$numcandidates>>>\n";
#   $iaec->Fire
#     (
#      Method => 'AIProlog',
#      Candidates => $candidates,
#      NodeDatumAndMetadatum => $nodedatumandmetadatum,
#     );
#   $candidates = $iaec->CollectCandidates
#     (
#      Method => 'AIProlog',
#      NodeDatumAndMetadatum => $nodedatumandmetadatum,
#     );
#   $numcandidates = scalar keys %$candidates;
# }



# # some things that need to be done - YASWI is too slow here.  We need
# # pengines integration, but that's blocking on this issue:
# # https://github.com/simularity/JavaPengine/issues/3

# # also our persistence is not very fast, maybe use data-integration
# # SWIPL MySQL ODBC integration to be faster, need to finish that

# # go through each file and directory

# # prove things that are true about it

# foreach my $filename (split /\n/, `ls ~/`) {
#   print "<$filename>\n";
#   Analyze
#     (
#      Data => '/home/andrewdo/Users_Interest_from_Social_Networks_SIGIR19.pdf',
#      Metadata => [
# 		  ['isa',Var('?DataPoint'),'filename'],
# 		  ['fileContains',['fileFn',Var('?DataPoint')],'researchPaper'],
# 		 ],
#     );
# }

# # have type prerequisites on tests
# # have expected timing on tests, worst-case, etc
# # have composite tests

# # have multiple answer types


# my $knowledge = [
# 		 "(implies (or (IsFileP ?Input) (IsDirP ?Input)) (ExistsP ?Input))",
# 		 "(implies (FilenameP ?Input) (and (propose-test IsDirectoryP ?Input) (propose-test DirTest ?Input)))",
# 		 "(implies (IsDirP ?Input) (queue-test DirTest ?Input))",
# 		];

# propose tests

sub AddNodeDatumAndMetadatum {
  my (%args) = @_;
  $args{NodeDataAndMetadata}->{$args{NodeDatumAndMetadatum}->Datum->Serialize}{$args{NodeDatumAndMetadatum}->Metadatum->Serialize} = $args{NodeDatumAndMetadatum};
}

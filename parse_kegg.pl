#!/gsc/bin/perl

use strict;
use warnings;
use IO::File;

#The kegg_db_file has details of all KEGG pathways. We just need to parse out and reformat the human ones
( scalar( @ARGV ) == 1 ) or die "Usage: perl $0 <kegg_db_file>\n";
my ( $kegg_db_file ) = @ARGV;

my $kegg_fh = IO::File->new( $kegg_db_file );
my @buffer = ();
my %pathways = ();
my ( $curr_path_id, $curr_data_type ) = ( '', '' );
while( my $line = $kegg_fh->getline )
{
  chomp( $line );
  $curr_path_id = $1 if( $line =~ m/^ENTRY\s+(\w+)\s+Pathway$/ );
  next if( $curr_path_id !~ m/^hsa/ ); #Skip non-human entries

  #Parse the data of this pathway entry and store it in a hash
  if( $line =~ m/^(\w*)\s+(.*)$/ )
  {
    $curr_data_type = $1 if( $1 );
    my $curr_data = $2;
    $curr_data =~ s/^H\d+\s+// if( $curr_data_type eq 'DISEASE' ); #Discard the Disease ID
    $curr_data =~ s/^D\d+\s+// if( $curr_data_type eq 'DRUG' ); #Discard the Drug ID
    if( $curr_data_type eq 'GENE' )
    {
      my ( $entrez_id, $gene_name ) = $curr_data =~ m/^(\d+)\s+(\S+)\s.*$/;
      next if( !defined $gene_name || $gene_name =~ m/\[KO:K\d+\]/ ); #A few entries have IDs but no names, ignore them
      $gene_name =~ s/(;|,)$//;
      $curr_data = "$entrez_id:$gene_name";
    }
    push( @{$pathways{$curr_path_id}{$curr_data_type}}, $curr_data ) if( $curr_data );
  }
}
$kegg_fh->close;

print "ID\tNAME\tCLASS\tGENES\tDISEASES\tDRUGS\tDESCRIPTION\n";
foreach my $path_id ( keys %pathways )
{
  print( "$path_id\t" );
  print((( defined $pathways{$path_id}{NAME} ) ? join( "|", @{$pathways{$path_id}{NAME}} ) . "\t" : "\t" ));
  print((( defined $pathways{$path_id}{CLASS} ) ? join( "|", @{$pathways{$path_id}{CLASS}} ) . "\t" : "\t" ));
  print((( defined $pathways{$path_id}{GENE} ) ? join( "|", @{$pathways{$path_id}{GENE}} ) . "\t" : "\t" ));
  print((( defined $pathways{$path_id}{DISEASE} ) ? join( "|", @{$pathways{$path_id}{DISEASE}} ) . "\t" : "\t" ));
  print((( defined $pathways{$path_id}{DRUG} ) ? join( "|", @{$pathways{$path_id}{DRUG}} ) . "\t" : "\t" ));
  print((( defined $pathways{$path_id}{DESCRIPTION} ) ? join( "|", @{$pathways{$path_id}{DESCRIPTION}} ) . "\n" : "\n" ));
}

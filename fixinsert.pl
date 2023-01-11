#!/usr/bin/env perl -w
###################################################
#
# fixinsert - Split insert statements and get
#             the maximum field lengths.
#
###################################################

my $pod2md = "pod2markdown.pl";	# Must be in $PATH

=head1 NAME

fixinsert - Split insert statements and get
            the maximum field lengths.

=head1 VERSION

Version 0.0.1

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2021 Matthias Nott (matthias.nott (at) sap.com).

Licensed under WTFPL.

=cut

###################################################
#
# Dependencies
#
###################################################

=head1 DEPENDENCIES

You need the following modules (which you can install
using like cpanm install module):

  Getopt::Long;
  Pod::Usage;

=cut

use strict;
use warnings;

binmode STDOUT, ":utf8";
use utf8;
use Getopt::Long;
use Pod::Usage;


my $help;
my $man;
my $doc;
my $file = $ARGV[$#ARGV];

my $field;
my $verbose;

#
# Handle Command Line Parameters
#
GetOptions(
    'f|field:s'		=> \$field,
    'v|verbose'		=> \$verbose,
	'h|?|help'		=> \$help,
	'man'			=> \$man,
	'doc'			=> \$doc,
);
pod2usage(1) if (defined $help);
pod2usage( -exitval => 0, -verbose => 2 ) if (defined $man);

if (defined $doc) {
	system("$pod2md < $0 >README.md");
	exit 0;
}

if (! defined $file) {
	die "Please specify a file name.\n";
}


#
# The actual program
#
my %cols;     # Hash holding columns and their lengths
my $mfl = 0;  # Maximum column name length, for output
my %vals;     # Unique values, for output

open(my $fh, '<:encoding(UTF-8)', $file) or die "Could not open file '$file' $!";

while (<$fh>) {
	chomp;
	my $insert_string = $_;
	my ($table, $fields, $values) = $insert_string =~ /^insert into (.*?) \((.*?)\) values \((.*?)\);$/;
	next if ! defined $values;

	#
	# Unsplit insert into strings into their values
	#
	$values =~ s/\',/\@a\@/g;
	$values =~ s/,\'/\@a\@/g;
	$values =~ s/\@a\@\'/\@a\@/g;
	$values =~ s/^\'//g;
	$values =~ s/\'$//g;
	$values =~ s/\@a\@ /\', /g;

	my @fields = split(',', $fields);
	my @values = split('@a@', $values);

	for my $i (0 .. $#values) {
		if (defined $verbose && defined $field && $fields[$i] eq $field) {
			$vals{$values[$i]} = "";
		}
		$mfl = $mfl < length($fields[$i]) ? length($fields[$i]) : $mfl;
		if (exists $cols{$fields[$i]}) {
			if ($cols{$fields[$i]} < length($values[$i])) {
				$cols{$fields[$i]} = length($values[$i]);
			}
		} else {
			$cols{$fields[$i]} = length($values[$i]);
		}
	}
}
close $fh;

# Print out the field lengths
for my $col (sort keys %cols) {
	next if defined $field and $col ne $field;
	printf("%${mfl}s : %5d\n", $col, $cols{$col});
}

# Print out the values
if (defined $field && keys %vals > 0) {
	print "\nValues:\n";
	foreach my $val (sort keys %vals) {
		print "$val\n";
	}
}






###################################################
#
# Documentation
#
###################################################


__END__

=head1 SYNOPSIS

./fixinsert.pl [options] abc.txt

If you run into an issue where you insert data into a database,
but your column layout has changed in the sense that your fields
become too short for the data that you are loading, you'll run
into error messages like this:

  Error: Executing Query:
  insert into bla ( field_1, field_2 ) values ('xy','z');
  DBD::mysql::st execute failed: Data too long for column 'field_1' ...

These error messages might be repeated if your program runs gracefully,
but the according rows won't end up in the database. The issue then
becomes to measure what actually is the colum that is incriminated.

Since you'll already have a whole screen full of such messages, this
program allows you to do just this:

  1. Select everything on the screen
  2. Paste that content to some file, e.g. abc.txt
  3. Run a command like this:

./fixinsert.pl -f field_1 abc.txt

If you omit the field name, you'll see the sizes for all fields
in all lines that were not inserted.


Command line parameters can take any order on the command line.

 Options:

   -field           the field to measure (alternatives: -f)
   -verbose         print out values     (alternatives: -v)
   -help            brief help message   (alternatives: ?, -h)
   -man             full documentation   (alternatives: -m)
   -doc             generate README.MD   (for submitting to Git)

=head1 OPTIONS

=over 8

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the manual page and exits.

=item B<-doc>

Use pod2markdown to recreate the documentation / README.md.
You need to configure your location of pod2markdown at the
top, if you want to do this (it's really an option for me,
only...)

=item B<-field>

If you specify the field to measure, only this field is
going to be printed.


=item B<-verbose>

If you specify the field to measure, only this field is
going to be printed, and if in addition to ask for the
program to run in verbose mode, it'll show the values
that that field had.


=back

=cut


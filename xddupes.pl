#!/usr/bin/perl
use utf8;
use strict;
use warnings;
use autodie;
use feature 'say';
use v5.34;
use Cwd;
use DBI;
use File::Basename;
use Getopt::Long;

=pod
                             _     _                       
                    __  ____| | __| |_   _ _ __   ___  ___ 
                    \ \/ / _` |/ _` | | | | '_ \ / _ \/ __|
                     >  < (_| | (_| | |_| | |_) |  __/\__ \
                    /_/\_\__,_|\__,_|\__,_| .__/ \___||___/
                                          |_|              
=head1 NAME 

    xdupes - Find and manage duplicate files

=head1 SYNOPSIS 

    xxdupes folder [-r] [-d] [-l]

=head1 DESCRIPTION

    This script finds duplicate files in the specified folder and optionally
    deletes them or creates symlinks to the original files.

=head1 OPTIONS

    -r      Recurse into subdirectories
    -d      Delete duplicates
    -l      Create symlinks to original files

=head1 AUTHOR

    Agustin Navarro

=head1 LICENSE

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

=head1 CHANGES :
 
  REF NO   VERSION  DATE     WHO     DETAIL
    0001   0.6.0  23-03-04   anp     documentation
    0002   0.7.0  24-03-05   anp     removed dbi database name
    0003   0.7.0  24-03-05   anp     remplaced md5sum by b3sum
    0004   0.7.1  25-02-09   anp     remplaced b3sum by sha3sum
    0005   0.8.0  25-02-10   anp     Deepseek Key Changes:
		1. **Command-line Argument Parsing**: Used `Getopt::Long` for better argument handling.
		2. **Code Refactoring**: Broke down large functions into smaller ones and improved variable names.
	0006   0.8.1  25-02-11   anp     Gemini Key Changes:
		1. **Improvent comments for better documentation.
	    2. **Integrate sole of the folder and file proceses.
        3. **Change some variable names for better clarity

=cut

our $VERSION = '0.8.1';

# Configuration variables
my $database = ""; # Database file (currently unused, but kept for potential future use)
my $driver   = "SQLite";
my $dsn      = "DBI:$driver:dbname=$database";
my $delete   = 0;
my $link     = 0;
my $recurse  = 0;
my $shasum   = "sha3sum -a 512 ";    # Command to calculate SHA512 checksums

# Counters for statistics
my $total_files     = 0;
my $duplicate_files = 0;
my $deleted_files   = 0;

# Get command-line options
GetOptions(
    'r|recurse' => \$recurse,
    'd|delete'  => \$delete,
    'l|link'    => \$link,
) or die "Usage: $0 <directory> [options]\n";

# Check for required directory argument
my $directory = shift(@ARGV) or die "No directory specified.\n";

# Handle "." as current directory
$directory = getcwd if $directory eq ".";

# Validate directory
die "Invalid directory: $directory\n" unless -d $directory;

# Add trailing slash if necessary
$directory .= "/" unless substr( $directory, -1, 1 ) eq "/";

# Database connection (using SQLite)
my $dbh = DBI->connect( $dsn, "", "", { RaiseError => 1, AutoCommit => 0 } )
  or die "Database connection failed: $DBI::errstr";

# Create the FILES table if it doesn't exist
$dbh->do(
    qq(
    CREATE TABLE IF NOT EXISTS FILES (
        SHA512 TEXT PRIMARY KEY NOT NULL,
        FILENAME TEXT NOT NULL
    )
)
);

# Prepare statements for efficiency
my $insert_statement =
  $dbh->prepare_cached('INSERT INTO FILES (SHA512, FILENAME) VALUES (?,?)')
  or die "Couldn't prepare insert statement: " . $dbh->errstr;

my $select_statement =
  $dbh->prepare_cached('SELECT FILENAME FROM FILES WHERE SHA512 = ?')
  or die "Couldn't prepare select statement: " . $dbh->errstr;

# Process the directory recursively
process_directory($directory);

# Print summary statistics
say
"Total files: $total_files, Total duplicates: $duplicate_files, Total deleted: $deleted_files";

# Disconnect from the database
# $dbh->disconnect;

exit(0);

# Subroutine to process a directory
sub process_directory {
    my ($dir) = @_;
    say "Entering $dir";

    opendir( my $dh, $dir ) or die "Could not open directory $dir: $!";
    my @files_and_dirs = readdir $dh;
    closedir $dh;

    foreach my $entry ( sort @files_and_dirs ) {
        next
          if $entry eq '.'
          or $entry eq '..'
          or $entry eq "lost+found";    # Skip special entries

        my $full_path = "$dir$entry";

        if ( -d $full_path && $recurse ) {
            process_directory("$full_path/")
              ;                         # Recursive call for subdirectories
        }
        elsif ( -f $full_path && $entry ne "xddupes.db" )
        {    # Process regular files, excluding the database
            process_file($full_path);
        }
    }
}

# Subroutine to process a file
sub process_file {
    my ($filename) = @_;
    print ".";    # Progress indicator

    $total_files++;

    my $sha = `$shasum "$filename"`;
    my ($sha512) = split( ' ', $sha );      # Extract the SHA512 hash

    $select_statement->execute($sha512)
      or die "Couldn't execute select statement: " . $select_statement->errstr;
    my ($original_filename) = $select_statement->fetchrow_array();

    if ( !$original_filename ) {

        # New file, insert into database
        $insert_statement->execute( $sha512, $filename ) or die $DBI::errstr;
        $dbh->commit                                     or die $dbh->errstr;
    }
    else {
        # Duplicate file found
        $duplicate_files++;
        say "\nDuplicate file: $filename --> $original_filename";

        if ($delete | $link) {
            unlink($filename) or die "Could not delete $filename: $!";
            $deleted_files++;
        }

        if ($link) {
            symlink( $original_filename, $filename )
              or die "Could not create symlink: $!";
        }
    }
}

#
#

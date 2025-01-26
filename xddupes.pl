#!/bin/perl
use utf8;
use strict;
use autodie;
use v5.34;

=pod

                       _                       
        __  ____  ____| |_   _ _ __   ___  ___ 
        \ \/ /\ \/ / _` | | | | '_ \ / _ \/ __|
        >  <  >  < (_| | |_| | |_) |  __/\__ \
        /_/\_\/_/\_\__,_|\__,_| .__/ \___||___/
                            |_|              


=head1 NAME 

    xxdupes folder r d l

=head1 SYNOPSIS 

    Target folder
    -r              Recurse
    -d              Delete duplicates
    -l              crate symlink

=head1 USAGE

=head1 DESCIPTION

=head1 OPTIONS

=head1 DIAGNOSTICS

=head1 EXIT STATUS

=head1 CONFIGURATION

=head1 DEPENDENCIES
        b3sum

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS
    The program finish with and an error related to the Sqlite data base.
    It have no impact in the program which otherwise runs perfect.

=head1 AUTHOR

=head1 LINCENSE AND COPYRIGHT 

=head1 VERSION

our $VERSION = qv('0.7.0');

 Date: Tue Mar  5 02:38:01 PM -04 2024

=head1 CHANGES :
 
  REF NO  VERSION    DATE      WHO     DETAIL
    0001   0.6.0  2023-03-04   anp     documentation
    0002   0.7.0  2024-03-05   anp     removed dbi database name
    0003   0.7.0  2024-03-05   anp     remplaced md5sum by b3sum

 
=head1 License
    This program is free software: you can redistribute it and/or modify it under the terms
    of the GNU General Public License as published by the Free Software Foundation, either
    version 3 of the License, or (at your option) any later version.
    This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
    without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
    See the GNU General Public License for more details.
    You should have received a copy of the GNU General Public License along with this program.
    If not, see <https://www.gnu.org/licenses/>. 
 

=cut

use Cwd;
use DBI;
use File::Basename;

# use File::Copy;

my $cdir;

# my $database = "xddupes.db";
my $database = "";

# my $date;
our $VERSION = q('0.7.0');
my $driver = "SQLite";
my $dsn    = "DBI:$driver:dbname=$database";
my $delete;
my $link;
my $recnum = 0;
my $recdel = 0;
my $recdup = 0;

# my $log;
my $par2;
my $par3;
my $password = "";
my $rdirectory;
my $recurse;
my $report;
my $userid = "";
my $vdirectory;
my $Repfh;
my $rc;

# $date = today();

# system("rm -f $database");

my $dbh = DBI->connect( $dsn, $userid, $password, { RaiseError => 1, AutoCommit => 0 } )
    or die $DBI::errstr;

# say "Opened database successfully\n";

my $stmt = qq(CREATE TABLE FILES
    (MD5  TEXT  PRIMARY KEY     NOT NULL,
    FILENAME           TEXT    NOT NULL););

my $rv = $dbh->do($stmt);

if ( $rv < 0 ) {
    say $DBI::errstr;
}
else {
    # say "Table created successfully\n";
}

my $insh = $dbh->prepare_cached('INSERT INTO FILES (MD5, FILENAME) VALUES (?,?)')
    or die "Couldn't prepare insertstatement: " . $dbh->errstr;

my $selh = $dbh->prepare_cached('SELECT FILENAME FROM FILES WHERE MD5 = ?')
    or die "Couldn't prepare select statement: " . $dbh->errstr;

unless (@ARGV) {
    die "No Directory To Report\n";
}

#  $#ARGV is the total number of arguments.  First argument is  $ARGV[0]

$rdirectory = shift(@ARGV);
unless ( -d $rdirectory ) {
    die "Invalid Directory specification";
}

#$report = "/home/anp/tmp/" . today() . "-xddupes.csv";
#open( $Repfh, ">", "$report" ) or die "Could not open the report file";

$par2 = shift(@ARGV);
if ( $par2 eq "r" ) {
    $recurse = "r";
}
if ( $par2 eq "d" ) {
    $delete = "d";
}

if ( $par2 eq "l" ) {
    $link = "l";
}

$par3 = shift(@ARGV);
if ( $par3 eq "d" ) {
    $delete = "d";
}

if ( $par3 eq "l" ) {
    $link = "l";
}

unless ( substr( $rdirectory, -1, 1 ) eq "/" ) {
    $rdirectory .= "/";
}

$cdir       = getcwd();
$vdirectory = basename($rdirectory);

$vdirectory .= "/";
say "\nEntering $rdirectory";
sdirectory( $vdirectory, $rdirectory );

system("sync");

# system("rm -f $database");

say "total files = ", $recnum, " total dup = ", $recdup, " total deleted = ", $recdel;

exit(0);

sub sdirectory {

    my $name;
    my $rdir2;
    my $rdir;
    my $vdir2;
    my $vdir;
    my @alldir;
    my $Dirfh;

    ( $vdir, $rdir ) = @_;

    # say "||2 || ", $vdir, " ||| ", $rdir, " |||";

    #say "Openning directory.. ", "$rdir";
    
    print "*";

    opendir( $Dirfh, "$rdir" ) or die "Could Not Open The Directory";
    @alldir = readdir $Dirfh;
    closedir($Dirfh);

    foreach my $name ( sort @alldir ) {

        print ".";


        if ( "$name" eq '.' or "$name" eq '..' or "$name" eq "lost+found" ) {
            next;
        }

        # say "||2a || ", $name;

        $rdir2 = $rdir . "$name";

        # say "||2c || ", $rdir2, " ||| ", $recurse;

        if ( -d "$rdir2" and $recurse eq "r" ) {
            $vdir2 = "$vdir" . $name . "/";
            $rdir2 = $rdir2 . "/";
            sdirectory( "$vdir2", "$rdir2" );
        }

        # say "||3 || ", $vdir, " ||| ", $rdir, " |||";

        if ( -f "$rdir2" ) {
            if ( "$name" eq "xddupes.db" ) {
                next;
            }

            srfile( "$rdir", "$name" );
        }

    }

    return;
}

sub srfile {

    my $file;
    my $filemd5;
    my $filename;
    my $rdir;
    my $tfilename;
    my $trashcmd;
    my $rows;
    my $sha;
    my $rest;

    ( $rdir, $file ) = @_;

    # say "$rdir", "$file";

    # say "||4 || ", $rdir, " ||| ", $file, " |||";

    # =======================================#
    # 1. check the md5 sum of the file
    # 2. check if is there a file with the same md5 sum
    # 3 if there is, optionally delete the file and or create a symlink to the original
    # 4 if there is not, create a new entry
    #

    $recnum += 1;
    $filename = qq[$rdir] . qq[$file];

    #say $filename;

    

    # $sha = `sha256sum \"$filename\"`;

    $sha = `b3sum \"$filename\"`;     #Alternate sum faster algorithm

    ( $filemd5, $rest ) = split( ' ', $sha );

    $selh->execute(qq[$filemd5])
        or die "Couldn't execute select statement: " . $selh->errstr;

    ($rows) = $selh->rows();

    ($tfilename) = $selh->fetchrow_array();

    #    if $tfilename in null, this is a new file and needs to be included in the data base
    #    otherwise is a duplicate and has to be deleted

    if ( "$tfilename" eq "" ) {

        my $rv = $insh->execute( qq[$filemd5], qq[$filename] ) or die $DBI::errstr;
        my $rc = $dbh->commit                                  or die $dbh->errstr;

    }

    else {

        $recdup += 1;

        print "\n";

        say "\n", "Duplicate file:", "$filename", "  -->  ", "$tfilename";

        #say $Repfh "Duplicate: ", "$filename", ";", "$tfilename";

        if ( $delete or "$link" ) {

            unlink("$filename") or die 'Could not delete "$filename"!\n';
            $recdel += 1;

        }

        if ("$link") {
            symlink( "$tfilename", "$filename" );

        }

        # say "Database file entry :  ", $rows, " ||| ", $filemd5, " ||| ",
        #    $filename, " ||| ", $tfilename;
    }

}

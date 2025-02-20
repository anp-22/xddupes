# Xddupes
                             _     _                       
                    __  ____| | __| |_   _ _ __   ___  ___ 
                    \ \/ / _` |/ _` | | | | '_ \ / _ \/ __|
                     >  < (_| | (_| | |_| | |_) |  __/\__ \
                    /_/\_\__,_|\__,_|\__,_| .__/ \___||___/
                                          |_|              

    Find and manage duplicate files


## Requirements
  * utf8
  * feature 'say'
  * v5.34
  * Cwd
  * DBI
  * File::Basename
  * Getopt::Long
## Running xddupes
To run xddupes

 xxdupes folder [-r] [-d] [-l]

    This script finds duplicate files in the specified folder and optionally
    deletes them or creates symlinks to the original files.

=head1 OPTIONS

    -r      Recurse into subdirectories
    -d      Delete duplicates
    -l      Create symlinks to original files

## License

This program is free software: you can redistribute it and/or modify it under the terms
    of the GNU General Public License as published by the Free Software Foundation, either
    version 3 of the License, or (at your option) any later version.
    This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
    without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
    See the GNU General Public License for more details.
    You should have received a copy of the GNU General Public License along with this program.
    If not, see <https://www.gnu.org/licenses/>.

Copyright (C) 2025 Agustin Navarro (agustin.navarro@gmail.com) 

# WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING

xddupes can quickly corrupt the system. Ensure it is run in a directory where you can errase duplicate files




#!/usr/local/bin/perl -w

#+
#  Name:
#     scb.pl

#  Purpose:
#     Generate listing of a Starlink source code file.

#  Language:
#     Perl 5

#  Description:
#     This script extracts the source code for a module in the USSC.  
#     It takes as an input value the name of the module, which
#     must be the key of an entry in the index dbm file generated by
#     scbindex.
#
#     It operates in two modes:
#        text:  prints the source file raw.
#        HTML:  prints the source code with HTML markup.
#
#     Normally, it will choose between the two modes according to whether 
#     it appears to have been called as a CGI program or not.  This can
#     be overridden to produce HTML output from the command line however.
#
#  Arguments:
#     $module.
#        Name of the module to retrieve.  This should be the key of one
#        of the entries in the index dbm file.  It is case sensitive,
#        but if it fails as entered, it will be tried capitalised as
#        well before being rejected.
#     $package (optional).
#        This argument provides a hint for which package the module may
#        be found in.  It is only used when there are multiple entries
#        in the index file for the key $module, to decide which to choose.
#
#     If invoked from the command line, then $module must be specified.
#     If invoked as a CGI script then if $module is specified an attempt
#     is made to retrieve that module.  If it is not, then a form is 
#     presented in which a module may be specified.
#
#     Arguments may be presented in ADAM style, either as 'arg=val' 
#     (which is what CGI makes them look like) or positionally determined.


#  Authors:
#     MBT: Mark Taylor (IoA, Starlink)
#     {enter_new_authors_here}

#  History:
#     25-AUG-1998 (MBT):
#       Initial revision.
#     {enter_further_changes_here}

#  Bugs:
#     {note_any_bugs_here}

#-

#  Directory locations.

$tmpbase = "/local/junk/scb";    # scratch directory
$tmpdir = "$tmpbase/$$";

#  Name of this program.

$self = $0;
$self =~ s%.*/%%;

#  Name of source code retrieval program.

$scb = $self;
$usage = "Usage: $self [-html]    <func-name> [<package>]\n"
       . "       $self [-html] -f <file-name> [<package>]\n";

#  Required libraries.

use Fcntl;
use Scb;
use FortranTag;
use CTag;
use Directory;

#  Declarations.

sub parse_args;
sub get_module;
sub query_form;
sub extract_file;
sub search_keys;
sub package_list;
sub output;
sub error;
sub header;
sub footer;
sub hprint;
sub quasialph;
sub demeta;

#  Determine whether we are being run as a CGI script, and take appropriate
#  action if so.

if (exists $ENV{'SERVER_PROTOCOL'}) {
   $cgi = 1;
   print "Content-Type: text/html\n\n";
   @ARGV = split '&', $ENV{'QUERY_STRING'};
}

#  Parse command line arguments.

($rarg, $rflag) = parse_args \@ARGV, qw/name package/;

#  Process flags.

$html = defined (delete ($rflag->{'html'})) || $cgi;
$exact = defined (delete ($rflag->{'exact'}));
error $usage if (%$rflag);

#  Process arguments.

$name = $rarg->{'name'} || '';
$package = $rarg->{'package'} || '';
$type = $rarg->{'type'} || '';

#  Initialise index objects containing locations of functions and files.

$func_index = Directory->new($func_indexfile, O_RDONLY);
$file_index = Directory->new($file_indexfile, O_RDONLY);

#  Read list of packages and tasks if it will be required.

if (!$name || $type eq 'regex') {
   my $pack;
   open TASKS, $taskfile or error "Couldn't open $taskfile";
   while (<TASKS>) {
      ($pack, @tasks) = split;
      $pack =~ s/:?$//;
      @{$tasks{$pack}} = @tasks;
   }
   close TASKS;
   @packages = sort keys %tasks;
}

#  Main processing.

if ($name && $type ne 'regex') {

#  Name argument has been supplied, so try to retrieve the requested file.
#  If a type ('file' or 'func') has been given, then try to match it in the 
#  appropriate index.  Otherwise try to match it in either index
#  (if the name contains a '.' try file first, else try func first).
#  For each type of match, try it exact first, but look for variants if
#  that fails - specifically, try appending an underscore to function 
#  names, and try lowercasing something which looks like a Fortran include.
#  By using the '||=' operator, once get_module has completed successfully,
#  no further calls are attempted.  If all attempts fail, exit with an
#  error.

   my $success = 0;
   my ($t, $n);
   my @types = $type ? ($type) 
                     : ($name =~ /\./ ? qw/file func/
                                      : qw/func file/);
   foreach $t (@types) {
      my @names = ($name);
      unless ($exact) {
         push @names, lc ($name) if ($t eq 'file' && $name =~ /^[A-Z0-9_]*$/);
         push @names, $name . "_" if ($t eq 'func' && $name !~ /_$/);
      }
      foreach $n (@names) {
         $success ||= get_module ($t, $n, $package);
      }
   }
   unless ($success) {
      error "Failed to find item $name",
         "This may be a result of a deficiency in the source
          code indexing program, or because the module you
          requested doesn't exist, or because the index 
          database <code>$func_indexfile</code> has become out of date.";
   }
}
elsif ($name && $type eq 'regex') {

#  Name has been supplied as a search term.

   if ($html) {
      header "$self: search for '" . demeta ($name) . "'";
      query_form $package;
      search_keys $name, $package;
      footer;
   }
   else {
      search_keys $name, $package;
   }

}
elsif (!$name) {

#  No name argument has been supplied.  Either present a form (HTML mode) 
#  or exit with a usage message (command-line mode).

   if ($html) {
      header $self;
      query_form $package;
      package_list $package;
      footer;
   }
   else {
      die $usage;
   }
}
else {
   error "Internal: program logic is wrong";
}

#  End

exit;



########################################################################
# Subroutines.
########################################################################


########################################################################
sub parse_args {

   my $rargv = shift;
   @default = @_;

   my (%arg, %flag);

#  Extract named arguments (format arg=value) and flags (format -flag).

   if (@$rargv) {
      for ($i = @$rargv - 1; $i>=0; $i--) {
         if ($rargv->[$i] =~ /(.*)=(.*)/) {
            $arg{$1} = $2;
            splice (@$rargv, $i, 1);
         }
         elsif ($rargv->[$i] =~ /^-(.*)/) {
            $flag{$1} = 1;
            splice (@$rargv, $i, 1);
         }
      }
   }

   while ($default = shift @default) {
      $arg{$default} ||= shift (@$rargv) || '';
   }

#  Decode HTTP-style hex encoded characters and spaces, and encode SGML 
#  metacharacters.

   foreach $key (keys %arg) {
      $arg{$key} =~ tr/+/ /;
      $arg{$key} =~ s/%(..)/pack("c",hex($1))/ge;
      $arg{$key} =~ s/</&lt;/g;
      $arg{$key} =~ s/>/&gt;/g;
   }

   return (\%arg, \%flag);
}


########################################################################
sub query_form {

#  CGI output of the program when no arguments have been specified.

#  Arguments.

   $package = shift;

#  Print form header.

   hprint "
      <h1>$self: Starlink Source Code Browser</h1>
      <form method=GET action='$self'>
   ";

#  Print query box for module.

   hprint "
      Name of item:
      <input name=name size=40 value=''>
      <br>
   ";

#  Print query box for type.

   my %radio;
   $radio{'func'}  = "<input type=radio name=type value='func'>";
   $radio{'file'}  = "<input type=radio name=type value='file'>";
   $radio{''}      = "<input type=radio name=type value=''>";
   $radio{'regex'} = "<input type=radio name=type value='regex'>";
   $radio{$type} =~ s/>/ checked>/;
   hprint "
      Type of item:
         $radio{'func'}&nbsp;Routine
         $radio{'file'}&nbsp;File
         $radio{''}&nbsp;Either
         $radio{'regex'}&nbsp;Search&nbsp;term
      <br>
   ";

#  Print query box for package.

   my $selected = $package ? '' : ' selected';
   hprint "
      Name of package (optional):
      <font size=-1>
      <select name=package>
      <option value=''$selected>Any
   ";
   for $pack (@packages) {
      $selected = $pack eq $package ? ' selected' : '';
      print "<option value='$pack'$selected>$pack\n";
   }
   print "</select></font>\n";

#  Print submission button and form footer.

   hprint "
      <br>
      <input type=submit value='Retrieve'>
      </form>
      <hr>
   ";
}


########################################################################
sub package_list {

   my $package = shift;


   if ($package) {

#     Give some indication of contents of package.

      print "<h2>$package</h2>\n";

      my @tasks = @{$tasks{$package}};
      my $sep = "<b>-</b>&nbsp;";

      if (@tasks) {

#        Print list of (maybe) tasks for selected package.

         hprint "
            <h3>Tasks</h3>
            The following appear to be tasks within package $package:
            <br>
            <dl> <dt> <br> <dd>
         ";
         my $module;
         foreach $module (sort @tasks) {
            $task = $module;
            $task =~ s/_$//;
            print "$sep<a href='$scb?$module&amp;$package#$module'>$task</a>\n";
         }
         print "</dl>\n<hr>\n";
      }

      if ($type =~ /^(func|regex|)$/) {

#        Go through list of modules from the selected package, grouping 
#        by prefix.

         my $loc;
         my (%modules, $mod, $prefix);
         while (($mod, $loc) = $func_index->each($package)) {
            $prefix = '';
            $prefix = $1 if ($mod =~ /^([^_]*_)./);
            push @{$modules{$prefix}}, $mod;
         }

         if (%modules) {

#           Print list of all modules in package.

            hprint "
               <h3>Routines</h3>
               The following routines (C and Fortran functions and subroutines)
               from the package $package are indexed:<br>
            ";
            print "<dl>\n";
            my ($prefix, $r_mods, $ignore);
            foreach $prefix (sort quasialph keys %modules) {
               print "<dt> $prefix <br>\n<dd>\n";
               foreach $mod (sort @{$modules{$prefix}}) {
                  if ($mod =~ /^(.*)&lt;t&gt;(.*)$/i) {
                     $ignore = "$1(" . join ('|', qw/i r d l c b ub w uw/) 
                               . ")$2";
                  }
                  if ($ignore) {
                     next if ($mod =~ $ignore);
                  }
                  else {
                     $ignore = undef;
                  }
                  print "$sep<a href='$scb?$mod&amp;$package#$mod'>$mod</a>\n";
               }
            }
            print "\n</dl>\n<hr>\n";
         }
      }

      if ($type =~ /^(file|regex|)$/) {

         my (%files, $file, $tarfile, $suffix);
         while (($file, $loc) = $file_index->each($package)) {
            $suffix = $tarfile = '';
            $tarfile = $1 if ($loc =~ m%([^/>#]+.tar)(?:\.[^/>#]*)?>[^/>#]+$%);
            $suffix = $1 if ($file =~ m%(\.[^/>#]+)$%);
            push @{$files{$suffix}}, $file;     #  Group by suffix.
            # push @{$files{$tarfile}}, $file;  #  Group by containing tar file.
         }
   
         if (%files) {

#           Print list of all files in package.

            hprint "
               <h3>Files</h3>
               The following files from the package are indexed:<br>
            ";
            print "<dl>\n";
            foreach $key (sort quasialph keys %files) {
               print "<dt> $key <br>\n<dd>\n";
               foreach $file (sort @{$files{$key}}) {
                  print 
                     "$sep<a href='$scb?$file&amp;$package&type=file'>",
                     "$file</a>\n";
               }
            }
            print "\n</dl>\n<hr>\n";
         }
      }

   }
   else {

#     Print list of all packages.

      hprint "
         <h2>Packages</h2>
         <dir compact>
      ";
      my $typesel = $type ? "type='$type'" : '';
      foreach $pack (@packages) {
         print "<li> ";
         print "<a href='$scb?package=$pack&$typesel'>$pack</a>\n";
      }
      print "</dir>\n";
   }

}
   

########################################################################
sub search_keys {

   my ($regex, $package) = @_;

   my (%match);
   my ($name, $loc, $pack, $index, $indtext);

   foreach $index (qw/file func/) {
      while (($name, $loc) = ${$index . '_index'}->each($package)) {
         if ($name =~ /$regex/o) {
            $pack = starpack $loc;
            $match{$index}{$pack}{$name} = $loc;
         }
      }
   }

   my $htregex = demeta $regex;
   print "\n<h2>Search results: $htregex</h2>\n";

   if (%match) {
      foreach $index (sort keys %match) {
         $indtext = {func => 'Routines', file => 'Files'}->{$index};
         if ($html) {
            print "\n<h3>$indtext:</h3>\n";
         }
         else {
            print "$indtext:\n";
         }
         foreach $pack (sort keys %{$match{$index}}) {
            print "<h4>$pack</h4>\n" if ($html && !$package);
            foreach $name (sort keys %{$match{$index}{$pack}}) {
               $loc = $match{$index}{$pack}{$name};
               if ($html) {
                  if ($index eq 'file') {
                     print
                        "<a href='$scb?$name&$package&$type=file'>",
                        "$name</a>",
                        "<br>\n";
                  }
                  elsif ($index eq 'func') {
                     print
                        "<a href='$scb?$name&$package&$type=func#$name'>",
                        "$name</a>",
                        "<br>\n";
                  }
               }
               else {
                  printf "%-20s => %s\n", $name, $loc;
               }
            }
         }
      }
   }
   else {
      print "No matches were found for the regular expression '$htregex'";
      print " in package <b>$package</b>" if $package;
      print ".<p>\n";
   }
      
}





########################################################################
sub quasialph {

#  Collation order for prefixes - same as ascii but with _ preceding 1.
#  This is useful because it allows 'FAC_' modules to come before 
#  'FAC1_' modules, where they belong.

   my ($na, $nb) = ($a, $b);
   $na =~ tr/_/!/;
   $nb =~ tr/_/!/;
   $na cmp $nb;
}


########################################################################
sub get_module {

#  This routine takes the name of a module, locates it using the index
#  dbm, and outputs it in an appropriate form.

#  Arguments.

   my $type = shift;          #  Type of module ('file' or 'func').
   my $module = shift;        #  Name of (checked) key in index file.
   my $package = shift;       #  Hint about which package contains module.

#  Get logical path name from database.  $locname is a global variable.

   $locname = undef;
   if ($type eq 'func') {
      $locname = $func_index->get($module, packpref => $package);
   }
   elsif ($type eq 'file') {
      $locname = $file_index->get($module, packpref => $package);
   }

#  Return with error status if no module of the requested name is indexed.

   return (0) unless ($locname);

#  Set up scratch directory.

   mkdir "$tmpdir", 0777;
   chdir "$tmpdir"  or error "Failed to enter $tmpdir";

#  Interpret the first element of the location as a package or symbolic
#  directory name.  Either way, change it for a logical path name.

   $locname =~ /^(.+)#(.+)/i;
   ($head, $tail) = ($1, $2);

   my ($file, $tarfile, $dir, $loc);
   if ($loc = $file_index->get("$head#")) {
      $file = ($loc =~ m%\.tar[^/>#]*$%) ? "$loc>$tail" : "$loc/$tail";
   }
   elsif (-d "$srcdir/$head") {
      $file = "$srcdir/$head/$tail";
   }
   elsif (defined ($tarfile = <$srcdir/$head.tar*>) && -f $tarfile) {
      $file = "$tarfile>$tail";
   }
   elsif ($head =~ /^INCLUDE$/i) {
      $file = "$incdir/$tail";
   }
   else {
      error "Failed to interpret location $locname",
         "Probably the index file $func_indexfile is outdated or corrupted.";
   }

#  Extract file from logical path.

   extract_file $file, $head;

#  Finished with STDOUT; by closing it here the CGI user doesn't have to
#  wait any longer than necessary (I think).

   close STDOUT;

#  Tidy up.

   rmrf $tmpdir;

#  Return successful exit code.

   return 1;

}

########################################################################
sub extract_file {

#+
#  Name:
#     extract_file

#  Purpose:
#     Locates or generates file given its logical pathname.

#  Language:
#     Perl 5

#  Invocation:
#     extract_file ($location, $package);

#  Description:
#     This routine, given a logical pathname, finds the file referred to
#     and outputs it.  It does this by calling itself recursively if
#     necessary to extract the named file from a tarfile (within a 
#     tarfile (within a tarfile...)).  When extracting from a tarfile,
#     the routine will check to see if the file already exists outside
#     the tarfile (which will be the case if the tarfile has been untarred
#     in place), in which case it will pick it up directly, and not 
#     bother to do the untarring itself.
#
#     On first entry, the logical pathname will start with a fully 
#     qualified pathname (starting with a '/'), but on subsequent
#     recursions, if we have extracted from a tar file to the current
#     (temporary) directory, it will start with a relative pathname.

#  Arguments:
#     $location = string.
#        Logical pathname of the file.
#     $package = string.
#        Hint about which package contains module.

#  Return value:
#     None.

#  Notes:

#  Authors:
#     MBT: Mark Taylor (IoA, Starlink)
#     {enter_new_authors_here}

#  History:
#     05-OCT-1998 (MBT):
#       Initial revision.
#     {enter_further_changes_here}

#  Bugs:
#     {note_any_bugs_here}

#-

#  Get arguments.

   my ($location, $package) = @_;

#  Parse logical pathname: 
#     $head is the directory containing the initial file
#     $tail is the name of the initial file in $head
#     $tarcontents is the file to extract from the initial file, if it
#        is a tar file
#     $rest is to $tarcontents as $tarcontents is to $location.

   $location =~ /^([^>]+)>?([^>]*)(>?.*)$/;
   ($initial, $tarcontents, $rest) = ($1, $2, $3);
   $initial =~ m%^(.*/)?([^/]+)$%;
   ($head, $tail) = ($1, $2);
   $head ||= '';

#  If $initial is not a tarfile, just output the file.

   if (!$tarcontents) {
      output $initial, $package;
   }

#  If required file exists outside named tarfile, use it directly.

   elsif (-f ($file = "$head$tarcontents")) {

#     If $file is a tarfile then recurse, else output file directly.

      if ($rest) {
         extract_file "$file$rest";
      }
      else {
         output $file, $package;
      }
   }

#  If required file doesn't exist, then extract it and recurse.

   else {
      tarxf "$head$tail", $tarcontents unless (-f $tarcontents);
      extract_file "$tarcontents$rest", $package;
      unlink $tarcontents;
   }
}



########################################################################
sub output {

#  Arguments.

   my $file = shift;          #  Filename of file to output.
   my $package = shift;       #  Hint about which package contains module.

#  Get file type.

   my ($ftype) = ($file =~ m%\.([^/.]*)$%);
   $ftype ||= '';

#  Open module source file.

   open FILE, $file 
      or error "Failed to open $file",
         "Probably the index file $func_indexfile is outdated or corrupted.";

#  Output appropriate header text.

   if ($html) {
      header $locname;
      print "<pre>\n" if ($html);
   }
   else {
      print STDERR "$locname\n";
   }

   my ($body, $name, @names, $include, $sub, $copyright);

   if ($html) {

#     Add SGML-like tags to source code.

      if ($ftype eq 'f' || $ftype eq 'gen') {
         $tagged = FortranTag::tag (join '', <FILE>);
      }
      elsif ($ftype eq 'c' || $ftype eq 'h') {
         $tagged = CTag::tag (join '', <FILE>);
      }     


#     Check tags, and remove those which fail to refer.

      if ($tagged) {
         my $inhref = 0;
         $tagged =~ s{(<[^>]+>)}{
            &{
               sub {
                  %tag = parsetag $1;
                  if (($tag{'Start'} eq 'a') && ($name = $tag{'href'})) {
                     my $href;
                     if ($name =~ /^INCLUDE-(.*)/) {
                        my $file = $1;
                        if ($file =~ /^[A-Z0-9_]*$/ && 
                           !$file_index->get($file)) {
                           $file =~ tr/A-Z/a-z/;
                        }
                        if ($file_index->get($file)) {
                           $href = "$scb?file=$file&amp;$package";
                        }
                     }
                     else {
                        $loc = $func_index->get($name);
                        if ($loc) {
                           if (index ($loc, $locname) >= 0) {
                              $href = "#$name";
                           }
                           else {
                              $href = "$scb?$name&amp;$package#$name";
                           }
                        }
                     }
                     if ($href) {
                        $inhref = 1;
                        return "<a href='$href'>";
                     }
                     else {
                        $inhref = 0;
                        return "<b>";
                     }
                  }
                  elsif ($tag{'End'} eq 'a') {
                     my $retval = $inhref ? '</a>' : '</b>';
                     $inhref = 0;
                     return $retval;
                  }
                  elsif (($tag{'Start'} eq 'a') && ($ftype eq 'gen') &&
                         ($tag{'name'} =~ /(.*)(&lt;t&gt;)(.*)/i)) {
                     my ($pre, $gen, $post) = ($1, $2, $3);
                     return join ('', map ("<a name='$pre$_$post'>",
                        ($gen, qw/i r d l c b ub w uw/)));
                  }
                  return $1;
               }
            }
         }ges;

         print $tagged;
      }
      else {

#        No tagging routine available; output raw text.

         while (<FILE>) {
            print;
         }

      }
   }

   else {

#     Output raw text to standard output.

      while (<FILE>) {
         print;
      }
   }

   close FILE;

#  Output appropriate footer text.

   print "</pre>\n" if ($html);
   if ($html && !$copyright) {
      my $year = 1900 + (localtime)[5];
      hprint "
         <hr><i>
         Copyright &copy; $year Central Laboratory of the Research Councils
         </i>
      ";
   }
   footer;

}


########################################################################
sub error {

#  This routine outputs an error message and exits with non-zero status.
#  It behaves differently according to whether the script is running in
#  cgi mode or from the command line.
#  The second argument is an optional wordy explanation of the first,
#  for explanation to users of the script of what might have gone wrong.

#  Arguments.

   my $message = shift;       # Terse error message text.
   my $more = shift;          # Verbose explanation of error.

   rmrf $tmpdir;

   if ($cgi) {
      header "Error";
      print "<h1>Error</h1>\n";
      hprint "<b>$message</b>\n";
      hprint "<p>\n$more\n" if $more;
      footer;
   }

#  Note in CGI mode this will probably log an error to the error_log.
#  This is intentional.

   die "$message\n";

}



########################################################################
sub header {

#  Arguments.

   my $title = shift;

   if ($html) {
      print "<html>\n";
      print "<head><title>", demeta ($title), "</title></head>\n";
      print "<body>\n";
   }
}


########################################################################
sub footer {
   print "</body>\n</html>\n" if $html;
}


sub demeta {

   my $string = shift;

   $string =~ s/&/&amp;/g;
   $string =~ s/>/&gt;/g;
   $string =~ s/</&lt;/g;

   return $string;
}

########################################################################
sub hprint {

#  Utility routine - this just prints a string after first stripping 
#  leading whitespace from each line.  Its only purpose is to
#  allow here-documents which don't mess up the indenting of the 
#  perl source.

   local $_ = shift;
   s%^\s*%%mg;
   print;
}

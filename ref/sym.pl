#!/usr/bin/perl -w
#------------------------------------------------------------------------------

use strict ;

use File::Find ;

#------------------------------------------------------------------------------

sub usage
{
  my $text = "" ;

  ( @_ > 0 ) && defined($_[0]) &&
    ( $text .= sprintf("\t\n\tError:  ". shift(@_)."\n",@_) ) ;

  $text .= "
	Usage:  sym <action>   [options] [arguments]
           as:  sym --list     [options] [ <directory> ... ]
           as:  sym --remove   [options] <file> [ <file> ]
           as:  sym --restore    [options] <file> [ <file> ]
            *:  sym --extract  [options] [ <directory> ... ] --- Not Yet Implemented

	  List (record) or restore file symlinks for a directory hierarchy.

	Actions:

	  -l | --list         List the file symlinks of '.' unless one or more
	                      other directories are specified.
	                      Include owner and group if '--owner' is specified.'
	
	  --remove            Remove the symlink files recorded in <file>.
	
	  --restore           Restore the file symlinks in <file> to '.' unless
	                      another root is specified using '--root'.
	                      Restore owner and group if '--owner' is specified.'
	
	  * -e | --extract    List CYGWIN symlinks from plain files '!symlink??<target-in-UTF8>'.
	                      Such plain files as restored from zip files from a BACKBLAZE restore.

          * !!! Not Yet Implemented !!!

	Options:

	  -h | --help         Print this usage information.

	  -v | --verbose      Print more verbose output, if any such is available.

	  -o | --out <file>   For LIST action, write symlinks to <file>.
	                      Meaningless for RESTORE action.

	  --overwrite         Overwrite files found where a symlink belongs.
	                      Only applicable for '--restore'.

	  * -n, --dry-run       Show symlinks that would be created.
	                      Only applicable for '--restore'.

	  * --owner           list/extract  - record link owner and group.
	                      restore         - after create, assign owner and group
	                                      to symlink itself (not the target).

	  -t | --type         list/extract  - record if target is a [d]irectory,
	                                      a [f]ile, [m]issing or [c]orrupt.
	                      restore         - if target type does not match,
	                                      do not create symlink.

	  * --native          restore         - create native NTFS symlnks
	                      list/extract  - no effect

	  * -d | --depth <#>  Only list/restore/extract up to hierarchy depth <#>.

	Examples :
	
         # Save symlinks from the current directory downward :
	  sym --list --out /tmp/symlinks.txt

         # Save symlinks from {src,build,lib} and downward :
	  sym --list --out /tmp/symlinks.txt src build lib

         # Remove the recorded symlinks :
	  sym --remove /tmp/symlinks.txt

         # Restore the recorded symlinks :
	  sym --restore /tmp/symlinks.txt

         # Restore the recorded symlinks to the specified root :
	  sym --restore --root /home/new-user /tmp/symlinks.txt

       - Also save owner and group info :

         # Save symlinks from the current directory downward :
	  sym --list --owner --out /tmp/symlinks.txt

         # Save symlinks from {src,build,lib} and downward :
	  sym --list --owner --out /tmp/symlinks.txt src build lib

         # Remove the recorded symlinks :
	  sym --remove /tmp/symlinks.txt

         # Restore the recorded symlinks :
	  sym --restore --owner /tmp/symlinks.txt

         # Restore the recorded symlinks to the specified root :
	  sym --restore --owner --root /home/new-user /tmp/symlinks.txt

	" ;

  $text =~ s/^\t//g ;
  $text =~ s/\n\t/\n/g ;

  my $fh = ( @_ > 0 ) ? *STDERR : *STDOUT ;

  print $fh $text ;

  exit ( @_ > 0 ) ;
}

#------------------------------------------------------------------------------

sub main
{
  my ($config,@argv) = options ( @_ ) ;

  if ( $config->{root} ne '.' ) {
    chdir($config->{root}) or
      fatal("Unable to move to directory '%s' - %s\n",$config->{root},$!);
  }

  ($config->{action})->($config,@argv);
}

#------------------------------------------------------------------------------

sub options
{
  my @argv = @_ ;

  my $config = { root => '.', action => undef, overwrite => 0, owner => 0, type => 0 } ;
  
  #----------------------------------------------------------------------------

  ( @argv > 0 ) ||
    usage("neither action nor any other argument specified.");

  my $action = shift @argv ;

  ( $action =~ /^(-l|--list)$/ ) &&
    ( $config->{action} = \&sym_list ) ;

  ( $action =~ /^(--remove)$/ ) &&
    ( $config->{action} = \&sym_remove ) ;

  ( $action =~ /^(--restore)$/ ) &&
    ( $config->{action} = \&sym_restore ) ;

  defined($config->{action}) ||
    usage("Unrecognized action '%s' - aborting.",$action);

  #----------------------------------------------------------------------------

  while ( ( @argv > 0 ) && ( $argv[0] =~ /^[-]./ ) )
  {
    my $option = shift @argv ;

    # printf STDERR "option:  %s\n", $option ;

    ( $option =~ /^(-h|--help)$/ ) &&
      usage();

    if ( $option =~ /^(-v|--verbose)$/ ) {
      $config->{verbose} ++ ;
      next ;
    }

    if ( $option =~ /^(--root)$/ ) {
      ( @argv <= 0 ) &&
        usage("Option '$option' found without directory argument (<dir>).") ;
      defined($config->{root}) &&
        usage("Option '$option' specified more than once.") ;
      $config->{root} = shift @argv ;
      next ;
    }

    if ( $option =~ /^(-o|--out)$/ ) {
      ( @argv <= 0 ) &&
        usage("Option '$option' found without output file argument (<file>).") ;
      defined($config->{output}) &&
        usage("Option '$option' specified more than once.") ;
      $config->{output} = shift @argv ;
      next ;
    }

    if ( $option =~ /^(--overwrite)$/ ) {
      $config->{overwrite} = 1 ;
      next ;
    }

    if ( $option =~ /^(--owner)$/ ) {
      $config->{owner} = 1 ;
      next ;
    }

    if ( $option =~ /^(-t|--type)$/ ) {
      $config->{type} = 1 ;
      next ;
    }

    usage("Unrecognized option '$option'.") ;
  }

  defined($config->{root}) ||
    ( $config->{root} = '.' ) ;

  ( $config, @argv ) ;
}

#------------------------------------------------------------------------------            

sub warning
{
  print STDERR sprintf("error:  ".shift(@_)."\n",@_) ;
}

#------------------------------------------------------------------------------

sub fatal
{
  print STDERR sprintf("error:  ".shift(@_)."\n",@_) ;
  exit 1 ;
}

#------------------------------------------------------------------------------
{

  my $config = undef ;

  #	  -t | --type         list/extract  - record if target is a [d]irectory,
  #	                                      a [f]ile, [m]issing or [c]orrupt.
  sub target_type
  {
    my ( $target ) = @_ ;

    ( defined($target) && length($target) ) ||
      return 'c' ;					# corrupt

    ( -e $target ) ||
      return 'm' ;					# missing

    ( -d $target ) &&
      return 'd' ;				        # directory

    return 'f' ;					# file
  }

  #----------------------------------------------------------------------------
  
  sub sym_list_wanted
  {
    return unless ( defined($_) && ( -l $_ )  ) ;

    ( my $target = readlink($_) ) ||
      warning("Unable to read symlink target value for '%s' - %s",$File::Find::name,$!);

    my $fh = $config->{out} ;

    my $type = '' ;
    ( $config->{type} ) &&
      ( $type = target_type($target) . ' : ' ) ;
    
    printf $fh "%s%s : %s\n", $type, $File::Find::name, $target || '' ;
  }

  #----------------------------------------------------------------------------

  sub sym_list
  {
    $config = shift @_ ;

    my @dirs = @_ ;

    ( @dirs > 0 ) ||
      ( @dirs = ( '.' ) ) ;

    if ( defined($config->{output}) ) {
      open(my $fh,"> $config->{output}") ||
	fatal("Unable to create/write output file '%s' - $!",$config->{output});
      $config->{out} = $fh ;
    } else {
      $config->{out} = \*STDOUT ;
    }

    map { find ( \&sym_list_wanted, $_ ) } @dirs ;

    defined($config->{out}) &&
      close $config->{out} ;

    0 ;
  }
}

#------------------------------------------------------------------------------

sub sym_restore
{
  my ( $config, @files ) = @_ ;

  map { sym_restore_worker($config,$_) } @files ;

  0 ;
}

#------------------------------------------------------------------------------

sub sym_restore_worker
{
  my ( $config, $file ) = @_ ;

  # config ...

  open(SLIST,"< $file") ||
    die "unable to open symlink file $file:  $!";

  my $status ;

  # [ <type> : ] <symlink> : <target>
  
  my ( $type, $symlink, $target ) ;
  
  while ( <SLIST> ) {

    chomp($_) ;

    next if ( $_ =~ /^#/ ) ;
    # printf "%s\n", $_ ;

    my @values = split(/[ ]:[ ]/,$_) ;

    ( @values > 2 ) &&
      ( $type = shift @values ) ;
    ( $symlink, $target ) = @values ;

    if ( $config->{type} ) {
      my $type_now = target_type($target) ;
      if ( $type != $type_now ) {
	warning("Target type mismatch, expected '%s', found '%s' for '%s'"
		, $type, $type_now, $target || '' ) ;
	next ;
      }
    }

    # printf "%s\n", $_ ;
    if ( -l $symlink || -e $symlink ) {
      # printf ": exists '%s'\n", $symlink ;
      next unless ( $config->{overwrite} ) ;
      if ( unlink($symlink) == 0 ) {
	warning("Unable to remove existing symlink file '%s' - %s",$symlink,$!);
	next ;
      }
    }
	
    printf "%s : '%s'\n", $symlink, $target || '' ;
    symlink($target,$symlink) ||
	warning("Unable to create symlink '%s' for '%s' - %s",$symlink,$target,$!);
  }
  
  close SLIST ;

  0 ;
}

#------------------------------------------------------------------------------

sub sym_remove
{
  my ( $config, @files ) = @_ ;

  map { sym_remove_worker ( $config, $_ ) } @files ;

  0 ;
}

#------------------------------------------------------------------------------

sub sym_remove_worker
{
  my ( $config, $file ) = @_ ;

  # config ...

  open(SLIST,"< $file") ||
    die "unable to open symlink file $file:  $!";

  my $status ;

  # [ <type> : ] <symlink> : <target>
  
  my ( $type, $symlink, $target ) ;
  
  while ( <SLIST> ) {

    chomp($_) ;

    my @values = split(/[ ]:[ ]/,$_) ;

    ( @values > 2 ) &&
      ( $type = shift @values ) ;
    ( $symlink, $target ) = @values ;

    printf "%s : '%s'\n", $symlink, $target || '' ;
    if ( ! -l $symlink ) {
      warning("'%s' symlink file is missing",$symlink);
      next ;
    }
	
    printf "%s : '%s'\n", $symlink, $target || '' ;
    ( unlink($symlink) == 0 ) &&
      warning("Unable to remove existing symlink file '%s' - %s",$symlink,$!);
  }
  
  close SLIST ;

  0 ;
}

#------------------------------------------------------------------------------

$| = 1 ; exit main @ARGV ;

#------------------------------------------------------------------------------

__END__


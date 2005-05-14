package Posy::Plugin::GenStatic;
use strict;

=head1 NAME

Posy::Plugin::GenStatic - Posy plugin for generating static pages.

=head1 VERSION

This describes version B<0.96> of Posy.

=cut

our $VERSION = '0.96';

=head1 SYNOPSIS

    require Posy;

    Posy->import(@plugins);
    Posy->run(%args);

=head1 DESCRIPTION

This plugin replaces the 'run' method in order to generate all
known pages of a given type.  It replaces the 'get_path_info' helper method.
It also provides a new action 'set_outfile', which will automatically be
added to the list of actions before 'render_page'.

It expects extra parameters:

=over

=item flavours=>\@flavours

The flavours to generate.  If this is not given, uses the default flavour.

=item static_dir=>I<directory>

The directory where the static pages are to be put.

=item gen_type=>I<string>

A comma-separated list of the type of pages to generate.

=over

=item init

Run the given actions, but produce no output.  This is useful for
things like setting up the file indexes before doing a full run.

=item path

Generate one file, given by the path.

=item entry

Generate all entry files.

=item category

Generate all category files.

=item chrono

Generate all chrono files.

=item other

Copy all "other" non-configuration files from the data dir over
to the static dir.

=back

=item gen_match=>I<regex>

If B<gen_type> is entry,category or chrono, then only generate those
files which match.

=item verbose=>1

Be verbose?

=back

=cut

use File::Spec;
use File::Copy;

=head1 CLASS METHODS

=head2 run

Posy->run(%args);

This version of run goes through the file list, creates a "fake"
path for the files wanted to generate, and calls the core
do_actions for each one.

=cut
sub run {
    my $class = shift;
    my %args = (@_);

    my $gen_type = delete $args{gen_type};
    my $gen_match = delete $args{gen_match};
    my $verbose = $args{verbose};
    my $static_dir = $args{static_dir};
    my @flavours = @{$args{flavours}} if defined $args{flavours};
    delete $args{flavours} if defined $args{flavours};

    # First, read in all the file info into a hash.
    # Make a new Posy object, set the actions to read
    # the information we want, save that information,
    # and then re-init the object to have the caller's
    # desired actions.
    my $self = $class->new(%args);
    $self->init();

    #
    # Change the actions
    #
    my @actions = @{$self->{actions}};

    # make some temporary actions to set {files} etc
    $self->{actions} = [qw(init_params parse_path set_config index_entries)];

    # add 'set_outfile' to the passed-in actions
    for (my $i=0; $i < @actions; $i++)
    {
	# if it's already there, exit the loop
	if ($actions[$i] eq 'set_outfile')
	{
	    last;
	}
	# otherwise put it just before 'render_page'
	if ($actions[$i] eq 'render_page')
	{
	    splice(@actions,$i,0, ('set_outfile'));
	    last;
	}
    }

    # now go and get the files and categories list
    $self->do_actions();
    my @files = keys %{$self->{files}};
    my @categories = keys %{$self->{categories}};

    my $default_flavour = $self->{config}->{flavour};
    # save the path
    my $orig_path = $self->param('path');
    $self->param('path'=>'');

    # run init if need be
    if ($gen_type =~ /init/)
    {
	# run the actions without generating anything
	# send the output to /dev/null
	$self->{params}->{path} = $orig_path;
	$self->{outfile} = File::Spec->devnull();
	@{$self->{actions}} = @actions;
	print STDERR "INIT start\n" if $verbose;
	$self->do_actions();
	print STDERR "INIT end\n" if $verbose;
	# if we are only doing init, then return.
	if ($gen_type eq 'init')
	{
	    return 1;
	}
    }

    if ($gen_type =~ /path/ and $orig_path)
    {
	# generate one file, the passed-in path
	$self->{_path} = $orig_path;
	my @path_split = split('/', $orig_path);
	@{$self->{actions}} = @actions;
	$self->do_actions();
	# if we are only doing path, then return.
	if ($gen_type eq 'path')
	{
	    return 1;
	}
    }
    # make sure the static directory exists!
    if (!-e $static_dir)
    {
	mkdir $static_dir;
    }
    #
    # copy over all the non-config "other" files
    #
    if ($gen_type =~ /other/)
    {
	while (my ($file, $cat_id) = each(%{$self->{others}}))
	{
	    if ($file !~ /config$/)
	    {
		# make the directory if need be
		my @cat_split = split('/', $cat_id);
		my @dir_parts = ();
		foreach my $dir_part (@cat_split)
		{
		    push @dir_parts, $dir_part;
		    my $fullcat = File::Spec->catdir($static_dir, @dir_parts);
		    if (!-e $fullcat)
		    {
			mkdir $fullcat;
			print STDERR "DIR: $fullcat\n" if $verbose;
		    }
		}
		# copy the file
		my $rel_file = File::Spec->abs2rel($file, $self->{data_dir});
		my $dest_file = File::Spec->rel2abs($rel_file, $static_dir);
		print STDERR "COPY: $file -> $dest_file\n" if $verbose;
		copy($file, $dest_file);
	    }
	}
	# if we are only doing other, then return.
	if ($gen_type eq 'other')
	{
	    return 1;
	}
    }

    # Assert: gen_type probably includes entry, category or chrono

    #
    # Make the list of paths to generate
    #
    my @paths = ();
    if ($gen_type =~ /category/)
    {
	push @paths,
	    (grep {(!$gen_match || ($gen_match && /$gen_match/o))} sort @categories);
    }
    if ($gen_type =~ /entry/)
    {
	push @paths,
	    (grep {(!$gen_match || ($gen_match && /$gen_match/o))} sort @files);
    }
    if ($gen_type =~ /chrono/)
    {
	# find out all the dates
	my %dates = ();
	foreach my $key (@files)
	{
	    my $chrono_path = join('/',
		$self->{files}->{$key}->{date}->[0], # year
		$self->{files}->{$key}->{date}->[1], # month
		$self->{files}->{$key}->{date}->[2]); # day
	    $dates{"$chrono_path"} = $self->{files}->{$key}->{date};
	}
	push @paths,
	    (grep {(!$gen_match || ($gen_match && /$gen_match/o))} sort keys %dates);
    }

    #
    # generate the files
    #
    push @flavours, $default_flavour if (!@flavours);
    foreach my $flavour (@flavours)
    {
	foreach my $path (@paths)
	{
	    @{$self->{actions}} = @actions;
	    $self->{_path} = "$path.$flavour";
	    # to side-step memory leaks, fork this
	    my $child_pid;
	    if (!defined($child_pid = fork())) {
		warn "cannot fork: $!";
		# do the actions anyway
		$self->do_actions();
	    } elsif ($child_pid) {
		# I'm the parent
		waitpid($child_pid,0);
	    } else {
		# I'm the child
		$self->do_actions();
		exit;
	    } 
	}
    }

} # run

=head1 Flow Action Methods

Methods implementing actions.  All such methods expect a
reference to a flow-state hash, and generally will update
either that hash or the object itself, or both in the course
of their running.

=head2 set_outfile

Calculates the outfile name from the current path, if $self->{outfile}
is not already set.
Creates directories if the directories don't already exist.

=cut
sub set_outfile {
    my $self = shift;
    my $flow_state = shift;

    return if $self->{outfile};

    my $static_dir = $self->{static_dir};
    my $verbose = $self->{verbose};

    # make the directories
    my @cat_split = split('/', $self->{path}->{cat_id});
    my $fullcat = File::Spec->catdir($static_dir, @cat_split);
    if (!-e $fullcat)
    {
	mkdir $fullcat;
	print STDERR "DIR: $fullcat\n" if $verbose;
    }
    if ($self->{path}->{type} eq 'chrono')
    {
	# year
	my $fulldatepath =
	    File::Spec->catdir($static_dir, $self->{path}->{year});
	if (!-e $fulldatepath)
	{
	    mkdir $fulldatepath;
	    print STDERR "DIR: $fulldatepath\n" if $verbose;
	}
	# month
	$fulldatepath =
	    File::Spec->catdir($static_dir, $self->{path}->{month});
	if (!-e $fulldatepath)
	{
	    mkdir $fulldatepath;
	    print STDERR "DIR: $fulldatepath\n" if $verbose;
	}
	# day
	$fulldatepath =
	    File::Spec->catdir($static_dir, $self->{path}->{day});
	if (!-e $fulldatepath)
	{
	    mkdir $fulldatepath;
	    print STDERR "DIR: $fulldatepath\n" if $verbose;
	}
    }

    # calculate the outfile name
    my $outfile = '';
    my $flavour = $self->{path}->{flavour};
    if ($self->{path}->{type} =~ /chrono/)
    {
	$outfile = File::Spec->catfile($static_dir,
	    $self->{path}->{year},
	    $self->{path}->{month},
	    $self->{path}->{day},
	    "index.$flavour");
    }
    elsif ($self->{path}->{basename})
    {
	$outfile = File::Spec->catfile($static_dir, @cat_split,
	    $self->{path}->{basename} . '.' . $flavour);
    }
    elsif ($self->{path}->{type} =~ /category/)
    {
	$outfile = File::Spec->catfile($static_dir, @cat_split, "index.$flavour");
    }

    $self->{outfile} = $outfile;
    print STDERR "outfile=", $self->{outfile}, "\n" if $self->{verbose};
} # set_outfile

=head1 Helper Methods

Methods which can be called from within other methods.

=head2 get_path_info

    my $path = $self->get_path_info();

Returns the current "path info" (to be parsed by 'parse_path')

=cut

sub get_path_info {
    my $self = shift;

    my $path_info = $self->{_path} || $self->param('path');

    return $path_info;
} # get_path_info

=head1 REQUIRES

    Posy
    Posy::Core
    File::Spec
    File::Copy

    Test::More

=head1 SEE ALSO

perl(1).
posy_static

=head1 BUGS

Please report any bugs or feature requests to the author.

=head1 AUTHOR

    Kathryn Andersen (RUBYKAT)
    perlkat AT katspace dot com
    http://www.katspace.com

=head1 COPYRIGHT AND LICENCE

Copyright (c) 2004-2005 by Kathryn Andersen

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Posy::Plugin::GenStatic
__END__

package Posy::Plugin::GenStatic;
use strict;

=head1 NAME

Posy::Plugin::GenStatic - Posy plugin for generating static pages.

=head1 VERSION

This describes version B<0.93> of Posy.

=cut

our $VERSION = '0.93';

=head1 SYNOPSIS

    require Posy;

    Posy->import(@plugins);
    Posy->run(%args);

=head1 DESCRIPTION

This plugin replaces the 'run' method in order to generate all
known pages of a given type.

It expects extra parameters:

=over

=item static_dir=>I<directory>

The directory where the static pages are to be put.

=item gen_type=>I<string>

The type of pages to generate.

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

=back

=item gen_match=>I<regex>

If B<gen_type> is entry,category or chrono, then only generate those
files which match.

=item verbose=>1

Be verbose?

=back

=cut

use File::Spec;
use Storable;
use Data::Dumper;

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

    my $static_dir = delete $args{static_dir};
    my $gen_type = delete $args{gen_type};
    my $gen_match = delete $args{gen_match};
    my $verbose = $args{verbose};

    # First, read in all the file info into a hash.
    # Make a new Posy object, set the actions to read
    # the information we want, save that information,
    # and then re-init the object to have the caller's
    # desired actions.
    my $self = $class->new(%args);
    $self->init();

    # now, change the actions
    my @actions = @{$self->{actions}};
    $self->{actions} = [qw(init_params parse_path set_config index_entries)];

    # now go and get the files and categories list
    $self->do_actions();
    my @files = keys %{$self->{files}};
    my @categories = keys %{$self->{categories}};

    my $flavour = $self->{config}->{flavour};
    # save the path
    my $orig_path = $self->param('path');
    $self->param('path'=>'');

    # now generate the files
    if ($gen_type eq 'init')
    {
	# run the actions without generating anything
	# send the output to /dev/null
	$self->{params}->{path} = $orig_path;
	$self->{outfile} = File::Spec->devnull();
	@{$self->{actions}} = @actions;
	print STDERR "INIT start\n" if $verbose;
	$self->do_actions();
	print STDERR "INIT end\n" if $verbose;
    }
    elsif ($gen_type eq 'path' and $orig_path)
    {
	# generate one file, the passed-in path
	$self->{params}->{path} = $orig_path;
	print STDERR "path=$orig_path\n" if $verbose;
	my @path_split = split('/', $orig_path);
	$self->{outfile} ||= File::Spec->catfile($static_dir, @path_split);
	print STDERR "outfile=", $self->{outfile}, "\n" if $verbose;
	@{$self->{actions}} = @actions;
	$self->do_actions();
    }
    elsif ($gen_type eq 'entry')
    {
	# go through every entry in @files
	foreach my $key (@files)
	{
	    if (!$gen_match
		|| ($gen_match && $key =~ /$gen_match/o))
	    {
		my @cat_split =
		    split(/\//, $self->{files}->{$key}->{cat_id});
		my $fullcat = File::Spec->catfile($static_dir, @cat_split);
		mkdir $fullcat if (!-e $fullcat);
		my $path = $key;
		$path .= '.' . $flavour;
		@{$self->{actions}} = @actions;
		$self->{params}->{path} = $path;
		print STDERR "$path\n" if $verbose;
		$self->{outfile} =
		    File::Spec->catfile($static_dir,
					@cat_split,
					$self->{files}->{$key}->{basename});
		$self->{outfile} .= '.' . $flavour;
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
    }
    elsif ($gen_type eq 'category')
    {
	# go through every category in $self->{categories}
	foreach my $category (@categories)
	{
	    if (!$gen_match
		|| ($gen_match && $category =~ /$gen_match/o))
	    {
		my @cat_split = split(/\//, $category);
		my $fullcat = File::Spec->catfile($static_dir, @cat_split);
		mkdir $fullcat if (!-e $fullcat);
		my $path = join('/', $category, 'index');
		$path .= '.' . $flavour;
		@{$self->{actions}} = @actions;
		$self->{params}->{path} = $path;
		print STDERR "$path\n" if $verbose;
		$self->{outfile} =
		    File::Spec->catfile($static_dir,
					@cat_split, 'index');
		$self->{outfile} .= '.' . $flavour;
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
    }
    elsif ($gen_type eq 'chrono')
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
	# generate for dates
	while (my $date = each %dates)
	{
	    if (!$gen_match
		|| ($gen_match && $date =~ /$gen_match/o))
	    {
		# make the date directories
		my @dparts = ();
		foreach my $dpart (@{$dates{$date}})
		{
		    push @dparts, $dpart;
		    my $fullpath = File::Spec->catdir($static_dir, @dparts);
		    if (!-e $fullpath)
		    {
			print STDERR "DIR: $fullpath\n" if $verbose;
			mkdir $fullpath;
		    }
		}
		my $path = $date;
		@{$self->{actions}} = @actions;
		$self->{params}->{path} = $path;
		$self->{params}->{flav} = $flavour;
		print STDERR "$path\n" if $verbose;
		$self->{outfile} = File::Spec->catfile($static_dir,
						       @{$dates{date}},
						       "index.$flavour");
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
    }

} # run

=head1 REQUIRES

    Posy
    Posy::Core

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

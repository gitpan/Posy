package Posy::Plugin::GenStatic;
use strict;

=head1 NAME

Posy::Plugin::GenStatic - Posy plugin for generating static pages.

=head1 VERSION

This describes version B<0.72> of Posy.

=cut

our $VERSION = '0.72';

=head1 SYNOPSIS

    require Posy;

    Posy->import(@plugins);
    Posy->run(%args);

=head1 DESCRIPTION

This plugin replaces the 'run' method in order to generate all
known pages of a given type.

It expects two extra parameters:

=over

=item static_dir

The directory where the static pages are to be put.

=item gen_type

The type of pages to generate.  There are three types: 'entry',
'category' and 'chrono'.

=back

=cut

use File::Spec;

=head1 CLASS METHODS

=head2 run

Posy->run(%args);

This version of run goes through the file list, creates a "fake"
path for the files wanted to generate, and calls the core
do_actions for each one.

=cut
sub run {
    my $class = shift;

    # first, read in all the file info into a hash.
    # The easiest way to do that is to have two Posy objects,
    # one of which is a little one which just has the information
    # we want, and just has the actions we want.
    my $static_posy = $class->new(@_);
    $static_posy->init();
    # now, change the actions of our meta_posy
    $static_posy->{actions} = [qw(init_params parse_path set_config index_entries)];
    # give it a fake path of the top directory
    $static_posy->{params}->{path} = "";
    # now go and get the files and categories list
    $static_posy->do_actions();

    my $flavour = $static_posy->{config}->{flavour};
    if ($static_posy->{gen_type} eq 'entry')
    {
	# go through every entry in $self->{files}
	foreach my $key (keys %{$static_posy->{files}})
	{
	    my @cat_split =
		split(/\//, $static_posy->{files}->{$key}->{cat_id});
	    my $fullcat = File::Spec->catfile($static_posy->{static_dir},
		@cat_split);
	    mkdir $fullcat if (!-e $fullcat);
	    my $path = $key;
	    $path .= '.' . $flavour;
	    my $self = $class->new(@_);
	    $self->init();
	    $self->{params}->{path} = $path;
	    print STDERR "$path\n" if $static_posy->{verbose};
	    $self->{outfile} =
		File::Spec->catfile($static_posy->{static_dir},
				    @cat_split,
				    $static_posy->{files}->{$key}->{basename});
	    $self->{outfile} .= '.' . $flavour;
	    $self->do_actions();
	}
    }
    elsif ($static_posy->{gen_type} eq 'category')
    {
	# go through every category in $self->{categories}
	foreach my $category (keys %{$static_posy->{categories}})
	{
	    my @cat_split = split(/\//, $category);
	    my $fullcat = File::Spec->catfile($static_posy->{static_dir},
		@cat_split);
	    mkdir $fullcat if (!-e $fullcat);
	    my $path = join('/', $category, 'index');
	    $path .= '.' . $flavour;
	    my $self = $class->new(@_);
	    $self->init();
	    $self->{params}->{path} = $path;
	    print STDERR "$path\n" if $static_posy->{verbose};
	    $self->{outfile} =
		File::Spec->catfile($static_posy->{static_dir},
				    @cat_split, 'index');
	    $self->{outfile} .= '.' . $flavour;
	    $self->do_actions();
	}
    }
    elsif ($static_posy->{gen_type} eq 'chrono')
    {
	# find out all the dates
	my %dates = ();
	foreach my $key (keys %{$static_posy->{files}})
	{
	    my $chrono_path = join('/',
		$static_posy->{files}->{$key}->{date}->[0], # year
		$static_posy->{files}->{$key}->{date}->[1], # month
		$static_posy->{files}->{$key}->{date}->[2]); # day
	    $dates{"$chrono_path"} = $static_posy->{files}->{$key}->{date};
	}
	# generate for all dates
	foreach my $date (keys %dates)
	{
	    # make the date directories
	    my @dparts = ();
	    foreach my $dpart (@{$dates{$date}})
	    {
		push @dparts, $dpart;
		my $fullpath = File::Spec->catdir($static_posy->{static_dir},
						  @dparts);
		if (!-e $fullpath)
		{
		    print STDERR "DIR: $fullpath\n" if $static_posy->{verbose};
		    mkdir $fullpath;
		}
	    }
	    my $path = $date;
	    my $self = $class->new(@_);
	    $self->init();
	    $self->{params}->{path} = $path;
	    $self->{params}->{flav} = $flavour;
	    print STDERR "$path\n" if $static_posy->{verbose};
	    $self->{outfile} = File::Spec->catfile($static_posy->{static_dir},
						   @{$dates{date}},
						   "index.$flavour");
	    $self->do_actions();
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

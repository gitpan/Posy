package Posy::Plugin::FlavourMenu;
use strict;

=head1 NAME

Posy::Plugin::FlavourMenu - Posy plugin to make a menu of flavours

=head1 VERSION

This describes version B<0.21> of Posy::Plugin::FlavourMenu.

=cut

our $VERSION = '0.21';

=head1 SYNOPSIS

    @plugins = qw(Posy::Core
	...
	Posy::Plugin::YamlConfig
	...
	Posy::Plugin::FlavourMenu
	...
	));
    @actions = qw(init_params
	    ...
	    head_template
	    flavour_menu_set
	    head_render
	    ...
	);

=head1 DESCRIPTION

This plugin creates a menu to let users choose a particular "flavour"
of page layout.

There is one variable filled in by this plugin that can be used within
your flavour files.  The $flow_flavour_menu variable contains the
list of links of the different flavours available on your site.

=head2 Activation

This plugin needs to be added to both the plugins list and the actions
list.  It doesn't really matter where it is in the plugins list,
just so long as you also have the Posy::Plugin::YamlConfig plugin
as well.

In the actions list, it needs to go somewhere after B<head_template>
and before B<head_render>, since the config needs to have been read,
and this needs to set values before the head is rendered.

=head2 Configuration

This expects configuration settings in the $self->{config} hash,
which, in the default Posy setup, can be defined in the main "config"
file in the data directory.

This requires the Posy::Plugin::YamlConfig plugin (or equivalent), because the
configuration variables for this plugin are not simple string values; it
expects the config values to be in a hash at
$self->{config}->{flavour_menu}

=over 

=item B<flavour_menu>

A hash containing the settings.

=over

=item B<flavours>

The list of flavours you want to offer in your menu, in the order
that you want them to be shown.

Note that for every entry in this list, there must be a corresponding
entry in the names hash.

=item B<names>

The labels to give the flavours in the menu list.

=back

=back

Example config file:

	---
	flavour_menu:
	  flavours:
	    - html
	    - top
	    - side
	    - rss
	  names:
	    html: Default
	    top: Top
	    side: Sidebar
	    rss: 'Rss Feed'

=cut

=head1 Flow Action Methods

Methods implementing actions.

=head2 flavour_menu_set

$self->flavour_menu_set($flow_state)

Sets $flow_state->{flavour_menu} (aka $flow_flavour_menu)
to be used inside flavour files.

=cut
sub flavour_menu_set {
    my $self = shift;
    my $flow_state = shift;

    my $flavour = $self->{path}->{flavour};
    my $links = $self->flavour_menu_links($flavour);

    $flow_state->{flavour_menu} = $links;

    1;
} # flavour_menu_set

=head1 Helper Methods

Methods which can be called from within other methods.

=head2 flavour_menu_links

$links = $self->flavour_menu_links($this_flavour);

Generates the list of all flavour links.
The $this_flavour variable is the name of the currently active flavour;
it won't be added to the list.

=cut
sub flavour_menu_links {
    my $self = shift;
    my $this_flavour = shift;

    if (!defined $self->{config}->{flavour_menu})
    {
	return '';
    }

    my $links  = qq{<ul class="flavour_menu">\n};

    my $item   = qq{<li class="flavour_menu_item">};
    my $url = $self->{url};
    my $path_and_filebase;
    if ($self->{path}->{type} eq 'top_category')
    {
	$path_and_filebase = '';
    }
    elsif ($self->{path}->{type} =~ /entry$/)
    {
	$path_and_filebase = $self->{path}->{file_key};
    }
    elsif ($self->{path}->{type} eq 'category')
    {
	$path_and_filebase = $self->{path}->{file_key};
	$path_and_filebase .= '/index';
    }
    elsif ($self->{path}->{type} eq 'chrono')
    {
	$path_and_filebase = $self->{path}->{info};
    }

    my $anchor = qq{<a href="$url/$path_and_filebase};
    my $end    = qq{</a></li>\n};

    # chrono seem to need to set the flavour with ?flav=flavour
    if ($self->{path}->{type} eq 'chrono')
    {
	foreach (@{$self->{config}->{flavour_menu}->{flavours}})
	{
	    my $name = $self->{config}->{flavour_menu}->{names}->{$_};
	    $links .= qq{$item$anchor?flav=$_">$name$end}
	    if (!/^$this_flavour$/);
	}
    }
    else
    {
	foreach (@{$self->{config}->{flavour_menu}->{flavours}})
	{
	    my $name = $self->{config}->{flavour_menu}->{names}->{$_};
	    $links .= qq{$item$anchor.$_">$name$end} if (!/^$this_flavour$/);
	}
    }

    $links .= qq{</ul>\n};

    return $links;
} # flavour_menu_links

=head1 REQUIRES

    Posy
    Posy::Core
    Posy::Plugin::YamlConfig

    Test::More

=head1 SEE ALSO

perl(1).
Posy
YAML

=head1 BUGS

Please report any bugs or feature requests to the author.

=head1 AUTHOR

    Kathryn Andersen (RUBYKAT)
    perlkat AT katspace dot com
    http://www.katspace.com

=head1 COPYRIGHT AND LICENCE

Copyright (c) 2004-2005 by Kathryn Andersen

Based in part on the 'css' blosxom plugin by
Eric Davis <edavis <at> foobargeek <dot> com> http://www.foobargeek.com
And in part on the 'flavourmenu' blosxom plugin by
Tim Lambert (lambert <at> cse <dot> unsw <dot> edu <dot> au)

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Posy::Plugin::FlavourMenu
__END__

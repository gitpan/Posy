package Posy::Plugin::DynamicCss;
use strict;

=head1 NAME

Posy::Plugin::DynamicCss - Posy plugin to load different CSS styles based on the UserAgent.

=head1 VERSION

This describes version B<0.02> of Posy::Plugin::DynamicCss.

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

    @plugins = qw(Posy::Core
	Posy::Plugin::YamlConfig
	Posy::Plugin::DynamicCss));
    @actions = qw(init_params
	    parse_path
	    stop_if_not_found
	    set_config
	    index_entries
	    select_by_path
	    filter_by_date
	    sort_entries
	    content_type
	    head_template
	    dynamic_css_set
	    head_render
	    do_entry_actions
	    foot_template
	    foot_render
	    render_page
	);

=head1 DESCRIPTION

This plugin enables Posy users to load different CSS stylesheets
based on the UserAgent.

There is one variable filled in by this plugin that can be used within your
flavour files.  The $flow_dynamic_css_line variable contains the stylesheet
link metatag for the currently selected (browser-specific) CSS file.  This
variable must be inserted into your head flavour file.

=head2 Activation

This plugin needs to be added to both the plugins list and the actions
list.  It doesn't really matter where it is in the plugins list,
just so long as you also have the Posy::Plugin::YamlConfig plugin
as well.

In the actions list, 'dynamic_css_set' needs to go somewhere after
B<set_config> and before B<head_render>, since the config needs to have been
read, and this needs to set values before the head is rendered.

=head2 Configuration

This expects configuration settings in the $self->{config} hash,
which, in the default Posy setup, can be defined in the main "config"
file in the data directory.

This requires the Posy::Plugin::YamlConfig plugin (or equivalent), because the
configuration variables for this plugin are not simple string values; it
expects the config values to be in a hash at $self->{config}->{dynamic_css}

=over 

=item B<dynamic_css>

A hash containing the settings.

=over

=item B<csspath>

Path to the subdirectory where you keep CSS files.

=item B<default>

The default CSS file to use when one can't figure out the browser.

=item B<files>

A hash containing, for each browser, the browser string to compare against,
and the CSS file to use if it matches.

=back

=back

Example config file:

	dynamic_css:
	  csspath: '/styles'
	  default: 'layout_netscape.css'
	  files:
	    gecko: 'layout_gecko.css'
	    'MSIE.6|MSIE.5': 'layout_msie.css'
	    'Mozilla.4' : 'layout_netscape.css'

=cut

=head1 Flow Action Methods

Methods implementing actions.

=head2 dynamic_css_set

$self->dynamic_css_set(\%flow_state)

Sets $flow_state->{dynamic_css_line} 
(aka $flow_dynamic_css_line)
to be used inside flavour files.

=cut
sub dynamic_css_set {
    my $self = shift;
    my $flow_state = shift;

    my $user = $ENV{HTTP_USER_AGENT};
    my $included = 0;
    my $fullpath = $self->{url};
    $fullpath =~ s/\/index.cgi//;
    $fullpath .= $self->{config}->{dynamic_css}->{csspath};
    my $cssline = '';
    my $done = 0;
    my $default_file = $self->{config}->{dynamic_css}->{default};
 
    while (my ($regex, $file) = each
    %{$self->{config}->{dynamic_css}->{files}}) {
	if ($user =~ /$regex/i) {
	    $cssline = "<link rel=\"stylesheet\" type=\"text/css\" 
                              href=\"$fullpath\/$file\" //>";
	    $done = 1;
	    last;
	}
    }
    if (! $done) {
	$cssline = "<link rel=\"stylesheet\" type=\"text/css\" 
                              href=\"$fullpath\/$default_file\" //>";
    }	
    $flow_state->{dynamic_css_line} = $cssline;
    1;
} # dynamic_css_set

=head1 REQUIRES

    HTML::DynamicCss

    Test::More

=head1 SEE ALSO

perl(1).
Posy

=head1 BUGS

Please report any bugs or feature requests to the author.

=head1 AUTHOR

    Kathryn Andersen (RUBYKAT)
    perlkat AT katspace dot com
    http://www.katspace.com

=head1 COPYRIGHT AND LICENCE

Copyright (c) 2004 by Kathryn Andersen

Original 'dynamiccss' blosxom copyright (c) 2004 by Brian Haberer
  http://www.canonical.org/~brian/software/dynamiccss

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

Or See: http://www.gnu.org/copyleft/gpl.html

=cut

1; # End of Posy::Plugin::DynamicCss
__END__

package Posy::Plugin::ThisFlavour;
use strict;

=head1 NAME

Posy::Plugin::ThisFlavour - change relative links to the current flavour

=head1 VERSION

This describes version B<0.10> of Posy::Plugin::ThisFlavour.

=cut

our $VERSION = '0.10';

=head1 SYNOPSIS

    @plugins = qw(Posy::Core Posy::Plugin::ThisFlavour));
    @entry_actions = qw(header
	    ...
	    parse_entry
	    ...
	    this_flavour
	    ...
	);

=head1 DESCRIPTION

This plugin changes relative links in entries from the default flavour
into the current flavour (if the flavours are not the same).

=head2 Configuration

This expects configuration settings in the $self->{config} hash,
which, in the default Posy setup, can be defined in the main "config"
file in the data directory.

=over

=item B<this_flavour_convert_links>

Set this_flavour_convert_links to off (zero) to turn off this plugin
(for example, to give different behaviour in different directories).
(default: on)

=back

=cut

=head1 OBJECT METHODS

Documentation for developers and those wishing to write plugins.

=head2 init

Do some initialization; make sure that default config values are set.

=cut
sub init {
    my $self = shift;
    $self->SUPER::init();

    # set defaults
    $self->{config}->{this_flavour_convert_links} = 1
	if (!defined $self->{config}->{this_flavour_convert_links});
} # init

=head1 Entry Action Methods

Methods implementing per-entry actions.

=head2 this_flavour

$self->this_flavour(\%flow_state, \%current_entry, \%entry_state)

Alters $current_entry->{body} by converting the relative links
to the current flavour.

=cut
sub this_flavour {
    my $self = shift;
    my $flow_state = shift;
    my $current_entry = shift;
    my $entry_state = shift;

    if ($self->{config}->{this_flavour_convert_links}
	&& ($self->{config}->{flavour} ne $self->{path}->{flavour}))
    {
	my $default_flavour = $self->{config}->{flavour};
	my $flavour = $self->{path}->{flavour};
	$current_entry->{body} =~ s/(href\s*=\s*"?(?!http:)[^">?#]+)\.${default_flavour}?([">?#\s]|$)/$1.${flavour}$2/sgi;
    }
    1;
} # this_flavour

=head1 REQUIRES

    Posy
    Posy::Core

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

Based on the blosxom 'toc' plugin by Gregor Rayman (copyright 2003)
<rayman <at> grayman <dot> de>

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Posy::Plugin::ThisFlavour
__END__

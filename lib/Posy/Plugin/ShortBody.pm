package Posy::Plugin::ShortBody;
use strict;
use warnings;

=head1 NAME

Posy::Plugin::ShortBody - Posy plugin to give the start of an entry body

=head1 VERSION

This describes version B<0.01> of Posy::Plugin::ShortBody.

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    @plugins = qw(Posy::Core Posy::Plugin::ShortBody));
    @entry_actions = qw(header
	    entry_template
	    read_entry
	    parse_entry
	    short_body
	    render_entry
	    append_entry
	);

=head1 DESCRIPTION

Purpose: Populates the flavour template variable $entry_short_body with the
first sentence of the entry body (defined as everything before the first .,
!, or ?) and strips out HTML tags along the way.  Perfect for providing
shortened, plaintext versions of stories for an RSS feed.

This creates a 'short_body' entry action, which should be placed
after 'parse_entry' in the entry_action list.

=head2 Configuration

This expects configuration settings in the $self->{config} hash,
which, in the default Posy setup, can be defined in the main "config"
file in the data directory.

=over

=item B<short_body_remove_header>

If true, removes the first header it encounters in the body, and
uses the first sentence after that. (1 is true, 0 is false)
(default: true)

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
    $self->{config}->{short_body_remove_header} = 1
	if (!defined $self->{config}->{short_body_remove_header});
} # init

=head1 Entry Action Methods

Methods implementing per-entry actions.

=head2 short_body

$self->short_body(\%flow_state, \%current_entry, \%entry_state)

Parses $current_entry->{body} into $current_entry->{short_body}

=cut
sub short_body {
    my $self = shift;
    my $flow_state = shift;
    my $current_entry = shift;
    my $entry_state = shift;

    my $body = $current_entry->{body};
    if ($self->{config}->{short_body_remove_header})
    {
	$body =~ s#<h\d[^>]*>[^<>]+</h\d>##;
    }
    # strip the HTML tags
    $body =~ s/<[^>]+>//gs;
    # strip out leading spaces
    $body =~ s/^\s*//gs;
    # get the first sentence
    $body =~ s/([\.\!\?]).+$/$1/s;
    $current_entry->{short_body} = $body;
    1;
} # short_body

=head1 REQUIRES

    HTML::ShortBody

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

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Posy::Plugin::ShortBody
__END__

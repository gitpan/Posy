package Posy::Plugin::Toc;
use strict;

=head1 NAME

Posy::Plugin::Toc - Posy plugin create a table of contents

=head1 VERSION

This describes version B<0.11> of Posy::Plugin::Toc.

=cut

our $VERSION = '0.11';

=head1 SYNOPSIS

    @plugins = qw(Posy::Core Posy::Plugin::Toc));
    @entry_actions = qw(header
	    ...
	    parse_entry
	    make_toc
	    render_entry
	    ...
	);

=head1 DESCRIPTION

Creates a table of contents generated from headings.

The table of contents will be generated only if the entry
contains string $toc_split and only from headers below
$toc_split. 

If there are no headers (element $toc_chapter_element), then 
no table of contents will be generated.

This creates a 'make_toc' entry action, which should be placed after
'parse_entry' and before 'render_entry' in the entry_action list.  If you
are using the Posy::Plugin::ShortBody plugin, this should be placed after
'short_body' in the entry_action list, not before it.

=head2 Configuration

This expects configuration settings in the $self->{config} hash,
which, in the default Posy setup, can be defined in the main "config"
file in the data directory.

=over

=item B<toc_split>

String which will be replaced by the table of contents.
(default: <!-- toc -->)

=item B<toc_chapter_element>

Which element marks the header of the "chapters"?
(default: h3)

=item B<toc_chapter_prefix>

This will prefix the chapters' headers.

=item B<toc_anchor>

Contents of the anchor of chapters prefix.

=item B<toc_prefix>

Prefix of the table of contents.
(default: <h3>Table of Contents</h3><ul class="PageTOC">)

=item B<toc_line_prefix>

Prefix of the line for each chapter will be inserted into the TOC 
(default: <li>)

=item B<toc_line_suffix>

Suffix of the line for each chapter will be inserted into the TOC 
(default: </li>)

=item B<toc_suffix>

Suffix of the table of contents.
(default: </ul>)

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
    $self->{config}->{toc_split} = qr/<!--\s*toc\s*-->/
	if (!defined $self->{config}->{toc_split});
    $self->{config}->{toc_chapter_element} = 'h3'
	if (!defined $self->{config}->{toc_chapter_element});
    $self->{config}->{toc_chapter_prefix} = q:" ":
	if (!defined $self->{config}->{toc_chapter_prefix});
    $self->{config}->{toc_anchor} = q:"${chap}.":
	if (!defined $self->{config}->{toc_anchor});
    $self->{config}->{toc_prefix} = '<h3>Table of Contents</h3>
<ul class="PageTOC">'
	if (!defined $self->{config}->{toc_prefix});
    $self->{config}->{toc_line_prefix} = '<li>'
	if (!defined $self->{config}->{toc_line_prefix});
    $self->{config}->{toc_line_suffix} = "</li>\n"
	if (!defined $self->{config}->{toc_line_suffix});
    $self->{config}->{toc_suffix} = '</ul>'
	if (!defined $self->{config}->{toc_suffix});

    # initialize private things
    $self->{toc}->{entry_num} = 0;
} # init

=head1 Entry Action Methods

Methods implementing per-entry actions.

=head2 make_toc

$self->make_toc($flow_state, $current_entry, $entry_state)

Alters $current_entry->{body} by adding a table-of-contents
if the "toc_split" string is in the body.

=cut
sub make_toc {
    my $self = shift;
    my $flow_state = shift;
    my $current_entry = shift;
    my $entry_state = shift;

    my $body = $current_entry->{body};
    my $text;
    ($body, $text) = split $self->{config}->{toc_split}, $body, 2;
  
    if ($text)
    {
	my $toc = "";
	my $toc_chapter_element = $self->{config}->{toc_chapter_element};
	my $toc_prefix = $self->{config}->{toc_prefix};
	my $toc_suffix = $self->{config}->{toc_suffix};
	$self->{toc}->{chap} = 0;

	$text =~ s:<($toc_chapter_element)(.*?)>(.*?)</$toc_chapter_element>:$self->_toc_do_stuff($1,$2,$3,\$toc):ego;
	if ($toc) {
	    my $entry_num = $self->{toc}->{entry_num};
	    $body .= "<a name='TOC${entry_num}'></a>"
	    . $self->{config}->{toc_prefix}
	    . $toc
	    . $self->{config}->{toc_suffix}
	    . $text;
	} else {
	    $body .= $text;
	}
	$current_entry->{body} = $body;
    }

    $self->{toc}->{entry_num}++;
    1;
} # make_toc

=head1 Private Methods

=head2 _toc_do_stuff

Return the stuff to be substituted in found header anchors,
and append to the $toc information.

=cut
sub _toc_do_stuff {
    my $self = shift;
    my $chap_el = shift;
    my $chap_att = shift;
    my $chap_label = shift;
    my $toc_ref = shift;

    my $entry_num = $self->{toc}->{entry_num};

    $self->{toc}->{chap}++;
    my $chap = $self->{toc}->{chap};
    my $chap_id;
    my $newhead;

    $chap_id = join('', 'toc_', ${entry_num}, '_', ${chap});
    $newhead = join('',
		    '<', $chap_el, $chap_att, '><a name="', $chap_id,
		    '" href="#TOC', $entry_num, '">',
		    eval($self->{config}->{toc_anchor}),
		    '</a>',
		    eval($self->{config}->{toc_chapter_prefix}),
		    $chap_label, '</', $chap_el, '>'
		   );

    $$toc_ref .= join('', $self->{config}->{toc_line_prefix},
		      '<a href="#', $chap_id, '">',
		      ${chap}, '. ', ${chap_label}, '</a>',
		      $self->{config}->{toc_line_suffix});

    return $newhead;
} # _toc_do_stuff

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

Copyright (c) 2004-2005 by Kathryn Andersen

Based on the blosxom 'toc' plugin by Gregor Rayman (copyright 2003)
<rayman <at> grayman <dot> de>

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Posy::Plugin::Toc
__END__

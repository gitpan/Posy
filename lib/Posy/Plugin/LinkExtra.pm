package Posy::Plugin::LinkExtra;
use strict;

=head1 NAME

Posy::Plugin::LinkExtra - Posy plugin to add extras to local links

=head1 VERSION

This describes version B<0.21> of Posy::Plugin::LinkExtra.

=cut

our $VERSION = '0.21';

=head1 SYNOPSIS

    @plugins = qw(Posy::Core
	...
	Posy::Plugin::FileStats
	Posy::Plugin::LinkExtra));
    @entry_actions = qw(header
	    ...
	    parse_entry
	    link_extra
	    ...
	);

=head1 DESCRIPTION

This plugin uses information from the Posy::Plugin::FileStats plugin to add
extra information to flagged relative links that link to files in the data
directory.

For any link to a file, add the extra attribute 'posy_link' with the
arguments for what extras you want for this link.

For example:

<a href="thingie.jpg" posy_link="size">my thingie</a>

will give

<a href="thingie.jpg">my thingie</a> (4K)

The 'posy_link' attribute must be the last attribute in the link (to make
it easier to parse).

Options:

=over

=item size

The size of the linked-to file, as "(size)" in K or M or bytes, depending
on how large the file is.

=item words

The number of words in the linked-to file (as given by the FileStats
plugin).

=item mod

The last-modified date of the linked-to file.

=back

This plugin creates a 'link_extra' entry action, which should be placed
after 'parse_entry' in the entry_action list.  If you are using
the Posy::Plugin::ShortBody plugin, this should be placed after
'short_body' in the entry_action list, not before it.

=cut
use File::Spec;

=head1 Entry Action Methods

Methods implementing per-entry actions.

=head2 link_extra

$self->link_extra($flow_state, $current_entry, $entry_state)

Alters $current_entry->{body} by adding extra information to
flagged local links.

=cut
sub link_extra {
    my $self = shift;
    my $flow_state = shift;
    my $current_entry = shift;
    my $entry_state = shift;

    if ($current_entry->{body})
    {
	$current_entry->{body} =~
	s/<a\s+href\s*=\s*['"](?!http:)([^"'>?#]+)['"]([^>]*)\s+posy_link=["']([^'"]+)['"]>([^<]+)<\/a>/$self->_link_extra_do($1,$2,$3,$4)/esg;
    }

    1;
} # link_extra

=head1 Private Methods

=head2 _link_extra_do

Return the stuff to be substituted in found links.

=cut
sub _link_extra_do {
    my $self = shift;
    my $link = shift;
    my $attrib = shift;
    my $args = shift;
    my $label = shift;

    # find the file
    my $fullname;
    # look in the local data directory
    my @path_split = split(/\//, $self->{path}->{cat_id});
    $fullname = File::Spec->catfile($self->{data_dir}, @path_split, $link);
    if (exists $self->{file_stats}->{$fullname})
    {
	my $extras;
	if ($args =~ /size/)
	{
	    $extras = $self->{file_stats}->{$fullname}->{size_string};
	}
	if ($args =~ /words/
	    && $self->{file_stats}->{$fullname}->{word_count})
	{
	    $extras = join(' ', $extras,
		$self->{file_stats}->{$fullname}->{word_count},
		'words');
	}
	$extras = join('', '(', $extras, ')') if $extras;
	if ($args =~ /mod/)
	{
	    my %date_time =
		$self->nice_date_time($self->{file_stats}->{$fullname}->{mtime});
	    $extras = join('', $extras,
		' ',
		$date_time{year}, '-',
		$date_time{mnum}, '-',
		$date_time{da}, ' ',
		$date_time{hour}, ':',
		$date_time{min},
		);
	}
	return join('', '<a href="', $link, '"', $attrib, '>', $label,
	    '</a> ', $extras);
    }
    return join('', '<a href="', $link, '"', $attrib, '>', $label, '</a>');

} # _link_extra_do

=head1 REQUIRES

    Posy
    Posy::Core
    Posy::Plugin::FileStats

    File::Spec

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

Copyright (c) 2005 by Kathryn Andersen

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Posy::Plugin::LinkExtra
__END__

package Posy::Plugin::NearLinks;
use strict;

=head1 NAME

Posy::Plugin::NearLinks - give links of articles in the current category

=head1 VERSION

This describes version B<0.10> of Posy::Plugin::NearLinks.

=cut

our $VERSION = '0.10';

=head1 SYNOPSIS

    @plugins = qw(Posy::Core
		  Posy::Plugin::TextTemplate
		  Posy::Plugin::EntryTitles
		  Posy::Plugin::LinkList
		  Posy::Plugin::NearLinks));

=head1 DESCRIPTION

This provides a method which can be called from the "head" flavour template
(if one is using the TextTemplate plugin).  This finds all the entries in
the current category, and their titles, and makes a list of links to them.

This depends on the L<Posy::Plugin::EntryTitles> plugin to get the titles
from the entries.
This depends on the L<Posy::Plugin::LinkList> plugin to make the actual
list of links.

=cut

=head1 Helper Methods

Methods which can be called from elsewhere.

=head2 near_links

$links = $self->near_links(
    pre_list=>'<ul>',
    post_list=>'</ul>',
    pre_item=>'<li>',
    post_item=>'</li>'
    pre_active_item=>'<li><em>',
    post_active_item=>'</em></li>',
    item_sep=>"\n");

Generates a list of links of entries in the current category.

=cut
sub near_links {
    my $self = shift;
    my %args = (
		pre_list=>'<ul>',
		post_list=>'</ul>',
		pre_item=>'<li>',
		post_item=>'</li>',
		pre_active_item=>'<li><em>',
		post_active_item=>'</em></li>',
		item_sep=>"\n",
		@_
	       );

    my @labels;
    my %links;

    # go through all the files in the titles index
    while (my ($file_id, $title) =  each(%{$self->{titles}}))
    {
	if (($self->{files}->{$file_id}->{path}
	     eq $self->{path}->{dir}) # category matches
	    and ($self->{files}->{$file_id}->{basename}
		 ne 'index') # don't include index entry-files
	   )
	{
	    push @labels, $title;
	    # make a link with the current flavour
	    my $link = '/' . $file_id . '.' . $self->{path}->{flavour};
	    $links{$title} = $link;
	}
    }
    # sort the labels alphabetically -- hey, it's as good an order as any
    @labels = sort @labels;

    return $self->link_list(
	labels=>\@labels,
	links=>\%links,
	%args);
} # near_links

=head1 REQUIRES

    Posy
    Posy::Core
    Posy::Plugin::TextTemplate
    Posy::Plugin::EntryTitles
    Posy::Plugin::LinkList

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

1; # End of Posy::Plugin::NearLinks
__END__

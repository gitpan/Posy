package Posy::Plugin::LinkList;
use strict;

=head1 NAME

Posy::Plugin::LinkList - Posy plugin to give a dynamic list of links

=head1 VERSION

This describes version B<0.10> of Posy::Plugin::LinkList.

=cut

our $VERSION = '0.10';

=head1 SYNOPSIS

    @plugins = qw(Posy::Core Posy::Plugin::TextTemplate Posy::Plugin::LinkList));

=head1 DESCRIPTION

This provides a method which can be called from the "head" flavour template
(if one is using the TextTemplate plugin).  When given an array of
labels and a hash of labels-to-relative-links, will produce a list of
links which take account of (a) what the current path is and (b)
what the current flavour is.  If the link matches the current path,
then only the label is used for that link.  If the extension part
of the link matches the default flavour, then the current flavour
replaces it.

With extra arguments, will change the style of the list; one can define
pre_list, post_list, pre_item, post_item, and item separators -- this
enables one to create an unordered list or a pipe-separated paragraph
just by changing these values.  Or one can give one's own CSS classes
to the parts.  The default is a plain <ul> list.

=cut

=head1 Helper Methods

Methods which can be called from elsewhere.

=head2 link_list

$links = $self->link_list(labels => \@labels,
    links=>\%links,
    pre_list=>'<ul>',
    post_list=>'</ul>',
    pre_item=>'<li>',
    post_item=>'</li>'
    pre_active_item=>'<li><em>',
    post_active_item=>'</em></li>',
    item_sep=>"\n");

Generates a list of links.

=cut
sub link_list {
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

    my @items = ();
    foreach my $label (@{$args{labels}})
    {
	my $link = $args{links}->{$label};
	$self->debug(2, "link_list: link=$link");
	if ($link =~ m/(.*)\.(\w+)$/)
	{
	    my $link_base = $1;
	    my $link_flavour = $2;
	    $link_flavour = $self->{path}->{flavour}
		if $link_flavour eq $self->{config}->{flavour};
	    $link = "$link_base.$link_flavour";
	}
	if ($link eq $self->{path}->{info}) # active
	{
	    push @items, join('', $args{pre_active_item},
			      $label,
			      $args{post_active_item});
	}
	else
	{
	    push @items, join('', $args{pre_item},
			      '<a href="', $self->{url}, $link, '">',
			      $label, '</a>',
			      $args{post_item});
	}
    }
    my $list = join($args{item_sep}, @items);
    return join('', $args{pre_list}, $list, $args{post_list});
} # link_list

=head1 REQUIRES

    Posy
    Posy::Core
    Posy::Plugin::TextTemplate

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

1; # End of Posy::Plugin::LinkList
__END__

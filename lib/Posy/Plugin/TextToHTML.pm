package Posy::Plugin::TextToHTML;
use strict;

=head1 NAME

Posy::Plugin::TextToHTML - Posy plugin to convert plain text files to HTML

=head1 VERSION

This describes version B<0.05> of Posy::Plugin::TextToHTML.

=cut

our $VERSION = '0.05';

=head1 SYNOPSIS

    @plugins = qw(Posy::Core Posy::Plugin::TextToHTML);

=head1 DESCRIPTION

This uses the HTML::TextToHTML module (as used by the txt2html script) to
convert the body of an entry from text into HTML.  This checks the
extension of the entry file, and if it is 'txt', then it will convert
the entry.

This basically replaces the 'parse_entry' method, and calls the parent
method for anything other than text.

=head2 Configuration

This expects configuration settings in the $self->{config} hash,
which, in the default Posy setup, can be defined in the main "config"
file in the data directory.

=over

=item B<txt2html_options>

Set the options for the text-to-HTML processing.  See L<HTML::TextToHTML>
for details.  Certain options are meaningless in this context and will
be ignored, since this is not being processed as a full file, but as
just body content. Therefore options such as 'append_file', 'prepend_file'
and 'append_head' will not work, as well as options which refer to doing
things to the headers.  But that's okay, since you can do things like
that with flavours and other plugins.

Give the options as one long space-separated string, with each option
name followed by its value.  For example:

txt2html_options: xhtml 1 escape_HTML_chars 0 make_anchors 0

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
    $self->{config}->{txt2html_options} = 
    'xhtml 1 make_anchors 0'
	if (!defined $self->{config}->{txt2html_options});
} # init

=head1 Entry Action Methods

Methods implementing per-entry actions.

=head2 parse_entry

$self->parse_entry(\%flow_state, \%current_entry, \%entry_state)

Parses $current_entry->{raw} into $current_entry->{title}
and $current_entry->{body}

=cut
sub parse_entry {
    my $self = shift;
    my $flow_state = shift;
    my $current_entry = shift;
    my $entry_state = shift;

    my $id = $current_entry->{id};
    if ($self->{files}->{$id}->{ext} =~ /^t[e]?xt$/)
    {
	require HTML::TextToHTML;

	my %options = ();
	if (defined $self->{config}->{txt2html_options})
	{
	    if (!ref $self->{config}->{txt2html_options}) # a string
	    {
		my @options = split(/\s+/, $self->{config}->{txt2html_options});
		%options = (@options);
		$self->{config}->{txt2html_options} = \%options;
	    }
	    else # assume we've converted it already
	    {
		%options = %{$self->{config}->{txt2html_options}};
	    }
	}
	$self->debug(2, "$id is txt");
	$current_entry->{raw} =~ m/^(.*)$/mi;
	$current_entry->{title} = $1;
	# make only one HTML::TextToHTML object
	if (!defined $self->{TextToHTML}->{obj})
	{
	    $self->{TextToHTML}->{obj} = HTML::TextToHTML->new(%options);
	}
	else # set the arguments
	{
	    $self->{TextToHTML}->{obj}->args(%options);
	}
	$current_entry->{body} =
	    $self->{TextToHTML}->{obj}->process_chunk($current_entry->{raw});
    }
    else # use parent
    {
	$self->SUPER::parse_entry($flow_state, $current_entry, $entry_state);
    }
    1;
} # parse_entry


=head1 REQUIRES

    HTML::TextToHTML

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

1; # End of Posy::Plugin::TextToHTML
__END__

package Posy::Plugin::Pod;
use strict;

=head1 NAME

Posy::Plugin::Pod - Posy plugin to convert POD files to HTML

=head1 VERSION

This describes version B<0.30> of Posy::Plugin::Pod.

=cut

our $VERSION = '0.30';

=head1 SYNOPSIS

    @plugins = qw(Posy::Core
	...
	Posy::Plugin::EntryTitles
	Posy::Plugin::Pod
	...);
    %file_extensions = (
	txt=>'text',
	html=>'html',
	...
	pm=>'pod',
	pod=>'pod',
    );

=head1 DESCRIPTION

This uses the Pod::Simple::HTML module to convert the the POD (Plain Old
Documentation) in a .pm or .pod file into HTML.  This expects the
file_extensions to have been set so that files with appropriate extensions
(such as .pm or .pod) will have been set with a file-type of 'pod'.  This
then converts entries of the 'pod' type.

This replaces the 'parse_entry' method, and calls the parent
method for anything other than POD.

This also replaces the 'get_title' method used by
Posy::Plugin::EntryTitles, so if one is using that module, one needs to put
this after that in the plugin list.

=cut

=head1 Entry Action Methods

Methods implementing per-entry actions.

=head2 parse_entry

$self->parse_entry($flow_state, $current_entry, $entry_state)

Parses $current_entry->{raw} into $current_entry->{title}
and $current_entry->{body}

=cut
sub parse_entry {
    my $self = shift;
    my $flow_state = shift;
    my $current_entry = shift;
    my $entry_state = shift;

    my $id = $current_entry->{id};
    my $file_type = $self->{file_extensions}->{$self->{files}->{$id}->{ext}};
    if ($file_type eq 'pod')
    {
	$self->debug(2, "$id is pod");
	my $html;
	$self->_init_pod_obj();
	$self->{Pod}->{obj}->output_string(\$html);
	$self->{Pod}->{obj}->set_source(\$current_entry->{raw});
	$self->{Pod}->{obj}->run;
	$html =~ m#<title>(.*)</title>#is;
	$current_entry->{title} = $1;
	$html =~ m#<body([^>]*)>(.*)</body>#is;
	$current_entry->{body_attrib} = $1;
	$current_entry->{body} = $2;
	# the dump plugin doesn't like this object, so delete it
	# if we are dumping
	delete $self->{Pod}->{obj} if ($INC{'Posy/Plugin/Dump.pm'});
    }
    else # use parent
    {
	$self->SUPER::parse_entry($flow_state, $current_entry, $entry_state);
    }
    1;
} # parse_entry

=head1 Helper Methods

Methods which can be called from elsewhere.

=head2 get_title

    $title = $self->get_title($file_id);

Get the title of the given entry file (by reading the file).

=cut
sub get_title {
    my $self = shift;
    my $file_id = shift;

    my $fullname = $self->{files}->{$file_id}->{fullname};
    my $ext = $self->{files}->{$file_id}->{ext};
    my $file_type = $self->{file_extensions}->{$ext};
    my $title = '';
    my $fh;
    if ($file_type eq 'pod')
    {
	my $html;
	$self->_init_pod_obj();
	$self->{Pod}->{obj}->output_string(\$html);
	$self->{Pod}->{obj}->set_source($fullname);
	$title = $self->{Pod}->{obj}->get_short_title;
	$title = $self->{files}->{$file_id}->{basename} if (!$title);
	$self->debug(2, "$file_id title=$title");
	# the dump plugin doesn't like this object, so delete it
	# if we are dumping
	delete $self->{Pod}->{obj} if ($INC{'Posy/Plugin/Dump.pm'});
    }
    else # use parent
    {
	$title = $self->SUPER::get_title($file_id);
    }
    return $title;
} # get_title

=head1 Private Methods

=head2 _init_pod_obj

Make the Pod::Simple::HTML object.

=cut
sub _init_pod_obj {
    my $self = shift;

    # make only one Pod::Simple::HTML object
    if (!defined $self->{Pod}->{obj})
    {
	require Pod::Simple::HTML;

	$self->{Pod}->{obj} = Pod::Simple::HTML->new;
	$self->{Pod}->{obj}->no_errata_section(1);
	$self->{Pod}->{obj}->index(1);
	# set some of the Pod::Simple::HTML globals
	$Pod::Simple::HTML::Computerese = '';
    }
} # _init_pod_obj

=head1 REQUIRES

    Posy
    Posy::Core
    Pod::Simple::HTML

    Test::More

=head1 SEE ALSO

perl(1).
Posy
Pod::Simple::HTML

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

1; # End of Posy::Plugin::Pod
__END__

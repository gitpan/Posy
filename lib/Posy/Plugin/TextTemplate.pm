package Posy::Plugin::TextTemplate;
use strict;

=head1 NAME

Posy::Plugin::TextTemplate - Posy plugin for interpolating with Text::Template

=head1 VERSION

This describes version B<0.05> of Posy::Plugin::TextTemplate.

=cut

our $VERSION = '0.05';

=head1 SYNOPSIS

    @plugins = qw(Posy::Core Posy::Plugin::TextTemplate);

=head1 DESCRIPTION

This overrides Posy's simple interpolate() method, by using
the Text::Template module.
This is I<not> compatible with core Posy style interpolation.

Note that, if you want access to any of posy's methods inside a template,
the Posy object should be available through the variable "$Posy".

=head2 Configuration

This expects configuration settings in the $self->{config} hash,
which, in the default Posy setup, can be defined in the main "config"
file in the data directory.

=over

=item B<tt_recurse_into_entry>

Do you want me to recursively interpolate into the entry $title
and $body?  Consider carefully before turning this on, since if
anyone other than you has the ability to post stories, there is
a chance of foolishness or malice, exposing variables and
calling actions/subroutines you might not want called.
(0 = No, 1 = Yes)

=item B<tt_left_delim> B<tt_right_delim>

The delimiters to use for Text::Template; for the sake of speed,
it is best not to use the original '{' '}' delimiters.
(default: tt_left_delim='[==', tt_right_delim='==]')

=back

=cut

use Text::Template;

=head1 OBJECT METHODS

Documentation for developers and those wishing to write plugins.

=head2 init

Do some initialization; make sure that default config values are set.

=cut
sub init {
    my $self = shift;
    $self->SUPER::init();

    # set defaults
    $self->{config}->{tt_recurse_into_entry} = 0
	if (!defined $self->{config}->{tt_recurse_into_entry});
    $self->{config}->{tt_left_delim} = '[=='
	if (!defined $self->{config}->{tt_left_delim});
    $self->{config}->{tt_right_delim} = '==]'
	if (!defined $self->{config}->{tt_right_delim});
} # init

=head1 Helper Methods

Methods which can be called from within other methods.

=head2 set_vars

    my %vars = $self->set_vars(\%flow_state);
    my %vars = $self->set_vars(\%flow_state, \%current_entry, \%entry_state);

Sets variable hashes to be used in interpolation of templates.

This can be called from a flow action or as an entry action, and will
use the given state hashes accordingly.

=cut
sub set_vars {
    my $self = shift;
    my %vars = $self->SUPER::set_vars(@_);

    $vars{Posy} = \$self;
    return %vars;
} # set_vars

=head2 interpolate

$content = $self->interpolate($chunk, $template, \%vars);

Interpolate the contents of the vars hash with the template
and return the result.  (This is passed the chunk name
just in case one wishes to do something different depending on
what chunk type it is.)

=cut
sub interpolate {
    my $self = shift;
    my $chunk = shift;
    my $template = shift;
    my $vars_ref = shift;

    # recurse into entry if we are processing an entry
    if ($chunk eq 'entry'
	and $self->{config}->{tt_recurse_into_entry})
    {
	if ($vars_ref->{entry_title}) {
	    my $title = $vars_ref->{entry_title};
	    my $ob1 = new Text::Template(
					 TYPE=>'STRING',
					 SOURCE => $title,
					 DELIMITERS =>
					 [$self->{config}->{tt_left_delim},
					 $self->{config}->{tt_right_delim}],
					);
	    $vars_ref->{entry_title} = $ob1->fill_in(HASH=>$vars_ref);
	    undef $ob1;
	}
	if ($vars_ref->{entry_body}) {
	    my $body = $vars_ref->{entry_body};
	    my $ob2 = new Text::Template(
					 TYPE=>'STRING',
					 SOURCE => $body,
					 DELIMITERS =>
					 [$self->{config}->{tt_left_delim},
					 $self->{config}->{tt_right_delim}],
					);
	    $vars_ref->{entry_body} = $ob2->fill_in(HASH=>$vars_ref);
	    undef $ob2;
	}
    }
    my $content = $template;
    $self->debug(1, "template undefined") if (!defined $template);
    my $obj = new Text::Template(
				 TYPE=>'STRING',
				 SOURCE => $content,
				 DELIMITERS =>
				 [$self->{config}->{tt_left_delim},
				 $self->{config}->{tt_right_delim}],
				);
    $content = $obj->fill_in(HASH=>$vars_ref);
    return $content;
} # interpolate

=head1 REQUIRES

    Text::Template

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

1; # End of Posy::Plugin::TextTemplate
__END__

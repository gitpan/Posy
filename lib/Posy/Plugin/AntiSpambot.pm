package Posy::Plugin::AntiSpambot;
use strict;

=head1 NAME

Posy::Plugin::AntiSpambot - Posy plugin to obfustcate mail links

=head1 VERSION

This describes version B<0.21> of Posy::Plugin::AntiSpambot.

=cut

our $VERSION = '0.21';

=head1 SYNOPSIS

    @plugins = qw(Posy::Core
	...
	Posy::Plugin::AntiSpambot));
    @actions = qw(init_params
	...
	set_config
	anti_spambot_redirect_mail
	...
    );
    @entry_actions = qw(header
	    ...
	    parse_entry
	    anti_spambot_obscure_mail
	    ...
	);

=head1 DESCRIPTION

The aim of this plugin is to frustrate the attempts of spambots to
harvest email addresses from your website, by concealing them by altering
mailto: links according to a given policy.
The choice of concealment policy is up to you.

Policies:

=over

=item spell

Convert the link to plain text where the email is spelled out; the @ sign
is converted to ' at ' and the '.' parts are converted to ' dot '.

=item cgi_link

Convert the mailto link to a link to the Posy cgi script with two
parameters -- the username and the domain of the original email
address.  When someone clicks on the link, AntiSpambot will then
interpret these parameters correctly and do a redirect to a mailto: URL,
which your browser will then interpret just as if the original
link were still there.

=item form

This is just like cgi_link above, but instead of putting the parameters
into a link (which might be parsed by the spambot) it puts it into
a form (which spambots are less likely to parse).  And you get
a button for folks to click on.

=back

=head2 Activation

Add the plugin to the plugin list.

This plugin creates an 'anti_spambot_obscure_mail' entry action, which should
be placed after 'parse_entry' in the entry_action list.  If you are using
the Posy::Plugin::ShortBody plugin, this should be placed after
'short_body' in the entry_action list, not before it.

This plugin also creates an 'anti_spambot_redirect_mail' action which will
check the incoming parameters and give a redirect to a mailto: url.
It needs to be placed after set_config in the action list, as it
checks config variables.

=head2 Configuration

This expects configuration settings in the $self->{config} hash,
which, in the default Posy setup, can be defined in the main "config"
file in the config directory.

=over

=item B<anti_spambot_policy>

The policy to use on email links.  By setting different configs in
different directories, you can change this on a per-directory basis.

=item B<anti_spambot_at>

The string to replace the '@' sign with if using the 'spell' policy.
(default: ' at ')

=item B<anti_spambot_dot>

The string to replace the '.' with if using the 'spell' policy.
(default: ' dot ')

=item B<anti_spambot_prefix>

The string to prefix the email with if using the 'spell' policy.
(default: &lt;)

=item B<anti_spambot_suffix>

The string to append to the email if using the 'spell' policy.
(default: &gt;)

=item B<anti_spambot_user_param>

The name of the parameter to define the user if using the 'cgi_link'
or 'form' policy.  There is deliberately no default for this, because
everyone ought to define their own parameter, so that the spambots
can't figure out a pattern.

=item B<anti_spambot_domain_param>

The name of the parameter to define the domain if using the 'cgi_link'
or 'form' policy.  There is deliberately no default for this, because
everyone ought to define their own parameter, so that the spambots
can't figure out a pattern.

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
    $self->{config}->{anti_spambot_policy} = 'spell'
	if (!defined $self->{config}->{anti_spambot_policy});
    $self->{config}->{anti_spambot_at} = ' at '
	if (!defined $self->{config}->{anti_spambot_at});
    $self->{config}->{anti_spambot_dot} = ' dot '
	if (!defined $self->{config}->{anti_spambot_dot});
    $self->{config}->{anti_spambot_prefix} = '&lt;'
	if (!defined $self->{config}->{anti_spambot_prefix});
    $self->{config}->{anti_spambot_suffix} = '&gt;'
	if (!defined $self->{config}->{anti_spambot_suffix});
} # init

=head1 Flow Action Methods

Methods implementing actions.

=head2 anti_spambot_redirect_mail

$self->anti_spambot_redirect_mail($flow_state)

If the AntiSpambot parameters are present, redirect to a mailto: URL

=cut
sub anti_spambot_redirect_mail {
    my $self = shift;
    my $flow_state = shift;

    if ($self->{dynamic}
	and defined $self->{config}->{anti_spambot_user_param}
	and $self->param($self->{config}->{anti_spambot_user_param})
	and defined $self->{config}->{anti_spambot_domain_param}
	and $self->param($self->{config}->{anti_spambot_domain_param})
       )
    {
	my $user =
	    $self->param($self->{config}->{anti_spambot_user_param});
	my $domain =
	    $self->param($self->{config}->{anti_spambot_domain_param});
	$|++;
	print "Location: mailto:$user\@$domain\n";
	print "Content-type: text/plain\n";
	print "\n";
	print "Email to $user\@$domain!\n";
	$flow_state->{stop} = 1;
    }
    1;
} # anti_spambot_redirect_mail

=head1 Entry Action Methods

Methods implementing per-entry actions.

=head2 anti_spambot_obscure_mail

$self->anti_spambot($flow_state, $current_entry, $entry_state)

Alters $current_entry->{body} by substituting mail links with
obfustcated links.

=cut
sub anti_spambot_obscure_mail {
    my $self = shift;
    my $flow_state = shift;
    my $current_entry = shift;
    my $entry_state = shift;

    if ($current_entry->{body})
    {
	if ($self->{config}->{anti_spambot_policy} eq 'spell')
	{
	    $current_entry->{body} =~
		s/<a\s+href\s*=\s*['"]mailto:([-_+.\w]+\@[-_+\w.]+)['"]\s*>\s*([^<]+)\s*<\/a>/$self->_anti_spambot_do_spell($1,$2)/eisg;
	}
	elsif (($self->{config}->{anti_spambot_policy} eq 'cgi_link'
		or $self->{config}->{anti_spambot_policy} eq 'form')
	       and defined $self->{config}->{anti_spambot_user_param}
	       and defined $self->{config}->{anti_spambot_domain_param})
	{
	    $current_entry->{body} =~
		s/<a\s+href\s*=\s*['"]mailto:([-+_.\w]+)\@([-_+\w.]+)['"]\s*>\s*([^<]+)\s*<\/a>/$self->_anti_spambot_do_link($1,$2,$3)/eisg;
	}
    }

    1;
} # anti_spambot_obscure_mail

=head1 Private Methods

=head2 _anti_spambot_do_spell

Return the stuff to be substituted in found links.

=cut
sub _anti_spambot_do_spell {
    my $self = shift;
    my $link = shift;
    my $label = shift;

    if ($label eq $link)
    {
	$link = $self->_anti_spambot_spell_out($link);
	return join('', 
		    $self->{config}->{anti_spambot_prefix},
		    $link,
		    $self->{config}->{anti_spambot_suffix});
    }
    else
    {
	$label = $self->_anti_spambot_spell_out($label) if ($label =~ /\@/);
	$link = $self->_anti_spambot_spell_out($link);
	return join('', $label, ' ',
		    $self->{config}->{anti_spambot_prefix},
		    $link,
		    $self->{config}->{anti_spambot_suffix});
    }

} # _anti_spambot_do_spell

=head2 _anti_spambot_spell_out

Spell out one mail address subsituting just the at and dots.

=cut
sub _anti_spambot_spell_out {
    my $self = shift;
    my $mail = shift;

    my $at = $self->{config}->{anti_spambot_at};
    my $dot = $self->{config}->{anti_spambot_dot};
    $mail =~ s/\@/$at/;
    $mail =~ s/\./$dot/g;

    return $mail;
} # _anti_spambot_spell_out

=head2 _anti_spambot_do_link

Return the stuff to be substituted in found links.

=cut
sub _anti_spambot_do_link {
    my $self = shift;
    my $user = shift;
    my $domain = shift;
    my $label = shift;

    $label = $self->_anti_spambot_spell_out($label) if ($label =~ /\@/);
    if ($self->{config}->{anti_spambot_policy} eq 'cgi_link')
    {
	return join('', '<a href="', $self->{url}, '?',
		    $self->{config}->{anti_spambot_user_param}, '=',
		    $user,
		    '&amp;',
		    $self->{config}->{anti_spambot_domain_param}, '=',
		    $domain,
		    '">', $label, '</a>');
    }
    elsif ($self->{config}->{anti_spambot_policy} eq 'form')
    {
	return join('',
		    '<form style="display: inline; margin: 0; padding: 0" method="post" action="',
		    $self->{url}, '">',
		    "\n<div>",
		    '<input type="hidden" name="',
		    $self->{config}->{anti_spambot_user_param},
		    '" value="', $user, '"/>',
		    '<input type="hidden" name="',
		    $self->{config}->{anti_spambot_domain_param},
		    '" value="', $domain, '"/>',
		    '<button name="submit" type="submit">',
		     $label,
		     "\n</button></div></form>");
    }

} # _anti_spambot_do_link

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

Copyright (c) 2005 by Kathryn Andersen http://www.katspace.com

Based in part on the Nomailto.pl script
Written by Greg Mullane <greg AT turnstep DOT com>
http://www.turnstep.com/Spambot/

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Posy::Plugin::AntiSpambot
__END__

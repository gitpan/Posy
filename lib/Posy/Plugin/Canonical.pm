package Posy::Plugin::Canonical;
use strict;

=head1 NAME

Posy::Plugin::Canonical - Posy plugin to force redirect to canonical URL.

=head1 VERSION

This describes version B<0.10> of Posy::Plugin::Canonical.

=cut

our $VERSION = '0.10';

=head1 SYNOPSIS

    @plugins = qw(Posy::Core
		  Posy::Plugin::Canonical);

=head1 DESCRIPTION

Have Posy force a redirect if a URI is not in canonical form with
respect to index.* component, trailing slash, or flavour extension.

This replaces the parse_path method.

=cut

=head1 Flow Action Methods

Methods implementing actions.

=head2 parse_path

Parse the path info.  This calls the parent parse_path and then
redirects to the canonical path if the original path isn't canonical
(and we are in dynamic mode).

=cut
sub parse_path {
    my $self = shift;
    my $flow_state = shift;

    $self->SUPER::parse_path($flow_state);
    my $path_info = $self->{path}->{info};
    $self->debug(1, "Canonical: path_info='$path_info'");
    if ($self->{dynamic} && !$self->{path}->{error})
    {
	# Write the desired canonical URI, then check if the
	# original path is canonical; if not, redirect.
	my $can_path;

	# categories
	if ($self->{path}->{type} eq 'category'
	    or ($self->{path}->{type} eq 'entry'
		and $self->{path}->{basename} eq 'index'))
	{
	    # canonical: dir with slash
	    $can_path = '/' . $self->{path}->{dir} . '/';
	    # if this is not the default flavour, put index.foo at end
	    if ($self->{path}->{flavour} ne $self->{config}->{flavour})
	    {
		$can_path .= 'index.' . $self->{path}->{flavour};
	    }
	}
	# because the top index page has often to be treated specially,
	# only redirect for this if enabled.
	elsif ($self->{redirect_top}
	       and ($self->{path}->{type} eq 'top'
		    or ($self->{path}->{type} eq 'top_entry'
			and $self->{path}->{basename} eq 'index')
		   )
	      )
	{
	    # canonical: slash
	    $can_path = '/';
	    # if this is not the default flavour, put index.foo at end
	    if ($self->{path}->{flavour} ne $self->{config}->{flavour})
	    {
		$can_path .= 'index.' . $self->{path}->{flavour};
	    }
	}
	elsif ($self->{path}->{type} eq 'entry'
	    and $self->{path}->{basename} ne 'index')
	{
	    # canonical: dir with slash then entry.foo
	    $can_path = '/' . $self->{path}->{dir} . '/'
		. $self->{path}->{basename}
		. '.'
		. $self->{path}->{flavour};
	}
	elsif ($self->{path}->{type} eq 'top_entry'
	    and $self->{path}->{basename} ne 'index')
	{
	    # canonical: dir with slash then entry.foo
	    $can_path = '/' 
		. $self->{path}->{basename}
		. '.'
		. $self->{path}->{flavour};
	}
	elsif ($self->{path}->{type} eq 'chrono')
	{
	    # Chronological selection is expected to be at the end of the path
	    # and can be year, year/month or year/month/day
	    $can_path = '/' . $self->{path}->{dir} . '/'
		. $self->{path}->{year} . '/';
	    $can_path .= $self->{path}->{month} . '/'
		if $self->{path}->{month};
	    $can_path .= $self->{path}->{day} . '/'
		if $self->{path}->{day};
	}
	else # some other type -- leave it alone
	{
	    $can_path = $self->{path}->{info};
	}
	$self->debug(1, "Canonical: path='$can_path'");

	if ($can_path ne $self->{path}->{info})
	{
	    my $uri = $self->{url} . $can_path;
	    $uri .= "?" . $ENV{QUERY_STRING} if $ENV{QUERY_STRING};
	    $self->redirect($flow_state, $uri);
	}
    }

    1;
} # parse_path

=head1 Helper Methods

Methods which can be called from elsewhere.

=head2 redirect

    $self->redirect($flow_state, $uri);

Redirect to the given URI.

=cut
sub redirect {
    my $self = shift;
    my $flow_state = shift;
    my $uri = shift;

    $flow_state->{stop} = 1;
    if ($self->{dynamic})
    {
	$self->debug(1, "redirecting to '$uri'");

	print "Content-Type: text/html\n";
	print "Status: 301\n";
	print "Location: $uri\n";
	print "\n";
	print "<html><body>\n";
	print "<p>Redirecting to <a href=\"$uri\">$uri</a>.\n";
	print "</body></html>\n";

	return 1;
    }
} # redirect

=head1 REQUIRES

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

Original canonicaluri blosxom plugin copyright 2004
Frank Hecker <hecker@hecker.org>, http://www.hecker.org/

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the "Software"),
to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

=cut

1; # End of Posy::Plugin::Canonical
__END__

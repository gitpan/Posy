package Posy::Plugin::CgiCarp;
use strict;
use warnings;

=head1 NAME

Posy::Plugin::CgiCarp - Posy plugin to aid debugging by using CGI::Carp

=head1 VERSION

This describes version B<0.10> of Posy::Plugin::CgiCarp.

=cut

our $VERSION = '0.10';

=head1 SYNOPSIS

    @plugins = qw(Posy::Core
	...
	Posy::Plugin::CgiCarp));

=head1 DESCRIPTION

This plugin is for developers to aid debugging by making all fatal errors
and warning messages be displayed in the browser by using the CGI::Carp
module.

=head2 Activation

This plugin needs to be added to the plugins list.

=cut
use CGI::Carp qw(fatalsToBrowser warningsToBrowser);

=head1 Flow Action Methods

Methods implementing actions.

=head2 stop_if_not_found

If there was an error parsing the path ($self->{path}->{error} is true)
then flag the actions to stop.

Also sends a 404 error if we are in dynamic mode; this assumes that
if it can't parse the path, it can't find the file.

This is done as a separate action method so that it makes it easier
to change this behaviour.

=cut
sub stop_if_not_found {
    my $self = shift;
    my $flow_state = shift;

    if ($self->{path}->{error})
    {
	$flow_state->{stop} = 1;
	if ($self->{dynamic})
	{
	    print "Content-Type: text/plain\n";
	    print "Status: 404\n";
	    print "\n";
	    warningsToBrowser(1);
	    print "404 page '", $self->{path}->{info}, "' not found";
	}
    }
} # stop_if_not_found

=head2 render_page

$self->render_page(\%flow_state);

Put the page together by pasting together 
its parts in the flow_state hash
and print it (either to a file, or to STDOUT).
If printing to a file, don't print content_type

=cut
sub render_page {
    my $self = shift;
    my $flow_state = shift;

    if (defined $self->{outfile}
	and $self->{outfile}) # print to a file
    {
	my $fh;
	if (open $fh, ">$self->{outfile}")
	{
	    warningsToBrowser(1);
	    print $fh $flow_state->{head};
	    print $fh @{$flow_state->{page_body}};
	    print $fh $flow_state->{foot};
	    close($fh);
	}
    }
    else {
	print 'Content-Type: ', $flow_state->{content_type}, "\n\n";
	warningsToBrowser(1);
	print $flow_state->{head};
	print @{$flow_state->{page_body}};
	print $flow_state->{foot};
    }
    1;	
} # render_page

=head1 Helper Methods

Methods which can be called from within other methods.

=head2 debug

Print a debug message (for debugging)
Checks $self->{'debug_level'}

=cut
sub debug {
    my $self = shift;
    my $level = shift;
    my $message = shift;

    if ($level <= $self->{'debug_level'})
    {
	carp "DEBUG: ", $message;
    }
} # debug

=head1 REQUIRES

    CGI::Carp
    Posy::Core
    Posy

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

Based in part on the 'css' blosxom plugin by
Eric Davis <edavis <at> foobargeek <dot> com> http://www.foobargeek.com
And in part on the 'flavourmenu' blosxom plugin by
Tim Lambert (lambert <at> cse <dot> unsw <dot> edu <dot> au)

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Posy::Plugin::CgiCarp
__END__

package Posy::Plugin::Dump;
use strict;
use warnings;

=head1 NAME

Posy::Plugin::Dump - Posy plugin to aid debugging by dumping object contents

=head1 VERSION

This describes version B<0.11> of Posy::Plugin::Dump.

=cut

our $VERSION = '0.11';

=head1 SYNOPSIS

    @plugins = qw(Posy::Core
	...
	Posy::Plugin::Dump));
    @actions = qw(init_params
	    parse_path
	    stop_if_not_found
	    ...
	    dump
	);

=head1 DESCRIPTION

This plugin is for developers to aid debugging by "dumping" the contents of
$self and the "state" hashes to STDERR when it is called.  Provides a 'dump'
method which can be put as an action into the actions list or into the
entry_actions list (or both).

=head2 Activation

This plugin needs to be added to both the plugins list and the actions
list.  It doesn't really matter where it is in the plugins list.

In the (entry_)actions list, it goes whereever you want it to go.

=cut
use Data::Dumper;

=head1 Flow Action Methods

Methods implementing actions.

=head2 dump

    $self->dump();
    $self->dump($flow_state);
    $self->dump($flow_state, $current_entry, $entry_state);

Dump object data (for debugging)

This can be called as a flow action or as an entry action, and will
dump the given state hashes accordingly.

=cut
sub dump {
    my $self = shift;
    my $flow_state = (@_ ? shift : undef);
    my $current_entry = (@_ ? shift : undef);
    my $entry_state = (@_ ? shift : undef);

    my $class = ref $self;
    my $oh = \*STDERR;
    print $oh "Posy=", Dumper($self);
    if (exists $self->{cgi} and defined $self->{cgi})
    {
	print $oh "params:\n";
	my @params = $self->{cgi}->param();
	foreach my $param (@params)
	{
	    print $oh "$param=", $self->{cgi}->param($param), "\n";
	}
    }
    if (defined $flow_state)
    {
	print $oh "flow_state=", Dumper($flow_state);
    }
    if (defined $current_entry)
    {
	print $oh "current_entry=", Dumper($current_entry);
    }
    if (defined $entry_state)
    {
	print $oh "entry_state=", Dumper($entry_state);
    }
} # dump

=head1 REQUIRES

    Data::Dumper
    Posy::Core
    Posy

    Test::More

=head1 SEE ALSO

perl(1).
Posy
Data::Dumper

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

1; # End of Posy::Plugin::Dump
__END__

package Posy::Plugin::YamlConfig;
use strict;

=head1 NAME

Posy::Plugin::YamlConfig - Posy plugin to read config files in YAML format

=head1 VERSION

This describes version B<0.02> of Posy::Plugin::YamlConfig.

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

    @plugins = qw(Posy::Core Posy::Plugin::YamlConfig);

=head1 DESCRIPTION

This uses the YAML module to parse config files, instead of the
default name:value format.  This enables config values to be
more complicated than simple strings; they can be arrays and hashes,
put in a simple format that's user-friendly.

For a simple name:value set of config variables, the only difference
between YAML format and Posy::Core format is that the file has to
start with a line of three dashes:

    ---
    site_title: My Wonderful Site
    sort_type: path

See L</YAML> for further details of YAML format.  If you have problems with
a particular config file, use the ysh program to help figure out what's
wrong and fix it.  (If the YAML module is installed, so should ysh be)

This replaces the 'read_config_file' method, and returns the hash
of values read.

=cut

use YAML;

=head1 Helper Methods

Methods which can be called from within other methods.

=head2 read_config_file

$self->read_config_file($filename);

Read the given config file, and return a hash of config settings from it.
The $filename is the full name of the file to read.

The config file is expected to be in YAML format.

=cut
sub read_config_file {
    my $self = shift;
    my $filename = shift;

    $self->debug(2, "read_config_file: $filename");
    my %config;
    if (-r $filename)
    {
	my $hashref = YAML::LoadFile($filename);
	%config = %{$hashref} if $hashref;
	return %config;
    }
    return ();
} # read_config_file


=head1 REQUIRES

    YAML

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

1; # End of Posy::Plugin::YamlConfig
__END__

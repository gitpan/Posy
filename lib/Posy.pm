package Posy;
use strict;
use warnings;

=head1 NAME

Posy - a website generator inspired by blosxom

=head1 VERSION

This describes version B<0.01> of Posy.

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    require Posy;

    Posy->import(@plugins);
    Posy->run(%args);

=head1 DESCRIPTION

This is a simple website content management system / blog inspired
by the design of blosxom.  The filesystem is the database, there
are flavour templates, and plugins.  However, this system doesn't
require one to write one's entry files in a particular format; one
can choose from pure HTML, plain text, or blosxom format.  And other
formats can be dealt with if one writes a plugin to deal with them.

=cut

use File::Spec;
use File::stat;
use FileHandle;

=head1 CLASS METHODS

=head2 import

Posy->import(@plugins);

This needs to be run before L</run>.
See L<Posy::Core> for more information.

This loads plugins, modules which subclass Posy and override its methods
and/or make additional methods.  The arguments of this method are the
module names, in the order in which they should be loaded.  The given
modules are required and arranged in an "is-a" chain.  That is, Posy
subclasses the last plugin given, which subclasses the second-to-last, up
to the first plugin given, which is the base class.

(idea taken from Module::Starter by Andy Lester and Ricardo Signes)

=cut
sub import {
    my $class = shift;

    my @plugins = @_ ? @_ : 'Posy::Core';
    my $parent;

    no strict 'refs';
    for (@plugins, $class) {
        if ($parent) {
            eval "require $parent;"; 
            die "couldn't load plugin $parent: $@" if $@;
            push @{"${_}::ISA"}, $parent;
        }
        $parent = $_;
    }
} # import

=head1 REQUIRES

    File::Spec
    File::stat
    FileHandle

    File::Find
    Data::Dumper
    Storable
    Carp
    CGI

    Test::More

=head1 INSTALLATION

To install this module, run the following commands:

    perl Build.PL
    ./Build
    ./Build test
    ./Build install

Or, if you're on a platform (like DOS or Windows) that doesn't like the
"./" notation, you can do this:

   perl Build.PL
   perl Build
   perl Build test
   perl Build install

In order to install somewhere other than the default, such as
in a directory under your home directory, like "/home/fred/perl"
go

   perl Build.PL --install_base /home/fred/perl

as the first step instead.

This will install the files underneath /home/fred/perl.

You will then need to make sure that you alter the PERL5LIB variable to
find the modules, and the PATH variable to find the script.

Therefore you will need to change:
your path, to include /home/fred/perl/script (where the script will be)

	PATH=/home/fred/perl/script:${PATH}

the PERL5LIB variable to add /home/fred/perl/lib

	PERL5LIB=/home/fred/perl/lib:${PERL5LIB}


=head1 SEE ALSO

perl(1).

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

1; # End of Posy
__END__

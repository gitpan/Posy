package Posy;
use strict;

=head1 NAME

Posy - a website generator inspired by blosxom

=head1 VERSION

This describes version B<0.72> of Posy.

=cut

our $VERSION = '0.72';

=head1 SYNOPSIS

    # use the posy_static script
    posy_static --flavour_dir /home/fred/posy/flavours ...

    # use the posy CGI script
    http://www.example.com/posy.cgi/top/wibbles/?theme_css=Midnight

    # from within a script
    require Posy;

    my @plugins = qw(Posy::Core Posy::Plugin::TextTemplate);
    Posy->import(@plugins);
    Posy->run(%args);

    # implicit loading from within a script
    use Posy qw(Posy::Core Posy::Plugin::TextTemplate);

=head1 DESCRIPTION

This is a simple website content management system inspired
by the design of blosxom.  The filesystem is the database, there
are flavour templates, and plugins.  However, this system doesn't
require one to write one's entry files in a particular format; one
can choose from pure HTML, plain text, or blosxom format.  And other
formats can be dealt with if one writes a plugin to deal with them.

This distribution includes a CGI script (posy.cgi) and two command-line
scripts (posy_static, posy_one) which use the Posy engine to process input
data files into web-page output.

It also includes a number of plugins.

=head2 Terms

A few terms:

=over

=item data_dir, data directory

The directory where the input data files are kept.  This need not be the
same directory as the posy.cgi script or any other script.  This is set up
with sub-directories in a hierarchical fashion and chiefly contains the
files holding the web content you wish to display.

=item state_dir, state directory

The directory where "state" files are written.  Thus this needs
to be a directory writable by the script, which may need special
care when using Posy with a CGI script, since the user and permissions
tend to be tricky with CGI scripts.

=item config_dir, config directory

The directory where configuration files are kept, in a hierarchical
manner which mirrors that of the data directory.
This defaults to being the same directory as the data_dir.

=item flavour_dir, flavour directory

The directory where flavour files are kept (see L</flavour>), in a
hierarchical manner which mirrors that of the data directory.

=item full path, full filename

The absolute location of a given file; the absolute pathname.

=item path

(a) the relative location of a file (relative to the data directory
or to the top of the website, depending on context)
(b) the current request path (which may or may not be the relative location
of a file)

=item path-type

The type of request path.  This can be "entry", for an individual file,
"category", for a sub-directory, "chrono" for a dated request, "top_entry"
for an entry at the top of the website, "top_category", for the very root page,
or "file" for a file which is not an entry.

=item basename

The "base" name of a file.  So a file called /wibbles.txt would have a
basename of "wibbles".

=item chunk

A given output page is pasted together from several chunks, each of which
has a "flavour" template for it.  The chunks are:

=over

=item content_type

The MIME-type of the output page.  Usually this is text/html, but some
variations may call for text/plain or something else.

=item head

The "head" part of the page; which usually includes the opening
<html> tag, the <head> content, and the opening <body> tag and
any initial content required.

=item header

A header part of a page; something which may or may not be repeated
over the page, depending on how its contents change.

=item entry

The template for the actual page content; for pages which source multiple
entry-files per page, this is repeated for each entry file.
An entry file is just an individual input content file.

=item foot

The "foot" part of the page; usually contains trailing content,
and the closing </body> and </html> tags.

=back

=item flavour

The Posy system, like the blosxom system, enables use of multiple
template-sets by giving them a "flavour" extension, which can be
parsed from the initial request path by either the extension of
the request path, or by a "flav" parameter.  One can then set up
a different template-set for each flavour, and customize the look
of the output pages while keeping the content separate.

=back

=cut

=head1 CLASS METHODS

=head2 import

require Posy;

Posy->import(@plugins);

This needs to be run before L</run>.
See L<Posy::Core> for more information.

This loads plugins, modules which subclass Posy and override its methods
and/or make additional methods.  The arguments of this method are the
module names, in the order in which they should be loaded.  The given
modules are required and arranged in an "is-a" chain.  That is, Posy
subclasses the last plugin given, which subclasses the second-to-last, up
to the first plugin given, which is the base class.

This can be called in two different ways.  It can be called implicitly
with the "use" directive, or it can be called explicitly if one 'requires'
Posy rather then 'use'-ing it.

The advantage of calling this explicitly is that one can set the
plugins dynamically, rather than hard-coding them in the calling
script.

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

    File::Find
    Data::Dumper
    Storable
    CGI::Minimal

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

Copyright (c) 2004-2005 by Kathryn Andersen

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Posy
__END__

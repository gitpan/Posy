package Posy;
use strict;

=head1 NAME

Posy - a website generator inspired by blosxom

=head1 VERSION

This describes version B<0.95> of Posy.

=cut

our $VERSION = '0.95';

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

=item base_dir, base directory

For convenience, one can just set a "base" directory and Posy will
set the data_dir to being $base_dir/data, the state_dir to being
$base_dir/state, and the flavour_dir to being $base_dir/flavours
and the config_dir to being the same as data_dir.

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

=head1 REQUIRES

    File::Spec
    File::Copy
    File::stat

    File::Find
    Data::Dumper
    Storable
    CGI::Minimal

    Test::More

=head1 INSTALLATION

Since this is a set of modules and scripts for a website-generator, then
installation needs will vary depending on the particular setup a person
has.  There are two parts to the installation, no matter the setup:
installing the modules, and installing the CGI script.

This section covers installing the modules.  The instructions for
installing the CGI script are in the script itself; just run perldoc on it.

    perldoc ./posy.cgi

But first, the modules.

=head2 Administrator, Automatic

If you are the administrator of the system, then the dead simple method of
installing the modules is to use the CPAN or CPANPLUS system.

    cpanp -i Posy

This will install the modules and the B<posy_static> and B<posy_one>
scripts in the usual places which they get installed when one is using
CPAN(PLUS).

Note, however, that this does NOT install the CGI script, and that this
will need to be done separately.  Therefore you will need to grovel around
to find the directory into which the Posy source was placed, in order to
get at the CGI script to install it.  Therefore you may find it simpler
to just download the Posy tarball and install it by hand.

Or, you may wish to install the Posy bundle:

    cpanp -i Bundle-Posy

This installs not only the base Posy system, but all the major plugins.
You still have to install the posy.cgi by hand, though.

=head2 Administrator, By Hand

If you are the administrator of the system, but don't wish to use the
CPAN(PLUS) method, then this is for you.  Take the Posy-*.tar.gz file
and untar it in a suitable directory.

    tar -xzvf Posy-0.81.tar.gz
    cd Posy-0.81

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

=head2 User With Shell Access

If you are a user on a system, and don't have root/administrator access,
you need to install Posy somewhere other than the default place (since you
don't have access to it).  However, if you have shell access to the system,
then you can install it in your home directory.

Say your home directory is "/home/fred", and you want to install the
modules into a subdirectory called "perl".

Download the Posy-*tar.gz file.

    tar -xzvf Posy-0.81.tar.gz
    cd Posy-0.81
    perl Build.PL --install_base /home/fred/perl
    ./Build
    ./Build test
    ./Build install

This will install the files underneath /home/fred/perl.

You will then need to make sure that you alter the PERL5LIB variable to
find the modules, and the PATH variable to find the scripts (posy_one,
posy_static).

Therefore you will need to change:
your path, to include /home/fred/perl/script (where the script will be)

	PATH=/home/fred/perl/script:${PATH}

the PERL5LIB variable to add /home/fred/perl/lib

	PERL5LIB=/home/fred/perl/lib:${PERL5LIB}

If you alter these in your setup files (e.g. .login) then they will be
set when you log in, and you will be able to run the scripts without
having to do anything special.

However, please take note of the value you used for PERL5LIB -- you will
need this when setting up the CGI script.

=head2 User With FTP-only Access

Okay, so you have an ISP/Web-Host, where you have your site, and you want
to use Posy for it.  You can ftp files from your PC to your site, but you
don't have shell access.  The most sensible thing I can think of is that
you set up your entire site on your own PC at home, and then mirror it with
FTP on your account with your ISP.  If your ISP uses Linux, then it would
probably be easier on you if you got Linux as well. (But how to install
Linux is definitely beyond the scope of this document!)

So follow the instructions for L</User With Shell Access>, but I can't
guarantee that it will work, since if you don't have shell access on the
system which has your web pages, it will be harder to troubleshoot if
things go wrong.

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

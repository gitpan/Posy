#!/usr/bin/perl -T
# vim:ts=8 sw=4 sts=4 ai
require v5.6.1;
$ENV{PATH} ="/bin:/usr/bin:/usr/local/bin";
delete @ENV{ 'IFS', 'CDPATH', 'ENV', 'BASH_ENV'};
use strict;

=head1 NAME

posy.cgi - CGI script using the Posy website generator

=head1 VERSION

This describes version B<0.92> of posy.cgi.

=cut

our $VERSION = '0.92';

=head1 SYNOPSIS

posy.cgi?path=/reviews/movies/

posy.cgi/reviews/movies/

=head1 DESCRIPTION

CGI script using the Posy web content manager.

=head1 INSTALLATION

First of all, install the Posy modules.  (See L<Posy>)

Edit the first line of "posy.cgi" if the location of perl is not in
"/usr/bin/perl".

=head2 Where To Put The CGI Script

=over

=item in cgi-bin

If your ISP/Web-Host only allows CGI scripts to be in the cgi-bin
directory on your website, then copy the posy.cgi script into that
directory and make it executable.

=item anywhere .cgi

If your ISP/Web-Host allows CGI scripts to be run from any directory,
then it's up to you to figure out where to put the posy.cgi script.
Don't forget to make it executable.

You could also rename it to 'index.cgi' and stick it in whatever directory
you want to be controlled by Posy (whether that's your whole site, or a
sub-directory).

=item on your own server

If you're running your own server, well, you can set up either one of the
above scenarios yourself.

=back

=head2 Where To Put The Data Directories

Posy gets its information -- entries, flavour files, configuration files --
from one or more data directories.  The default setup is to have
one data directory, with a few sub-directories in it, for the entries
(data), flavours (flavours) and state (state) directories.  (See below for
more information on the individual directories).

=over

=item in your home directory

If you aren't running your own server, then likely you'll just have access
to your home directory.  You don't have to put the data directories under
public_html, you can make them separate.  For example

    /home/fred/posy_data/docs
    /home/fred/posy_data/flavours

=item somewhere global

If you are running your own server, you may wish to put the data
directories somewhere more global, like /var/www/posy or something like
that.

=back

=head2 Configuration

For simplicity's sake, the initial (bootstrap) configuration settings for
posy are held in this script itself.  Therefore if you can't actually edit
the script after it has been copied into its final destination, you will
need to edit it beforehand.

Some configuration settings are essential, some can be left at the default.

Essential:

=over

=item libdir

If you installed the Posy modules in your home directory, then
you need to tell this script where to look for them.  Set $libdir
to that directory.

For example, if you installed the Posy modules in /home/fred/perl
(and thus the Posy.pm module file is in /home/fred/perl/lib)
then

    BEGIN {
	$libdir = '/home/fred/perl/lib';
    }

This assumes that any Posy plugins are also under the same directory.
(Note that the $libdir MUST be set inside the BEGIN block, or it won't find
the Posy modules or the plugin modules.  It's a perl thing, don't worry.)

If you run your own server and installed the Posy modules globally, $libdir
does not need to be set.

=cut

our $libdir;
BEGIN {
    $libdir = '';
}

=item base_dir

Posy needs to be told where to look for the data, as well as being told
where to look for the modules.  The data is in four directories: data_dir
(for the entry files), flavour_dir (for the flavour templates), config_dir
(for the configuration files) and state_dir (for the "state" files).

The most convenient way to set these is to simply give a "base" data
directory, under which these directories live.

    our $base_dir = '/var/www/posy';

In this case, if not overridden, this would set:

    data_dir -> /var/www/posy/data
    flavour_dir -> /var/www/posy/flavours
    config_dir -> /var/www/posy/data (same as data_dir)
    state_dir -> /var/www/posy/state

=cut

our $base_dir = '/var/www/posy';

=back

Optional:

=over

=item data_dir

If you don't set base_dir, you need to set this.  If you want to override
the default if you I<did> set base_dir, then set this.

    our $data_dir = '/home/fred/posy_data/docs';
    our $data_dir = '/var/www/posy/docs';

=cut

our $data_dir;

=item flavour_dir

The directory where "flavour" template files are put.
The default value is "flavours" under the base directory.
If you don't set base_dir, you need to set this.  If you want to override
the default if you I<did> set base_dir, then set this.

    our $flavour_dir = "/home/fred/posy_data/flavours";

=cut
our $flavour_dir;

=item config_dir

If you want your config files to be in a different
directory to data_dir, then change this value.

    our $config_dir = '/var/www/posy/config';

=cut
our $config_dir;

=item state_dir

The directory where "state" information is put.  The default value is
"state" under the base directory.
If you don't set base_dir, you need to set this.  If you want to override
the default if you I<did> set base_dir, then set this.

=cut

our $state_dir;

=item url

What is my preferred base URL for this posy site?  (leave unset for
automatic)

    our $url = 'http://www.example.com/posy/';
    our $url = '/~fred/';

=cut

our $url;

=item plugins

If you wish to use any plugins, you must put them in the plugins list,
as well as installing the actual plugin modules.  Some plugins also require
adding actions to the L</actions> or L</entry_actions> lists.

For example, if you are using the Posy::Plugin::TextTemplate module,
then the TextTemplate.pm file should be installed in the same way
that you installed the core Posy modules.

Then you add the name of the plugin to this plugins list.
Always put Posy::Core first.

    my @plugins = qw(Posy::Core Posy::Plugin::TextTemplate);

Remember that the order of plugins in the list is important if two
plugins override the same method.

=cut

our @plugins;

=item file_extensions

If you wish to change the default file extensions, then set this.
Generally one would only do this if one had added a plugin to deal
with a new kind of file, or if you want to use a different extension
for a standard type of file.
 
    our %file_extensions = (
	txt=>'text',
	html=>'html',
	blx=>'blosxom',
	);

=cut

our %file_extensions;

=item actions

The list of actions which Posy will perform.  Only alter this if you're using
a plugin which requires adding a new action.

    our @actions = qw(init_params
	    parse_path
	    process_path_error
	    set_config
	    index_entries
	    select_entries
	    filter_by_date
	    sort_entries
	    content_type
	    head_template
	    foot_template
	    head_render
	    do_entry_actions
	    foot_render
	    render_page
	);

=cut

our @actions;

=item entry_actions

The list of actions which Posy will perform on each entry.  Only alter this if
you're using a plugin which requires adding a new entry action.

    our @entry_actions = qw(
	    count_or_stop
	    read_entry
	    parse_entry
	    head_render
	    header
	    entry_template
	    render_entry
	    append_entry
	    foot_render
	);

=cut

our @entry_actions;

=item DayWeek2Name

This is a hash which sets how a day-of-the-week number will be
converted into a name.  Change this if you want, for example,
all weekdays to be truncated, or in another language.

=cut
our %DayWeek2Name = ( 0 => 'Sunday',
	    1 => 'Monday',
	    2 => 'Tuesday',
	    3 => 'Wednesday',
	    4 => 'Thursday',
	    5 => 'Friday',
	    6 => 'Saturday');

=item MonthNum2Name

This is a hash which sets how a month-number will be
converted into a name.  Change this if you want, for example,
all month-names to be truncated, or in another language.

=cut
our %MonthNum2Name = (1=>'January',
	    2=>'February',
	    3=>'March',
	    4=>'April',
	    5=>'May',
	    6=>'June',
	    7=>'July',
	    8=>'August',
	    9=>'September',
	    10=>'October',
	    11=>'November',
	    12=>'December'
	);

=back

=head1 SEE ALSO

L<perl(1)>
L<Posy>
L<Posy::Core>

=cut

#========================================================
# Subroutines

#========================================================
# Main

eval "use lib '$libdir'" if $libdir;
die "invalid libdir $libdir: $@" if $@;
my $class='Posy';
eval "require $class;";
die "invalid starter class $class: $@" if $@;

$class->import(@plugins);

my %run_args = (
		base_dir=>$base_dir,
		DayWeek2Name=>\%DayWeek2Name,
		MonthNum2Name=>\%MonthNum2Name,
		debug_level=>0,
	       );
# set the other options, if they exist
$run_args{data_dir} = $data_dir if $data_dir;
$run_args{flavour_dir} = $flavour_dir if $flavour_dir;
$run_args{config_dir} = $config_dir if $config_dir;
$run_args{state_dir} = $state_dir if $state_dir;
$run_args{url} = $url if defined $url;
$run_args{file_extensions} = \%file_extensions if %file_extensions;
$run_args{actions} = \@actions if @actions;
$run_args{entry_actions} = \@entry_actions if @entry_actions;

$class->run(%run_args);

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

__END__

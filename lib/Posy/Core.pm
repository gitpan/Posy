package Posy::Core;
use strict;

=head1 NAME

Posy::Core - the core methods for the Posy generator

=head1 VERSION

This describes version B<0.90> of Posy::Core.

=cut

our $VERSION = '0.90';

=head1 SYNOPSIS

    # implicitly
    use Posy qw(Posy::Core Posy::Plugin::TextTemplate ...);

    # or explicitly
    require Posy;

    @plugins = qw(Posy::Core Posy::Plugin::TextTemplate ...);
    Posy->import(@plugins);
    Posy->run(%args);

=head1 DESCRIPTION

This is a simple website content management system inspired
by the design of blosxom.  The filesystem is the database, there
are flavour templates, and plugins.  However, this system doesn't
require one to write one's entry files in a particular format; one
can choose from pure HTML, plain text, or blosxom format.  And other
formats can be dealt with if one writes a plugin to deal with them.

Posy::Core provides the core functionality of the system.  Other
functions can be added and overridden by plugin modules.

=cut

use File::Spec;
use File::stat;
use File::Find;

=head1 CLASS METHODS

=head2 run

Posy->run(%args);

C<run> is the only method you should need to use from outside
this module; other methods are called internally by this one.

This method orchestrates all the work; it creates a new object,
and applies all the actions.

Arguments include:

=over

=item B<actions>

The actions that should be performed by the Posy engine.  If none
are given, then the default sequence will be used.

=item B<entry_actions>

The actions which should be performed on each entry.  If none are
given, then the default sequence will be used.

=item B<base_dir>

The directory to use as a prefix when setting the default locations
of the data_dir, the flavour_dir, the config_dir and the state_dir.
This is just for convenience; if those directories are given in the
arguments, we use those.
(default: the current directory)

=item B<data_dir>

The directory where the entry data is.

=item B<state_dir>

The directory where the state-related data is (what used to be "plugins/state"
in blosxom).

=item B<flavour_dir>

The directory where the flavour template files are.

=item B<config_dir>

The directory where the configuration files are.  Defaults to being
the same as B<data_dir>.

=item B<debug_level>

Setting the debug_level to something other then 0 will turn on varying
levels of debugging output.  The higher the number, the more voluminous
the output (though generally most debugging messages are either level 1
or level 2).

=back

=cut
sub run {
    my $class = shift;

    my $self = $class->new(@_);
    $self->init();

    $self->do_actions();
} # run

=head1 OBJECT METHODS

Documentation for developers and those wishing to write plugins.

=head2 new

Make a new object.  See L</run> for the arguments.

=cut

sub new {
    my $class = shift;
    my $self = bless ({@_}, ref ($class) || $class);

    return ($self);
} # new

=head2 init

Do some initialization of the object after it's created.
Set up defaults for things which haven't been defined.

Plugin writers should override this method rather than L</new>
if they want to do some initialization for their plugin.

=cut

sub init {
    my $self = shift;

    if (!defined $self->{file_extensions})
    {
	$self->{file_extensions} = { txt=>'text', html=>'html', blx=>'blosxom'};
    }
    if (!defined $self->{actions})
    {
	$self->{actions} = [qw(init_params
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
	)];
    }
    if (!defined $self->{entry_actions})
    {
	$self->{entry_actions} = [qw(
	    count_or_stop
	    read_entry
	    parse_entry
	    head_render
	    header
	    entry_template
	    render_entry
	    append_entry
	    foot_render
	)];
    }
    if (!defined $self->{DayWeek2Name})
    {
	$self->{DayWeek2Name} = { 0 => 'Sunday',
	    1 => 'Monday',
	    2 => 'Tuesday',
	    3 => 'Wednesday',
	    4 => 'Thursday',
	    5 => 'Friday',
	    6 => 'Saturday'};
    }
    if (!defined $self->{MonthNum2Name})
    {
	$self->{MonthNum2Name} = {1=>'January',
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
	};
    }

    # tidy up a few bits of data
    if (! ref $self->{actions}) # is a string
    {
	$self->{actions} = [split(/(?:\s*,\s*|\s+)/, $self->{actions})];
    }
    if (! ref $self->{entry_actions}) # is a string
    {
	$self->{entry_actions} = [split(/(?:\s*,\s*|\s+)/, $self->{entry_actions})];
    }
    if (! ref $self->{file_extensions}) # is a string
    {
	$self->{file_extensions} = {split(/(?:\s*,\s*|\s+)/, $self->{file_extensions})};
    }
    my $extensions_re = join('|', keys %{$self->{file_extensions}});
    $self->{extensions_re} = qr/($extensions_re)/;
    $self->{debug_level} ||= 0;

    $self->{base_dir} ||= File::Spec->rel2abs('.');
    $self->{data_dir} ||= File::Spec->catdir($self->{base_dir}, 'data'); 
    $self->{data_dir} =~ s#/$##;
    $self->{config_dir} ||= $self->{data_dir};
    $self->{state_dir} ||= File::Spec->catdir($self->{base_dir}, 'state'); 
    $self->{flavour_dir} ||= File::Spec->catdir($self->{base_dir},
						'flavours'); 

    # set the error templates if not already set
    $self->{templates}->{content_type}->{error} ||= 'text/html';
    $self->{templates}->{head}->{error} ||=
		'<html><body><p><font color="red">Error: I\'m afraid this is the first I\'ve heard of a "$path_flavour" flavoured Posy.  Try dropping the "/.$path_flavour" bit from the end of the URL.</font>';
    $self->{templates}->{header}->{error} ||= '<h3>$entry_dw, $entry_da $entry_month $entry_year</h3>';
    $self->{templates}->{entry}->{error} ||=
		'<p><b>$entry_title</b><br />$entry_body <a href="$url/$path_cat_id/$path_basename.$config_flavour">#</a></p>';
    $self->{templates}->{foot}->{error} ||= '</body></html>';

    #
    # set default config things if they aren't already set
    #
    $self->{config}->{site_title} = 'My Web Site'
	if (!defined $self->{config}->{site_title});
    $self->{config}->{flavour} = 'html'
	if (!defined $self->{config}->{flavour});

    # note the current time
    $self->{now} = time;
    my @tarr = localtime($self->{now});
    $self->{this_year} = $tarr[5] + 1900;
    $self->{this_month} = $tarr[4] + 1;

    return ($self);
} # init

=head2 do_actions

$self->do_actions();

Do all the actions in the $self->{actions} list.  (Called from L</run>).

=cut
sub do_actions {
    my $self = shift;

    my %state = ();
    $state{stop} = 0;

    no strict qw(subs refs);
    # pop off each action as we go;
    # that way it's possible for an action to
    # manipulate the actions array
    while (@{$self->{actions}})
    {
	my $action = shift @{$self->{actions}};
	last if $state{stop};
	$state{action} = $action;
	$self->debug(1, "action: $action");
	$self->$action(\%state);
    }
    use strict qw(subs refs);
    1;
} # do_actions

=head1 Flow Action Methods

Methods implementing actions.  All such methods expect a
reference to a flow-state hash, and generally will update
either that hash or the object itself, or both in the course
of their running.

=head2 init_params

Parse the global parameters.
Creates a CGI object in $self->{cgi} and checks whether we are
in a CGI environment (dynamic) or not (static) and sets
$self->{dynamic} and $self->{static} accordingly.

Note that "static" does not mean the same thing as with blosxom2;
what actions are performed depend entirely on the $self->{actions} array;
it won't be trying to generate all the files just because we
aren't in CGI mode.

Sets $self->{url} if it isn't already set.

When this is not in dynamic mode, the parameters can be set (a) by giving
them on the command line and (b) by passing them through the
$self->{params} hash (by setting params=>{...} when calling L</new> or
L</run>).  This can be useful for writing scripts that aren't CGI scripts.
Note that the command-line is checked before the $self->{params}
hash, so it is probably best, if writing a script, to use one method
or the other but not both.

=cut
sub init_params {
    my $self = shift;
    my $flow_state = shift;

    use CGI::Minimal;

    if ($ENV{GATEWAY_INTERFACE}) {
	$self->{dynamic} = 1;
	$self->{static} = 0;
	# if we were redirected in a non-standard way, check query string
	if (!$ENV{QUERY_STRING} and $ENV{REDIRECT_QUERY_STRING})
	{
	    $ENV{QUERY_STRING} = $ENV{REDIRECT_QUERY_STRING};
	}
	$self->{cgi} = new CGI::Minimal;
    }
    else
    {
	$self->{dynamic} = 0;
	$self->{static} = 1;
	# trick CGI::Minimal into NOT reading STDIN
	# but give it the contents of @ARGV instead
	$ENV{REQUEST_METHOD} = 'GET';
	$ENV{QUERY_STRING} = join(';', @ARGV);
	$self->{cgi} = new CGI::Minimal;

	# set the parameters from $self->{params}
	if (exists $self->{params} and defined $self->{params})
	{
	    while (my ($key, $val) = each %{$self->{params}})
	    {
		$self->{cgi}->param($key=>$val);
	    }
	}
    }
    # only set $self->{url} if it isn't defined; this allows users
    # to define an empty URL for static generation
    if (!defined $self->{url})
    {
	$self->{url} = $self->_url();
    }
} # init_params

=head2 parse_path

Parse the PATH_INFO (or 'path' parameter) to get the parts of the path
and figure out various bits of information about the path.
If the path is undefined, uses DOCUMENT_URI or REDIRECT_URL.

This checks whether or not the requested file/directory exists
under the data directory.

Sets $self->{path} hash as follows:

=over

=item info

The original PATH_INFO or equivalent.

=item type

The type of the path: entry, top_entry, category, top_category chrono, file.

=item file_key

The path in unix style without the extension; used as a key in $self->{files}.

=item ext

The extension of the actual entry file or "file" file.

=item data_file

The full path of the found file.

=item basename

The base name of the file without directory or extension.

=item cat_id

The directory (category) part of the path in unix style.

=item depth

The depth of the file from the top directory.

=item flavour

The flavour of the request.

=item name

The path directory with underscores instead of slashes.

=item year

For "chrono" paths, the year part of the request.

=item month

For "chrono" paths, the month part of the request.  Optional.

=item day

For "chrono" paths, the day part of the request.  Optional.

=back

Expects parameters to have been initialized (so that it can check
$self->param('path') as well as PATH_INFO).

If it fails to parse the path, sets $self->{path}->{error} to true,
and $self->{path}->{info} will be the only other part set.
This can be used by later actions, such as L</process_path_error>.

=cut
sub parse_path {
    my $self = shift;
    my $flow_state = shift;

    my $data_dir = $self->{data_dir};
    my $path_type = '';
    my $path_info = $ENV{PATH_INFO} || $self->param('path');
    $path_info = $ENV{DOCUMENT_URI} if (!defined $path_info);
    $path_info = $ENV{REDIRECT_URL} if (!defined $path_info);
    $self->{path}->{info} = $path_info;
    $self->debug(2, "parse_path: path_info=$path_info");
    # set the status to 200 until not found
    $self->{path}->{status} = 200;

    my ($path_and_filebase, $suffix) = $path_info =~ /^(.*)\.(\w+)$/;
    $path_and_filebase = $path_info if (!$suffix);
    $path_and_filebase =~ s#^\./##; # remove an initial "./"
    $path_and_filebase =~ s#^/##;
    $path_and_filebase =~ s#/$##;
    my $flavour = $suffix || $self->param('flav') || $self->{config}->{flavour};
    $self->{path}->{flavour} = $flavour;

    # note that the PATH will be in the standard this/is/a/dir form
    # so just use split
    my @path_split = split(/\//, $path_and_filebase);
    my $full_no_ext = File::Spec->catdir($data_dir, @path_split);
    my $full_path_info = ($suffix ? "${full_no_ext}.$suffix" : $full_no_ext);
    # look for a possible filename
    my ($fullname, $ext) = $self->_find_file_and_ext($full_no_ext);

    if ($fullname) # is an entry
    {
	$self->{path}->{type} = 'entry';
	$self->{path}->{file_key} = $path_and_filebase;
	$self->{path}->{ext} = $ext;
	$self->{path}->{data_file} = $fullname;
	$self->{path}->{basename} = pop @path_split;
	$self->{path}->{cat_id} = (@path_split ? join('/', @path_split) : '');
	$self->{path}->{depth} = @path_split;
    }
    elsif (-f $full_path_info) # is a file
    {
	$self->{path}->{type} = 'file';
	$self->{path}->{file_key} = $path_and_filebase;
	$self->{path}->{ext} = $suffix;
	$self->{path}->{data_file} = $full_path_info;
	$self->{path}->{basename} = pop @path_split;
	$self->{path}->{cat_id} = (@path_split ? join('/', @path_split) : '');
	$self->{path}->{depth} = @path_split;
    }
    elsif (-d $full_no_ext) # is a category
    {
	# check for an existing "index" entry first
	my $fpaf = File::Spec->catfile($full_no_ext, 'index');
	($fullname, $ext) = $self->_find_file_and_ext($fpaf);
	if ($fullname) # is an entry
	{
	    $self->{path}->{type} = 'entry';
	    $self->{path}->{file_key} = 
		($path_and_filebase ? "${path_and_filebase}/index"
		    : 'index');
	    $self->{path}->{ext} = $ext;
	    $self->{path}->{data_file} = $fullname;
	    $self->{path}->{basename} = 'index';
	    $self->{path}->{cat_id} = $path_and_filebase;
	    $self->{path}->{depth} = @path_split;
	}
	else # is really a category
	{
	    $self->{path}->{type} = 'category';
	    $self->{path}->{file_key} = $path_and_filebase;
	    $self->{path}->{cat_id} = $path_and_filebase;
	    $self->{path}->{ext} = '';
	    $self->{path}->{basename} = '';
	    $self->{path}->{data_file} = '';
	    $self->{path}->{depth} = @path_split;
	}
    }
    elsif ($path_and_filebase eq 'index') # is the top page
    {
	$self->{path}->{type} = 'top_category';
	$self->{path}->{file_key} = '';
	$self->{path}->{cat_id} = '';
	$self->{path}->{ext} = '';
	$self->{path}->{basename} = '';
	$self->{path}->{data_file} = '';
	$self->{path}->{depth} = 0;
    }
    else
    {
	# Could be a chrono or an index; check the last part of the path
	# Chronological selection is expected to be at the end of the path
	# and can be year, year/month or year/month/day
	# I'm going to be pedantic and say that a year must be
	# four digits long, and the other date components must be 1 or 2 digits
	my $last_bit = pop @path_split;
	$full_no_ext = (@path_split
	    ?  File::Spec->catdir($data_dir, @path_split)
	    : $data_dir);
	if (-d $full_no_ext)
	{
	    if ($last_bit eq 'index') # is a category index
	    {
		$self->{path}->{type} = 'category';
		$self->{path}->{file_key} = join('/', @path_split);
		$self->{path}->{cat_id} = $self->{path}->{file_key};
		$self->{path}->{ext} = '';
		$self->{path}->{basename} = '';
		$self->{path}->{data_file} = '';
		$self->{path}->{depth} = @path_split;
	    }
	    elsif ($last_bit =~ /\d+/) # assume it's a chrono
	    {
		if ($last_bit =~ /^\d{4}$/) # a year
		{
		    $self->{path}->{type} = 'chrono';
		    $self->{path}->{year} = $last_bit;
		    $self->{path}->{file_key} = '';
		    $self->{path}->{cat_id} = join('/', @path_split);
		    $self->{path}->{ext} = '';
		    $self->{path}->{basename} = '';
		    $self->{path}->{data_file} = '';
		    $self->{path}->{depth} = @path_split;
		}
		elsif ($last_bit =~ /^\d{1,2}$/) # a month? a day?
		{
		    # make it the current year
		    $self->{path}->{type} = 'chrono';
		    $self->{path}->{year} = $self->{this_year};
		    if ($last_bit > 12) # a day
		    {
			# use the current month
			$self->{path}->{month} = $self->{this_month};
			$self->{path}->{day} = $last_bit;
		    }
		    else # a month
		    {
			$self->{path}->{month} = $last_bit;
		    }
		    $self->{path}->{file_key} = '';
		    $self->{path}->{cat_id} = join('/', @path_split);
		    $self->{path}->{ext} = '';
		    $self->{path}->{basename} = '';
		    $self->{path}->{data_file} = '';
		    $self->{path}->{depth} = @path_split;
		}
		else
		{
		    # don't know how to parse this!
		    warn "parse_path: error parsing '$path_info'";
		    $self->{path}->{error} = 1;
		}
	    }
	    else
	    {
		# reference to a non-existant entry/file
		warn "parse_path: error parsing '$path_info'";
		$self->{path}->{error} = 1;
	    }
	}
	else # no category yet
	{
	    my $second_last_bit = pop @path_split;
	    $full_no_ext = File::Spec->catdir($data_dir, @path_split);
	    if (-d $full_no_ext) # yay, it exists!
	    {
		if ($second_last_bit =~ /^\d{4}$/) # a year + a month
		{
		    $self->{path}->{type} = 'chrono';
		    $self->{path}->{year} = $second_last_bit;
		    $self->{path}->{month} = $last_bit;
		    $self->{path}->{file_key} = '';
		    $self->{path}->{cat_id} = join('/', @path_split);
		    $self->{path}->{ext} = '';
		    $self->{path}->{basename} = '';
		    $self->{path}->{data_file} = '';
		    $self->{path}->{depth} = @path_split;
		}
		elsif ($second_last_bit =~ /^\d{1,2}$/) # a month + a day
		{
		    # make it the current year
		    $self->{path}->{type} = 'chrono';
		    $self->{path}->{year} = $self->{this_year};
		    $self->{path}->{month} = $second_last_bit;
		    $self->{path}->{day} = $last_bit;
		    $self->{path}->{file_key} = '';
		    $self->{path}->{cat_id} = join('/', @path_split);
		    $self->{path}->{ext} = '';
		    $self->{path}->{basename} = '';
		    $self->{path}->{data_file} = '';
		    $self->{path}->{depth} = @path_split;
		}
		else
		{
		    # don't know how to parse this!
		    warn "parse_path: error parsing '$path_info'";
		    $self->{path}->{error} = 1;
		}
	    }
	    else # keep looking
	    {
		my $third_last_bit = pop @path_split;
		$full_no_ext = File::Spec->catdir($data_dir, @path_split);
		if (-d $full_no_ext) # yay, it exists!
		{
		    if ($third_last_bit =~ /^\d{4}$/) # a year + a month + day
		    {
			$self->{path}->{type} = 'chrono';
			$self->{path}->{year} = $third_last_bit;
			$self->{path}->{month} = $second_last_bit;
			$self->{path}->{day} = $last_bit;
			$self->{path}->{file_key} = '';
			$self->{path}->{cat_id} = join('/', @path_split);
			$self->{path}->{ext} = '';
			$self->{path}->{basename} = '';
			$self->{path}->{data_file} = '';
			$self->{path}->{depth} = @path_split;
		    }
		    elsif ($third_last_bit =~ /^\d{1,2}$/) # short year?
		    {
			# guestimate the year
			if ($third_last_bit < 50)
			{
			    $third_last_bit += 2000;
			}
			else
			{
			    $third_last_bit += 1900;
			}
			$self->{path}->{type} = 'chrono';
			$self->{path}->{year} = $third_last_bit;
			$self->{path}->{month} = $second_last_bit;
			$self->{path}->{day} = $last_bit;
			$self->{path}->{file_key} = '';
			$self->{path}->{cat_id} = join('/', @path_split);
			$self->{path}->{ext} = '';
			$self->{path}->{basename} = '';
			$self->{path}->{data_file} = '';
			$self->{path}->{depth} = @path_split;
		    }
		    else
		    {
			# don't know how to parse this!
			warn "parse_path: error parsing '$path_info'";
			$self->{path}->{error} = 1;
		    }
		}
		else # huh?
		{
		    # don't know how to parse this!
		    warn "parse_path: error parsing '$path_info'";
		    $self->{path}->{error} = 1;
		}
	    }
	}
    }
    if (!$self->{path}->{error})
    {
	if ($self->{path}->{type} eq 'entry'
	    and $self->{path}->{cat_id} eq '')
	{
	    $self->{path}->{type} = 'top_entry';
	}
	if ($self->{path}->{type} eq 'category'
	    and $self->{path}->{cat_id} eq '')
	{
	    $self->{path}->{type} = 'top_category';
	}

	# make path_name be the path-dir with underscores
	$self->{path}->{name} = $self->{path}->{cat_id};
	$self->{path}->{name} =~ s#/#_#g;
	# and pretty the whole id with '::'
	$self->{path}->{pretty} = $path_and_filebase;
	$self->{path}->{pretty} =~ s#/# :: #g;
	$self->{path}->{pretty} =~ s#_# #g;
	$self->{path}->{pretty} =~ s/(\w+)/\u\L$1/g;
    }

    1;
} # parse_path

=head2 process_path_error

If there was an error parsing the path ($self->{path}->{error} is true)
then flag the actions to stop.

Also sends a 404 error if we are in dynamic mode; this assumes that
if it can't parse the path, it can't find the file.

This is done as a separate action method so that it makes it easier
to change this behaviour.

=cut
sub process_path_error {
    my $self = shift;
    my $flow_state = shift;

    if ($self->{path}->{error})
    {
	$self->{path}->{status} = 404;
	$flow_state->{stop} = 1;
	if ($self->{dynamic})
	{
	    $self->print_header(content_type=>'text/plain');
	    print "404 page '", $self->{path}->{info}, "' not found";
	}
    }
} # process_path_error

=head2 set_config

$self->set_config($flow_state);

Set $self->{config} from the config files.
Takes into account the path, but does not use chunk information;
useful for setting global parameters.

=cut
sub set_config {
    my $self = shift;
    my $flow_state = shift;

    my %config = $self->get_config('');
    while (my ($key, $val) = each %config)
    {
	$self->{config}->{$key} = $val;
    }
} # set_config

=head2 index_entries

Find the entries files, the "other" files, and the categories.
This uses caching by default.

Expects $self->{path} and $self->{config} to be set.

Sets $self->{reindex} if full reindexing has been done.

This will do a full reindex if
(a) there are no caches existing
(b) the 'reindex' parameter is true

This will do a partial reindex (one category) if the 'reindex_cat'
parameter is set to a category id.

This will delete missing files from the indexes if the 'delindex'
parameter is true.

This will add a single new file to the index is it is not there,
and it does exist, and it is the current path request.

=cut

sub index_entries {
    my $self = shift;
    my $flow_state = shift;

    # set the cache info if not already set
    $self->{config}->{use_caching} = 1
	if (!defined $self->{config}->{use_caching});
    $self->{config}->{files_cachefile} ||=
	File::Spec->catfile($self->{state_dir}, 'files.dat');
    $self->{config}->{others_cachefile} ||=
	File::Spec->catfile($self->{state_dir}, 'others.dat');
    $self->{config}->{categories_cachefile} ||=
	File::Spec->catfile($self->{state_dir}, 'categories.dat');

    $self->{reindex} = 1 if ($self->param('reindex'));
    $self->{reindex} = 1 if (!$self->_init_caching());
    if (!$self->{reindex})
    {
	$self->{reindex} = 1 if (!$self->_read_caches());
    }

    if ($self->{reindex}) {
	$self->{files} = {};
	$self->{others} = {};
	$self->{categories} = {};
	$self->debug(1, "reindexing $self->{reindex}");
	find({wanted=>sub { $self->_wanted() },
	    untaint=>1,
	    follow=>$self->{follow_symlinks},
	    },
	     $self->{data_dir});
	$self->_save_caches();
    }
    else {
	# Check for things that just need updating
	my $reindex_cat = $self->param('reindex_cat');
	# since this is a category ID, then need to split it on /
	# to get something which can be turned into a directory path
	my @rc_split = split('/', $reindex_cat);
	my $reindex_dir = File::Spec->catdir($self->{data_dir}, @rc_split);
	if ($reindex_cat and -d $reindex_dir)
	{
	    $self->debug(1, "reindexing $reindex_cat = $reindex_dir");
	    find({wanted=>sub { $self->_wanted() },
		 untaint=>1,
		 follow=>$self->{follow_symlinks},
		 },
		 $reindex_dir);
	    $self->_save_caches();
	}

	# If any files not available, delete them and just save the cache
	if ($self->param('delindex'))
	{
	    $self->debug(1, "checking for deleted files");
	    my $deletions = 0;
	    while (my $key = each %{$self->{files}})
	    { -f $self->{files}->{$key}->{fullname}
		or do { $deletions++; delete $self->{files}->{$key} };
	    }
	    while (my $key = each %{$self->{others}})
	    { -f $key
		or do { $deletions++; delete $self->{others}->{$key} };
	    }
	    while (my $key = each %{$self->{categories}})
	    { -d $self->{categories}->{$key}->{fullname}
		or do { $deletions++; delete $self->{categories}->{$key} };
	    }
	    $self->_save_caches() if $deletions;
	}

	# if the current path entry exists, but is not indexed,
	# set the data for it
	if (!$self->{path}->{error}
	    && !exists $self->{files}->{$self->{path}->{file_key}}
	    && -f $self->{path}->{data_file}
	    && $self->{path}->{type} =~ /entry$/)
	{
	    my $file_id = $self->{path}->{file_key};
	    my $cat_id = $self->{path}->{cat_id};
	    $self->{files}->{$file_id}->{ext} = $self->{path}->{ext};
	    $self->{files}->{$file_id}->{fullname} = $self->{path}->{data_file};
	    $self->{files}->{$file_id}->{basename} = $self->{path}->{basename};
	    $self->{files}->{$file_id}->{cat_id} = $cat_id;
	    $self->{files}->{$file_id}->{mtime} =
		stat($self->{files}->{$file_id}->{fullname})->mtime;
	    @{$self->{files}->{$file_id}->{date}} =
		$self->extract_date($self->{files}->{$file_id}->{mtime});
	    if (!exists $self->{categories}->{$cat_id})
	    {
		my @path_split = split(/\//, $cat_id);
		$self->{categories}->{$cat_id}->{id} = $cat_id;
		$self->{categories}->{$cat_id}->{fullname} =
		    File::Spec->catdir($self->{data_dir}, @path_split);
		$self->{categories}->{$cat_id}->{depth} = $self->{path}->{depth};
		$self->{categories}->{$cat_id}->{basename} = pop @path_split;
		$self->{categories}->{$cat_id}->{num_entries} = 0;
		$self->{categories}->{$cat_id}->{pretty} =
		    $self->{categories}->{$cat_id}->{basename};
		$self->{categories}->{$cat_id}->{pretty} =~ s#_# #g;
		$self->{categories}->{$cat_id}->{pretty} =~ s/(\w+)/\u\L$1/g;
	    }
	    $self->{categories}->{$cat_id}->{num_entries}++
		if ($self->{files}->{$file_id}->{basename} ne 'index');
	    $self->debug(1, "added new file $file_id");
	    $self->_save_caches();
	}
    }
} # index_entries

=head2 select_entries

$self->select_entries($flow_state);

Select entries by looking at the path information.
Assumes that no entries have been selected before.
Sets $flow_state->{entries}.  Assumes it hasn't
already been set.

=cut
sub select_entries {
    my $self = shift;
    my $flow_state = shift;

    if ($self->{path}->{type} eq 'entry'
	or $self->{path}->{type} eq 'top_entry')
    {
	$flow_state->{entries} = [$self->{path}->{file_key}];
    }
    elsif ($self->{path}->{type} eq 'file')
    {
	$flow_state->{entries} = [];
    }
    elsif ($self->{path}->{cat_id} eq '') 
    {
	@{$flow_state->{entries}} = keys %{$self->{files}};
    }
    else
    {
	$flow_state->{entries} = [];
	foreach my $key (keys %{$self->{files}})
	{
	    if (($self->{files}->{$key}->{cat_id} 
		 eq $self->{path}->{cat_id}) # the same directory
		or ($self->{files}->{$key}->{cat_id} 
		    =~ m#^$self->{path}->{cat_id}/#) # a subdir
	       )
	    {
		push @{$flow_state->{entries}}, $key;
	    }
	}
    }
} # select_entries

=head2 filter_by_date

$self->filter_by_date($flow_state);

Filter entries by looking at the date-time information
in $self->{path}.
Assumes that $flow_state->{entries} has already been
populated; updates it.

=cut
sub filter_by_date {
    my $self = shift;
    my $flow_state = shift;

    if ($self->{path}->{type} eq 'chrono')
    {
	my @entries = ();
	foreach my $key (@{$flow_state->{entries}})
	{
	    if ($self->{files}->{$key}->{date}->[0]
		== $self->{path}->{year}
		and ((!exists $self->{path}->{month})
		    or ($self->{path}->{month}
			== $self->{files}->{$key}->{date}->[1]))
		and ((!exists $self->{path}->{day})
		    or ($self->{path}->{day}
			== $self->{files}->{$key}->{date}->[2]))
		)
	    {
		push @entries, $key;
	    }
	}
	@{$flow_state->{entries}} = @entries;
    }
} # filter_by_date

=head2 sort_entries

$self->sort_entries($flow_state);

Sort the selected entries (that is, $flow_state->{entries})
Checks $self->{config}->{sort_type} to determine the sort order.
The possible types are:
time, time_reversed, name, name_reversed, path, path_reversed
(default: time_reversed)

=cut
sub sort_entries {
    my $self = shift;
    my $flow_state = shift;

    # no point sorting if there's only one
    if (@{$flow_state->{entries}} > 1)
    {
	my $sort_type = (defined $self->{config}->{sort_type}
	    ? $self->{config}->{sort_type} : 'time_reversed');
	my $sort_time = ($sort_type eq 'time');
	my $sort_time_reversed = ($sort_type eq 'time_reversed');
	my $sort_name = ($sort_type eq 'name');
	my $sort_name_reversed = ($sort_type eq 'name_reversed');
	my $sort_path = ($sort_type eq 'path');
	my $sort_path_reversed = ($sort_type eq 'path_reversed');
	$self->debug(2, "sort_type=$sort_type");
	$flow_state->{entries} = [ 
	    sort { 
		return
		    ($sort_time_reversed
		     ? ($self->{files}->{$b}->{mtime} <=> 
			$self->{files}->{$a}->{mtime})
		     : ($sort_time
			? ($self->{files}->{$a}->{mtime} <=> 
			   $self->{files}->{$b}->{mtime})
			: ($sort_name
			   ? ($self->{files}->{$a}->{basename} cmp
			      $self->{files}->{$b}->{basename})
			   : ($sort_name_reversed
			      ? ($self->{files}->{$b}->{basename} cmp
				 $self->{files}->{$a}->{basename})
			      : ($sort_path
				 ? ($a cmp $b)
				 : ($b cmp $a)
				)
			     )
			  )
		       )
		    );
	    } @{$flow_state->{entries}} 
	];
    }

    1;	
} # sort_entries

=head2 content_type

$self->content_type($flow_state);

Set the content_type content in $flow_state->{content_type}

=cut
sub content_type {
    my $self = shift;
    my $flow_state = shift;

    my %config = $self->get_config('content_type');
    while (my ($key, $val) = each %config)
    {
	$self->{config}->{$key} = $val;
    }
    my %vars = $self->set_vars($flow_state);
    my $template = $self->get_template('content_type');
    my $content_type = $self->interpolate('content_type', $template, \%vars);
    $content_type =~ s#\n.*##s;
    $flow_state->{content_type} = join('', $content_type);
    1;	
} # content_type

=head2 head_template

$self->head_template($flow_state, $current_entry, $entry_state);

Set the head template in $flow_state->{head_template}
This also sets the $self->{config} for head.

=cut
sub head_template {
    my $self = shift;
    my $flow_state = shift;

    my %config = $self->get_config('head');
    while (my ($key, $val) = each %config)
    {
	$self->{config}->{$key} = $val;
    }
    $flow_state->{head_template} = $self->get_template('head');
    1;	
} # head_template

=head2 foot_template

$self->foot_template($flow_state);

Set the foot template in $flow_state->{foot_template}
This also sets the $self->{config} for foot.

=cut
sub foot_template {
    my $self = shift;
    my $flow_state = shift;

    my %config = $self->get_config('foot');
    while (my ($key, $val) = each %config)
    {
	$self->{config}->{$key} = $val;
    }
    $flow_state->{foot_template} = $self->get_template('foot');
    1;	
} # foot_template

=head2 head_render

$self->head_render($flow_state);

$self->head_render($flow_state, $current_entry, $entry_state);

Interpolate the head template into the head content;
Set the head content in $flow_state->{head}

If called as an entry action, will do nothing unless the current
path type ($self->{path}->{type}) is an entry; if it is an entry,
this will set the entry variables and override the previous
call to head_render -- this can be used to enable entry-specific
head stuff.

=cut
sub head_render {
    my $self = shift;
    my $flow_state = shift;
    my $current_entry = (@_ ? shift : undef);
    my $entry_state = (@_ ? shift : undef);

    if (!$current_entry)
    {
	my %vars = $self->set_vars($flow_state);
	my $template = $flow_state->{head_template};
	$flow_state->{head} = $self->interpolate('head', $template, \%vars);
	$flow_state->{page_body} = [];
    }
    elsif ($current_entry && $self->{path}->{type} =~ /entry$/)
    {
	my %vars = $self->set_vars($flow_state, $current_entry, $entry_state);
	my $template = $flow_state->{head_template};
	$flow_state->{head} = $self->interpolate('head', $template, \%vars);
	$flow_state->{page_body} = [];
    }
    1;	
} # head_render

=head2 foot_render

$self->foot_render($flow_state);

Interpolate the foot template into the foot content;
Set the foot content in $flow_state->{foot}

If called as an entry action, will do nothing unless the current
path type ($self->{path}->{type}) is an entry; if it is an entry,
this will set the entry variables and set $flow_state->{foot}.
If not called as an entry action, will not set $flow_state->{foot}
if the path type is an entry and the foot has already been set.

=cut
sub foot_render {
    my $self = shift;
    my $flow_state = shift;
    my $current_entry = (@_ ? shift : undef);
    my $entry_state = (@_ ? shift : undef);

    if ($self->{path}->{type} =~ /entry$/ and $current_entry)
    {
	$self->debug(2, "foot_render: rendering entry foot");
	my %vars = $self->set_vars($flow_state, $current_entry, $entry_state);
	my $template = $flow_state->{foot_template};
	$flow_state->{foot} = $self->interpolate('foot', $template, \%vars);
    }
    elsif ($self->{path}->{type} !~ /entry/
	and !$current_entry)
    {
	$self->debug(2, "foot_render: rendering non-entry foot");
	my %vars = $self->set_vars($flow_state);
	my $template = $flow_state->{foot_template};
	$flow_state->{foot} = $self->interpolate('foot', $template, \%vars);
    }
    1;	
} # foot

=head2 do_entry_actions

$self->do_entry_actions($flow_state);

Process the $self->{entry_action} list.

=cut
sub do_entry_actions {
    my $self = shift;
    my $flow_state = shift;

    my %current_entry = ();
    $current_entry{stop} = 0;
    my %entry_state = ();

    no strict qw(subs refs);
    # Iterate through the entries array by index;
    # that way it's possible for an action to
    # manipulate the entries array
    for ($current_entry{num}=0;
	$current_entry{num} < @{$flow_state->{entries}};
	$current_entry{num}++)
    {
	my $entry_id = $flow_state->{entries}->[$current_entry{num}];
	$self->debug(2, "entry_id=$entry_id");
	last if $current_entry{stop};
	my $i = $current_entry{num};
	%current_entry = ();
	$current_entry{num} = $i;
	$current_entry{id} = $entry_id;
	$current_entry{basename} = $self->{files}->{$entry_id}->{basename};
	$current_entry{ext} = $self->{files}->{$entry_id}->{ext};
	$current_entry{path} = $self->{files}->{$entry_id}->{cat_id};
	$current_entry{path_name} = $self->{files}->{$entry_id}->{cat_id};
	$current_entry{path_name} =~ s#/#_#g;
	if (!defined $current_entry{path_name}) # oh dear!
	{
	    require Data::Dumper;
	    warn "path_name undefined: entry_id=$entry_id";
	    warn "Posy=", Data::Dumper::Dumper($self);
	}
	$current_entry{path_pretty} = $self->{files}->{$entry_id}->{cat_id};
	$current_entry{path_pretty} =~ s#/# :: #g;
	$current_entry{path_pretty} =~ s#_# #g;
	$current_entry{path_pretty} =~ s/(\w+)/\u\L$1/g;

	%entry_state = ();
	$entry_state{stop} = 0;
	# pop off each action as we go;
	# that way it's possible for an action to
	# manipulate the actions array
	@{$current_entry{entry_actions}} = @{$self->{entry_actions}};
	while (@{$current_entry{entry_actions}})
	{
	    my $action = shift @{$current_entry{entry_actions}};
	    last if $entry_state{stop};
	    $entry_state{action} = $action;
	    $self->debug(1, "entry_action: $action");
	    $self->$action($flow_state,
		\%current_entry,
		\%entry_state);
	}
    }
    use strict qw(subs refs);
    1;
} # do_entry_actions

=head2 render_page

$self->render_page($flow_state);

Put the page together by pasting together 
its parts in the $flow_state hash
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
	    print $fh $flow_state->{head};
	    print $fh @{$flow_state->{page_body}};
	    print $fh $flow_state->{foot};
	    close($fh);
	}
    }
    else {
	$self->print_header(content_type=>$flow_state->{content_type});
	print $flow_state->{head};
	print @{$flow_state->{page_body}};
	print $flow_state->{foot};
    }
    1;	
} # render_page

=head1 Entry Action Methods

Methods implementing per-entry actions.

=head2 count_or_stop

$self->count_or_stop($flow_state, $current_entry, $entry_state)

Increment the $flow_state->{entry_count} and stop the processing of this
entry if it goes beyond the required number in
$self->{config}->{num_entries}.

=cut
sub count_or_stop {
    my $self = shift;
    my $flow_state = shift;
    my $current_entry = shift;
    my $entry_state = shift;

    $flow_state->{entry_count} = 0 if (!exists $flow_state->{entry_count});
    $flow_state->{entry_count}++;
    if ($self->{config}->{num_entries}
	and $flow_state->{entry_count} > $self->{config}->{num_entries})
    {
	$current_entry->{stop} = 1;
	$entry_state->{stop} = 1;
    }
} # count_or_stop

=head2 read_entry

$self->read_entry($flow_state, $current_entry, $entry_state)

Reads in the current entry file.
Sets $current_entry->{raw} with the contents.

=cut
sub read_entry {
    my $self = shift;
    my $flow_state = shift;
    my $current_entry = shift;
    my $entry_state = shift;

    my $fullname = $self->{files}->{$current_entry->{id}}->{fullname};
    {
	my $fh;
	local $/;
	if (-r $fullname
	    and open $fh, $fullname) 
	{
	    $current_entry->{raw} = <$fh>;
	    close($fh);
	}
	else # error
	{
	    warn "Could not open '$fullname' id='$current_entry->{id}'";
	    # skip this entry, but keep processing the rest.
	    $entry_state->{stop} = 1;
	}
    }
    1;
} # read_entry

=head2 parse_entry

$self->parse_entry($flow_state, $current_entry, $entry_state)

Parses $current_entry->{raw} into $current_entry->{title}
and $current_entry->{body}.  For HTML entries, it also sets
$current_entry->{body_attrib} and $current_entry->{html_head}.

The template variables set are therefore:

=over

=item entry_raw

The unaltered entry text.

=item entry_title

The entry title.

=item entry_body

The "body" content of the entry.

=item entry_html_head

The contents of the <head> tag of a HTML entry, minus the <title> tag.

=item entry_body_attrib

The attributes of the body tag, or $self->{config}->{body_attrib}
if no attributes were in the body.

=back

=cut
sub parse_entry {
    my $self = shift;
    my $flow_state = shift;
    my $current_entry = shift;
    my $entry_state = shift;

    my $id = $current_entry->{id};
    my $file_type = $self->{file_extensions}->{$self->{files}->{$id}->{ext}};
    if ($file_type eq 'html')
    {
	$self->debug(2, "$id is html");
	$current_entry->{raw} =~ m#<head>(.*)</head>#si;
	$current_entry->{html_head} = $1;
	$current_entry->{html_head} =~ s#<title>(.*)</title>##si;
	$current_entry->{raw} =~ m#<title>(.*)</title>#si;
	$current_entry->{title} = $1;
	$current_entry->{raw} =~ m#<body([^>]*)>(.*)</body>#is;
	$current_entry->{body_attrib} = $1;
	$current_entry->{body} = $2;
    }
    elsif ($file_type eq 'text')
    {
	$self->debug(2, "$id is txt");
	$current_entry->{raw} =~ m/^(.*)$/mi;
	$current_entry->{title} = $1;
	$current_entry->{html_head} = '';
	# very primitive text HTML-isation
	$current_entry->{body} =
	    join('', "\n<pre>\n", $current_entry->{raw}, "\n</pre>\n");
	$current_entry->{body_attrib} = '';
    }
    # blosxom format
    elsif ($file_type eq 'blosxom')
    {
	$self->debug(2, "$id is blosxom");
	# title on first line, body in the rest
	$current_entry->{raw} =~ m/^(.*)$/mi;
	$current_entry->{title} = $1;
	$current_entry->{html_head} = '';
	$current_entry->{body} = $current_entry->{raw};
	$current_entry->{body} =~ s/^(.*)$//mi;
	$current_entry->{body_attrib} = '';
    }
    else # something else
    {
	$self->debug(2, "$id is something else");
	$current_entry->{title} = '';
	$current_entry->{html_head} = '';
	$current_entry->{body_attrib} = '';
	$current_entry->{body} = $current_entry->{raw};
    }
    $current_entry->{body_attrib} ||= $self->{config}->{body_attrib};
    1;
} # parse_entry

=head2 header

$self->header($flow_state, $current_entry, $entry_state)

Sets the entry date vars for this entry, in $curent_entry.
See L</nice_date_time> for details.

Set the header content in $flow_state->{header}
and add the header to @{$flow_state->{page_body}}
if it is different to the previous header.

=cut
sub header {
    my $self = shift;
    my $flow_state = shift;
    my $current_entry = shift;
    my $entry_state = shift;

    # get the nice date-time info
    my %date_time = $self->nice_date_time($self->{files}->
					  {$current_entry->{id}}->{mtime});
    while (my ($key, $val) = each %date_time)
    {
	$current_entry->{$key} = $val;
    }
    my %config = $self->get_config('header');
    while (my ($key, $val) = each %config)
    {
	$self->{config}->{$key} = $val;
    }
    my %vars = $self->set_vars($flow_state, $current_entry, $entry_state);
    my $template = $self->get_template('header');
    my $header = $self->interpolate('header', $template, \%vars);
    if (!defined $flow_state->{header}
	or ($header ne $flow_state->{header}))
    {
	push @{$flow_state->{page_body}},  $header;
	$flow_state->{header} = $header;
    }
    1;	
} # header

=head2 entry_template

$self->entry_template($flow_state, $current_entry, $entry_state)

Set the entry template in $entry_state->{entry_template}
This also sets the $self->{config} for entry.

=cut
sub entry_template {
    my $self = shift;
    my $flow_state = shift;
    my $current_entry = shift;
    my $entry_state = shift;

    my %config = $self->get_config('entry');
    while (my ($key, $val) = each %config)
    {
	$self->{config}->{$key} = $val;
    }
    $entry_state->{entry_template} = $self->get_template('entry');
    1;	
} # entry_template

=head2 render_entry

$self->render_entry($flow_state, $current_entry, $entry_state)

Interpolate the current entry, replacing $current_entry->{body}.

=cut
sub render_entry {
    my $self = shift;
    my $flow_state = shift;
    my $current_entry = shift;
    my $entry_state = shift;

    my %vars = $self->set_vars($flow_state, $current_entry, $entry_state);
    my $template = $entry_state->{entry_template};
    $current_entry->{body} = $self->interpolate('entry', $template, \%vars);
    1;	
} # render_entry

=head2 append_entry

$self->append_entry($flow_state, $current_entry, $entry_state)

Add $current_entry->{body} to @{$flow_state->{page_body}}
(This is done as a separate step so that plugins can alter
the entry before it's added to the page).

=cut
sub append_entry {
    my $self = shift;
    my $flow_state = shift;
    my $current_entry = shift;
    my $entry_state = shift;

    push @{$flow_state->{page_body}}, $current_entry->{body};
    1;	
} # append_entry

=head1 Helper Methods

Methods which can be called from within other methods.

=head2 param

    my $value = $self->param($name);

Return or set global parameters.

This passes the arguments on to $self->{cgi}->param();
See L<CGI::Minimal> for more information.

=cut
sub param {
    my $self = shift;

    if (defined $self->{cgi}) {
	return $self->{cgi}->param(@_);
    }
    return 0;
} # param

=head2 set_vars

    my %vars = $self->set_vars($flow_state);

    my %vars = $self->set_vars($flow_state, $current_entry, $entry_state);

    $content = $self->interpolate($chunk, $template, \%vars);

Sets variable hashes to be used in interpolation of templates.

This can be called from a flow action or from an entry action, and will
use the given state hashes accordingly.

This sets the variable hash as follows:

=over

=item *

$self->{I<name>} where it is a simple value (eg 'url') -> $I<name>

=item *

$self->{path}->{I<name>} -> $path_I<name>

=item *

$self->param('I<name>') -> $param_<name>

=item *

$self->{config}->{I<name>} -> $config_<name>

=item *

$flow_state->{I<name>} -> $flow_<name>

=item *

$current_entry->{I<name>} -> $entry_<name>

=item *

$entry_state->{I<name>} -> $es_<name>

=back

=cut
sub set_vars {
    my $self = shift;
    my $flow_state = shift;
    my $current_entry = (@_ ? shift : undef);
    my $entry_state = (@_ ? shift : undef);

    my %vars = ();
    # set various global vars
    foreach my $key (keys %{$self})
    {
	if (!ref $self->{$key})
	{
	    $vars{$key} = $self->{$key};
	}
    }
    # set the path vars with path_ prepended
    foreach my $key (keys %{$self->{path}})
    {
	my $nm = "path_$key";
	$vars{$nm} = $self->{path}->{$key};
    }
    # set the param vars with param_ prepended
    my @keys = $self->param();
    foreach my $key (@keys)
    {
	my $nm = "param_$key";
	$vars{$nm} = $self->param($key);
    }
    # set the config vars with config_ prepended
    foreach my $key (keys %{$self->{config}})
    {
	my $nm = "config_$key";
	$vars{$nm} = $self->{config}->{$key};
    }
    # set the flow vars with flow_ prepended
    foreach my $key (keys %{$flow_state})
    {
	my $nm = "flow_$key";
	$vars{$nm} = $flow_state->{$key};
    }
    if (defined $current_entry)
    {
	# set the entry vars with entry_ prepended
	foreach my $key (keys %{$current_entry})
	{
	    my $nm = "entry_$key";
	    $vars{$nm} = $current_entry->{$key};
	}
    }
    if (defined $entry_state)
    {
	# set the entry-state vars with es_ prepended
	foreach my $key (keys %{$entry_state})
	{
	    my $nm = "es_$key";
	    $vars{$nm} = $entry_state->{$key};
	}
    }
    return %vars;
} # set_vars

=head2 get_template

    my $template = $self->get_template($chunk);

Get the template file for this state, taking into account
$self->{path}->{cat_id},
$self->{path}->{type},
$self->{path}->{flavour},
and of course $chunk

Returns (a copy of) the found template.
This is so that the following actions can alter the template as they see fit.

Possible chunks are "content_type", "head", "header", "entry", "foot".
The "header" and "entry" chunks are used during entry processing.

Also looks for alternative path-types (minus the 'top_')

The template files are called

=over

=item *

I<chunk>.I<path_type>.I<basename>.I<flavour>

=item *

I<chunk>.I<alt_path_type>.I<basename>.I<flavour>

=item *

I<chunk>.I<path_type>.I<flavour>

=item *

I<chunk>.I<alt_path_type>.I<flavour>

=item *

I<chunk>.I<flavour>

=back

=cut
sub get_template {
    my $self = shift;
    my $chunk = shift;

    my $cat_id = $self->{path}->{cat_id};
    my $path_type = $self->{path}->{type};
    my $alt_path_type = ($path_type =~ /^top_(.*)$/ ? $1 : '');
    my $flavour = $self->{path}->{flavour} || $self->{config}->{flavour};

    my @path_split = split(/\//, $cat_id);
    my $base_dir = (defined $self->{flavour_dir} and $self->{flavour_dir}
	? $self->{flavour_dir} : $self->{data_dir});
    # to save time, cache the templates, but only as we need them
    # (useful for "header" and "story" templates)
    # if we fail to find one, deliberately set it to undefined

    my $template = '';
    my $found = 0;
    do {
	my $path_id = (@path_split ? join('/', @path_split) : '');
	my $look_dir = ($path_id ?
	    File::Spec->catdir($base_dir, @path_split) : $base_dir);
	# chunk, flavour, path, path_type
	$template = $self->_look_for_template(look_dir=>$look_dir,
	    chunk=>$chunk,
	    flavour=>$flavour,
	    path_id=>$path_id,
	    path_type=>$path_type);
	return $template if (defined $template);
	# chunk, flavour, path, alt_path_type
	if ($alt_path_type)
	{
	    $template = $self->_look_for_template(look_dir=>$look_dir,
						  chunk=>$chunk,
						  flavour=>$flavour,
						  path_id=>$path_id,
						  path_type=>$alt_path_type);
	    return $template if (defined $template);
	}
	# chunk, flavour, path
	$template = $self->_look_for_template(look_dir=>$look_dir,
	    chunk=>$chunk,
	    flavour=>$flavour,
	    path_id=>$path_id,
	    path_type=>'');
	return $template if (defined $template);
    } while (pop @path_split);

    # if all else fails, use the error flavour
    $template = $self->{templates}->{$chunk}->{error};
    return $template;
} # get_template

=head2 get_config

    my %config = $self->get_config($chunk);

Get the config settings for this state, taking into account
$self->{path}->{cat_id},
$self->{path}->{type}
$self->{path}->{basename}
and $chunk

Possible chunks are nothing, "content_type", "head", "header", "entry",
"foot".

The config files are called

=over

=item *

I<path_type>.I<chunk>.I<basename>.config

=item *

I<path_type>.I<basename>.config

=item *

I<chunk>.I<basename>.config

=item *

I<path_type>.I<chunk>.config

=item *

I<path_type>.config

=item *

I<chunk>.config

=item *

config

=back

Returns a hash of cumulative config settings.

=cut
sub get_config {
    my $self = shift;
    my $chunk = shift;

    my $cat_id = $self->{path}->{cat_id};
    my $basename = $self->{path}->{basename};
    my $path_type = ($self->{path}->{type} ? $self->{path}->{type} : '');
    my $alt_path_type = ($path_type =~ /^top_(.*)$/ ? $1 : '');
    my $pathtype_chunk = ($path_type ? "$chunk.$path_type" : $chunk);
    my $alt_pathtype_chunk = ($alt_path_type ? "$chunk.$alt_path_type" : $chunk);

    my @path_split = split(/\//, $cat_id);
    my $base_dir = $self->{config_dir};

    $self->debug(2, "get_config: chunk=$chunk, cat_id=$cat_id, path_type=$path_type");
    # to save time, cache the settings, but only as we need them
    # if we fail to find one, deliberately set it to undefined

    # Put each found hash onto the array of found configs
    # so that we can set them with the correct scope.
    # We are finding them depth-first, so later we will have
    # to look at the array in reverse, so that the deeper
    # configs will override the shallower ones.
    my @config_hashes = ();
    my $found = 0;
    my $conf = undef;
    do {
	my $path_id = (@path_split ? join('/', @path_split) : '');
	my $look_dir = File::Spec->catdir($base_dir, @path_split);
	if ($basename)
	{
	    if ($chunk)
	    {
		# basename, path, path_type, chunk
		$conf = $self->_look_for_config(look_dir=>$look_dir,
						basename=>$basename,
						chunk=>$chunk,
						path_id=>$path_id,
						path_type=>$path_type);
		push @config_hashes, $conf if (defined $conf);
		# basename, path, chunk
		$conf = $self->_look_for_config(look_dir=>$look_dir,
						basename=>$basename,
						chunk=>$chunk,
						path_id=>$path_id,
						path_type=>'');
		push @config_hashes, $conf if (defined $conf);
	    }
	    # basename, path, path_type
	    $conf = $self->_look_for_config(look_dir=>$look_dir,
					    basename=>$basename,
					    path_id=>$path_id,
					    path_type=>$path_type);
	    push @config_hashes, $conf if (defined $conf);
	    # basename, path
	    if ($path_id)
	    {
		$conf = $self->_look_for_config(look_dir=>$look_dir,
						basename=>$basename,
						path_id=>$path_id,
						path_type=>'');
		push @config_hashes, $conf if (defined $conf);
	    }
	    else # basename, top dir
	    {
		$conf = $self->_look_for_config(look_dir=>$base_dir,
						basename=>$basename,
						path_id=>'',
						path_type=>'');
		push @config_hashes, $conf if (defined $conf);
	    }
	}
	if ($chunk)
	{
	    # path, path_type, chunk
	    $conf = $self->_look_for_config(look_dir=>$look_dir,
		chunk=>$chunk,
		path_id=>$path_id,
		path_type=>$path_type);
	    push @config_hashes, $conf if (defined $conf);
	    # path, chunk
	    $conf = $self->_look_for_config(look_dir=>$look_dir,
		chunk=>$chunk,
		path_id=>$path_id,
		path_type=>'');
	    push @config_hashes, $conf if (defined $conf);
	}
	# path, path_type
	$conf = $self->_look_for_config(look_dir=>$look_dir,
					   path_id=>$path_id,
					   path_type=>$path_type);
	push @config_hashes, $conf if (defined $conf);
	# path
	if ($path_id)
	{
	    $conf = $self->_look_for_config(look_dir=>$look_dir,
					       path_id=>$path_id,
					       path_type=>'');
	    push @config_hashes, $conf if (defined $conf);
	}
	else # top dir
	{
	    $conf = $self->_look_for_config(look_dir=>$base_dir,
					       path_id=>'',
					       path_type=>'');
	    push @config_hashes, $conf if (defined $conf);
	}
    } while (pop @path_split);

    my %config = ();
    # go through the config hashes in reverse
    # so that the last found (shallowest) get overridden by the deepest
    foreach my $cfg (reverse @config_hashes)
    {
	while (my ($key, $val) = each %{$cfg})
	{
	    $config{$key} = $val;
	}
    }

    return %config;
} # get_config

=head2 read_config_file

$self->read_config_file($filename);

Read the given config file, and return a hash of config settings from it.
The $filename is the full name of the file to read.

The config file is made up of name:value pairs of data.

=cut
sub read_config_file {
    my $self = shift;
    my $filename = shift;

    $self->debug(2, "read_config_file: $filename");
    my %config;
    if (-r $filename)
    {
	my $fh;
	open($fh, $filename)
		or die "couldn't open config file $filename: $!";
	$self->debug(2, "read_config_file: file found");

	while (<$fh>) { 
		chomp;
		next if /\A\s*\Z/sm;
		if (/\A(\w+):\s*(.+)\Z/sm)
		{
		    my $arg = $1;
		    my $val = $2;
		    $config{$arg} = $val;
		}
	}
	close($fh);
	return %config;
    }
    return ();
} # read_config_file

=head2 interpolate

$content = $self->interpolate($chunk, $template, \%vars);

Interpolate the contents of the vars hash with the template
and return the result.

(This is passed the chunk name just in case a future plugin which overrides
this method wishes to do something different depending on what chunk type
it is.)

=cut
sub interpolate {
    my $self = shift;
    my $chunk = shift;
    my $template = shift;
    my $vars_ref = shift;

    my $content = $template;
    $self->debug(1, "template undefined") if (!defined $template);
    $content =~ s/\$(\w+[\w:]*)/(defined $vars_ref->{$1} ? $vars_ref->{$1} : '')/ge;
    return $content;
} # interpolate

=head2 nice_date_time

    my %nice_vals = $self->nice_date_time($mtime);

Given a unixtime (in seconds since whenever it was)
will return a hash containing the portions of the date-time:

=over

=item sec

The second.

=item min

The minute.

=item hour

The hour (24-hour time).

=item year

The 4-digit year.

=item mnum

The number of the month (1-12).

=item da

The day of the month.

=item wday

The day of the week (number).

=item dw

The day of the week (name).

=item month

The month name.

=back

=cut

sub nice_date_time {
    my $self = shift;
    my $unixtime = shift;

    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =
	localtime($unixtime);
    my %vals = (
	sec=>$sec,
	min=>$min,
	hour=>$hour,
	year=>$year + 1900,
	mnum=>$mon + 1,
	da=>$mday,
	wday=>$wday,
	dw=>($self->{DayWeek2Name}->{$wday}),
	month=>($self->{MonthNum2Name}->{$mon + 1}),
    );
    return %vals;
} # nice_date_time

=head2 print_header

    $self->print_header(content_type=>$content_type,
	status=>$status,
	extra=>$extra);

Print a web-page header, with content-type and any extra things
required for the header.
The default status is $self->{path}->{status}, but this can be
changed by using the 'status' argument if need be.

This is done as a separate method to enable it to be overridden
by plugins such as L<Posy::Plugin::CgiCarp>.

=cut
sub print_header {
    my $self = shift;
    my %args = (
	content_type=>'text/html',
	status=>$self->{path}->{status},
	extra=>'',
	@_
    );
    my $content_type = $args{content_type};
    my $status = $args{status};
    my $extra = $args{extra};

    print "Content-Type: $content_type\n";
    print "Status: $status\n" if $status;
    print $extra, "\n" if $extra;
    print "\n";
} # print_header

=head2 debug

    $self->debug($level, $message);

Print a debug message (for debugging).
Checks $self->{'debug_level'} to see if the message should be printed or
not.

=cut
sub debug {
    my $self = shift;
    my $level = shift;
    my $message = shift;

    if ($level <= $self->{'debug_level'})
    {
	my $oh = \*STDERR;
	print $oh $message, "\n";
    }
} # debug

=head1 Private Methods

Methods which may or may not be here in future.

=head2 _whowasi

For debugging: say who called this 

=cut
sub _whowasi { (caller(1))[3] . '()' }

=head2 _find_file_and_ext

($fullname, $ext) = $self->_find_file_and_ext($full_path_and_filebase);

Returns the full path file and the extentsion of the given
path-plus-basename-of-file; if no matching entry file exists
under the data directory, the returned values are empty strings.

=cut
sub _find_file_and_ext {
    my $self = shift;
    my $full_path_and_filebase = shift;

    my $ext = '';
    my $fullname = '';
    foreach my $aext (sort keys %{$self->{file_extensions}})
    {
	my $full = $full_path_and_filebase . '.' . $aext;
	$self->debug(3, "find_file_end_ext: $full");
	if (-f $full)
	{
	    $ext = $aext;
	    $fullname = $full;
	    return ($fullname, $ext);
	}
    }
    return ($fullname, $ext);
} # _find_file_and_ext

=head2 _look_for_template

Look for the given template with combination of features.

=cut
sub _look_for_template {
    my $self = shift;
    my %args = (
	chunk=>'',
	@_
	);
    my $look_dir = $args{look_dir};
    my $chunk = $args{chunk};
    my $flavour = $args{flavour};
    my $path_id = $args{path_id};
    my $path_type = $args{path_type};

    my $pathtype_chunk = ($path_type ? "$chunk.$path_type" : $chunk);
    my $fh;

    my $template = undef;
    if (exists $self->{templates}->{$chunk}->
	{$flavour}->{path}->{$path_id}->{$path_type}
	and defined $self->{templates}->{$chunk}->
	{$flavour}->{path}->{$path_id}->{$path_type})
    {
	$template = 
	    $self->{templates}->{$chunk}->
	    {$flavour}->{path}->{$path_id}->{$path_type};
	return $template;
    }
    elsif (!exists $self->{templates}->{$chunk}->
	   {$flavour}->{path}->{$path_id}->{$path_type})
    {
	local $/;
	# look for the file
	my $look_file = File::Spec->catfile($look_dir, "$pathtype_chunk.$flavour");
	if (-r $look_file and open($fh, $look_file))
	{
	    my $data = <$fh>;
	    # taint checking
	    $data =~ m/^([^`]*)$/s;
	    $self->{templates}->{$chunk}->
	    {$flavour}->{path}->{$path_id}->{$path_type} = $1;
	    close($fh);
	    $template =
		$self->{templates}->{$chunk}->
		{$flavour}->{path}->{$path_id}->{$path_type};
	    return $template;
	}
	else # not there
	{
	    $self->{templates}->{$chunk}->
	    {$flavour}->{path}->{$path_id}->{$path_type} = undef;
	}
    }
    return undef;
} #_look_for_template

=head2 _look_for_config

Look for the given config with combination of features.

=cut
sub _look_for_config {
    my $self = shift;
    my %args = (
	chunk=>'',
	basename=>'',
	path_type=>'',
	path_id=>'',
	path_type=>'',
	@_
	);
    my $look_dir = $args{look_dir};
    my $chunk = $args{chunk};
    my $basename = $args{basename};
    my $path_id = $args{path_id};
    my $path_type = $args{path_type};


    my $conf_file;
    $conf_file = "${chunk}.${path_type}.${basename}.config"
	if ($path_type and $chunk and $basename);
    $conf_file = "${chunk}.${basename}.config"
	if (!$path_type and $chunk and $basename);
    $conf_file = "${path_type}.${basename}.config"
	if ($path_type and !$chunk and $basename);
    $conf_file = "${chunk}.${path_type}.config"
	if ($path_type and $chunk and !$basename);
    $conf_file = "${basename}.config"
	if (!$path_type and !$chunk and $basename);
    $conf_file = "${path_type}.config"
	if ($path_type and !$chunk and !$basename);
    $conf_file = "${chunk}.config"
	if (!$path_type and $chunk and !$basename);
    $conf_file = 'config'
	if (!$path_type and !$chunk and !$basename);

    my $fh;

    my $config = undef;
    if (exists $self->{configs}->{$path_id}->{$path_type}->{$chunk}->{$basename}
	and defined $self->{configs}->{$path_id}->{$path_type}->{$chunk}->{$basename})
    {
	$config = 
	    $self->{configs}->{$path_id}->{$path_type}->{$chunk}->{$basename};
	return $config;
    }
    elsif (!exists $self->{configs}->{$path_id}->{$path_type}->{$chunk}->{$basename})
    {
	# look for the file
	my $look_file = File::Spec->catfile($look_dir, $conf_file);
	my %cfg = $self->read_config_file($look_file);
	$self->{configs}->{$path_id}->{$path_type}->{$chunk}->{$basename} =
	    (%cfg ? \%cfg : undef);
	return \%cfg if %cfg;
    }
    return undef;
} #_look_for_config

=head2 _wanted

$self->_wanted();

This is a method called from a wrapper 'wanted' function inside
the call to File::Find::find inside the index_entries method.
This does all the work in indexing the entries.

=cut
sub _wanted {
    my $self = shift;

    my $fullname = ($self->{follow_symlinks} ? $File::Find::fullname
	: $File::Find::name);

    if (-r $File::Find::name) {
	if (-d $File::Find::name) # a directory
	{
	    my $dir_base = $_;
	    my $path = File::Spec->abs2rel($File::Find::name,
					   $self->{data_dir});
	    my @path_split = File::Spec->splitdir($path);
	    my $cat_id = join('/', @path_split);
	    if ($dir_base !~ /^\./) # not hidden
	    {
		$self->{categories}->{$cat_id}->{id} = $cat_id;
		$self->{categories}->{$cat_id}->{fullname} = $File::Find::name;
		$self->{categories}->{$cat_id}->{depth} = 
		    (@path_split ? scalar(@path_split) : 0);
		$self->{categories}->{$cat_id}->{basename} =
		    $path_split[$#path_split];
		# make a pretty name
		$self->{categories}->{$cat_id}->{pretty} =
		    $self->{categories}->{$cat_id}->{basename};
		$self->{categories}->{$cat_id}->{pretty} =~ s#_# #g;
		$self->{categories}->{$cat_id}->{pretty} =~ s/(\w+)/\u\L$1/g;

		$self->{categories}->{$cat_id}->{num_entries} = 0;
	    }
	    else
	    {
		$self->{others}->{$File::Find::name} = $cat_id;
	    }
	}
	else {
	    my $path = File::Spec->abs2rel($File::Find::dir, $self->{data_dir});
	    my @path_split = File::Spec->splitdir($path);
	    my $cat_id = join('/', @path_split);
	    my $filename = $_;
	    my $ere = $self->{extensions_re};
	    if ($filename =~ m#^(.+)\.($ere)$#
		and $1 !~ /^\./) # an entry file
	    {
		my $fn_base = $1;
		my $ext = $2;
		my $path_and_filebase = ($cat_id
		    ? join('/', $cat_id, $fn_base) : $fn_base);
		$self->debug(2, "$cat_id:$fn_base:$ext <=> $fullname\n");

		# to show or not to show future entries
		if ($self->{config}->{show_future_entries}
		    or stat($File::Find::name)->mtime <= $self->{now}) 
		{
		    $self->{files}->{$path_and_filebase}->{fullname} =
			$File::Find::name;
		    $self->{files}->{$path_and_filebase}->{cat_id} = $cat_id;
		    $self->{files}->{$path_and_filebase}->{basename} = $fn_base;
		    $self->{files}->{$path_and_filebase}->{ext} = $ext;
		    ( $self->{files}->{$path_and_filebase}->{mtime} = 
		      stat($File::Find::name)->mtime );
		    @{$self->{files}->{$path_and_filebase}->{date}} =
			$self->extract_date(
			    $self->{files}->{$path_and_filebase}->{mtime});
		    if ($cat_id eq ''
			and !exists $self->{categories}->{$cat_id}->{id})
		    {
			# set data for root
			$self->{categories}->{$cat_id}->{id} = $cat_id;
			$self->{categories}->{$cat_id}->{fullname} = $self->{data_dir};
			$self->{categories}->{$cat_id}->{depth} = 0;
			$self->{categories}->{$cat_id}->{basename} = '';
		    }
		    $self->{categories}->{$cat_id}->{num_entries}++
			if ($fn_base ne 'index');
		}
	    }
	    else { # others
		$self->{others}->{$File::Find::name} = $cat_id;
	    }
	}
    }
} # _wanted

=head2 _init_caching

Initialize the caching stuff used by index_entries

=cut
sub _init_caching {
    my $self = shift;

    return 0 if (!$self->{config}->{use_caching});
    eval "require Storable";
    if ($@) {
	$self->debug(1, "cache disabled, Storable not available"); 
	$self->{config}->{use_caching} = 0; 
	return 0;
    }
    if (!Storable->can('lock_retrieve')) {
	$self->debug(1, "cache disabled, Storable::lock_retrieve not available");
	$self->{config}->{use_caching} = 0;
	return 0;
    }
    $self->debug(1, "using caching");
    return 1;
} # _init_caching

=head2 _read_caches

Reads the cached information used by index_entries

=cut
sub _read_caches {
    my $self = shift;

    return 0 if (!$self->{config}->{use_caching});
    $self->{files} = (-r $self->{config}->{files_cachefile}
	? Storable::lock_retrieve($self->{config}->{files_cachefile}) : undef);
    $self->{others} = (-r $self->{config}->{others_cachefile}
	? Storable::lock_retrieve($self->{config}->{others_cachefile}) : undef);
    $self->{categories} = (-r $self->{config}->{categories_cachefile}
	? Storable::lock_retrieve($self->{config}->{categories_cachefile}) : undef);
    if ($self->{categories} && $self->{files} && $self->{others}) {
	$self->debug(1, "Using cached state");
	return 1;
    }
    $self->{files} = {};
    $self->{others} = {};
    $self->{categories} = {};
    $self->debug(1, "Flushing caches");
    return 0;
} # _read_caches

=head2 _save_caches

Saved the information gathered by index_entries to caches.

=cut
sub _save_caches {
    my $self = shift;
    return if (!$self->{config}->{use_caching});
    # create the state dir if it doesn't exist
    if (!-d $self->{state_dir})
    {
	mkdir $self->{state_dir}
	    or die "Cannot create state directory ", $self->{state_dir};
	$self->debug(1, "Creating state dir $self->{state_dir}");
    }
    $self->debug(1, "Saving caches");
    Storable::lock_store($self->{files}, $self->{config}->{files_cachefile});
    Storable::lock_store($self->{others}, $self->{config}->{others_cachefile});
    Storable::lock_store($self->{categories}, $self->{config}->{categories_cachefile});
} # _save_caches

=head2 extract_date

Given a unixtime (in seconds since whenever it was)
will return an array containing the 4-digit year, the month (1-12)
and the day of the month.

=cut

sub extract_date {
    my $self = shift;
    my $unixtime = shift;

    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =
	localtime($unixtime);
    return ($year + 1900, $mon + 1, $mday);
} # extract_date

=head2 _url

Figure out the full url.

=cut
sub _url {
    my $self = shift;

    my $protocol = $self->_protocol();
    my $url = "$protocol://";
    my $vh = $ENV{HTTP_HOST};
    if ($vh) {
	$url .= $vh;
    } else {
	$url .= ($ENV{SERVER_NAME} || 'localhost');
	my $port = $self->_server_port;
	$url .= ":" . $port unless (lc($protocol) eq 'http' && $port == 80)
	    or (lc($protocol) eq 'https' && $port == 443);
    }
    $url .= ($ENV{SCRIPT_NAME} || "/$0" || '');

    $url =~ s/^included:/http:/; # Fix for Server Side Includes (SSI)
    $url =~ s#/$##;
    return $url;
} # url

=head2 _protocol

Figure out the protocol.  (taken from CGI::Simple)

=cut
sub _protocol {
    local($^W)=0;
    my $self = shift;

    return 'https' if uc $ENV{'HTTPS'} eq 'ON';
    return 'https' if $self->_server_port() == 443;
    my( $protocol, $version ) = split '/', $self->_server_protocol();
    return lc $protocol;
} # protocol

=head2 _server_port

And the server port.

=cut
sub _server_port      { $ENV{'SERVER_PORT'} || 80 }

=head2 _server_protocol

And the server protocol.

=cut
sub _server_protocol  { $ENV{'SERVER_PROTOCOL'} || 'HTTP/1.0' }

=head1 REQUIRES

    File::Spec
    File::stat

    File::Find
    Storable
    CGI::Minimal

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

Copyright (c) 2004-2005 by Kathryn Andersen

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Posy::Core
__END__

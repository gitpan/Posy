use strict;
use warnings;
use Test::More;

# only test plugins if they have all the prerequisites for them
BEGIN {
    eval {
	require Text::Template;
	require HTML::TextToHTML;
	require YAML;
    };
    if ($@) {
	plan skip_all => "modules needed for certain plugin modules not installed";
    }
    else {
	plan tests => 9;
    }
}


# run with indexes of various kinds
use File::Spec;
require Posy;
require 't/compare.pl';

my $test = '31_plugins_index';
my $debug_level = 0;
my $state_dir = File::Spec->catdir(File::Spec->rel2abs('blib'), 'state');
my $data_dir = File::Spec->catdir(File::Spec->rel2abs('data'), 'docs');
my $flavour_dir = File::Spec->catdir(File::Spec->rel2abs('data'), 'tt_flavours');
my $config_dir = File::Spec->catdir(File::Spec->rel2abs('data'), 'yconfig');
# main index
my $path = "index.html";
my $outfile = $path;

Posy->import(qw(Posy::Core
    Posy::Plugin::TextTemplate
    Posy::Plugin::TextToHTML
    Posy::Plugin::YamlConfig
    Posy::Plugin::ShortBody));
my @entry_actions = qw(
	    header
	    entry_template
	    read_entry
	    parse_entry
	    short_body
	    render_entry
	    append_entry
	);
my $res = Posy->run(params=>{path=>$path},
		    data_dir=>$data_dir,
		    flavour_dir=>$flavour_dir,
		    state_dir=>$state_dir,
		    config_dir=>$config_dir,
		    entry_actions=>\@entry_actions,
		    debug_level=>$debug_level,
		    outfile=>$outfile);
ok($res, "Posy run path='$path'");
ok(-e $outfile, "$outfile exists");
my $result = compare($outfile, "tfiles/${test}_${outfile}.ok");
ok($result, "$outfile matches tfiles/${test}_${outfile}.ok");
if ($result)
{
    unlink($outfile);
}

$path = "";
$res = Posy->run(params=>{path=>$path},
		 data_dir=>$data_dir,
		 flavour_dir=>$flavour_dir,
		 state_dir=>$state_dir,
		 config_dir=>$config_dir,
		 entry_actions=>\@entry_actions,
		 debug_level=>$debug_level,
		 outfile=>$outfile);
ok($res, "Posy run path='$path'");
ok(-e $outfile, "$outfile exists");
$result = compare($outfile, "tfiles/${test}_${outfile}.ok");
ok($result, "$outfile matches tfiles/${test}_${outfile}.ok");
if ($result)
{
    unlink($outfile);
}

# category index
$path = "plugins/";
$outfile = 'plugins_index.html';
$res = Posy->run(params=>{path=>$path},
		 data_dir=>$data_dir,
		 flavour_dir=>$flavour_dir,
		 state_dir=>$state_dir,
		 config_dir=>$config_dir,
		 entry_actions=>\@entry_actions,
		 debug_level=>$debug_level,
		 outfile=>$outfile);
ok($res, "Posy run path='$path'");
ok(-e $outfile, "$outfile exists");
$result = compare($outfile, "tfiles/${test}_${outfile}.ok");
ok($result, "$outfile matches tfiles/${test}_${outfile}.ok");
if ($result)
{
    unlink($outfile);
}


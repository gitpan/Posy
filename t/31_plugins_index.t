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
my $result = look_for($outfile, '<h3 id="plugins_howto">Plugins HOWTO</h3>')
    and look_for($outfile, '<h3 id="plugins_0intro">Plugins</h3>')
    and look_for($outfile, '<h3 id="_content">Content</h3>')
    and look_for($outfile, '<h3 id="_feedback">Feedback</h3>')
    and look_for($outfile, '<h3 id="_alpha">Alpha</h3>')
    and look_for($outfile, '<h3 id="_welcome">Posy : Welcome</h3>')
    and look_for($outfile, '<h3 id="vr5_index">VR.5: The Wind of the Mind</h3>')
    and look_for($outfile, '<h1>The File Morgan Sent in "Love and Death"</h1>')
    and look_for($outfile, '<h3 id="vr5_confr">Control Freak</h3>');
ok($result, "$outfile matches expected output");
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
$result = look_for($outfile, '<h3 id="plugins_howto">Plugins HOWTO</h3>')
    and look_for($outfile, '<h3 id="plugins_0intro">Plugins</h3>')
    and look_for($outfile, '<h3 id="_content">Content</h3>')
    and look_for($outfile, '<h3 id="_feedback">Feedback</h3>')
    and look_for($outfile, '<h3 id="_alpha">Alpha</h3>')
    and look_for($outfile, '<h3 id="_welcome">Posy : Welcome</h3>')
    and look_for($outfile, '<h3 id="vr5_index">VR.5: The Wind of the Mind</h3>')
    and look_for($outfile, '<h1>The File Morgan Sent in "Love and Death"</h1>')
    and look_for($outfile, '<h3 id="vr5_confr">Control Freak</h3>');
ok($result, "$outfile matches expected output");
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
$result = look_for($outfile, '<h3 id="plugins_howto">Plugins HOWTO</h3>')
    and look_for($outfile, '<h3 id="plugins_0intro">Plugins</h3>');
ok($result, "$outfile matches expected output");
if ($result)
{
    unlink($outfile);
}


use strict;
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

use File::Spec;
require 't/compare.pl';
use Posy qw(Posy::Core
    Posy::Plugin::TextTemplate
    Posy::Plugin::TextToHTML
    Posy::Plugin::YamlConfig
    Posy::Plugin::EntryTitles);

my $test = '30_plugins1';
my $debug_level = 0;
my $state_dir = File::Spec->catdir(File::Spec->rel2abs('blib'), 'state');
my $data_dir = File::Spec->catdir(File::Spec->rel2abs('data'), 'docs');
my $flavour_dir = File::Spec->catdir(File::Spec->rel2abs('data'), 'tt_flavours');
my $config_dir = File::Spec->catdir(File::Spec->rel2abs('data'), 'yconfig');
my $path = "welcome.html";
my $outfile = $path;

my $res = Posy->run(params=>{path=>$path},
		    data_dir=>$data_dir,
		    flavour_dir=>$flavour_dir,
		    state_dir=>$state_dir,
		    config_dir=>$config_dir,
		    debug_level=>$debug_level,
		    outfile=>$outfile);
ok($res, "Posy run path='$path'");
ok(-e $outfile, "$outfile exists");
my $result = look_for($outfile, '<h3 id="_welcome">Posy : Welcome</h3>');
ok($result, "$outfile matches expected output");
if ($result)
{
    unlink($outfile);
}

$path = "plugins/howto.html";
$outfile = "howto.html";
$res = Posy->run(params=>{path=>$path},
		 data_dir=>$data_dir,
		 flavour_dir=>$flavour_dir,
		 state_dir=>$state_dir,
		 config_dir=>$config_dir,
		 debug_level=>$debug_level,
		 outfile=>$outfile);
ok($res, "Posy run path='$path'");
ok(-e $outfile, "$outfile exists");
$result = look_for($outfile, '<h3 id="plugins_howto">Plugins HOWTO</h3>');
ok($result, "$outfile matches expected output");
if ($result)
{
    unlink($outfile);
}

$path = "vr5/mfile.html";
$outfile = "mfile.html";
$res = Posy->run(params=>{path=>$path},
		 data_dir=>$data_dir,
		 flavour_dir=>$flavour_dir,
		 state_dir=>$state_dir,
		 config_dir=>$config_dir,
		 debug_level=>$debug_level,
		 outfile=>$outfile);
ok($res, "Posy run path='$path'");
ok(-e $outfile, "$outfile exists");
$result = look_for($outfile, '<h1>The File Morgan Sent in "Love and Death"</h1>');
ok($result, "$outfile matches expected output");
if ($result)
{
    unlink($outfile);
}

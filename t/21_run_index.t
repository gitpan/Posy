use strict;
use warnings;
use Test::More tests => 18;

# run with indexes of various kinds
use File::Spec;
use Posy;
require 't/compare.pl';

my $test = '21_run_index';
my $debug_level = 0;
my $state_dir = File::Spec->catdir(File::Spec->rel2abs('blib'), 'state');
my $data_dir = File::Spec->catdir(File::Spec->rel2abs('data'), 'docs');
my $flavour_dir = File::Spec->catdir(File::Spec->rel2abs('data'), 'flavours');
# main index
my $path = "index.html";
my $outfile = $path;

Posy->import();
my $res = Posy->run(params=>{path=>$path},
		    data_dir=>$data_dir,
		    flavour_dir=>$flavour_dir,
		    state_dir=>$state_dir,
		    debug_level=>$debug_level,
		    outfile=>$outfile);
ok($res, "Posy run path='$path'");
ok(-e $outfile, "$outfile exists");
my $result = look_for($outfile, '^Plugins HOWTO$')
    and look_for($outfile, '^Plugins$')
    and look_for($outfile, '<h3 id="content">Content</h3>')
    and look_for($outfile, '^Alpha$')
    and look_for($outfile, '<h3 id="welcome">Posy : Welcome</h3>')
    and look_for($outfile, '<h3 id="index">VR.5: The Wind of the Mind</h3>')
    and look_for($outfile, '<h1>The File Morgan Sent in "Love and Death"</h1>')
    and look_for($outfile, '<h3 id="confr">Control Freak</h3>');
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
		 debug_level=>$debug_level,
		 outfile=>$outfile);
ok($res, "Posy run path='$path'");
ok(-e $outfile, "$outfile exists");
$result = look_for($outfile, '^Plugins HOWTO$')
    and look_for($outfile, '^Plugins$')
    and look_for($outfile, '<h3 id="content">Content</h3>')
    and look_for($outfile, '^Alpha$')
    and look_for($outfile, '<h3 id="welcome">Posy : Welcome</h3>')
    and look_for($outfile, '<h3 id="index">VR.5: The Wind of the Mind</h3>')
    and look_for($outfile, '<h1>The File Morgan Sent in "Love and Death"</h1>')
    and look_for($outfile, '<h3 id="confr">Control Freak</h3>');
ok($result, "$outfile matches expected output");
if ($result)
{
    unlink($outfile);
}

# category index
$path = "plugins/index.html";
$outfile = "plugins_index.html";
$res = Posy->run(params=>{path=>$path},
		 data_dir=>$data_dir,
		 flavour_dir=>$flavour_dir,
		 state_dir=>$state_dir,
		 debug_level=>$debug_level,
		 outfile=>$outfile);
ok($res, "Posy run path='$path'");
ok(-e $outfile, "$outfile exists");
$result = look_for($outfile, '^Plugins HOWTO$')
    and look_for($outfile, '^Plugins$');
ok($result, "$outfile matches expected output");
if ($result)
{
    unlink($outfile);
}

$path = "plugins/";
$res = Posy->run(params=>{path=>$path},
		 data_dir=>$data_dir,
		 flavour_dir=>$flavour_dir,
		 state_dir=>$state_dir,
		 debug_level=>$debug_level,
		 outfile=>$outfile);
ok($res, "Posy run path='$path'");
ok(-e $outfile, "$outfile exists");
$result = look_for($outfile, '^Plugins HOWTO$')
    and look_for($outfile, '^Plugins$');
ok($result, "$outfile matches expected output");
if ($result)
{
    unlink($outfile);
}

# index with index entry
$path = "vr5/index.html";
$outfile = 'vr5_index.html';
$res = Posy->run(params=>{path=>$path},
		 data_dir=>$data_dir,
		 flavour_dir=>$flavour_dir,
		 state_dir=>$state_dir,
		 debug_level=>$debug_level,
		 outfile=>$outfile);
ok($res, "Posy run path='$path'");
ok(-e $outfile, "$outfile exists");
$result = look_for($outfile, '<h3 id="index">VR.5: The Wind of the Mind</h3>')
    and look_for($outfile, '<h1>The File Morgan Sent in "Love and Death"</h1>')
    and look_for($outfile, '<h3 id="confr">Control Freak</h3>');
ok($result, "$outfile matches expected output");
if ($result)
{
    unlink($outfile);
}

$path = "vr5";
$res = Posy->run(params=>{path=>$path},
		 data_dir=>$data_dir,
		 flavour_dir=>$flavour_dir,
		 state_dir=>$state_dir,
		 debug_level=>$debug_level,
		 outfile=>$outfile);
ok($res, "Posy run path='$path'");
ok(-e $outfile, "$outfile exists");
$result = look_for($outfile, '<h3 id="index">VR.5: The Wind of the Mind</h3>')
    and look_for($outfile, '<h1>The File Morgan Sent in "Love and Death"</h1>')
    and look_for($outfile, '<h3 id="confr">Control Freak</h3>');
ok($result, "$outfile matches expected output");
if ($result)
{
    unlink($outfile);
}

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
$result = compare($outfile, "tfiles/${test}_${outfile}.ok");
ok($result, "$outfile matches tfiles/${test}_${outfile}.ok");
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
$result = compare($outfile, "tfiles/${test}_${outfile}.ok");
ok($result, "$outfile matches tfiles/${test}_${outfile}.ok");
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
$result = compare($outfile, "tfiles/${test}_${outfile}.ok");
ok($result, "$outfile matches tfiles/${test}_${outfile}.ok");
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
$result = compare($outfile, "tfiles/${test}_${outfile}.ok");
ok($result, "$outfile matches tfiles/${test}_${outfile}.ok");
if ($result)
{
    unlink($outfile);
}

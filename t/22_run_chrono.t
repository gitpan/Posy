use strict;
use warnings;
use Test::More tests => 9;
require 't/compare.pl';

use File::Spec;
use Posy;

# run with chrono paths
my $test = '22_run_chrono';
my $debug_level = 0;
my $state_dir = File::Spec->catdir(File::Spec->rel2abs('blib'), 'state');
my $data_dir = File::Spec->catdir(File::Spec->rel2abs('data'), 'docs');
my $flavour_dir = File::Spec->catdir(File::Spec->rel2abs('data'), 'flavours');
my $path = "2004";
my $outfile = '2004.html';

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

$path = "plugins/2004";
$outfile = 'plugins_2004.html';
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

$path = "2004/12";
$outfile = '2004_12.html';
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


use strict;
use warnings;
use Test::More tests => 9;
# run with entry

use File::Spec;
use Posy;
require 't/compare.pl';

my $test = '20_run_entry';
my $debug_level = 0;
my $state_dir = File::Spec->catdir(File::Spec->rel2abs('blib'), 'state');
my $data_dir = File::Spec->catdir(File::Spec->rel2abs('data'), 'docs');
my $flavour_dir = File::Spec->catdir(File::Spec->rel2abs('data'), 'flavours');
my $path = "welcome.html";
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

$path = "plugins/howto.html";
$outfile = "howto.html";
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

$path = "vr5/mfile.html";
$outfile = "mfile.html";
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

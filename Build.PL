use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Posy',
    license             => 'perl',
    dist_author         => 'Kathryn Andersen',
    dist_version_from   => 'lib/Posy.pm',
	requires            => {
	'File::Spec' => 0,
	'File::Copy' => 0,
	'File::stat' => 0,
	'File::Find' => 0,
	'Storable' => 0,
	'CGI::Minimal' => 0,
	'Getopt::Long' => 2.34,
	'Pod::Usage' => 0,
	'Getopt::ArgvFile' => 1.09,
	},
    build_requires => {
        'Test::More' => 0,
    },
    #add_to_cleanup      => [ 'Posy-*' ],
    script_files => [qw(scripts/posy_static)],

);

$builder->create_build_script();

# create the Makefile.PL
use Module::Build::Compat;
print "creating Makefile.PL\n";
Module::Build::Compat->create_makefile_pl('passthrough', $builder);

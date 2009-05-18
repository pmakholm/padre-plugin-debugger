#
# This file is part of Padre::Plugin::Debug.
# Copyright (c) 2009 Peter Makholm, all rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
#

use strict;
use warnings;

use Module::Build;
my $BuildClass = "Module::Build";

eval {
    require Padre::PluginBuilder;
    $BuildClass = "Padre::PluginBuilder";
};

my $builder = $BuildClass->new(
    module_name         => 'Padre::Plugin::Debugger',
    license             => 'perl',
    dist_author         => 'Peter Makholm <peter@makholm.net>',
    dist_version_from   => 'lib/Padre/Plugin/Debugger.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'Devel::ebug'           => '0.49',
        'File::Basename'        => 0,
        'File::Spec::Functions' => 0,
        'Padre'                 => '0.28',
        'Padre::Plugin'         => '0.28',
        'parent'                => 0,
    },
    meta_merge => {
        resources => {
            repository => 'http://github.com/pmakholm/padre-plugin-debugger/tree/master',
        }
    }

);

$builder->create_build_script();

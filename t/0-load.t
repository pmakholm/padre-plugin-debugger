#
# This file is part of Padre::Plugin::Debugger.
# Copyright (c) 2009 Peter Makholm, all rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
#

use strict;
use warnings;

use Test::More tests => 1;

BEGIN {
    use_ok( 'Padre::Plugin::Debugger' );
}
diag( "Testing Padre::Plugin::Debugger $Padre::Plugin::Debugger::VERSION, Perl $], $^X" );

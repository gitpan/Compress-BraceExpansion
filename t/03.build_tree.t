#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 13;
use_ok( 'Compress::BraceExpansion' );

use lib "t/";
use CompressBraceExpansionTestCases;

while ( my $test_case = CompressBraceExpansionTestCases::get_next_test_case() ) {

    is_deeply( Compress::BraceExpansion::_build_tree_recurse( @{ $test_case->{expanded} } ),
               $test_case->{'tree'},
               $test_case->{'description'},
           );

}

#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 12;
use Compress::BraceExpansion;

use lib "t/";
use CompressBraceExpansionTestCases;


while ( my $test_case = CompressBraceExpansionTestCases::get_next_test_case() ) {

    my ( $output ) = Compress::BraceExpansion::_print_tree_recurse( '', $test_case->{'tree'}->{'ROOT'} );
    is( $output,
        $test_case->{'tree_print'},
        $test_case->{'description'},
    );

}

#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;

use Test::More tests => 12;
use Compress::BraceExpansion;

use lib "t/";
use CompressBraceExpansionTestCases;

while ( my $test_case = CompressBraceExpansionTestCases::get_next_test_case() ) {
    # reset the pointer id
    Compress::BraceExpansion::_reset_pointer_id();

    my ( $tree ) = Compress::BraceExpansion::_merge_tree_recurse( $test_case->{'tree'} );

    is_deeply( $tree,
               $test_case->{'tree_merge'},
               $test_case->{'description'},
           );

}


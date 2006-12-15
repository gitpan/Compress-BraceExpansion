#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;

use Test::More qw(no_plan);
use Compress::BraceExpansion;

{
    my $tree = { 'ROOT' => { a => { b => { c => { 'end' => 1 } } } } };
    my $transplants = { 'POINTERS' => {} };

    my ( $root, $pointers ) = Compress::BraceExpansion::_transplant( $tree, 1, {} );

    is_deeply( $root,
               { 'ROOT' => { 'POINTER' => 'PID:1001' } },
               'root check after transplanting single branch one node deep'
           );

    is_deeply( $pointers,
               { 'POINTERS' => { 'PID:1001' => { 'a' => { 'b' => { 'c' => { 'end' => 1 } } } } } },
               'pointer check after transplanting single branch one node deep'
           );
}

{
    my $tree = { 'ROOT' => { a => { b => { c => { 'end' => 1 } } } } };
    my $transplants = { 'POINTERS' => {} };

    my ( $root, $pointers ) = Compress::BraceExpansion::_transplant( $tree, 2, {} );

    is_deeply( $root,
               { 'ROOT' => { 'a' => { 'POINTER' => 'PID:1002' } } },
               'root check after transplanting single branch 2 nodes deep'
           );

    is_deeply( $pointers,
               { 'POINTERS' => { 'PID:1002' => { 'b' => { 'c' => { 'end' => 1 } } } } },
               'pointer check after transplanting single branch 2 nodes deep'
           );
}


{
    my $tree = { 'ROOT' => { a => { b => { c => { 'end' => 1 } } } } };
    my $transplants = { 'POINTERS' => {} };

    my ( $root, $pointers ) = Compress::BraceExpansion::_transplant( $tree, 3, {} );

    is_deeply( $root,
               { 'ROOT' => { 'a' => { b => { 'POINTER' => 'PID:1003' } } } },
               'root check after transplanting single branch 3 nodes deep'
           );

    is_deeply( $pointers,
               { 'POINTERS' => { 'PID:1003' => { 'c' => { 'end' => 1 } } } },
               'pointer check after transplanting single branch 3 nodes deep'
           );
}


{
    my $tree = { 'ROOT' => { a => { b => { c => { 'end' => 1 } } } } };

    ok( ! eval { Compress::BraceExpansion::_transplant( $tree, 4, {} ) },
        'transplanting single branch past end of tree',
        );

    ok( ! eval { Compress::BraceExpansion::_transplant( $tree, 5, {} ) },
        'transplanting single branch past end of tree',
        );

    ok( ! eval { Compress::BraceExpansion::_transplant( $tree, 6, {} ) },
        'transplanting single branch past end of tree',
        );
}



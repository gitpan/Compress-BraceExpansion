#!/usr/bin/perl -w
use strict;

use Compress::BraceExpansion;

if ( @ARGV ) {
    print Compress::BraceExpansion::shrink( @ARGV );
}
else {
    my @entries;
    while ( <> ) {
        push @entries, split /\s+/;
    }
    print Compress::BraceExpansion::shrink( @entries );
}

exit;

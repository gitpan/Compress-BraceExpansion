#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 23;
use Compress::BraceExpansion;

use lib "t/";
use CompressBraceExpansionTestCases;


while ( my $test_case = CompressBraceExpansionTestCases::get_next_test_case() ) {
    is( Compress::BraceExpansion::shrink( @{ $test_case->{'expanded'} } ),
        $test_case->{'compressed'},
        $test_case->{'description'},
    );
}

is( Compress::BraceExpansion::shrink( qw( aabb aacc ) ),
    "aa{bb,cc}",
    "aabb aacc                                                        = aa{bb,cc}",
);

is( Compress::BraceExpansion::shrink( qw( aabb aacc aad ) ),
    "aa{bb,cc,d}",
    "aabb aacc aad                                                    = aa{bb,cc,d}",
);

is( Compress::BraceExpansion::shrink( qw( app-xy-02a app-xy-02b ) ),
    "app-xy-02{a,b}",
    "app-xy-02a app-xy-02b                                            = app-xy-02{a,b}",
);

is( Compress::BraceExpansion::shrink( qw( app-xy-02a app-zz-02b ) ),
    "app-{xy-02a,zz-02b}",
    "app-xy-02a app-zz-02b                                            = app-{xy-02a,zz-02b}",
);

is( Compress::BraceExpansion::shrink( qw( app-xy-02a app-xy-02b app-xy-03a app-xy-03b ) ),
    "app-xy-0{2,3}{a,b}",
    "app-xy-02a app-xy-02b app-xy-03a app-xy-03b                     = app-xy-0{2,3}{a,b}",
);

is( Compress::BraceExpansion::shrink( qw( app-xy-02a app-xy-02b app-xy-03a app-xy-03b app-xy-09 app-xy-10 ) ),
    "app-xy-{0{2{a,b},3{a,b},9},10}",
    "app-xy-02a app-xy-02b app-xy-03a app-xy-03b app-xy-09 app-xy-10 = app-xy-{0{2{a,b},3{a,b},9},10}",
);

is( Compress::BraceExpansion::shrink( qw( app-xy-02a cci-zz-app03 ) ),
    "{app-xy-02a,cci-zz-app03}",
    "app-xy-02a cci-zz-app03                                         = {app-xy-02a,cci-zz-app03}",
);

is( Compress::BraceExpansion::shrink( qw( xxbbcc yybbcc ) ),
    "{xx,yy}bbcc",
    "xxbbcc yybbcc                                                   = {xx,yy}bbcc",
);

is( Compress::BraceExpansion::shrink( qw( xxbbcc yybbcc zzbbcc ) ),
    "{xx,yy,zz}bbcc",
    "xxbbcc yybbcc zzbbcc                                            = {xx,yy,zz}bbcc",
);

is( Compress::BraceExpansion::shrink( qw( app-xy-02a app-zz-02a ) ),
    "app-{xy,zz}-02a",
    "app-xy-02a app-zz-02a                                           = app-{xy,zz}-02a",
);

is( Compress::BraceExpansion::shrink( qw( htadiehtcjnr htheeehtcjnr ) ),
    "ht{adi,hee}ehtcjnr",
    "htadiehtcjnr htheeehtcjnr                                       = ht{adi,hee}ehtcjnr",
);


#
#_* Future Test Cases
#

# the tree splits, then comes back together, then splits again
# is( Compress::BraceExpansion::shrink( qw( app-xy-02a app-zz-02a app-xy-02b app-zz-02b ) ),
#     "app-{xy,zz}-{02a,02b}",
#     "app-{xy,zz}-{02a,02b}"
# );

# tricky++...  multiple compressions are possible, 'a{bc,yz},xbc' is
# the most likely given the tree algorithm, but '{a,x}bc,ayz' is more
# efficient.
#is( Compress::BraceExpansion::shrink( qw( abc ayz xbc ) ),
#    "{a,x}bc,ayz",
#    "{a,x}bc,ayz",
#);


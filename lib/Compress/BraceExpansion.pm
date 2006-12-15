package Compress::BraceExpansion;

use warnings;
use strict;

# tasks - use it or lose it
use Carp;

# tasks - get rid of dependence on clone module
use Clone qw(clone);

use version; our $VERSION = qv('0.0.7');

# tasks - get rid of global variable - hack for test cases
my $pointer_id;
_reset_pointer_id();

# given an array of strings, attempt compression
sub shrink {
    my @texts = @_;

    my $tree_h = _build_tree_recurse( @texts );

    # merge the main tree
    ( $tree_h ) = _merge_tree_recurse( $tree_h );

    # todo: merging for the pointers
    # for my $branch ( keys %{ $tree_h->{'POINTERS'} } ) {
    #     my ( $pointers ) = _merge_tree_recurse( $tree_h->{'POINTERS'}->{$branch} );
    #     print Dumper $pointers;
    # }

    my ( $buffer ) = _print_tree_recurse( '', $tree_h->{'ROOT'}, $tree_h );

    return $buffer;
}

# given an array of strings, walk through a build a data tree to
# represent the strings.  Each string will be split into a hash where
# each layer of the hash represents one character in the string.  For
# example, abc will be represented as:
#
#     { a => { b => { c => { end => 1 } } } }
#
sub _build_tree_recurse {
    my @texts = @_;
    my $tree_h = { ROOT => {} };
    for my $text ( @texts ) {
        my $pointer = $tree_h->{'ROOT'};
        for my $character_count ( 0 .. length( $text )-1 ) {
            my $character = substr( $text, $character_count, 1 );
            $pointer->{ $character } = {} unless $pointer->{ $character };
            # if leaf node
            if ( $character_count == length( $text ) - 1 ) {
                $pointer->{ $character }->{'end'} = 1;
            }
            $pointer = $pointer->{ $character };
        }
        $pointer = $text;
    }
    return $tree_h;
}

# walk through the tree looking for ends that are identical.  If
# identical ends are found on all branches, copy the branch off to a
# temporary branch location and replace the originals with a link to
# the new location.  Currently this only handles the cases where all
# branches are identical at some depth.
sub _merge_tree_recurse {
    my ( $main_tree, $tree ) = @_;

    # save a pointer to the main tree as we go deeper into the
    # recursion.  if the main tree pointer isn't specified, this must
    # be the first layer.
    unless ( $tree ) {
        $tree = $main_tree;
    }

    my @nodes = keys %{ $tree };
    if ( @nodes == 1 ) {
        return ( $main_tree, $tree ) if $nodes[0] eq 'end';
        ( $main_tree, $tree ) = _merge_tree_recurse( $main_tree, $tree->{ $nodes[0] } );
    }
    elsif ( @nodes > 1 ) {
        my @paths;
        for my $node ( @nodes ) {
            my ( $text ) = _print_tree_recurse( '', $tree->{$node}, $main_tree );
            return ( $main_tree, $tree ) unless $text;
            push @paths, $text;
        }

        # check for merge points in the tree.  if they exist,
        # transplant them.
        my $depth = _check_merge_point( @paths );
        if ( defined( $depth ) ) {
            #print "\n\n";
            #print "Merging at depth: $depth\n";
            #print Dumper @paths;
            #print "\n\n";
            ( $tree, $main_tree ) = _transplant( $tree, $depth||1, $main_tree );
        }
    }
    #print Dumper $main_tree;
    return ( $main_tree, $tree );
}

# given a data tree, a set of paths within that tree, and the depth
# beyond which they are all identical, clone the paths and relocate
# the identical branches on the POINTERS node.  Remove the specified
# paths and replace them with a link to the new location.
sub _transplant {
    my ( $tree_h, $depth, $main_tree ) = @_;

    my @nodes = keys %{ $tree_h };

    my $id = _get_new_pointer_id();
    my $pruned;

    for my $node ( @nodes ) {
        my ( $depth_pointer, $next_node );
        if ( $depth > 1 ) {
            $depth_pointer = $tree_h->{ $node };
            $next_node = (keys %{ $depth_pointer })[0];
            die "tried to transplant past end of tree" if $next_node eq 'end';
            if ( $depth > 2 ) {
                for my $depth ( 2 .. $depth - 1) {
                    $depth_pointer = $depth_pointer->{ $next_node };
                    $next_node = (keys %{ $depth_pointer })[0];
                    die "tried to transplant past end of tree" if $next_node eq 'end';
                    #print "DEPTH:\n";
                    #print Dumper $depth_pointer;
                }
            }
        }
        else {
            $depth_pointer = $tree_h;
            $next_node = $node;
        }

        # if this is the end of the tree, give up trying
        my $child_node = $depth_pointer->{ $next_node };
        my $child_node_name = (keys %{ $depth_pointer->{ $next_node } })[0];
        if ( $child_node_name eq 'end' ) {
            die "Error: Tried to transplant end of tree";
        }

        unless ( $pruned ) {
            $pruned = clone( $depth_pointer->{ $next_node } );
            #print "PRUNED:\n";
            #print Dumper $pruned;
        }
        $depth_pointer->{ $next_node } = { POINTER => $id };
    }
    $main_tree->{POINTERS}->{ $id } = $pruned;
    #print Dumper $main_tree->{POINTERS};
    #die;

    return ( $tree_h, $main_tree );
}

# given a series of strings, determine the longest number of
# characters that all strings have in common beginning from the tail
# end.  Return the number of characters from the current location
# (which will represent the number of hash levels deep) where the
# similar strings begin.
sub _check_merge_point {
    my ( @strings ) = @_;

    # search for the longest substring from the end that all strings
    # match.
    my $base = $strings[0];
    my $base_length = length( $base );
    my $length = $base_length;
    while ( $length ) {
        my @ends;
        for my $string ( @strings ) {
            return unless length( $string ) eq $base_length;
            my $end = substr( $string, $base_length - $length, $length );
            push @ends, $end;
        }
        if ( _check_array_values_equal( @ends ) ) {
            return $base_length - $length + 1;
        }
        $length--;
    }
    return;
}

# given an array of strings, check that if strings are the same.
sub _check_array_values_equal {
    my ( @array ) = @_;

    my $base = $array[0];
    for my $array ( @array ) {
        return unless $array eq $base;
    }
    return 1;
}

# given a data tree, recurse through and print the structure.
sub _print_tree_recurse {
    my ( $buffer, $tree_h, $main_tree ) = @_;
    return unless ref $tree_h eq 'HASH';

    # this is the first layer of recursion
    unless ( $main_tree ) {
        $main_tree = $tree_h;
    }
    my @nodes = sort keys %{ $tree_h };
    return ( $buffer ) if @nodes == 0;
    my $pointer;

    if ( @nodes == 1 ) {
        if ( $nodes[0] eq 'POINTER' ) {
            return ( $buffer, $tree_h->{ $nodes[0] } );
        }
        else {
            for my $node ( @nodes ) {
                if ( $node eq 'end' ) {
                    $buffer .= "";
                }
                else {
                    $buffer .= $node;
                    my $lbuffer;
                    ( $lbuffer, $pointer ) = _print_tree_recurse( '', $tree_h->{$node}, $main_tree );
                    $buffer .= $lbuffer;
                }
            }
        }
    }
    elsif ( @nodes > 1 ) {
        $buffer .= "{";
        my ( @bits );
        for my $node ( @nodes ) {
            next if $node eq 'POINTERS';
            if ( $node eq 'POINTER' ) {
                $pointer = $tree_h->{$node};
            }
            elsif ( $node eq 'end' ) {
                push @bits, "";
            }
            else {
                my $lbuffer;
                ( $lbuffer, $pointer ) = _print_tree_recurse( $node, $tree_h->{$node}, $main_tree );
                push @bits, $lbuffer;
            }
        }
        $buffer .= join ",", @bits;
        $buffer .= "}";

        if ( $pointer && $main_tree->{'POINTERS'}->{ $pointer }  ) {
            my $output;
            ( $output, undef ) = _print_tree_recurse( '', $main_tree->{'POINTERS'}->{ $pointer }, $main_tree );
            $buffer .= $output;
            delete $main_tree->{'POINTERS'}->{ $pointer };
            $pointer = undef;
        }
    }
    return ( $buffer, $pointer );
}


sub _get_new_pointer_id {
    $pointer_id++;
    return "PID:$pointer_id";

}

sub _reset_pointer_id {
    $pointer_id = 1000;
}

# next generation idea
#
# 1. add weights to each node in graph based on how many strings pass
#    through each node
# 2. test collapses around nodes with highest weights
# 3. develop an api of collapsing strategies
# 4. autogenerated test cases - expand in shell - compare efficiency
#
#




1;

__END__

=head1 NAME

Compress::BraceExpansion - create a human-readable compressed string
suitable for shell brace expansion.

=head1 VERSION

This document describes Compress::BraceExpansion version 0.0.7.  This
is a beta release.


=head1 SYNOPSIS

    use Compress::BraceExpansion;

    # output: ab{c,d}
    print Compress::BraceExpansion::shrink( qw( abc abd ) );

    # output: aabb{cc,dd}
    print Compress::BraceExpansion::shrink( qw( aabbcc aabbdd ) );

    # output: aa{bb{cc,dd},eeff}
    print Compress::BraceExpansion::shrink( qw( aabbcc aabbdd aaeeff ) );

=head1 DESCRIPTION

Shells such as bash and zsh have a feature call brace expansion.
These allow users to specify an expression to generate a series of
strings that contain similar patterns.  For example:

  $ echo a{b,c}
  ab ac

  $ echo aa{bb,xx}cc
  aabbcc aaxxcc

  $ echo a{b,x}c{d,y}e
  abcde abcye axcde axcye

  $ echo a{b,x{y,z}}c
  abc axyc axzc

This module was designed to take a list of strings with similar
patterns (e.g. the output of a shell expansion) and generate the
un-expanded expression.  Given a reasonably sized array of similar
strings, this module will generate a single compressed string that can
be comfortably parsed by a human.

The current algorithm is most efficient if groups of the input strings
start with or end with similar characters.  See BUGS AND LIMITATIONS
section for more details.

=head1 WHY?

My initial motivation to write this module was to compress the number
of characters that are necessary to display a list of server names,
e.g. to send in the subject of a text message to a pager/mobile phone.
If I start with a long list of servers that follow a standard naming
convention, e.g.:

    app-dc-srv01 app-dc-srv02 app-dc-srv03 app-dc-srv04 app-dc-srv05
    app-dc-srv06 app-dc-srv07 app-dc-srv08 app-dc-srv09 app-dc-srv10

After running through this module, they can be displayed much more
efficiently on a pager as:

    app-dc-srv{0{1,2,3,4,5,6,7,8,9},10}

The algorithm also works great for directories:

    /usr/local/{bin,etc,lib,man,sbin}


=head1 BRACE EXPANSION?

Despite the name, this module does not perform brace expansion.  If it
did, it probably should have been located in the Shell:: heirarchy.
It attempts to do the opposite which might be referred to as 'brace
compression', hence the location it in the Compress:: heirarchy.  The
strings it generates could be used in a shell, but are more likely
useful to make a (potentially) human-readable compressed string.  I
chose the name BraceExpansion since that's the common term, so
hopefully it will be more recognizable than if it were named
BraceCompression.


=head1 INTERFACE

=over 8

=item C<shrink( @strings )>

Perform brace compression on strings.  Returns a string that is
suitable for brace expansion by the shell.


=back


=head1 BUGS AND LIMITATIONS

The current algorithm may only generate efficient compressions when
there are similarities in the beginnings and/or endings of multiple
strings in the array.  Finding the 'most' optimized compression is a
rather tricky problem.  The next generation should add weights to the
tree and use branching and bounding to search for the most efficient
compression.

If multiple identical strings are supplied as input, they will only be
represented once in the resulting compressed string.  For example, if
"aaa aaa aab" was supplied as input to shrink(), then the result would
simply be "aa{a,b}".

This module has reasonably fast performance to at least 1000 inputs
strings.  I've run several tests where I cut a 10k word slice from
/usr/share/dict/words and have consistently achieved around 50%
compression.  However, the output rapidly loses human readability
beyond a couple hundred characters.

Please report problems to VVu@geekfarm.org.

Patches are welcome!


=head1 AUTHOR

Alex White  C<< <vvu@geekfarm.org> >>



=head1 LICENCE AND COPYRIGHT

Copyright (c) 2006, Alex White C<< <vvu@geekfarm.org> >>. All rights reserved.

All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

- Redistributions of source code must retain the above copyright
  notice, this list of conditions and the following disclaimer.

- Redistributions in binary form must reproduce the above copyright
  notice, this list of conditions and the following disclaimer in the
  documentation and/or other materials provided with the distribution.

- Neither the name of the geekfarm.org nor the names of its
  contributors may be used to endorse or promote products derived from
  this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.








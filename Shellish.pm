package Regexp::Shellish ;

#
# Copyright 1999, Barrie Slaymaker <barries@slaysys.com>
#
# You may distribute under the terms of either the GNU General Public
# License or the Artistic License, as specified in the README file.
#

=head1 NAME

Regexp::Shellish - Shell-like regular expressions

=head1 DESCRIPTION

Provides shell-like regular expressions.  The wildcards provided
are '?', '*' and '**', where '**' is like '*' but matches '/'.  See
L</compile_shellish> for details.

=over

=cut

use strict ;

use Carp ;
use Exporter ;

use vars qw( $VERSION @ISA @EXPORT_OK %EXPORT_TAGS ) ;

$VERSION = '0.9' ;

@ISA = qw( Exporter ) ;

@EXPORT_OK = qw(
   compile_shellish
   shellish_glob
) ;

%EXPORT_TAGS = ( 'all' => \@EXPORT_OK ) ;

=item compile_shellish

Compiles a string containing a shellish regular expression a, returning a
Regexp reference.  Regexp references passed in are passed through
unmolested.

Here are the transformation rules:

   '*'  => '[^/]*'
   '?'  => '.'
   '**' => '.*'               ## unless { star_star => 0 }

   '('  => '('                ## unless { parens => 0 }
   ')'  => ')'                ## unless { parens => 0 }

   '{a,b,c}' => '(?:a|b|c)'   ## unless { braces => 0 }

   '\a' => 'a'                ## These are de-escaped and passed to quotemeta()
   '\*' => '\*'

The wildcards treat newlines as normal characters.

Parens group in to $1..$n, since they are passed through unmolested
(unless option parens => 0 is passed).  This is useless when using
glob_shellish(), though.

The final parameter can be a hash reference containing options:

   compile_shellish(
      '**',
      {
         case_sensitive    => 0,   ## Make case insensitive
         star_star         => 0,   ## Make '**' just be two '*' wildcards
	 parens            => 0,   ## Treat '(' and ')' as regular chars
      }
   ) ;

No option affects Regexps passed through.

=cut

sub compile_shellish {
   my $o = @_ && ref $_[-1] eq 'HASH' ? pop : {} ;
   my $re = shift ;

   return $re if ref $re eq 'Regexp' ;

   my $star_star = ( ! exists $o->{star_star} || $o->{star_star} )
      ? '.*'
      : '[^/]*[^/]*' ;

   my $case = ( ! exists $o->{case_sensitive} || $o->{case_sensitive} )
      ? ''
      : 'i' ;

   my $pass_parens = ( ! exists $o->{parens} || $o->{parens} ) ;
   my $pass_braces = ( ! exists $o->{braces} || $o->{braces} ) ;

   my $brace_depth = 0 ;

   my $orig = $re ;

   $re =~ s@
      (  \\.
      |  \*\*
      |  .
      )
   @
      if ( $1 eq '?' ) {
	 '[^/]' ;
      }
      elsif ( $1 eq '*' ) {
	 '[^/]*' ;
      }
      elsif ( $1 eq '**' ) {
	 $star_star ;
      }
      elsif ( $pass_braces && $1 eq '{' ) {
	 ++$brace_depth ;
         '(?:' ;
      }
      elsif ( $pass_braces && $1 eq '}' ) {
	 croak "Unmatched '}' in '$orig'" unless $brace_depth-- ;
         ')' ;
      }
      elsif ( $pass_braces && $brace_depth && $1 eq ',' ) {
         '|' ;
      }
      elsif ( $pass_parens && index( '()', $1 ) >= 0 ) {
         $1 ;
      }
      else {
	 quotemeta(substr( $1, -1 ) );
      }
   @gexs ;

   croak "Unmatched '{' in '$orig'" if $brace_depth ;

   return qr/\A(?$case:$re)\Z/s ;
}


=item shellish_glob

Pass a regular expression and a list of possible values, get back a list of
matching values.

   my @matches = shellish_glob( '*/*', @possibilities ) ;
   my @matches = shellish_glob( '*/*', @possibilities, %options ) ;

=cut

sub shellish_glob {
   my $o = @_ > 1 && ref $_[-1] eq 'HASH' ? pop : {} ;
   my $re = compile_shellish( shift, $o ) ;
   return grep { m/$re/ } @_ ;
}

=back

=head1 AUTHOR

Barrie Slaymaker

=cut


1 ;

let $PERL5LIB = join( filter( map ( [ 't/lib', 'lib' ], { idx, val -> getcwd() . '/' . val } ), { idx, val -> isdirectory( val ) } ), ':' )  . ':' . $PERL5LIB

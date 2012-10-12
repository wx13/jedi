editor.rb
=========

editor.rb is a text editor writen in ruby for the unix console.

Main goals
----------

1. Zero install / portable
2. Easy to customize/hack/extend

Portability is achieved by using a single file of ruby code with no
external library dependencies.  The only libraries it requires are
optparse (for parsing command line options) and yaml (for storing
history).  Even those are non-essential, if you really want no
dependencies.

Hackability is achieved by writing it in ruby.  Ruby supports
metaprogramming, which means writing extensions is very simple.  See
the scripts/ folder for example extensions.  Also ruby's wonderful
string handling makes adding or changing features quite simple.


A note about portability
------------------------

editor.rb does not use curses or ncurses, but instead reads from
standard in and writes to standard out.  It uses terminal escape codes
to format the output.  Some terminals don't seem to support as many
keycodes and will have reduced functionality.  For example, the mac
terminal does not report shift/control + arrow keys (accept for
ctrl-left/right).  I continually test it in xterm on linux, xterm on
cygwin and gnome terminal on linux, all with ruby 1.6.  I occationally
test in on a Mac terminal and in ruby 1.9.



Installing & running
--------------------

There is not installation; just run "ruby editor.rb".

Alternatively, create a directory ~/.editor containing the files
config.rb and history.yaml.  Then create an alias:

	alias editor='ruby $HOME/bin/editor.rb -s $HOME/.editor -y $HOME/.editor/history.yaml'

This tells editor.rb to read all *.rb files from ~/.editor/ as scripts
and to save command/search/script history in ~/.jedi/history.yaml.


More information
----------------

See the doc/ folder for more details.

------------------------------------------------------------------------

Copyright (C) 2011-2012, Jason P. DeVita (jason@wx13.com)

Copying and distribution of this file, with or without modification,
are permitted in any medium without royalty or restriction.  This file
is offered as-is, without any warranty.

------------------------------------------------------------------------


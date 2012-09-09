editor.rb
=========

editor.rb is a text editor writen in ruby for the unix console.

Design goals
------------
1. Zero install
2. Easily customizable
3. Text UI

Goal #1 is achieved with a single file of ruby code with no
external library dependencies.  The only libraries it requires
are optparse (for parsing command line options) and yaml (for
storing history).  Even those are non-essential, if you really
want no dependencies.

Goal #2 is achieved because ruby supports metaprogramming, which
means writing extensions is very simple.  See the extras/ folder
for example extensions.  Also ruby's wonderful string handling
makes adding or changing features quite simple.

Goal #3 is achieved by reading and writing to stdin and stdout.

Caveats
-------
editor.rb does not use curses or ncurses, but instead reads from
standard in and writes to standard out.  It uses terminal escape codes
to format the output.  Some terminals don't seem to support as many
keycodes and will have reduced functionality.  For example, the mac
terminal does not report shift/control + arrow keys (accept for
ctrl-left/right).  I continually test it in xterm on linux, xterm on
cygwin, gnome terminal on linux, and terminal on mac; and on ruby 1.8
and 1.9.


Installing & running
--------------------
1. Just run "ruby editor.rb".

2. Alternatively, create a directory ~/.editor containing the files
config.rb and history.yaml.  Then create an alias:

	alias jedi='ruby $HOME/bin/editor.rb -s $HOME/.jedi -y $HOME/.jedi/history.yaml'

This tells editor.rb to read all *.rb files from ~/.jedi/ as scripts and to
save command/search/script history in ~/.jedi/history.yaml.


More information
----------------
See http://wx13.com/code/editor for more details.

------------------------------------------------------------------------
Copyright (C) 2011-2012, Jason P. DeVita (jason@wx13.com)

Copying and distribution of this file, with or without modification,
are permitted in any medium without royalty or restriction.  This file
is offered as-is, without any warranty.
------------------------------------------------------------------------


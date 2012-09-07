editor.rb
=========


editor.rb is a text editor writen in ruby for the unix console.


Why another text editor?
------------------------

1. Zero install
	- Single file of ruby code
	- No external libraries
2. Hackable
	- Metaprogramming
	- No compiling
3. Text UI


Most text editors are written in C, which causes several problems.

1. C is cumbersome for working with strings that keep changing.

Answer: Ruby handles strings very easily.

2. Modifying a C text editor requires you to

	a. keep a set of patches (and continually resolve conflicts
	   as the code changes)

Answer: Ruby allows metaprogramming, which means writing extensions
is almost trivial.

	b. recompile the editor (I hope your admin has installed all
	   the right development libraries!)

Answer: It is possible in ruby to write a text editor which uses no
external libraries.



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


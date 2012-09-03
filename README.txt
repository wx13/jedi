=========
editor.rb
=========

editor.rb is a text editor writen in ruby for the unix console. It does
not use curses or ncurses, but instead reads from standard in and
writes to standard out.  It uses terminal escape codes to format the
output.  Some terminals don't seem to support as many keycodes and will
have reduced functionality.  For example, the mac terminal does not
report shift/control + arrow keys (accept for ctrl-left/right).  I
continually test it in xterm on linux, xterm on cygwin, gnome terminal
on linux, and terminal on mac.

Major design goals:
1. Zero install
	- single file of ruby code
	- only use built-in libraries
2. Easy to modify, script, extend, and configure
	- run scripts at startup or while running

See http://wx13.com/code/editor for more details.


Installing & running
====================

1. Just run "ruby editor.rb".

2. Alternatively, create a directory ~/.editor containing the files
config.rb and history.yaml.  Then create an alias:

	alias jedi='ruby $HOME/bin/editor.rb -s $HOME/.jedi -y $HOME/.jedi/history.yaml'

This tells editor.rb to read all *.rb files from ~/.jedi/ as scripts and to
save command/search/script history in ~/.jedi/history.yaml.


Options
-------

A few parameters and flags, (such as tab size, and autoindent)
can be set with command line options.  Type "ruby editor.rb -h" to see
available options.


Configuration
-------------

Configuration, scripting, and extensions are all the same.  The editor
does not parse a configuration file; instead it can execute scripts at
startup.  A simple configuration file might look like:

	$tabsize = 8
	$autoindent = true
	$syntax_color = false

Start the editor with "-s config.rb" or "-s dir_containing_config/" set.


------------------------------------------------------------------------
Copyright (C) 2011-2012, Jason P. DeVita (jason@wx13.com)

Copying and distribution of this file, with or without modification,
are permitted in any medium without royalty or restriction.  This file
is offered as-is, without any warranty.
------------------------------------------------------------------------


editor.rb
=========

editor.rb is a text editor writen in ruby for the unix console,
designed to be portable and hackable.  No installation is required, and
it does not use external libraries or gems.  The editor can be extended
or modified with external ruby scripts, and ruby commands can be run
within the editor to perform complex editing tasks.  Features include:
undo/redo (two levels), multiple cursor modes, text folding, split
screen mode, "indentation facade", copy/paste history, and more.  See
the doc/ directory for details.



Installing and running
----------------------

No installation is required; just run

    ruby editor.rb [options] [files]

To "install" the editor, run the included install script:

    sh install.sh

This will copy the editor.rb file to `$HOME/bin/`, create a config
directory in `$HOME/.editor`, and create an executable script in
`$HOME/bin` containing the single line:

    ruby editor.rb -s ~/.editor -y ~/.editor/history.yaml $@

This tells editor.rb to read all *.rb files from ~/.editor/ as
start-up scripts and to save command/search/script history in
~/.jedi/history.yaml.  Then you can just type `editor` to start the
editor.


A note about portability
------------------------

editor.rb does not use curses or ncurses, but instead reads from
standard input and writes to standard output.  It uses terminal escape
codes to format the output.  Some terminals don't seem to support as
many keycodes and will have reduced functionality.  For example, the
mac terminal does not report shift/control + arrow keys (aside from
ctrl-left/right).  I continually test it in xterm on linux, xterm on
cygwin and gnome terminal on linux, with ruby 1.8.  I occasionally test
in on a Mac terminal and in ruby 1.9. Other than modified arrow keys,
it should run on any unix-compatible terminal emulator.  If you type
`echo -e "\e[2J"` and it clears the screen, then you should be fine.


License
-------

All code and documentation are covered by the following license:

------------------------------------------------------------------------

Copyright (C) 2011-2013, Jason P. DeVita (jason@wx13.com)

Copying and distribution of this file, with or without modification,
are permitted in any medium without royalty or restriction.  This file
is offered as-is, without any warranty.

------------------------------------------------------------------------


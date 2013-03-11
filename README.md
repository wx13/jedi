Jedi (J's EDItor)
=================

Jedi is a text editor writen in ruby for the unix console,
designed to be portable and hackable.

 - No installation required
 - Needs only ruby to run (no libraries or gems)
 - Full ruby scriptability (on startup, and while running)
 - Multi-level undo/redo with (optional) file history saved to disk.
 - Multiple cursor modes (row, column, nmuloc, and ad hoc)
 - Indentation facade (use whatever indentation you want, regardless of
   what the file uses)
 - Searchable copy/paste history
 - Split screen modes and multiple views of a singe file
 - Text folding, including pattern-based auto-folding


Installing and running
----------------------

No installation is required; just run

    ruby jedi.rb [options] [files]

To "install" jedi, run the included install script:

    sh install.sh

This will copy the editor.rb file to `$HOME/local/bin/`, create a
config directory in `$HOME/.editor`, and create an executable script in
`$HOME/bin` containing the single line:

    ruby jedi.rb -s ~/.jedi -y ~/.jedi/history.yaml $@

This tells jedi.rb to read all *.rb files from ~/.jedi/ as
start-up scripts and to save command/search/script history in
~/.jedi/history.yaml.  Then you can just type `jedi` to start the
editor.


Single file
-----------

The code is split into multiple files to simplify development.  The
install script creates a single file script from those files.  To
create the single file script without installing, run

    sh make_jedi.sh > jedi.rb

The resulting file is entirely self contained, and may be executed
anywhere ruby is installed.


A note about portability
------------------------

Jedi does not use curses or ncurses, but instead reads from
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


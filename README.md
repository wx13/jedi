editor.rb
=========

editor.rb is a text editor writen in ruby for the unix console,
designed to be portable and hackable.


Installing and running
----------------------

There is no installation; just run

    ruby editor.rb [list of files]

Alternatively, create a directory ~/.editor containing the files
config.rb and history.yaml.  Then create an alias:

    alias editor='ruby $HOME/bin/editor.rb -s $HOME/.editor -y $HOME/.editor/history.yaml'

This tells editor.rb to read all *.rb files from ~/.editor/ as
start-up scripts and to save command/search/script history in
~/.jedi/history.yaml.


License
-------

All code and documentation are covered by the following license

Copying and distribution of this file, with or without modification,
are permitted in any medium without royalty or restriction.  This file
is offered as-is, without any warranty.



A note about portability
------------------------

editor.rb does not use curses or ncurses, but instead reads from
standard input and writes to standard output.  It uses terminal escape
codes to format the output.  Some terminals don't seem to support as
many keycodes and will have reduced functionality.  For example, the
mac terminal does not report shift/control + arrow keys (accept for
ctrl-left/right).  I continually test it in xterm on linux, xterm on
cygwin and gnome terminal on linux, all with ruby 1.8.  I occasionally
test in on a Mac terminal and in ruby 1.9.


More information
----------------

See the doc/ folder for more details.

------------------------------------------------------------------------

Copyright (C) 2011-2012, Jason P. DeVita (jason@wx13.com)

Copying and distribution of this file, with or without modification,
are permitted in any medium without royalty or restriction.  This file
is offered as-is, without any warranty.

------------------------------------------------------------------------


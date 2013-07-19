Jedi (J's EDItor)
=================

Jedi is a text editor, writen in ruby, for the unix console,
designed to be portable and hackable.

 - Portable
   + No installation required
   + No dependencies, other than ruby
 - Hackable
   + Full ruby scriptability (on startup, and while running)
   + 3000 SLOC
 - Features
   + Text folding (manual and pattern-based auto-folding)
   + Multi-level undo/redo with (optional) history saved to disk
   + Multiple cursor modes
   + Indentation facade
   + Searchable copy/paste history
   + Split screen modes



Try it out
----------

To try out the latest release:

    wget http://wx13.com/jedi/latest/jedi.rb
    ruby jedi.rb <list of files>



Installation
------------

*Option 1:*

Stick the jedi.rb file in your path.

*Option 2:*

Grab the full source code from
http://github.com/wx13/jedi, and run

    sh install.sh [prefix]

The default installation prefix is `$HOME/local/`.

To uninstall:

    rm -r $prefix/bin/jedi $prefix/share/man/man1/jedi.1 \
        $HOME/.jedi



Single file executable
----------------------

The code is split into multiple files to simplify development.  To test
the code during development, execute:

    ruby run_jedi.rb

To create a single-file portable executable, run

    ruby make_jedi.rb

The resulting file is entirely self contained, and may be executed
anywhere ruby is installed.  The installer script does this for you.


A note about portability
------------------------

Jedi does not use curses or ncurses, but instead reads from standard
input and writes to standard output.  It uses terminal escape codes to
format the output.  Some terminals don't seem to support as many
keycodes and will have reduced functionality.  For example, the mac
terminal does not report shift/control + arrow keys (aside from
ctrl-left/right). Other than modified arrow keys, it should run on any
unix-compatible terminal emulator.  If you type `echo -e "\e[2J"` and
it clears the screen, then you should be fine.

I periodically test it on the following platforms:

 - xterm on linux
 - xterm on cygwin
 - gnome terminal on linux
 - ruby 1.8.5, 1.8.6, 1.8.7, 1.9.3, 2.0.0



More information
----------------

http://jedi.wx13.com

Feel free to email me (jason@wx13.com) with any questions or
feedback.  I started this project to satisfy my own needs, and as far
as I know, I am the only user.  So you if you find this useful or
interesting, I'd like to hear about it.


License
-------

All code and documentation are covered by license shown below.  It says
you can do pretty much anything you want with it.

------------------------------------------------------------------------

Copyright (C) 2011-2013, Jason P. DeVita (jason@wx13.com)

Copying and distribution of this file, with or without modification,
are permitted in any medium without royalty or restriction.  This file
is offered as-is, without any warranty.

------------------------------------------------------------------------


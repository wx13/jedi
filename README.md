Jedi (J's EDItor)
=================

Jedi is a unix console text editor designed to be portable and
hackable.

 - Portable
   + No installation required
   + No build step
   + No dependencies, other than ruby
 - Hackable
   + Full ruby scriptability (on startup, and while running)
   + 3K SLOC
 - Cool Features
   + Text folding (manual and pattern-based auto-folding)
   + Multi-level undo/redo with (optional) history saved to disk
   + Multiple cursor modes (normal, column, multiple)
   + Indentation facade (buffer can use different indentation string
     than file)
   + Searchable copy/paste history
   + Split screen modes
   + Drop into an IRB session at anytime




Installation
------------

Grab the code with git

	git clone https://github.com/wx13/jedi.git

or download and extract the tarball:

	wget https://github.com/wx13/jedi/archive/master.zip

Then run

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



Philosophy and Requirements
---------------------------

The dual goals of the Jedi text editor are portability and hackability.
By portability I mean: if you are in a unix-like environment, you
should be able to run jedi (regardless of user access, build tool
availability, etc.).  By hackability, I mean: you can modify the code
anywhere at anytime (regardless of user access, build tool
availability, etc.).

Derived requirements:

 * No dependencies other than the ruby interpreter
   * Any code with external dependencies must remain an extension, and not
     part of the core code.
 * Keep the code short and simple
   * The longer and more complex the code gets, the harder it is to hack.
   * Some advanced functionality may have to be built as optional
     extensions, to keep the code base small.


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


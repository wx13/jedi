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


Try it out
----------

To try out the latest release:

    wget http://wx13.com/jedi/latest/jedi.rb
    ruby jedi.rb <list of files>

Or download it [here](http://wx13.com/jedi/latest/jedi.rb).
To try the newest (unreleased) version, replace "latest" with
"testing".


Manual install
--------------

No installation is required.  You can just run the code, as shown in
the above section.  If you want to use configuration/extension scripts,
specify files/directories with the `-s` option.  To store
search/command/etc history, specify a file with the `-y` option.

To install, copy the jedi.rb file to your path, and create a shell
script in that same location containing the single line:

    ruby <path>/jedi.rb -s ~/.jedi -y ~/.jedi/history.yaml $@

Then all config/extend/history files can reside in the `~/.jedi`
directory.


Auto install
------------

Grab the full source code from http://github.com/wx13/editor, and run

    sh install.sh 

This will create the jedi.rb file from the files in `src/`,
copy the jedi.rb file to `$HOME/local/bin/`, create a
config directory in `$HOME/.jedi`, and create an executable script in
`$HOME/local/bin` containing the single line:

    ruby $HOME/local/bin/jedi.rb -s ~/.jedi -y ~/.jedi/history.yaml $@

This tells jedi.rb to read all *.rb files from ~/.jedi/ as
start-up scripts and to save command/search/script history in
~/.jedi/history.yaml.  Then you can just type `jedi` to start the
editor.


Single file
-----------

The code is split into multiple files to simplify development.  The
install script creates a single file script from those files.  To
create the single file script without installing, run

    ruby make_jedi.rb

The resulting file is entirely self contained, and may be executed
anywhere ruby is installed.  To include extension scripts, you can use
the flags mentioned in the "Manual Install" section; or just place the
scripts in the src directory before running the make_jedi command.  The
only caveat is that files are included in alphabetical order.


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

See the manual in
[doc/manual.md](https://github.com/wx13/editor/tree/master/doc/manual.md)

See the website at
[http://jedi.wx13.com](http://jedi.wx13.com).

Also, feel free to email me (jason@wx13.com) with any questions or
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


======
editor
======

Editor is a text editor writen in ruby/curses.

Design goals:
1. Simplicity
	- single file of ruby code
	- only use built-in libraries
	- easy to modify
2. Power
	- execute arbitrary ruby commands within the editor
	  for maximum flexibilty

Features:
- syntax coloring (single line only)
- multiple buffers
- search & replace
	- with search term history
	- optional regular expressions
- autoindent
- block comment & indent
- justify text & line wrap
- column editing (long vertical cursor)
- undo-redo
- run ruby commands from within the editor
- configuration file can run arbitrary commands


Future work:
- display & edit diffs
- record & replay keypresses (macros)
- undo-redo for arbitrary ruby commands



Installation
============

You can just run "ruby editor.rb".
Or put is somewhere in your path and give it execute permission.
Rename it whatever you like.


Configuration & options
=======================

Options
-------

A few parameters and flags, (such as tab size, and autoindent)
can be set with command line options.  Type "editor -h" to see
available options.

Configuration
-------------

The "-s" or "--script" option calls a script or set of scripts to
be run at startup.  This can be used to set basic parameters, for example:

Create a file called "config.rb" containing:

	$tabsize = 8
	$autoindent = true
	$syntax_color = false

And start the editor with "-s config.rb" set.

One can do more complex configurations, such as swapping keybindings.
Suppose you like to use nano's "ctrl-x" for quit, rather than
"ctrl-q":

	$commandlist[$ctrl_x] = "buffer = buffers.close"
	$commandlist[$ctrl_q] = "buffer = buffers.mark"

One can go even further, and modify/create class methods.  For example,
if you prefer that ctrl-e take you to the last character of the line,
rather than just past the last character:

	class FileBuffer
		def cursor_eol
			@col = @text[@row].length-1
		end
	end

As you can see, this can be used for simple configuration, or to create
mods/extenstions to the editor.



Description of code and methods
===============================

Keybindings
-----------

The keybindings section is near the top of the code. It has three sections:
commandlist, editmode_commandlist, and viewmode_commandlist.  The first is
for universal keybindings. The second only works in editmode, and the third
works only in viewmode.

Classes
-------

The code contains four classes:
1. Screen
2. FileBuffer
3. BuffersList
4. BufferHistory

Screen contains methods related to curses screen output, such as:
initialiing the screen, writing a message to the bottom of the window,
and writing a line of text.

FileBuffer stores the current state of the file text, plus things like
position within the buffer, and marks.  It contains methods related to
working with the file text, such as adding and deleting characters,
cut/copy/paste, search, etc.

BuffersList manages multiple buffers, and stores up the copy/paste text.

BufferHistory is a linked list of buffer text state, used for undo/redo.


Undo-redo
---------

The buffer text is stored in an array of strings (lines).  Each time the user
does something, a snapshot of the text is saved.  This snapshot is a shallow
copy (it is a new array, but each element is pointer to the old string).
Before a line is changed, a deep copy is made of that line (now the array has
one differing element). These sequences of snapshots are saved in a linked
list (BufferHistory class). The linked list format allows the possibility of
undo-trees if I ever feel they would be useful.  Undo and redo, are as simple
as bumping a pointer up or down the link list of text buffers.




Usage
=====

Starting the editor
-------------------

To start the editor just run "ruby editor.rb <optional list of files>".

There are no command line options.


Modes
-----

This is not a modal editor, but it does have two modes.
In the "edit" mode you can do pretty much everything.
In the "vew" mode, you cannot modify the text (not strictly true),
and there are some shorcuts for navigation, such as:
	- h,j,k,l to move the cursor
	- space, b for page down/up
	- / to search
	- H,J,K,L to shift screen around
	- ",","." (unshifted >,<) to change buffers
	- g to goto a line

To get to view mode, hit "ctrl-6 v". To get to edit mode, hit
"ctrl-6 e" or just hit "i".


Remember that all the keymappings can be easily changed.



Basic editing
-------------

Basic editing is verys simlar to gnu-nano.

	- Arrow keys & page up/down to move around.
	- Ctrl-{v,y} are also page down/up.
	- Ctrl-w to search
	- Ctrl-o to save
	- Ctrl-q to close file (quit if only one file open)
	- Ctrl-e end of line
	- Ctrl-a start of line
	- Ctrl-d delete character
	- Ctrl-{b,n} previous/next text buffer
	- Ctrl-f open file
	- Ctrl-r search & replace
	- Ctrl-g go to line number (empty=0, negative = up from bottom)
	- Ctrl-l justify text
	- Ctrl-p copy
	- Ctrl-k cut
	- Ctrl-u paste
	- Ctrl-c cancel operation
	- Ctrl-6 toggle various things
		- e = edit mode
		- v = view mode
		- a = autoindent
		- m = manual indent
		- i = insert mode
		- o = overwrite mode
		- c = column mode
		- r = row mode
	- Ctrl-x mark text


Some examples:

To open a file for reading, hit "ctrl-f".  Tab key cycles through matches.

Cut/paste work just like in gnu-nano. Copy is just like cut, but ctrl-p.

To run an arbitrary ruby command, type "ctrl-6 v :". Then type the command and
hit enter.

To indent a block of text
	1. hit "ctrl-x" at first line (or last) line of text
	2. navigate to last line (or first)
	3. type tabs or spaces

To comment a block of text, do the same as indent, but type "ctrl-t <enter>"

To insert arbitrary text at the start of a set of lines, to the same as
above, but type "ctrl-t <text> <enter>".

Alternatively, enter column mode "ctrl-6 c".  Then "ctrl-x" to make a long cursor
that you can type anything at (other than enter).


Entering ruby commands
----------------------

Type "ctrl-6 v : <ruby commands> <enter>".

For example:

To change the tabsize:

	@tabsize = 8

To specify that the file is a fortran file for syntax coloring:

	@filetype = 'f'

To change the color of comments from cyan to green

	$color_comment = $color_green

To change a bulleted ("-") list which starts on line 47 and is 10 lines long
to a numbered list

	k=0; @text[47,10].each{|line|; k+=1; line.sub!(/^(\s*)-/,"\\1#{k}.")}



------------------------------------------------------------------------
Copyright (C) 2011-2012, Jason P. DeVita (jason@wx13.com)

Copying and distribution of this file, with or without modification,
are permitted in any medium without royalty provided the copyright
notice and this notice are preserved.  This file is offered as-is,
without any warranty.
------------------------------------------------------------------------


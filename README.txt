=========
editor.rb
=========

editor.rb is a text editor writen in ruby/curses.

Design goals:

1. Simplicity
	- single file of ruby code
	- only use built-in libraries
	- easy to modify, customize & extend
2. Scriptable
	- execute single-line ruby commands within the editor
	- execute ruby script files from within the editor
	- execute ruby script files at startup


Features:

+ typical text editor stuff:
	- syntax coloring
	- multiple buffers
	- search & replace
	- autoindent, linewrap, justify text
	- column editing
	- undo-redo
+ run arbitrary ruby scripts within the editor
  or at startup


Future work:

+ display & edit diffs
+ record & replay keypresses (macros)
+ undo-redo for arbitrary ruby scripts
	- challenging: how to know what has changed?
	- currently: make sure to .dup lines before changing





Usage
=====

Installing & running
--------------------

You can just run "ruby editor.rb".
Or put is somewhere in your path and give it execute permission.
Rename it whatever you like.


Options
-------

A few parameters and flags, (such as tab size, and autoindent)
can be set with command line options.  Type "editor -h" to see
available options.


Configuration
-------------

The code does not parse a configuration file per se.  Because ruby
supports metaprogramming, configuration and modification/extension
are all the same.

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

Here are some other useful mods:

Change the syntax coloring:

	$color_comment = $color_green

Make files that end in ".h" get c-style coloring:

	$filetypes[/\.h$/] = "c"

As you can see, this can be used for simple configuration, or to create
mods/extenstions to the editor.







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

To get to view mode, hit "ctrl-t v". To get to edit mode, hit
"ctrl-t e" or just hit "i".


Remember that all the keymappings can be easily changed, and one
could easily write a set of keybindings that are very vim-like.



Basic editing
-------------

Basic editing is verys simlar to gnu-nano.

	- Arrow keys & page up/down to move around.
	- Ctrl-{v,y} are also page down/up.
	- Ctrl-w to search
	- Ctrl-r search & replace
	- Ctrl-o to save
	- Ctrl-q to close file (quit if only one file open)
	- Ctrl-e end of line
	- Ctrl-a start of line
	- Ctrl-d delete character
	- Ctrl-{b,n} previous/next text buffer
	- Ctrl-f open file
	- Ctrl-g go to line number (empty=0, negative = up from bottom)
	- Ctrl-l justify text
	- Ctrl-p copy
	- Ctrl-k cut
	- Ctrl-u paste
	- Ctrl-c cancel operation
	- Ctrl-t toggle various things
		- e = edit mode
		- v = view mode
		- a = autoindent
		- m = manual indent
		- i = insert mode
		- o = overwrite mode
		- c = column mode
		- r = row mode
		- s = syntax coloring on
		- b = syntax coloring off
	- Ctrl-x mark text


Some examples:

To open a file for reading, hit "ctrl-f".  Tab key cycles through matches.

Cut/paste work just like in gnu-nano. Copy is just like cut, but ctrl-p.

To run an arbitrary ruby command, type "ctrl-t v :". Then type the command and
hit enter.

To indent a block of text
	1. hit "ctrl-x" at first line (or last) line of text
	2. navigate to last line (or first)
	3. type tabs or spaces

To comment a block of text, do the same as indent, but type "ctrl-t v t <enter>"

Alternatively, enter column mode "ctrl-t c".  Then "ctrl-x" to make a long cursor
that you can type anything at (other than enter).


Entering ruby commands
----------------------

Type "ctrl-t v : <ruby commands> <enter>".

For example:

To change the tabsize:

	@tabsize = 8

To specify that the file is a fortran file for syntax coloring:

	@filetype = 'f'

To change the color of comments from cyan to green

	$color_comment = $color_green

To change a bulleted ("-") list which starts on the current line and
is 10 lines long to a numbered list

	k=0; @text[@row,10].each{|line|; k+=1; line=line.sub(/^(\s*)-/,"\\1#{k}.")}

To turn a double underline to a single underline, go to the underline row:
                 =========             ---------

	@text[@row] = @text[@row].gsub("=","-")

To underline a line of text:

	@text.insert(@row+1,"-"*@text[@row].length)

**Important**:
Notice in each of the above examples, when modifying the text buffer,
I am careful to do stuff like:

	@text[@row] = @text[@row].gsub(...

instead of the more compact:

	@text[@row].gsub!(...

These are not the same command!  The first replaces the array element
with a new element; the second modifies the existing element.  This
is important because of undo-redo change detection.  The first is
undo-able; the second is not.


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



------------------------------------------------------------------------
Copyright (C) 2011-2012, Jason P. DeVita (jason@wx13.com)

Copying and distribution of this file, with or without modification,
are permitted in any medium without royalty provided the copyright
notice and this notice are preserved.  This file is offered as-is,
without any warranty.
------------------------------------------------------------------------


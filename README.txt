======
editor
======

Text editor writen in ruby/curses.  Designed to do things the way I want.

Features:
- syntax coloring
- multiple buffers
	- tab completion file selection
- search & replace
	- with search term history
	- optionaly regular expressions
- autoindent
- block comment & indent
- justify text
- column editing:
	- ctrl-6,c/r toggles column/row editing
	- in col editing:
		- single column highlighted (elongated cursor)
		- ctrl-t inserts arb text before cursor
		- backspace delets before long cursor
		- ctrl-d is still single-line
- arbitrary ruby commands
	- in view mode, hit ":"
	- then type in any ruby commands
	- will be exectured in context of the current buffer class
	- example:
		- @tabsize = 4 # adjust tabsize on the fly
		- $color_comment = $color_cyan # make comments cyan colored
		- @text.each{|line|; line.gsub(/foo/,"bar");}


To do:
- speed up screen dump: only dump if text changes or
  if linefeed/colfeed changes
- autoindent -- what if previous two lines start ith same string?
- line wrap
- diffs
- record & replay keypresses
	- use this to make column mode editing better
- after search replace, cursor should go back to orig pos



Description of code and methods
===============================

The keybindings section is near the top of the code.
It has three sections: commandlist, editmode_commandlist, and
viewmode_commandlist.  The first is for universal keybindings.
The second only works in editmode, and the third works only in
viewmode.


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


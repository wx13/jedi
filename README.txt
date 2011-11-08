======
editor
======

Text editor writen in ruby/curses.  Designed to be easy to modify.

Features:
- syntax coloring
- multiple buffers
	- tab completion file selection
- search & replace
	+ with search term history
- autoindent
- block comment & indent
- justify text


To do:
- block unindent -- only require that all lines start with
  same string.
- block indent -- what if previous two lines start ith same string?
- comments should color over everything
- line wrap
- diffs
- regular expression searches
- multi-line syntax coloring?
- record & replay keypresses
- sometimes cursor ends up in weird places
- move to place where undo/redo occurs


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


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
- autoindent
- block comment & indent
- justify text
- regular expression searches
- column editing:
	- ctrl-6,c/r toggles column/row editing
	- in col editing:
		- single column highlighted (elongated cursor)
		- ctrl-t inserts arb text before cursor
		- backspace delets before long cursor
		- ctrl-d is still single-line


To do:
- block unindent -- only require that all lines start with
  same string.
- block indent -- what if previous two lines start ith same string?
- comments should color over everything
- line wrap
- diffs
- multi-line syntax coloring?
- record & replay keypresses
- sometimes cursor ends up in weird places

diff view:
- toggle btw regular and diff view.
- diff view is unified diff, with infinite lines of context
- editing (-) lines not allowed.
- editing (+) lines fine.
- editing other lines causes (-+) to form


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


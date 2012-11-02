Bugs
====

* Buffers may diverge when editing the same file in two windows.
	+ Look at indentation facade stuff specifically.
		- Fixed (I think)
	+ Do some more testing of multiple-window editing.

* Indentation facade infinite loop when converting spaces to spaces.
	+ Clearly we need a smarter regexp, that doesn't try to convert already
	converted spaces.

* Indentation facade won't update folded lines
	+ probably should offer to unfold lines
	+ how hard would it be to unfold & then refold?
		- would have to keep track of a lot of things
		- maybe instead, a second loop through folded text.


Features
========

* File selection menu
	- opening new files
	- flipping between buffers


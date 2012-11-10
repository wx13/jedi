Bugs
====

* [test] Buffers may diverge when editing the same file in two windows.
	+ Look at indentation facade stuff specifically.
		- Fixed (I think)
	+ Do some more testing of multiple-window editing.

* [test] Indentation facade infinite loop when converting spaces to spaces.
	+ Clearly we need a smarter regexp, that doesn't try to convert already
	converted spaces.
	+ I think this is fixed now

* [test] Indentation facade won't update folded lines
	+ probably should offer to unfold lines
	+ how hard would it be to unfold & then refold?
		- would have to keep track of a lot of things
		- maybe instead, a second loop through folded text.
	+ Took the second-loop approach: seems to be working


Features
========

* File selection menu
	- opening new files
	- flipping between buffers

* Tailor parameters to types of files
	- Currently we only do colors, but we could do things like line-wrap,
	indentation string, etc.

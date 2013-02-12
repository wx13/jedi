This tutorial is designed to get you up and running quickly, and
demonstrate some of the editor's basic capabilities. For more details
about running, configuring, and modifying editor.rb, see the manual.

Getting started
===============

One the major design goals of the editor is to be completely portable.
Thus no installation is required.  You can just type

    ruby editor.rb

(optionally followed by a list of files and/or option flags) to run the editor.
By default, it will not save any history.  See the README file for
other installation options.


Basic editing
=============

Basic editing commands are similar (but not identical) to the gnu-nano
text editor.

The obvious things work: Arrow keys move the cursor around.  Page
up/down move the cursor a longer distance up or down.

Level one commands
------------------

    ^k                 cut (marked text if marked, otherwise current line)
    ^p                 copy (ditto)
    ^u                 paste
    ^a                 go to start of line
    ^e                 go to end of line
    ^w                 search
    ^r                 search and replace
    ^o                 save
    ^q                 quit
    ^g                 go to line (it will ask for a line number)
    ^s                 run a ruby command on the text
    ^d                 delete current character
    ^l                 switch between buffers on a split screen
    ^z                 suspend
    ^x                 mark
    ^n                 switch to next page
    ^b                 switch to previous page
    ^t                 toggle a state (hit 'tab' to see choices)
    ^6                 access extra commands (b/c there aren't enough keys)
    shift-arrow        scroll the buffer
    ^left/right        undo/redo
    ^shift-left/right  undo/redo to last saved state



Some handy tricks
=================

Indent a block of text
----------------------
1. Set the cursor mode to column: `^tc` (default for editing code)
2. Mark the first (last) line of the block: `^x`
3. Navigate to the last (first) line.
4. Now you have a long vertical cursor which you can use to add or
remove any text you want.

To add stuff to the end of a set of lines, do the same as above, but
put the cursor mode to nmuloc (`^tC`).  Then the long vertical cursor
is positioned with respect to the end of the line.


Fold some text
--------------

1. Mark the first (last) line: `^x`
2. Navigate to the last (first) line and type `^6h`

Unfold with `^6u`. To fold all the classes in a ruby file

1. type `^6H`
2. enter the start pattern: `^class`  (literal carat, not control)
3. enter the end pattern: `^end`  (literal carat, not control)

To unfold all folded lines, type `^6U`. To fold all comments

1. type `^6H`
2. enter the start pattern `^\s*#`
3. enter the end pattern `^n`  (control-n)


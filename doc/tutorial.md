This tutorial is designed to get you up and running quickly, and
demonstrate some of the editor's basic capabilities. For more details
about running, configuring, and modifying editor.rb, see the manual.

Getting started
===============

One the major design goals of the editor is to be completely portable.
Thus no installation is required.  You can just type

    ruby editor.rb

(optionally followed by a list of files and/or option flags) to run the editor.
By default, it will not save any history.

Typically, you would want to have configuration and history saved
somewhere. The -s   flag tells the editor to load and execute a script
file at start-up, and the -y flag   tells the editor to store history
in a file.  A sensible way to structure things   is to create a
directory, say $HOME/.editor.  Then run

    ruby editor.rb -s $HOME/.editor -y $HOME/.editor/history.yaml

This will run at start-up any file in $HOME/.editor/ with the ".rb" extension.


Basic editing
=============

If you have used the gnu-nano text editor, then you will be in
familiar territory. In addition to the standard way of editing text
(arrow keys, page-up/down, backspace, etc) there are a number of handy
shortcuts.  Here is a list of commonly used commands:

    ^k           cut (marked text if marked, otherwise current line)
    ^p           copy (")
    ^u           paste
    ^a           go to start of line
    ^e           go to end of line
    ^w           search
    ^r           search and replace
    ^o           save
    ^q           quit
    ^g           go to line (it will ask for a line number)
    ^s           run a ruby command on the text
    ^d           delete current character
    ^l           switch between buffers on a split screen
    ^z           suspend
    ^x           mark
    ^n           switch to next page
    ^b           switch to previous page
    ^t           toggle a state
    ^6           access extra commands (b/c there aren't enough keys)
    S[arrow]     scroll the buffer
    ^S[U/D]      scroll all buffers on the page
    ^[L/R]       undo/redo
    ^S[L/R]      (un)revert to saved


Some handy tricks
=================


Indent a block of text
----------------------
1. Set the cursor mode to column: `^tc`
2. Mark the first (last) line of the block: `^x`
3. Navigate to the last (first) line.
4. Now you have a long vertical cursor which you can use to add or
remove any text you want.


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


This tutorial is designed to get you up and running quickly, and
demonstrate some of editor.rb's capabilities. For more details about
running, configuring, and modifying editor.rb, see the manual.

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


Editing text
============

If you are familiar with the gnu-nano text editor, then you will be in
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
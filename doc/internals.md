This document describes the internal structure and algorithms of the
editor.rb code.


Overview of classes
===================

The code is contained in a single file, for portability reasons.  Thus
all code is found in editor.rb.  The code is split into 9 classes. This
section describes them in the order they occur in the code.


Screen
------

The Screen class manages screen output and user input.  Some things it
is respnsible for

 * Define the color escape codes and key codes
 * Recieve keypresses
 * Start, suspend, resume, and close the interactive session
 * Position the cursor in the terminal
 * Write/clear text to/from the terminal
 * Display messages for the user
 * Display the status bar
 * Ask the user a question
 * Display a menu of choices to the user


Window
------

The Window class manages a virtual window within the screen.  Some
things it is responsible for

 * Map positions within a window to positions on the screen
 * Determine the window size and position, given the number of other
   windows on the screen and the stacking orientation
 * Act as a pass-through to the Screen class, so that a buffer only
   interacts with a window


FileBuffer
----------

The FileBuffer class manages everything about a single file buffer. It
is huge, because it contains all the text editing functionality.  What
it does:

 * Let the user enter a ruby command or script file
 * Bookmark positions in the file
 * Read/save/reload files
 * A whole slew of text modifications on the buffer text
 * Navigation and scrolling
 * Search and replace
 * Marking, copying, cutting, and pasting
 * Syntax coloring and hightlighting
 * Send text to the window for display
 * Map buffer position to screen position and back
 * Text folding/hiding
 * Manage the indentation facade


BufferHistory
-------------

The BufferHistory class keeps track of buffer states for undo and redo.

 * Take snapshots of the current text state
 * Prune the history tree if it gets too big
 * Determine if the buffer has been modified


BufferList
----------

The BufferList class keeps track of all the buffers that are open.

 * Keep track of which buffers are on which pages
 * Let the user switch between buffers and pages
 * Open and close buffers
 * Move buffers between pages


KeyMap
------

The KeyMap class defines the keyboard presses for doing stuff.

 * Store the mapping between keys and commands


Histories
---------

The Histories class manages the search/script/command/folding
histories.

 * Read/save histories from/to history file


SyntaxColors
------------

The SyntaxColors class defines the syntax colors.  It is just a
container class.


Editor
------

The Editor class orchestrates everything.

 * Set default parameter values
 * Declare other classes
 * Parse command-line options
 * Run start-up scripts
 * Start user interaction loop


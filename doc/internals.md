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



Algorithm details
=================

This section describes some details about how the editor does its thing.


The text buffer
---------------

The actual file text is stored as an array of strings.  Each line from
the input file becomes an element.  Any combination of line-ending
characters ("\r","\n","\r\n") is considered to be then end of the line.
Which ever line-ending sting is used, is stored up for writing the text
buffer to file. If the line-endings are mixed, then the output file
will not be the same as the input file.

When modifying the text buffer, two important things must be kept in
mind.  First, never replace the entire buffer.  For example to copy
the buffer `text` into `@text`, use

    @text.slice!(1..-1)
    text.each{|k|
        @text[k] = text[k]
    }

instead of

    @text = text

The second form create an entirely new array. This causes two problems:
1) the buffer history becomes much less efficient in both space and
time; 2) if the same file is open in two buffers, the buffers will
diverge.

The second thing to keep in mind is when modifying a single line,
always replace the entire line.  For example do

    @text[@row] = @text[@row].gsub(/x/,'y')

instead of

    @text[@row].gsub!(/x/,'y')

History snapshots of the text buffer are shallow copies.  The first
method causes the current buffer to differ from the previous buffer at
one line, making the change undo-able.  The second method modifies the
line of the current buffer *and* the previous buffer (because they are
the same in memory), and is thus not undo-able.


Buffer history
--------------

As alluded to above, history snapshots of the text buffer are shallow
copies.  This is one of the advantages of using ruby, in that we can
take a snapshot with `@text.dup`.  This duplicates the *array*, but the
elements of the array are identical in memory.  Thus we create a new
array containing all the old strings.


Multiple editing of the same file
---------------------------------

Sometimes it is convenient to edit the same file in multiple windows.
We do this by:

 1. dup'ing the buffer (which gives a new buffer with all the old data)
 2. dup'ing the window (so we have a different display)

This way we have a different window, but all the parameters and
histories and text are linked together.  Each buffer thinks it is
independent, but the information is shared behind the scenes.


Text folding/hiding
-------------------

Text folding is almost trivial in this buffer model.  We just replace
the folded lines (elements in the array) with an array of strings.  So
unfolded lines are string elements of the text buffer array, and folded
lines are array elements of the text buffer array.  The only
complication, is that we must be careful to check if a line is a string
or array before we modify or display it.  Other than that, things like
copy/paste don't care if they are moving strings or arrays around in
the buffer.


Indentation facade
------------------

One of the cool features of this editor is the indentation facade,
where the actual (file) indentation strings differ from the apparent
indentation strings.  So you can edit a file indented by spaces, but
pretend as if it is indented by tabs.  Most of the work is in checking
that things are sane (e.g. no mixing of indentation strings) and
getting input from the user.  The real work is done with

	@text.map{|line|
		efis = Regexp.escape(@fileindentstring)
		after = line.split(/^(#{efis})+/).last
		next if after.nil?
		ni = (line.length - after.length)/(@fileindentstring.length)
		line.slice!(0..-1)
		line << @indentstring * ni
		line << after
	}

This simply swaps out one indentation string for another in the buffer
text.  Notice that this violates the rule of not modifying the text
buffer strings.  This is on purpose, to fool the buffer history into
thinking that the file hasn't changed.  The only other thing, is to
convert back the indentation on saving the file.







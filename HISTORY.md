0.4.2
-----

Bug fixes:

  + Now compatible with ruby 1.8.5 and 1.8.6.

Clean up:

  + Various clean-ups
    - Reduce duplicate code
    - Move some methods out of FileBuffer, to reduce its size.

Features:

  + Memory of column position on cursor up/down.
    - This is something other editors do, which I resisted for a long
      time. I felt it violated the principle of least surprise (the
      behavior of cursor up/down would depend on more than the current
      position), but the truth is that this is very handy.
  + Let backups be toggle-able from in the editor.


0.4.1
-----

Bug fixes:

  + Fixed potential crashing caused by bad color specification in
    config file.
  + Fixed typo in set_cursor_color, which could cause crashing.
  + Fixed terminal resize bug, where other pages did not resize.
  + Fixed ruby version specific bug that only affects development (not
    installed or single-file editor)
  + Changed puts to print in show_cursor method (newline difference)
  + Nmuloc mode was crashing when cursor went off the screen. Fixed.

Clean up:

  + Better documentation organization
  + Added a man page
  + Changed backup-file suffix to a prefix, for less cluttered
    directories.

Features:

  + Better handling of character encodings (see commit c4ed7a2 for more
    details.
      - Handle mixed, incompatible encodings
      - Allow ruby 1.8 users to convert multi-byte characters to tildes,
        for easier editing.
      - Force reading/writing to UTF-8 if available.
  + Better handling of regexp search/replace.  Can now use /(...)(...)/
    type notation in search and ...\1...\2... type notation in replace.
    Makes for more powerful search/replace.

0.4.0
-----

Mostly code restructuring changes.

Bug fixes:

  + Better handling of replace strings for search/replace
  + Potential issue with handling of keyboard input (never occured in
    practice, though)
  + Fixed seversl bugs that arose when putting many windows on the same
    screen.
  + Allow user to cancel command execution


Clean up:

  + Significant refactoring
    - Separated code into multiple files
    - Wrote a bash script to combine into a single file
    - Moved a bunch of stuff out of FileBuffer, and into other classes
  + Make commands run in scope of the FileBuffer, rather than globally.
    Makes more sense to me.

Features:

  + Yes-to-all option for search/replace


0.3.0
-----

Bug fixes:

  + Cursor placement on undone auto-indent.
    - When we undo an auto-indent, the cursor should end up at the
      start of the line.  It was going to the previous line.
  + Proper tab completion in filenames.
    - previous efforts to clean up the file selector code caused this
      behavior to disappear.
  + Prevent line-wrap from chocking on some nil lines.
  + Don't depend on terminal for non-linewrapping.
    - some terminals do funky things; instead manually measure the
      correct line length.

Clean up:

  + Removed explicit references to the escape character outside of the
    terminal class
  + Simplified syntax coloring and line output.

Features:

  + Undo autoindent whitespace separately from non-whitespace.
    - When autoindent involves non-whitespace characters, separate
      snapshots so that we can quickly undo unwanted autoindents.
  + Save buffer history to a backup file. Then resuming the editor will
    read in the old history and use it as the buffer history.


0.2.2
-----

Bug fixes:

Speed up:

  + More efficient screen writing.

Clean up:

  + Simplified the ask method.
  + More consistent menu method.

Features:

  + Multiple saved states for BufferHistory.  This way you can jump
    between macroscopic snapshots of the buffer.
  + Use 'row' mode even in col mode, when the cursor is on the same
    line as the start of the mark.
  + Copy buffer history, plus menu for selecting from recent
    copy/pastes.
  + Search in a menu.
  + Installation script.
  + Allow indentation in line-wrapping mode.  Good for writing markdown
    text.

0.2.1
-----

Bug fixes:

  + Improved syntax coloring algorithm
  + Handle large negative line numbers (go-to)

0.2.0
-----

Bug fixes:

  + Correct ordering of session restoring keycodes on exit.
  + Save-to-file when in indentation facade was removing the
    last line of the file.
  + Make save-to-file atomic (so we don't lose information when
    something goes wrong).
  + Escape indent strings in indentation facade
    (this allows special characters to be used for indentation).
  + Make sure show_cursor is run on exit/suspend.
  + Handle crazy terminal sizes better.

Clean up:

  + Moved all terminal interaction to its own module.
  + Allow editmode to be multivalued, to allow extensions
    to add modes.

Features:

  + Search-and-replace only in marked text.
  + Allow config parameters to be determined by filetype.
  + Optional mouse support (moved from extension to main code).


0.1.1
-----

Fixed some non-critical search-and-replace bugs.

0.1.0
-----

Initial release.
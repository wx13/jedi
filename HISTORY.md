Bug fixes:

  + Cursor placement on undone auto-indent.
    - When we undo an auto-indent, the cursor should end up at the
      start of the line.  It was going to the previous line.
  + Proper tab completion in filenames.
    - previous efforts to clean up the file selector code caused this
      behavior to disappear.

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
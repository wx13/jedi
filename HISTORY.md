Bug fixes:

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
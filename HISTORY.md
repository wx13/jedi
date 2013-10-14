0.4.7
-----

Bug fixes:

 + Fixed some bugs in the test code
 + Set a default histories file location
 + Undo/redo issues when changes were made a the end of a file.
 + Handle empty history file

Clean up:

 + Split Antsy code into 3 files.
 + Removed some redundant code
 + Replaced a bunch of methods with "missing_method"

Features:

 + Drop into an IRB session at any time.  All the editor variables and
   methods will be accessible.
 + Syntax coloring for R


0.4.6
-----

Bug fixes:

  + Fixed some issues with character input and various terminals
  + Fixed a mouse highlighting crash
  + Set stdout.sync = true to prevent output deadlocking
  + Fixed some regexp issues
  + Fixed crashing when cancelling menu search
  + Fixed string compatability code errors
  + Fixed some text code errors
  + Fixed two indentation facade bugs

Clean up:

  + Updated documentation
  + Prettier folded text
  + Handle tabs in ask line
  + Don't clear as many lines on startup

Features:

  + Copy text to/ from xclip (if available)


0.4.5
-----

Bug fixes:

  + When loading backups, must turn array into TextBuffer array
  + Search/replace: jump length-1 columns to ensure we catch an adjacent
    match
  + Option to turn off suspending, for systems without unix job control.
  + Create an empty buffer when opening a directory.
  + Justify can now handle very long words.
  + Fixed a few syntax coloring bugs.
  + Fixed handling of regex search terms
  + Fixed handling of folded text for very narrow screens

Clean up:

  + Moved documentation to ronn

Features:

  + Horizontal scroll option: entire screen or single line.
  + Easier to change the tab character
  + Support for local config files (local to a directory tree)


0.4.4
-----

Bug fixes:

  + Reading an empty file should result in [""], not [].

Clean up:

  + Added a bunch of test code.
  + Moved some stuff around, due to test code structure.

Features:

  + Can use install.sh to install globally as root.


0.4.3
-----

Bug fixes:

  + Update nmuloc mode to behave like column mode for single-line stuff.
  + Fix two mistakes in recently introduced compatiblity code.
  + Better cursor position in some situations
  + Handle long words in justify/linewrap.
    - If word was longer than the wrap length, weird things happened.
  + Made syntax color rules accessible outside syntax colors class, so
    things can be set from a config script.
  + Use index instead of match (in syntax colors) to avoid regex
    weirdness.
  + Run update_indentation on save.
  + write_message can now handle non-strings.
  + Better handling of unknown keypresses

Clean up:

  + Created FileAccessor class
    - Handles interactions with the file.
    - Lightens the load of the FileBuffer class
  + Created utils.rb to handle some basic string/array stuff. Lightens
    the load on FileBuffer class.
  + Simplified some complex methods:
    - copy/paste
    - search/replace
  + Code organization
    - moved jedi to run_jedi in root dir
    - automatically include all files in src directory

Features:

  + Better cursor position for undo/redo
    - Move cursor to changed line before making the change.
  + Indentations string swapping using object ids
    - For indentation facade, swap indentation strings throughout history,
      so that undo/redo is seamless
  + Shorten saved history length for large files, for speedup.


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
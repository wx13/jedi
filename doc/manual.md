Installation
============

One the major design goals of the editor is to be completely portable.
Thus no installation is required.  You can just type `ruby editor.rb`
(optionally followed by a list of files and/or option flags) to run the
editor. By default, it will not save any history.

Typically, you would want to have configuration and history saved
somewhere. The `-s` flag tells the editor to load and execute a script
file at start-up, and the `-y` flag tells the editor to store history
in a file.  A sensible way to structure things is to create a
directory, say $HOME/.editor.  Then run

	ruby editor.rb -s $HOME/.editor -y $HOME/.editor/history.yaml

This will run at start-up any file in $HOME/.editor/ with the ".rb"
extension.


Configuration
=============

Key Bindings
------------

Keybindings are very easy to change. This section gives an overview of how
to configure keybindings of your liking.  The key bindings are stored in
an instance (`$keymap`) of the class `KeyMap`. This class contains five
hashes: `commandlist` (global keys), `extramode_commandlist` (for keys
that don't fit elsewhere), `editmode_commandlist` (only work when
editing), `viewmode_commandlist` (only work in view-mode), and
`togglelist` (toggle various states).

To change keybindings with in a configuration file, you can do something like:

	$keymap.commandlist[:ctrl_n] = "buffer.page_down"
	$keymap.commandlist[:ctrl_p] = "buffer.page_up"

Or to completely change all of them:

	$keymap.commandlist = {
		:ctrl_n => "buffer.page_down",
		:ctrl_p => "buffer.page_up",
		...
	}

To see all the default keybindings, search for `/^class KeyMap/` in the file.


Syntax Coloring
---------------

Syntax coloring in editor.rb is very simplistic.  It is only done on a
single line, and uses no parsing of the code structure (only regular
expressions). The colors are inserted into the text (just before
rendering) as special characters. The coloring of elements is set in
the Editor class by the `define_colors` method like this:

	color = {
		:string => :yellow,
		:comment => :cyan,
		:whitespace => [:red,:reverse],
		:hiddentext => :green,
		:status => :underline,
		:message => :yellow,
		:regex => :normal,
		:marked => [:reverse,:blue],
		:message => :yellow,
	}

Changing a color is as simple as:

	$color[:string] = :green

In the config file.  To change colors on the fly is slightly different,
because the colors list gets processed by the `Screen` class.  Hit `^s`
and enter the script:

	$color[:string] = $color[:green]

Syntax coloring is toggle on by the flag `-C` or by the command `^tS`,
and off by the flag `-c` or by the command `^ts`.


Indentation
-----------

The tab key can be configure to insert something other than the literal
tab character.  This can be accomplished on the command line with the
`-T` flag, which takes a string as a parameter.  It can also be set in
a configuration file by setting the `$tabchar` variable.  It can be set
on the fly (for the current buffer only) by setting the `@tabchar`
variable. The width of a literal tab character is set by `-t`,
`$tabsize`, or `@tabsize` respectively.


Cursor color
------------

On some terminals (notably gnome-terminal), the cursor is set to be the
the reverse of the text. This can cause problems when the text in the
editor is reversed, because the cursor can get hidden.  Some terminals
support dynamic setting of the cursor color.  The configuration
parameter `$cursor_color` can be set in the configuration file.  Or
else `^6C` will prompt you for a color.

Note that this will change the cursor color for the terminal, and will
remain in effect even after exiting the editor.  To change back, either
use the same command within the editor, or type

	echo -e "\e]12;${color}\007"

where color is the desired cursor color.


Editing
=======

Undo and Redo
-------------

The text for each buffer is stored in an array of strings.  Each string
is a line of text.  Ruby's shallow copy functionality means that after
each text change, we can store a snapshop of the text buffer.  These
snapshots are managed by the BufferHistory class.  Each buffer has its
own instance of this class.

By default the ctrl-left/right arrow keys are bound to undo/redo, and
the shift-ctrl-left/right arrow keys are bound to revert-to-saved and
unrevert-to-saved.  This last pair undoes all changes since the last
time the file was saved, and redoes all changes back to the last revert
request.  Note that this is different from reloading the file (`^6R`)
for two reasons: 1.) the file may have been changed by another program;
2.) revert moves you around the change history, while reload adds a new
set of changes to the tip of the change history.


Multiple buffers
----------------

You can edit multiple files in one of three ways

1. speficy them on the command line
2. open a new file with `^f`
3. open a duplicate window on the current file with `^6f`

Initially each buffer is on its own screen.  If multiple buffers are
open, the status bar will show how many are open and which (number)
buffer you are currently editing.  The keys `^n` and `^b` go to the
next and previous pages.

Multiple buffers can be displayed on the same screen with one of the
following:

1. move all buffers onto one screen: `^60` (if all buffers are already
on one screen, this will spread them out onto their own screens).
2. move the current buffer to another screen: `^6#` where `#` is a
number from 1-9. It is possible to have more than 9 screens (it is
unlimited, actually), but only 1-9 are available for this operation.


Indentation facade
------------------

If you like to use a different indentation character/string than is
used the file, but you don't want to change every line of the file,
then indentation facade is what you are looking for.  Type `^6i` and
you will be prompted for the file indentation string. This is the
string the file currently uses for indentation.  Next it will prompt
you for the desired indentation string.

From then on, the text will appear to use the desired indentation
string, but silently convert behind the scenes.


Cursor modes
------------


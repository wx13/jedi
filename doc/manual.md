Installation
============

One the major design goals of the editor is to be completely portable.
Thus no installation is required.  You can just type "ruby editor.rb"
(optionally followed by a list of files and/or option flags) to run the
editor. By default, it will not save any history.

Typically, you would want to have configuration and history saved
somewhere. The -s flag tells the editor to load and execute a script
file at start-up, and the -y flag tells the editor to store history in
a file.  A sensible way to structure things is to create a directory,
say $HOME/.editor.  Then run

	ruby editor.rb -s $HOME/.editor -y $HOME/.editor/history.yaml

This will run at start-up any file in $HOME/.editor/ with the ".rb"
extension.

Key Bindings
============

Keybindings are very easy to change. This section gives an overview of how
to configure keybindings of your liking.  The key bindings are stored in
an instance (`$keymap`) of the class `KeyMap`.
This class contains five hashes:

*commandlist*
keybindings that work in both editmode and view mode

*extramode_commandlist*
less frequently used keybindings, which require an extra keypress to get to

*editmode_commandlist*
keybindings for edit mode only

*viewmode_commandlist*
keybindings for view mode only

*togglelist*
special list of toggles (turning modes on and off)

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
===============

Syntax coloring in editor.rb is very simplistic.  It is only done on a
single line, and uses no parsing of the code structure (only regular
expressions). The colors are inserted into the text (just before
rendering) as special characters. Each change in color is two
characters: $color followed by $color_green for example. The coloring
of elements is set by the code

	$color[:string] = :yellow
	$color[:comment] = :cyan
	$color[:whitespace] = [:red,:reverse]
	$color[:hiddentext] = :green
	$color[:status] = :underline
	$color[:message] = :yellow

more to come...
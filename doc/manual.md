jedi users manual
=================


Jedi is a text editor written in ruby for the unix console.  It is
designed to be portable and hackable.


Contents
--------

1. [Getting started](#tutorial)
	1. [Installation](#install)
	2. [Basic usage](#usage)
2. [Configuration](#config)
3. [Advanced usage](#advanced)
4. [Hacking the code](#hacking)
	1. [Writing extensions](#extend)
	2. [Code structure](#code_structure)
	3. [Algorithm details](#algo)



<a id="tutorial"></a>
## Getting Started

This section will get you up-and-running quickly.



<a id="install"></a>
### Installation

One the major design goals of the editor is to be completely portable.
Thus no installation is required.  You can just type

	ruby editor.rb

(optionally followed by a list of files and/or option flags) to run the editor.
By default, it will not save any history.  See the README file for
other installation options.

Typically, you would want to have configuration and history saved
somewhere. The `-s` flag tells the editor to load and execute a script
file at start-up, and the `-y` flag tells the editor to store history
in a file.  A sensible way to structure things is to create a
directory, say $HOME/.jedi.  Then run

	ruby jedi.rb -s $HOME/.jedi -y $HOME/.jedi/history.yaml

This will run at start-up any file in $HOME/.editor/ with the ".rb"
extension.  The script `install.sh` will automate this process.

For development purposes, the code is split into multiple files.  The
install script calls `make_jedi.sh` which constructs a single file
code.  This is useful if you want to the single file, without doing an
install.



<a id="usage"></a>
### Basic usage

Basic editing commands are similar (but not identical) to the gnu-nano
text editor.

The obvious things work in the obvious ways: Arrow keys move the cursor
around. Page up/down move the cursor a longer distance up or down.

#### Level one commands

	^k                 cut (marked text if marked, otherwise current line)
	^p                 copy (ditto)
	^u                 paste
	^a                 go to start of line
	^e                 go to end of line
	^w                 search
	^r                 search and replace
	^o                 save
	^q                 quit
	^g                 go to line (it will ask for a line number)
	^s                 run a ruby command on the text
	^d                 delete current character
	^l                 switch between buffers on a split screen
	^z                 suspend
	^x                 mark
	^n                 switch to next page
	^b                 switch to previous page
	^t                 toggle a state (hit 'tab' to see choices)
	^6                 access extra commands (b/c there aren't enough keys)
	shift-arrow        scroll the buffer
	^left/right        undo/redo
	^shift-left/right  undo/redo to last saved state



#### Some handy tricks

##### Indent a block of text

1. Set the cursor mode to column: `^tc` (default for editing code)
2. Mark the first (last) line of the block: `^x`
3. Navigate to the last (first) line.
4. Now you have a long vertical cursor which you can use to add or
remove any text you want.

To add stuff to the end of a set of lines, do the same as above, but
put the cursor mode to nmuloc (`^tC`).  Then the long vertical cursor
is positioned with respect to the end of the line.


##### Fold some text

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




<a id="config"></a>
## Configuration


### Key Bindings

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


### Mouse wheel

When mouse mode is enabled, scrolling the wheel should scroll the
screen.  This does not work in an xterm, because xterm does not use the
standard mouse wheel key codes.  Putting the following code into your
.Xdefaults file:

	xterm*VT100.translations: #override <Key>F1: keymap(x)
	xterm*VT100.xKeymap.translations: \
		<Key>F1: keymap(y) \n\
		<Btn4Down>,<Btn4Up>: string("0x1B") string("[M`11") \n\
		<Btn5Down>,<Btn5Up>: string("0x1B") string("[Ma11") \n\
		Ctrl<Btn4Down>,<Btn4Up>: string("0x1B") string("[Mp11") \n\
		Ctrl<Btn5Down>,<Btn5Up>: string("0x1B") string("[Mq11")
	xterm*VT100.yKeymap.translations: \
		<Key>F1: keymap(x) \n\
		<Btn4Down>,<Btn4Up>: scroll-back(4,line) \n\
		<Btn5Down>,<Btn5Up>: scroll-forw(4,line) \n\
		Ctrl <Btn4Down>,<Btn4Up>: scroll-back(1,halfpage) \n\
		Ctrl <Btn5Down>,<Btn5Up>: scroll-forw(1,halfpage)

will let you toggle between xterm scrolling and editor.rb scrolling by
hitting the F1 key.  Enable mouse mode with the -M flag or by hitting
`^TM`.  Then hit F1 to scroll the editor.rb screen.  Hit F1 again to
scroll the xterm window. And hit F1 to go back to editor.rb scrolling.


### Syntax Coloring

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


### Indentation

The tab key can be configure to insert something other than the literal
tab character.  This can be accomplished on the command line with the
`-T` flag, which takes a string as a parameter.  It can also be set in
a configuration file by setting the `$tabchar` variable.  It can be set
on the fly (for the current buffer only) by setting the `@tabchar`
variable. The width of a literal tab character is set by `-t`,
`$tabsize`, or `@tabsize` respectively.


### Cursor color

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


<a id="advanced"></a>
## Advanced Editing

### Undo and Redo

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


### Multiple buffers

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

Typing `^t-` will set vertical stacking (buffers aligned above one
another) and `^t|` will set horizontal stacking (side-by-side buffers).
To scroll only the current buffer up/down, use shift-up/down.  To
scroll all the buffers on the current screen up/down, use ctrl-up/down.


### Indentation facade

If you like to use a different indentation character/string than is
used the file, but you don't want to change every line of the file,
then indentation facade is what you are looking for.  Type `^6i` and
you will be prompted for the file indentation string. This is the
string the file currently uses for indentation.  Next it will prompt
you for the desired indentation string.

From then on, the text will appear to use the desired indentation
string, but silently convert behind the scenes.


### Marking modes

There are four cusor modes for marked text.  In 'row' mode, the text is
marked row-wise from the mark to the current position.  In 'col' mode,
the text is marked in a vertical column from the current position to
the start row.  In this mode, the marked column acts like a long
cursor, where you can insert, delete, or backspace along the vertical
bar.  Type `^tr` to toggle row mode, and `^tc` to toggle column mode.

The third mode is 'loc' (backwards 'col').  It is exactly the same as
'col', but position is relative to the end of the line.  Type
`^tC` to toggle nmuloc mode.  Finally, there is multicursor mode.  Type
`^6x` to start marking the cursors.  Each time you hit `^x` a new
cursor appears.  Type `^6x` again to exit cursor selection mode.  Now
you will have a set of cursors which act as one.This tutorial is designed to get you up and running quickly, and
demonstrate some of the editor's basic capabilities. For more details
about running, configuring, and modifying editor.rb, see the manual.



<a id="hacking"></a>
## Hacking the code

Jedi is designed to be hackable.  Thanks to ruby, jedi has the
following properties:

- Low-level string handling is hidden away
	+ Ruby's powerful and flexible built-in string handling allow us to
	  focus on high-level processing.  This keeps the code cleaner and
	  easier to read.
- Ruby's meta-programming allows the editor to be modified on the fly.
	+ Configuration and extension are one-and-the-same.  Any valid ruby
	  code can be evaluated at start-up or during run-time.
	+ Local code modifications can live in a separate file, making version
	  updates and code testing simple.
- Interpreted code with no third-party libraries makes the code
  portable
	+ No building or linking necessary to test modifications.  Change
	  something and run it, to see if it works.


<a id="extend"></a>
### Writing extensions

As described above, writing extensions is simple.  This is probably
best described with an example.  Suppose you want jedi to confirm with
the user before suspending the editor.  Create a file called something
like 'my_extension.rb' and put in it:

	class BuffersList
		def suspend
			ans = $screen.ask_yesno("Suspend?")
			if ans == "yes"
				$screen.suspend
				update_screen_size
			else
				$screen.write_message("Cancelled.")
			end
		end
	end

Then run

	jedi -s my_extension.rb ...

All we did was rewrite the suspend method in a separate file.  This new
method overwrites the old one on start-up.



<a id="code_structure"></a>
### Code structure

The code is split into multiple files for ease of development.  The
files are combined by a simple script upon installation.  This way the
code can be carried around as a single file, for ultimate portability.
The files are:

- jedi.rb
	+ Creates an instance of the Editor class and runs it.
- editor.rb
	+ Creates instances of Screen, BuffersList, KeyMap, etc, and runs
	  startup stuff.
- ansty.rb
	+ Contains everything related to terminal/screen/window interaction.
- keymap.rb
	+ Defines the keymapping
- bufferslist.rb
	+ Manages multiple file buffers, including moving them around from
	  screen to screen, opening and closing, etc.
- filebuffer.rb
	+ Contains everything related to storing and processing text.
- bufferhistory.rb
	+ Manages a list of text buffer states for undo/redo.
- histories.rb
	+ Stores, saves, and reads histories for: search terms, commands,
	  autofolding, etc.
- syntaxcolors.rb
	+ Everything related to syntax coloring



<a id="algo"></a>
### Algorithm details

This section describes some details about how the editor does its thing.
It is not yet comprehensive.


#### The text buffer

The actual file text is stored as an array of strings.  Each line from
the input file becomes an element.  Any combination of line-ending
characters ("\r","\n","\r\n") is considered to be then end of the line.
Which ever line-ending sting is used is stored up for writing the text
buffer to file. If the line-endings are mixed, then the output file
will not be the same as the input file.  Hypothetically, we could store
up the line-ending characters for each line; but if you are using mixed
line-endings, then you probably don't care about line-endings anyway.

When modifying the text buffer, two important things must be kept in
mind.  First, never replace the entire buffer.  For example to copy
the buffer `text` into `@text`, use

    @text.slice!(1..-1)
    text.each_index{|k|
        @text[k] = text[k]
    }

instead of

    @text = text

The second form replaces the array entirely. This causes two problems:
1) the buffer history becomes much less efficient in both space and
time; 2) if the same file is open in two buffers, the buffers will
diverge.  The first form leaves the array in place, but replaces its
contents.

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


#### Buffer history

As alluded to above, history snapshots of the text buffer are shallow
copies.  This is one of the advantages of using ruby, in that we can
take a snapshot with `@text.dup`.  This duplicates the *array*, but the
elements of the array are identical in memory.  Thus we create a new
array containing all the old strings.


#### Multiple editing of the same file

Sometimes it is convenient to edit the same file in multiple windows.
We do this by:

 1. dup'ing the buffer (which gives a new buffer with all the old data)
 2. dup'ing the window (so we have a different display)

This way we have a different window, but all the parameters and
histories and text are linked together.  Each buffer thinks it is
independent, but the information is shared behind the scenes.


#### Text folding/hiding

Text folding is almost trivial in this buffer model.  We just replace
the folded lines (elements in the array) with an array of strings.  So
unfolded lines are string elements of the text buffer array, and folded
lines are array elements of the text buffer array.  The only
complication, is that we must be careful to check if a line is a string
or array before we modify or display it.  Other than that, things like
copy/paste don't care if they are moving strings or arrays around in
the buffer.


#### Indentation facade

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


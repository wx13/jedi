#
# Example config file
#
# A config file is really no different than a script or extension.
# Arbitrarily complex code can be placed in here.  This file shows
# some simple configuration options.
#


#-----------------------------------------------------------
# Indentation
#-----------------------------------------------------------

# Set the default display width of the tab character.
# This will be the tab display width for all file types,
# unless specified subsequently.
$tabsize = Hash.new(4)

# To leave previous per-filetype specifications alone, and only
# change the default behavior, do this instead.  For example,
# we have previously set the python tab width to 4, this won't
# change that. It will only change it for 'miscillaneous' filestypes.
$tabsize.default = 4

# Set the tab display width for python files.
$tabsize[:python] = 4

# This controls the string that gets inserted when the tab
# key is pressed.
$tabchar = Hash.new("\t")
$tabchar[:yaml] = "  "
$tabchar[:fortran] = " "*6

# Set autoindent preferences.
$autoindent = Hash.new(true)
$autoindent[:text] = false
$autoindent[:markdown] = false

#-----------------------------------------------------------



#-----------------------------------------------------------
# Colors
#-----------------------------------------------------------

# Set the cursor color.  Without this, the default terminal
# cursor is used.  Setting this, sets the actual terminal cursor
# color, which will persist after the editor exits.  There is
# no way to automate resetting the color, because there is no
# way to probe the current cursor color.  To set the cursor color
# outside of the editor, use:
#
#     echo -e "\e]12;color\007"
#
# where 'color' is one of the standar unix colors, such as: green,
# red, yellow, white, cyan, magenta, etc.
$cursor_color = "green"

# Enable syntax coloring.  Similar to the indentation
# section, the first line (re)sets the default.  The subsequent
# lines toggle coloring on/off for individual filetypes.
$syntax_color = Hash.new(true)
$syntax_color[:text] = false
$syntax_color[:markdown] = false

# Choose the colors for syntax coloring.  Currently, there is
# no way to set different colors for different filetypes.
$color[:comment] = :cyan
$color[:string] = :yellow
$color[:whitespace] = [:red,:reverse]
$color[:hiddentext] = :green
$color[:message] = :yellow    # messages at the bottom of the screen
$color[:status] = :underline  # status bar at the top of the screen
$color[:regex] = :normal

# Define a new file type for coloring
$filetypes[/\.foobar$/] = :foobar
$syntax_colors.comments[:foobar] = {'//'=>/$/, '/*'=>'*/'}

#-----------------------------------------------------------


#-----------------------------------------------------------
# Miscillaneous parameters
#-----------------------------------------------------------

# linewrap
$linewrap = Hash.new(false)
$linewrap[:text] = true
$linewrap[:markdown] = true
$linewrap[:git] = true
# Line length for text wrapping (0 = use the terminal width)
$linelength = Hash.new(72)

# start in column-mode for marking/selecting text
$cursormode = Hash.new(:col)
$cursormode[:text] = :row
$cursormode[:markdown] = :row

# Turn on backups
$backups = Hash.new('.~')

# Turn on histories
$histories_file = ENV['HOME'] + "/.jedi/history.yaml"

#-----------------------------------------------------------

#-----------------------------------------------------------
# keybindings
#-----------------------------------------------------------

$keymap.commandlist[:ctrl_q] = "buffer = $buffers.close"
$keymap.commandlist[:ctrl_x] = "buffer.mark"

#-----------------------------------------------------------


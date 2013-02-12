#
# Example config file
#
# All lines are optional (and currenlty set to the default values).

# set the tab width
$tabsize = Hash.new(4)

# What gets inserted when the tab key is pressed
$tabchar = Hash.new("\t")
$tabchar[:yaml] = "  "
$tabchar[:fortran] = "  "

# Cursor color
# Comment out to keep terminal default.
# $cursor_color = "green"

# do autoindent
$autoindent = Hash.new(true)
$autoindent[:text] = false
$autoindent[:markdown] = false

# don't wrap lines
$linewrap = Hash.new(false)
$linewrap[:text] = true
$linewrap[:markdown] = true
$linewrap[:git] = true

# Line length for text wrapping.
# 0 means use the terminal width.
$linelength = Hash.new(72)

# start in column-mode for marking/selecting text
$cursormode = Hash.new('col')
$cursormode[:text] = 'row'
$cursormode[:markdown] = 'row'

# enable syntax coloring & choose colors
$syntax_color = Hash.new(true)
$syntax_color[:text] = false
$syntax_color[:markdown] = false
$color[:comment] = :cyan
$color[:string] = :yellow
$color[:whitespace] = [:red,:reverse]
$color[:hiddentext] = :green
$color[:message] = :yellow
$color[:status] = :underline
$color[:regex] = :normal



#
# keybindings
#

#$keymap.commandlist[:ctrl_q] = "buffer = $buffers.close"
#$keymap.commandlist[:ctrl_x] = "buffer.mark"



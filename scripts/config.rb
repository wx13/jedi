#
# Example config file
#
# All lines are optional (and currenlty set to the default values).

# set the tab width
$tabsize = 4

# What gets inserted when the tab key is pressed
$tabchar = "\t"

# Cursor color
# Comment out to keep terminal default.
# $cursor_color = "green"

# do autoindent
$autoindent = true

# don't wrap lines
$linewrap = false

# Line length for text wrapping.
# 0 means use the terminal width.
$linelength = 72

# start in column-mode for marking/selecting text
$cursormode = 'col'

# enable syntax coloring & choose colors
$syntax_color = true
$color[:comment] = :cyan
$color[:string] = :yellow
$color[:whitespace] = [:red,:reverse]
$color[:hiddentext] = :green
$color[:message] = :yellow
$color[:status] = :underline
$color[:regex] = :normal


#
# Define new syntax coloring schemes
#

# let perl and awk files be colored like shell scripts
$syntax_colors.filetypes[/\.pl$/] = "shell"
$syntax_colors.filetypes[/\.awk$/] = "shell"

# configure html highlighting
$syntax_colors.filetypes[/\.html$/] = "html"
$syntax_colors.bc["html"] = {"<!--"=>"-->"}


#
# keybindings
#

$keymap.commandlist[:ctrl_q] = "buffer = $buffers.close"
$keymap.commandlist[:ctrl_x] = "buffer.mark"



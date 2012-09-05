#
# Example config file
#
# All lines are optional (and currenlty set to the default values).

# set the tab size
$tabsize = 4

# do autoindent
$autoindent = true

# don't wrap lines
$linewrap = false

# start in column-mode for marking/selecting text
$cursormode = 'row'

# enable syntax coloring & choose colors
$syntax_color = true
$color_comment = $color_cyan
$color_string = $color_yellow
$color_whitespace = $color_red


#
# Define new syntax coloring schemes
#

# let perl and awk files be colored like shell scripts
$filetypes[/\.pl$/] = "shell"
$filetypes[/\.awk$/] = "shell"

# configure html highlighting
$filetypes[/\.html$/] = "html"
$syntax_color_bc["html"] = {"<!--"=>"-->"}

#
# keybindings
#

# swap ctrl_x and ctrl_q
$keymap.commandlist[:ctrl_x] = "buffer = $buffers.close"
$keymap.commandlist[:ctrl_q] = "buffer.mark"

# edit mode keybindings
$keymap.edimode_commandlist[:ctrl_r] = "buffer.bookmark"


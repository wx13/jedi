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

# swap ctrl_x and ctrl_q
$keymap.commandlist[:ctrl_q] = "buffer = $buffers.close"
$keymap.commandlist[:ctrl_x] = "buffer.mark"



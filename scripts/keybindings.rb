#
# Example of configuring keybindings
#


# universal keybindings
$commandlist[$ctrl_x] = "buffer = buffer.close"
$commandlist[$ctrl_q] = "buffer = buffer.mark"

# edit mode keybindings
$edimode_commandlist[$ctrl_r] = "buffer.bookmark"


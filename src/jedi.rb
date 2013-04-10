require './editor.rb'
require './antsy.rb'
require './filebuffer.rb'
require './keymap.rb'
require './histories.rb'
require './syntaxcolors.rb'
require './bufferslist.rb'
require './bufferhistory.rb'

#---------------------------------------------------------------------
# Run the editor
#---------------------------------------------------------------------
$editor = Editor.new
$editor.go


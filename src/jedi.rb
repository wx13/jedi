require './editor.rb'
require './antsy.rb'
require './filebuffer.rb'
require './keymap.rb'
require './histories.rb'
require './syntaxcolors.rb'
require './bufferslist.rb'
require './bufferhistory.rb'
require './compatibility.rb'
require './utils.rb'

#---------------------------------------------------------------------
# Run the editor
#---------------------------------------------------------------------
$editor = Editor.new
$editor.go


require './src/editor.rb'
require './src/antsy.rb'
require './src/filebuffer.rb'
require './src/keymap.rb'
require './src/histories.rb'
require './src/syntaxcolors.rb'
require './src/bufferslist.rb'
require './src/bufferhistory.rb'
require './src/compatibility.rb'
require './src/utils.rb'

#---------------------------------------------------------------------
# Run the editor
#---------------------------------------------------------------------
$editor = Editor.new
$editor.go


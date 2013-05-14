#---------------------------------------------------------------------
# Runs the editor for testing purposes.
#---------------------------------------------------------------------

# Require all the files in 'src'.
Dir[File.dirname(__FILE__) + '/src/*.rb'].each{|file|
	require file
}

# Run the editor
$editor = Editor.new
$editor.go

